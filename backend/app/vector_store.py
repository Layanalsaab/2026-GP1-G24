"""Text vectors kept in a few large Firestore documents instead of one per profile.

Each vector is stored as 384 float32 numbers packed into 1,536 bytes, under a field named
after its profile key ("s-<startupId>" or "i-<investorId>"), in one of 16 documents
vectorChunks/c00 … vectorChunks/c15. Loading every vector therefore costs 16 document
reads instead of one per profile, which keeps the server inside Firestore's free daily reads.
Each document can hold about 600 vectors before Firestore's 1 MB limit (about 9,600 in total).
"""

from __future__ import annotations

import hashlib

import numpy as np

from .data import Source
from .embeddings import DIM

COLLECTION = "vectorChunks"
CHUNKS = 16
_BYTES = DIM * 4


def chunk_path(key: str) -> str:
    """The same key always lands in the same document."""
    number = int(hashlib.sha1(key.encode("utf-8")).hexdigest(), 16) % CHUNKS
    return f"{COLLECTION}/c{number:02d}"


def pack(vector) -> bytes:
    return np.asarray(vector, dtype="<f4").tobytes()


def unpack(raw: object) -> np.ndarray | None:
    """The stored vector, or None if it is missing, the wrong size or not finite."""
    if not isinstance(raw, (bytes, bytearray)) or len(raw) != _BYTES:
        return None
    vector = np.frombuffer(bytes(raw), dtype="<f4").astype(float)
    return vector if np.isfinite(vector).all() else None


def load_all(source: Source) -> dict[str, dict]:
    vectors: dict[str, dict] = {}
    for _, chunk in source.stream(COLLECTION):
        for key, entry in chunk.items():
            if isinstance(entry, dict):
                vectors[key] = entry
    return vectors


def read(source: Source, key: str) -> dict | None:
    chunk = source.get(chunk_path(key)) or {}
    entry = chunk.get(key)
    return entry if isinstance(entry, dict) else None


def write(source: Source, key: str, entry: dict) -> None:
    source.merge(chunk_path(key), {key: entry})


def remove(source: Source, key: str) -> None:
    source.delete_field(chunk_path(key), key)
