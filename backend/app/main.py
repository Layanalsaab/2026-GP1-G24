"""The For You server: /for-you, /profile-text and /health."""

from __future__ import annotations

import os
from datetime import datetime
from typing import Callable, Literal

from fastapi import Depends, FastAPI, Header, HTTPException
from pydantic import BaseModel, Field

from .data import DataStore, FirestoreSource, utc_now
from .embeddings import MODEL_NAME, Embedder, fingerprint, profile_texts
from .recommend import for_you


class ForYouItem(BaseModel):
    id: str
    kind: Literal["startup", "investor"]
    score: float


class ForYouResponse(BaseModel):
    items: list[ForYouItem]
    generatedAt: datetime


class ProfileTextRequest(BaseModel):
    kind: Literal["startup", "investor"]
    id: str = Field(min_length=1)


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
) -> FastAPI:
    app = FastAPI(title="Start.sa For You")
    loaded: dict[str, Embedder] = {}

    def get_embedder() -> Embedder:
        if "model" not in loaded:
            loaded["model"] = embedder()
        return loaded["model"]

    def current_uid(authorization: str | None = Header(default=None)) -> str:
        if not authorization or not authorization.startswith("Bearer "):
            raise HTTPException(status_code=401, detail="Sign in again")
        try:
            claims = verify_token(authorization[len("Bearer "):].strip())
        except Exception:
            raise HTTPException(status_code=401, detail="Sign in again")
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
        if store.user_context(uid) is None:
            raise HTTPException(status_code=403, detail="This account has no founder or investor profile")
        collection = "startups" if request.kind == "startup" else "investors"
        doc = store.source.get(f"{collection}/{request.id}")
        if doc is None:
            raise HTTPException(status_code=404, detail="Profile not found")
        if not _owns(uid, request.kind, request.id, doc):
            raise HTTPException(status_code=403, detail="You can only update your own profile")

        path = f"vectors/{'s' if request.kind == 'startup' else 'i'}-{request.id}"
        texts = profile_texts(doc, request.kind)
        current = fingerprint(doc, request.kind)
        if not texts:
            store.source.delete(path)
            store.remember_profile(request.kind, request.id, doc, None)
            return ProfileTextResponse(updated=True)
        existing = store.source.get(path)
        if existing and existing.get("model") == MODEL_NAME and existing.get("fingerprint") == current:
            return ProfileTextResponse(updated=False)
        vector = get_embedder().profile_vector(texts)
        vector_doc = {"vector": [float(x) for x in vector], "model": MODEL_NAME, "fingerprint": current}
        store.source.set(path, vector_doc)
        store.remember_profile(request.kind, request.id, doc, vector_doc)
        return ProfileTextResponse(updated=True)

    return app


# --- the production app: Firestore and Firebase Auth are set up on the first request ---

_store: DataStore | None = None


def _production_store() -> DataStore:
    global _store
    if _store is None:
        _store = DataStore(FirestoreSource.from_env())
    return _store


class _LazyStore:
    def __getattr__(self, name: str):
        return getattr(_production_store(), name)


def _verify_firebase_token(token: str) -> dict:
    _production_store()  # initialises firebase_admin with the service account
    from firebase_admin import auth

    return auth.verify_id_token(token)


app = create_app(
    _LazyStore(),  # type: ignore[arg-type]
    _verify_firebase_token,
    lambda: Embedder(cache_dir=os.environ.get("MODEL_CACHE_DIR")),
)
