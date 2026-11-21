import math

import numpy as np

from app.vector_store import CHUNKS, load_all, pack, read, remove, unpack, write
from tests.fakes import FakeSource


def entry(k: int) -> dict:
    return {"v": pack(np.eye(384)[k % 384]), "model": "m", "fingerprint": f"f{k}"}


def test_many_vectors_live_in_at_most_16_documents_and_load_back():
    source = FakeSource()
    for k in range(200):
        write(source, f"s-{k}", entry(k))
    chunks = [p for p in source.docs if p.startswith("vectorChunks/")]
    assert 10 <= len(chunks) <= CHUNKS == 16
    loaded = load_all(source)
    assert len(loaded) == 200 and loaded["s-7"]["fingerprint"] == "f7"
    assert read(source, "s-7")["fingerprint"] == "f7" and read(source, "s-missing") is None


def test_pack_round_trip_and_size():
    v = np.linspace(-1, 1, 384)
    raw = pack(v)
    assert isinstance(raw, bytes) and len(raw) == 384 * 4
    assert np.allclose(unpack(raw), v, atol=1e-6)


def test_unpack_rejects_wrong_length_and_bad_numbers():
    assert unpack(b"123") is None and unpack(None) is None and unpack([0.0] * 384) is None
    assert unpack(pack([math.nan] * 384)) is None


def test_remove_deletes_only_that_vector():
    source = FakeSource()
    write(source, "s-a", entry(1))
    write(source, "s-b", entry(2))
    remove(source, "s-a")
    remove(source, "s-never")
    assert read(source, "s-a") is None and read(source, "s-b")["fingerprint"] == "f2"
