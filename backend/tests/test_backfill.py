import numpy as np

from app.embeddings import MODEL_NAME
from scripts.backfill_vectors import backfill
from tests.fakes import FakeSource


class StubEmbedder:
    def __init__(self):
        self.calls = 0

    def profile_vector(self, texts):
        self.calls += 1
        return np.eye(384)[1] if texts else None


def test_backfill_writes_then_skips():
    source = FakeSource({
        "startups/s1": {"name": "Payly", "isPublic": True, "description": "Payroll for clinics"},
        "startups/s2": {"name": "Quiet", "isPublic": True},
        "startups/s3": {"name": "Hidden", "isPublic": False, "description": "Not listed"},
        "investors/i1": {"fullName": "Nora", "bio": "Angel investor in health"},
        "vectors/s-s2": {"vector": [0.0] * 384, "model": MODEL_NAME, "fingerprint": "old"},
    })
    embedder = StubEmbedder()

    assert backfill(source, embedder) == {"written": 2, "unchanged": 0, "deleted": 1}
    assert source.docs["vectors/s-s1"]["model"] == MODEL_NAME and source.docs["vectors/i-i1"]["vector"][1] == 1.0
    assert "vectors/s-s2" not in source.docs and "vectors/s-s3" not in source.docs

    assert backfill(source, embedder) == {"written": 0, "unchanged": 2, "deleted": 0}
    assert embedder.calls == 2
