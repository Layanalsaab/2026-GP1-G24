"""Encode every public startup and every investor that has no up-to-date text vector.

Run once after setting FIREBASE_SERVICE_ACCOUNT_JSON (see README):
    .venv/bin/python -m scripts.backfill_vectors
"""

from __future__ import annotations

import logging
import os

from app.data import FirestoreSource, Source
from app.embeddings import MODEL_NAME, Embedder, fingerprint, profile_texts
from app.vector_store import load_all, pack, remove, write

log = logging.getLogger("startsa.backfill")


def backfill(source: Source, embedder: Embedder) -> dict[str, int]:
    counts = {"written": 0, "unchanged": 0, "deleted": 0, "failed": 0}
    stored = load_all(source)  # every vector in a few document reads
    profiles = [("startup", "s", row) for row in source.stream("startups", "isPublic", "==", True)]
    profiles += [("investor", "i", row) for row in source.stream("investors")]
    for kind, prefix, (doc_id, doc) in profiles:
        key = f"{prefix}-{doc_id}"
        existing = stored.get(key)
        texts = profile_texts(doc, kind)
        if not texts:
            if existing is not None:
                remove(source, key)
                counts["deleted"] += 1
            continue
        current = fingerprint(doc, kind)
        if existing and existing.get("model") == MODEL_NAME and existing.get("fingerprint") == current:
            counts["unchanged"] += 1
            continue
        try:
            vector = embedder.profile_vector(texts)
            write(source, key, {"v": pack(vector), "model": MODEL_NAME, "fingerprint": current})
            counts["written"] += 1
        except Exception:
            log.exception("Could not encode %s", key)
            counts["failed"] += 1
    return counts


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    print(backfill(FirestoreSource.from_env(), Embedder(cache_dir=os.environ.get("MODEL_CACHE_DIR"))))
