"""The For You server: /for-you, /profile-text and /health."""

from __future__ import annotations

import logging
import os
import threading
from contextlib import asynccontextmanager
from datetime import datetime
from typing import Callable, Generic, Literal, TypeVar

from fastapi import Depends, FastAPI, Header, HTTPException, Request
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field, field_validator

from .data import DataStore, FirestoreSource, utc_now
from .embeddings import MODEL_NAME, Embedder, fingerprint, profile_texts
from .recommend import for_you
from .vector_store import pack, read, remove, write

log = logging.getLogger("startsa.for_you")
T = TypeVar("T")


class Once(Generic[T]):
    """Builds a value the first time it is asked for, once, even when requests arrive together."""

    def __init__(self, factory: Callable[[], T]):
        self._factory = factory
        self._value: T | None = None
        self._lock = threading.Lock()

    def get(self) -> T:
        if self._value is None:
            with self._lock:
                if self._value is None:
                    self._value = self._factory()
        return self._value


class ForYouItem(BaseModel):
    id: str
    kind: Literal["startup", "investor"]
    score: float


class ForYouResponse(BaseModel):
    items: list[ForYouItem]
    generatedAt: datetime


class ProfileTextRequest(BaseModel):
    kind: Literal["startup", "investor"]
    id: str = Field(min_length=1, max_length=200, pattern=r"^[^/]+$")

    @field_validator("id")
    @classmethod
    def not_a_path(cls, value: str) -> str:
        if value in (".", ".."):
            raise ValueError("not a document id")
        return value


class ProfileTextResponse(BaseModel):
    updated: bool


def _owns(uid: str, kind: str, doc_id: str, doc: dict) -> bool:
    if kind == "investor":
        return doc_id == uid
    members = doc.get("memberIds")
    return doc.get("founderId") == uid or (isinstance(members, list) and uid in members)


def create_app(
    store: DataStore,
    verify_token: Callable[[str], dict],
    embedder: Callable[[], Embedder],
    clock: Callable[[], datetime] = utc_now,
    on_startup: Callable[[], None] | None = None,
) -> FastAPI:
    """verify_token returns the token's claims and raises ValueError for a token that isn't valid."""

    @asynccontextmanager
    async def lifespan(_: FastAPI):
        if on_startup is not None:
            on_startup()
        yield

    app = FastAPI(title="Start.sa For You", lifespan=lifespan)
    model = Once(embedder)

    @app.exception_handler(Exception)
    async def unexpected(request: Request, error: Exception) -> JSONResponse:
        log.error("%s %s failed", request.method, request.url.path, exc_info=error)
        return JSONResponse(status_code=500, content={"detail": "Something went wrong. Try again later."})

    def current_uid(authorization: str | None = Header(default=None)) -> str:
        if not authorization or not authorization.startswith("Bearer "):
            raise HTTPException(status_code=401, detail="Sign in again")
        try:
            claims = verify_token(authorization[len("Bearer "):].strip())
        except ValueError:
            raise HTTPException(status_code=401, detail="Sign in again")
        except Exception:
            log.exception("Checking a login token failed")
            raise HTTPException(status_code=503, detail="Recommendations are unavailable right now. Try again later.")
        uid = claims.get("uid") if isinstance(claims, dict) else None
        if not isinstance(uid, str) or not uid:
            raise HTTPException(status_code=401, detail="Sign in again")
        return uid

    @app.get("/health")
    def health() -> dict:
        return {"status": "ok"}

    @app.post("/for-you", response_model=ForYouResponse)
    def recommend(uid: str = Depends(current_uid)) -> ForYouResponse:
        ctx = store.user_context(uid)
        if ctx is None:
            raise HTTPException(status_code=403, detail="This account has no founder or investor profile")
        now = clock()
        kind = "startup" if ctx.role == "investor" else "investor"
        picks = for_you(ctx, store.snapshot(), now)
        return ForYouResponse(items=[ForYouItem(id=p.id, kind=kind, score=p.score) for p in picks], generatedAt=now)

    @app.post("/profile-text", response_model=ProfileTextResponse)
    def profile_text(request: ProfileTextRequest, uid: str = Depends(current_uid)) -> ProfileTextResponse:
        if store.role_of(uid) is None:
            raise HTTPException(status_code=403, detail="This account has no founder or investor profile")
        collection = "startups" if request.kind == "startup" else "investors"
        doc = store.source.get(f"{collection}/{request.id}")
        if doc is None:
            raise HTTPException(status_code=404, detail="Profile not found")
        if not _owns(uid, request.kind, request.id, doc):
            raise HTTPException(status_code=403, detail="You can only update your own profile")

        key = f"{'s' if request.kind == 'startup' else 'i'}-{request.id}"
        texts = profile_texts(doc, request.kind)
        current = fingerprint(doc, request.kind)
        if not texts:
            remove(store.source, key)
            store.remember_profile(request.kind, request.id, doc, None)
            return ProfileTextResponse(updated=True)
        existing = read(store.source, key)
        if existing and existing.get("model") == MODEL_NAME and existing.get("fingerprint") == current:
            return ProfileTextResponse(updated=False)
        entry = {"v": pack(model.get().profile_vector(texts)), "model": MODEL_NAME, "fingerprint": current}
        write(store.source, key, entry)
        store.remember_profile(request.kind, request.id, doc, entry)
        return ProfileTextResponse(updated=True)

    return app


# --- the production app: Firestore and Firebase Auth are set up on the first request ---

_store = Once(lambda: DataStore(FirestoreSource.from_env()))


class _LazyStore:
    def __getattr__(self, name: str):
        return getattr(_store.get(), name)


def _verify_firebase_token(token: str) -> dict:
    _store.get()  # initialises firebase_admin with the service account
    from firebase_admin import auth

    try:
        return auth.verify_id_token(token)
    except (auth.InvalidIdTokenError, auth.UserDisabledError) as error:  # includes expired and revoked tokens
        raise ValueError(str(error)) from error


logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s: %(message)s")

# Connecting at start-up makes a missing or broken FIREBASE_SERVICE_ACCOUNT_JSON fail the deploy
# instead of answering every request with an error.
app = create_app(
    _LazyStore(),  # type: ignore[arg-type]
    _verify_firebase_token,
    lambda: Embedder(cache_dir=os.environ.get("MODEL_CACHE_DIR")),
    on_startup=lambda: _store.get(),
)
