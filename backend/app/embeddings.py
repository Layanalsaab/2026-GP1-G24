"""Profile text vectors with all-MiniLM-L6-v2 through FastEmbed (ONNX, no PyTorch)."""

from __future__ import annotations

import hashlib
import sys
from typing import Literal

import numpy as np
from sklearn.preprocessing import normalize

MODEL_NAME = "sentence-transformers/all-MiniLM-L6-v2"
DIM = 384
STARTUP_TEXT_FIELDS = ("description", "problem", "solution", "targetCustomers", "differentiation")
INVESTOR_TEXT_FIELDS = ("bio", "offer", "lookingFor")

Kind = Literal["startup", "investor"]


def _fields(kind: Kind) -> tuple[str, ...]:
    return STARTUP_TEXT_FIELDS if kind == "startup" else INVESTOR_TEXT_FIELDS


def _clean(raw: object) -> str:
    return raw.strip() if isinstance(raw, str) else ""


def profile_texts(doc: dict, kind: Kind) -> list[str]:
    """The profile's non-empty text fields, in field order."""
    return [text for text in (_clean(doc.get(f)) for f in _fields(kind)) if text]


def fingerprint(doc: dict, kind: Kind) -> str:
    """Changes whenever any text field changes; other fields don't affect it."""
    joined = "\x1f".join(_clean(doc.get(f)) for f in _fields(kind))
    return hashlib.sha256(joined.encode("utf-8")).hexdigest()


class Embedder:
    def __init__(self, model_name: str = MODEL_NAME, cache_dir: str | None = None):
        from fastembed import TextEmbedding

        self._model = TextEmbedding(model_name=model_name, cache_dir=cache_dir)

    def profile_vector(self, texts: list[str]) -> np.ndarray | None:
        """Each text encoded on its own, averaged, scaled to length 1; None without texts."""
        if not texts:
            return None
        vectors = normalize(np.array(list(self._model.embed(texts)), dtype=float))
        return normalize(vectors.mean(axis=0).reshape(1, -1))[0]


if __name__ == "__main__":
    # python -m app.embeddings --warm <cache_dir>: download the model at image build time.
    if len(sys.argv) == 3 and sys.argv[1] == "--warm":
        Embedder(cache_dir=sys.argv[2]).profile_vector(["warm up"])
        print(f"model ready in {sys.argv[2]}")
    else:
        sys.exit("usage: python -m app.embeddings --warm <cache_dir>")
