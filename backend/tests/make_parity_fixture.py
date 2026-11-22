"""Writes tests/fixtures/for_you_parity.json: a For You scenario and the Python ranking of it.

The Dart test test/recommender/for_you_parity_test.dart ranks the same scenario with
lib/recommender/for_you.dart and must get the same ids and scores.
Run: .venv/bin/python -m tests.make_parity_fixture
"""

from __future__ import annotations

import json
from datetime import datetime
from pathlib import Path

import numpy as np

from app.features import LABEL_GROUPS, encode
from app.ranking import recommend_best
from app.scoring import score_candidates
from app.taste import Signal, build_taste

FIXTURE = Path(__file__).parent / "fixtures" / "for_you_parity.json"

SCENARIO = {
    "now": "2026-11-21T09:00:00Z",
    "limit": 6,
    "base": {"sector": ["fintech", "ai", "saas"], "stage": ["seed", "series_a"], "model": ["b2b", "b2c"]},
    "likes": [
        # a bookmark 45 days old
        {"groups": {"sector": ["healthtech", "ai"], "stage": ["seed"], "model": ["b2b"]}, "at": "2026-10-07T09:00:00Z", "strength": 1.0},
        # a bookmark 200 days old (weight floored at 0.4)
        {"groups": {"sector": ["logistics"], "stage": ["series_b"], "model": ["b2c"]}, "at": "2026-05-05T09:00:00Z", "strength": 1.0},
        # an open ticket from 11 days 5.5 hours ago (269 whole hours)
        {"groups": {"sector": ["fintech", "logistics"], "stage": ["seed"], "model": []}, "at": "2026-11-10T03:30:00Z", "strength": 1.5},
    ],
    "candidates": [
        {"id": "c1", "name": "Payly", "mainSector": "fintech", "groups": {"sector": ["fintech"], "stage": ["seed"], "model": ["b2b"]}},
        {"id": "c2", "name": "MediBook", "mainSector": "healthtech", "groups": {"sector": ["healthtech", "ai"], "stage": ["seed"], "model": ["b2c"]}},
        {"id": "c3", "name": "Shiply", "mainSector": "logistics", "groups": {"sector": ["logistics"], "stage": ["series_b"], "model": ["b2b"]}},
        {"id": "c4", "name": "Learnly", "mainSector": "edtech", "groups": {"sector": ["edtech"], "stage": ["pre_seed"], "model": ["b2c"]}},
        {"id": "c5", "name": "CloudOps", "mainSector": "saas", "groups": {"sector": ["saas", "ai"], "stage": ["series_a"], "model": []}},
        {"id": "c6", "name": "Farmly", "mainSector": "agritech", "groups": {"sector": ["agritech"], "stage": ["series_c"], "model": ["g2c"]}},
        {"id": "c7", "name": "Coinly", "mainSector": "fintech", "groups": {"sector": ["fintech"], "stage": ["seed"], "model": ["b2b"]}},
        {"id": "c8", "name": "GreenGrid", "mainSector": "energy", "groups": {"sector": ["energy", "logistics"], "stage": ["seed"], "model": ["b2b"]}},
        # left over after the first 3 places but its sector is already listed: the other-sector places must skip it
        {"id": "c9", "name": "Fundly", "mainSector": "fintech", "groups": {"sector": ["fintech"], "stage": ["seed"], "model": ["d2c"]}},
        # no main sector (null), which counts as a sector not yet in the list
        {"id": "c10", "name": "Nameless Sector", "mainSector": None, "groups": {"sector": ["ai"], "stage": ["series_a"], "model": ["b2c"]}},
    ],
}


def _time(text: str) -> datetime:
    return datetime.fromisoformat(text.replace("Z", "+00:00"))


def compute_expected(scenario: dict) -> list[dict]:
    likes = [Signal(encode(l["groups"]), _time(l["at"]), l["strength"]) for l in scenario["likes"]]
    taste = build_taste(encode(scenario["base"]), likes, [], _time(scenario["now"]))
    encoded = [encode(c["groups"]) for c in scenario["candidates"]]
    rows = {g: np.stack([e[g] for e in encoded]) for g in LABEL_GROUPS}
    scores = score_candidates(taste, rows)[None, :]
    picks = recommend_best(
        [c["id"] for c in scenario["candidates"]],
        [c["name"] for c in scenario["candidates"]],
        [c["mainSector"] for c in scenario["candidates"]],
        scores=scores,
        allowed=np.ones_like(scores, dtype=bool),
        bonus=np.zeros_like(scores),
        limit=scenario["limit"],
    )
    return [{"id": p.id, "score": p.score} for p in picks]


def main() -> None:
    FIXTURE.parent.mkdir(parents=True, exist_ok=True)
    FIXTURE.write_text(json.dumps({**SCENARIO, "expected": compute_expected(SCENARIO)}, indent=2) + "\n")
    print(f"wrote {FIXTURE}")


if __name__ == "__main__":
    main()
