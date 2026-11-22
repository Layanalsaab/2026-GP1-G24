import numpy as np

from app.embeddings import MODEL_NAME
from app.vector_store import pack, read, unpack, write
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
    })
    write(source, "s-s2", {"v": pack([0.0] * 384), "model": MODEL_NAME, "fingerprint": "old"})
    embedder = StubEmbedder()

    assert backfill(source, embedder) == {"written": 2, "unchanged": 0, "deleted": 1, "failed": 0}
    assert read(source, "s-s1")["model"] == MODEL_NAME and unpack(read(source, "i-i1")["v"])[1] == 1.0
    assert read(source, "s-s2") is None and read(source, "s-s3") is None

    assert backfill(source, embedder) == {"written": 0, "unchanged": 2, "deleted": 0, "failed": 0}
    assert embedder.calls == 2



def test_backfill_removes_vectors_of_profiles_that_are_gone():
    source = FakeSource({
        "startups/kept": {"name": "Payly", "isPublic": True, "description": "Payroll for clinics"},
        "startups/private": {"name": "Hidden", "isPublic": False, "description": "Now private"},
        "investors/kept": {"fullName": "Nora", "bio": "Angel investor in health"},
    })
    backfill(source, StubEmbedder())  # vectors for the two listed profiles
    old = {"v": pack([0.0] * 384), "model": MODEL_NAME, "fingerprint": "x"}
    write(source, "s-deleted", old)  # the startup was deleted
    write(source, "s-private", old)  # the startup was made private
    write(source, "i-deleted", old)  # the investor deleted their account

    assert backfill(source, StubEmbedder()) == {"written": 0, "unchanged": 2, "deleted": 3, "failed": 0}
    assert read(source, "s-deleted") is None
    assert read(source, "s-private") is None
    assert read(source, "i-deleted") is None
    assert read(source, "s-kept") is not None and read(source, "i-kept") is not None
    assert backfill(source, StubEmbedder())["deleted"] == 0  # nothing left to remove


def test_backfill_keeps_going_when_one_profile_fails():
    class Flaky(StubEmbedder):
        def profile_vector(self, texts):
            if "boom" in texts[0]:
                raise RuntimeError("model error")
            return super().profile_vector(texts)

    source = FakeSource({
        "startups/s1": {"name": "Bad", "isPublic": True, "description": "boom"},
        "startups/s2": {"name": "Good", "isPublic": True, "description": "fine"},
    })
    assert backfill(source, Flaky()) == {"written": 1, "unchanged": 0, "deleted": 0, "failed": 1}
    assert read(source, "s-s2") is not None


def test_backfill_reads_vectors_in_a_few_documents():
    source = FakeSource({f"startups/s{k}": {"name": f"S{k}", "isPublic": True, "description": "x"} for k in range(50)})
    backfill(source, StubEmbedder())
    source.docs_read = 0
    backfill(source, StubEmbedder())
    assert source.docs_read <= 50 + 16
