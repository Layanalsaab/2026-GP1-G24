"""Reading Firestore: a shared snapshot kept for 30 minutes, and each user's own data."""

from __future__ import annotations

import json
import os
import threading
from dataclasses import dataclass, replace
from datetime import datetime, timedelta, timezone
from typing import Callable, Protocol

ROLES = ("founder", "investor")


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


class Source(Protocol):
    def stream(self, collection: str, field: str | None = None, op: str | None = None, value: object = None) -> list[tuple[str, dict]]: ...

    def get(self, path: str) -> dict | None: ...

    def set(self, path: str, data: dict) -> None: ...

    def delete(self, path: str) -> None: ...


class FirestoreSource:
    """The real Firestore, through firebase-admin."""

    def __init__(self, client):
        self._db = client

    @classmethod
    def from_env(cls) -> "FirestoreSource":
        import firebase_admin
        from firebase_admin import credentials, firestore

        if not firebase_admin._apps:
            info = json.loads(os.environ["FIREBASE_SERVICE_ACCOUNT_JSON"])
            firebase_admin.initialize_app(credentials.Certificate(info))
        return cls(firestore.client())

    def stream(self, collection: str, field: str | None = None, op: str | None = None, value: object = None) -> list[tuple[str, dict]]:
        from google.cloud.firestore_v1.base_query import FieldFilter

        query = self._db.collection(collection)
        if field is not None:
            query = query.where(filter=FieldFilter(field, op, value))
        return [(doc.id, doc.to_dict() or {}) for doc in query.stream()]

    def get(self, path: str) -> dict | None:
        snap = self._db.document(path).get()
        return snap.to_dict() if snap.exists else None

    def set(self, path: str, data: dict) -> None:
        from firebase_admin import firestore

        self._db.document(path).set({**data, "updatedAt": firestore.SERVER_TIMESTAMP})

    def delete(self, path: str) -> None:
        self._db.document(path).delete()


@dataclass
class Snapshot:
    startups: dict[str, dict]
    investors: dict[str, dict]
    tickets: list[dict]
    vectors: dict[str, dict]
    loaded_at: datetime


@dataclass
class UserContext:
    uid: str
    role: str
    user_doc: dict
    bookmarks: dict[str, datetime]
    dislikes: dict[str, datetime]
    own_startups: dict[str, dict]


def _as_time(raw: object, fallback: datetime) -> datetime:
    if not isinstance(raw, datetime):
        return fallback
    return raw if raw.tzinfo is not None else raw.replace(tzinfo=timezone.utc)


def _docs(rows: list[tuple[str, dict]]) -> dict[str, dict]:
    return {doc_id: data for doc_id, data in rows if isinstance(data, dict)}


class DataStore:
    def __init__(self, source: Source, ttl: timedelta = timedelta(minutes=30), clock: Callable[[], datetime] = utc_now):
        self.source = source
        self._ttl = ttl
        self._clock = clock
        self._snapshot: Snapshot | None = None
        self._lock = threading.Lock()  # requests run in a thread pool

    def snapshot(self) -> Snapshot:
        with self._lock:
            now = self._clock()
            if self._snapshot is not None and now - self._snapshot.loaded_at < self._ttl:
                return self._snapshot
            self._snapshot = Snapshot(
                startups=_docs(self.source.stream("startups", "isPublic", "==", True)),
                investors=_docs(self.source.stream("investors")),
                tickets=list(_docs(self.source.stream("tickets", "status", "==", "open")).values()),
                vectors=_docs(self.source.stream("vectors")),
                loaded_at=now,
            )
            return self._snapshot

    def remember_profile(self, kind: str, doc_id: str, doc: dict, vector_doc: dict | None) -> None:
        """After an edit, put the new text and vector into the cached snapshot so they count at once.

        Builds new dictionaries instead of changing the cached ones, so a request that is
        reading the old snapshot in another thread is never disturbed.
        """
        with self._lock:
            snap = self._snapshot
            if snap is None:
                return
            group = "startups" if kind == "startup" else "investors"
            docs = dict(getattr(snap, group))
            if kind != "startup" or doc.get("isPublic") is True:
                docs[doc_id] = doc
            vectors = dict(snap.vectors)
            key = f"{'s' if kind == 'startup' else 'i'}-{doc_id}"
            if vector_doc is None:
                vectors.pop(key, None)
            else:
                vectors[key] = vector_doc
            self._snapshot = replace(snap, **{group: docs}, vectors=vectors)

    def _dated(self, collection: str, now: datetime) -> dict[str, datetime]:
        return {key: _as_time(data.get("createdAt"), now) for key, data in _docs(self.source.stream(collection)).items()}

    def user_context(self, uid: str) -> UserContext | None:
        user = self.source.get(f"users/{uid}")
        if not isinstance(user, dict) or user.get("role") not in ROLES:
            return None
        now = self._clock()
        own = _docs(self.source.stream("startups", "founderId", "==", uid))
        own.update(_docs(self.source.stream("startups", "memberIds", "array-contains", uid)))
        return UserContext(
            uid=uid,
            role=user["role"],
            user_doc=user,
            bookmarks=self._dated(f"users/{uid}/bookmarks", now),
            dislikes=self._dated(f"users/{uid}/notInterested", now),
            own_startups=own,
        )
