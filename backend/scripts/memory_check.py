"""Checks the server fits Render's free plan (512 MB): run locally, not in the container.

Loads the app with Firestore's libraries, a fake snapshot of 1,100 profiles with vectors,
answers one /for-you and one /profile-text (real MiniLM), then prints the peak memory.
    .venv/bin/python -m scripts.memory_check
"""

from __future__ import annotations

import resource
import sys
from datetime import datetime, timezone

LIMIT_MB = 450
SECTORS = ["fintech", "healthtech", "ai", "saas", "logistics", "edtech", "energy", "retail"]
STAGES = ["pre_seed", "seed", "series_a", "series_b"]


def peak_mb() -> float:
    peak = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss
    return peak / (1024 * 1024) if sys.platform == "darwin" else peak / 1024  # bytes on macOS, KB on Linux


def build_docs() -> tuple[dict[str, dict], dict[str, dict]]:
    from app.embeddings import MODEL_NAME, fingerprint
    from app.vector_store import pack

    vectors: dict[str, dict] = {}
    docs: dict[str, dict] = {
        "users/inv1": {"role": "investor", "preferredSectors": ["Fintech", "AI"], "preferredStages": ["Seed"]},
        "users/f1": {"role": "founder"},
    }
    for k in range(1000):
        doc = {"name": f"Startup {k}", "isPublic": True, "founderId": "f1" if k == 0 else f"f{k}",
               "sector": SECTORS[k % 8], "stage": STAGES[k % 4], "commerceModel": "b2b", "location": "riyadh",
               "lookingFor": ["funding"], "fundingRequirement": 1_000_000,
               "description": f"Startup number {k} building software for {SECTORS[k % 8]} customers"}
        docs[f"startups/s{k}"] = doc
        vectors[f"s-s{k}"] = {"v": pack([((k + j) % 7) / 7 for j in range(384)]), "model": MODEL_NAME,
                              "fingerprint": fingerprint(doc, "startup")}
    for k in range(100):
        doc = {"fullName": f"Investor {k}", "preferredSectors": ["Fintech"], "preferredStages": ["Seed"],
               "bio": f"Angel investor number {k}"}
        docs[f"investors/i{k}"] = doc
        vectors[f"i-i{k}"] = {"v": pack([((k * j) % 5) / 5 for j in range(384)]), "model": MODEL_NAME,
                              "fingerprint": fingerprint(doc, "investor")}
    return docs, vectors


def main() -> int:
    import firebase_admin  # noqa: F401  (loaded in production)
    import google.cloud.firestore  # noqa: F401
    from fastapi.testclient import TestClient

    from app.data import DataStore
    from app.embeddings import Embedder
    from app.main import create_app
    from tests.fakes import FakeSource

    from app.vector_store import write

    docs, vectors = build_docs()
    source = FakeSource(docs)
    for key, entry in vectors.items():
        write(source, key, entry)
    store = DataStore(source)
    client = TestClient(create_app(store, lambda token: {"uid": token}, Embedder,
                                   clock=lambda: datetime.now(timezone.utc)))
    items = client.post("/for-you", headers={"Authorization": "Bearer inv1"}).json()["items"]
    store.source.docs["startups/s0"]["description"] = "Edited text for the memory check"
    updated = client.post("/profile-text", headers={"Authorization": "Bearer f1"},
                          json={"kind": "startup", "id": "s0"}).json()["updated"]
    peak = peak_mb()
    print(f"for-you items: {len(items)}, profile-text updated: {updated}, peak memory: {peak:.0f} MB (limit {LIMIT_MB} MB)")
    return 0 if peak < LIMIT_MB else 1


if __name__ == "__main__":
    sys.exit(main())
