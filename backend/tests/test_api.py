from datetime import datetime, timezone

import numpy as np
import pytest
from fastapi.testclient import TestClient

from app.data import DataStore
from app.embeddings import MODEL_NAME, fingerprint
from app.main import create_app
from tests.fakes import FakeSource

NOW = datetime(2026, 11, 21, 9, 0, tzinfo=timezone.utc)
PAYLY = {"name": "Payly", "isPublic": True, "founderId": "f1", "sector": "fintech", "stage": "seed",
         "commerceModel": "b2b", "lookingFor": ["funding"], "fundingRequirement": 1_000_000, "description": "Payroll for clinics"}


class StubEmbedder:
    def __init__(self):
        self.calls = 0

    def profile_vector(self, texts):
        self.calls += 1
        return np.eye(384)[0] if texts else None


def verify(token: str) -> dict:
    if not token.startswith("good-"):
        raise ValueError("bad token")
    return {"uid": token[len("good-"):]}


def make(docs=None):
    source = FakeSource({
        "users/inv1": {"role": "investor", "preferredSectors": ["Fintech"], "preferredStages": ["Seed"]},
        "users/new": {"role": "investor"},
        "users/f1": {"role": "founder"},
        "users/x1": {"fullName": "No role"},
        "investors/inv1": {"fullName": "Nora"},
        "startups/s1": dict(PAYLY),
        "startups/s2": {"name": "Quiet", "isPublic": True, "founderId": "f1", "sector": "ai", "stage": "seed"},
        "vectors/s-s2": {"vector": [0.0] * 384, "model": MODEL_NAME, "fingerprint": "old"},
        **(docs or {}),
    })
    store = DataStore(source, clock=lambda: NOW)
    embedder = StubEmbedder()
    client = TestClient(create_app(store, verify, lambda: embedder, clock=lambda: NOW))
    return client, source, store, embedder


def auth(uid: str) -> dict:
    return {"Authorization": f"Bearer good-{uid}"}


def test_health():
    client, *_ = make()
    assert client.get("/health").json() == {"status": "ok"}


def test_for_you_requires_a_token():
    client, *_ = make()
    for headers in ({}, {"Authorization": "Bearer bad"}, {"Authorization": "good-inv1"}):
        response = client.post("/for-you", headers=headers)
        assert response.status_code == 401 and response.json()["detail"] == "Sign in again"


def test_for_you_returns_items_for_an_investor():
    client, *_ = make()
    body = client.post("/for-you", headers=auth("inv1")).json()
    assert body["items"][0]["id"] == "s1" and body["items"][0]["kind"] == "startup"
    assert body["items"][0]["score"] == pytest.approx(1.0)
    assert datetime.fromisoformat(body["generatedAt"]) == NOW


def test_new_investor_gets_200_and_empty_items():
    client, *_ = make()
    response = client.post("/for-you", headers=auth("new"))
    assert response.status_code == 200 and response.json()["items"] == []


def test_user_without_role_gets_403():
    client, *_ = make()
    assert client.post("/for-you", headers=auth("x1")).status_code == 403
    assert client.post("/for-you", headers=auth("nobody")).status_code == 403


def test_profile_text_owner_writes_then_skips_unchanged():
    client, source, _, embedder = make()
    first = client.post("/profile-text", headers=auth("f1"), json={"kind": "startup", "id": "s1"})
    assert first.status_code == 200 and first.json() == {"updated": True}
    stored = source.docs["vectors/s-s1"]
    assert stored["model"] == MODEL_NAME and stored["fingerprint"] == fingerprint(PAYLY, "startup")
    assert len(stored["vector"]) == 384 and stored["vector"][0] == 1.0
    second = client.post("/profile-text", headers=auth("f1"), json={"kind": "startup", "id": "s1"})
    assert second.json() == {"updated": False} and embedder.calls == 1


def test_profile_text_not_owner_is_403_and_unknown_is_404():
    client, *_ = make()
    assert client.post("/profile-text", headers=auth("inv1"), json={"kind": "startup", "id": "s1"}).status_code == 403
    assert client.post("/profile-text", headers=auth("f1"), json={"kind": "investor", "id": "inv1"}).status_code == 403
    assert client.post("/profile-text", headers=auth("f1"), json={"kind": "startup", "id": "gone"}).status_code == 404
    assert client.post("/profile-text", headers=auth("f1"), json={"kind": "team", "id": "s1"}).status_code == 422


def test_profile_text_with_empty_texts_deletes_the_vector():
    client, source, *_ = make()
    response = client.post("/profile-text", headers=auth("f1"), json={"kind": "startup", "id": "s2"})
    assert response.json() == {"updated": True} and "vectors/s-s2" not in source.docs


def test_profile_text_updates_the_cached_snapshot():
    client, source, store, _ = make()
    store.snapshot()  # loaded before the edit
    edited = {**PAYLY, "description": "Payroll and HR for clinics"}
    source.docs["startups/s1"] = edited
    client.post("/profile-text", headers=auth("f1"), json={"kind": "startup", "id": "s1"})
    snap = store.snapshot()
    assert snap.startups["s1"]["description"] == "Payroll and HR for clinics"
    assert snap.vectors["s-s1"]["fingerprint"] == fingerprint(edited, "startup")
