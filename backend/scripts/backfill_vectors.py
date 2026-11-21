"""Encode every public startup and every investor that has no up-to-date text vector.

Run once after setting FIREBASE_SERVICE_ACCOUNT_JSON (see README):
    .venv/bin/python -m scripts.backfill_vectors
"""

from __future__ import annotations

from app.data import FirestoreSource, Source
from app.embeddings import MODEL_NAME, Embedder, fingerprint, profile_texts


def backfill(source: Source, embedder: Embedder) -> dict[str, int]:
    counts = {"written": 0, "unchanged": 0, "deleted": 0}
    profiles = [("startup", "s", row) for row in source.stream("startups", "isPublic", "==", True)]
    profiles += [("investor", "i", row) for row in source.stream("investors")]
    for kind, prefix, (doc_id, doc) in profiles:
        path = f"vectors/{prefix}-{doc_id}"
        existing = source.get(path)
        texts = profile_texts(doc, kind)
        if not texts:
            if existing is not None:
                source.delete(path)
                counts["deleted"] += 1
            continue
        current = fingerprint(doc, kind)
        if existing and existing.get("model") == MODEL_NAME and existing.get("fingerprint") == current:
            counts["unchanged"] += 1
            continue
        vector = embedder.profile_vector(texts)
        source.set(path, {"vector": [float(x) for x in vector], "model": MODEL_NAME, "fingerprint": current})
        counts["written"] += 1
    return counts


if __name__ == "__main__":
    print(backfill(FirestoreSource.from_env(), Embedder()))
