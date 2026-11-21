from datetime import datetime, timezone

import numpy as np
import pytest

from app.data import Snapshot, UserContext
from app.embeddings import MODEL_NAME, fingerprint
from app.recommend import for_you, investor_main_sector
from app.vector_store import pack

NOW = datetime(2026, 11, 21, 9, 0, tzinfo=timezone.utc)


def startup(name, sector, stage, model="b2b", **extra):
    return {"name": name, "isPublic": True, "founderId": "someone", "sector": sector, "stage": stage,
            "commerceModel": model, "location": "riyadh", "lookingFor": ["funding"], "fundingRequirement": 1_000_000,
            "raisedInRound": 0, **extra}


def snap(startups=None, investors=None, tickets=None, vectors=None) -> Snapshot:
    return Snapshot(startups or {}, investors or {}, tickets or [], vectors or {}, NOW)


def investor_ctx(user_doc=None, bookmarks=None, dislikes=None, own=None, uid="inv1") -> UserContext:
    return UserContext(uid, "investor", {"role": "investor", **(user_doc or {})}, bookmarks or {}, dislikes or {}, own or {})


FINTECH_SEED = {"preferredSectors": ["Fintech"], "preferredStages": ["Seed"]}


def test_investor_prefers_matching_startup():
    s = snap({"health": startup("MediBook", "healthtech", "series_b", "b2c"), "fin": startup("Payly", "fintech", "seed")})
    picks = for_you(investor_ctx(FINTECH_SEED), s, NOW)
    assert picks[0].id == "fin" and picks[0].score == pytest.approx(1.0)


def test_bookmarked_disliked_private_closed_and_own_are_excluded():
    s = snap({
        "fin": startup("Payly", "fintech", "seed"),
        "saved": startup("Saved", "fintech", "seed"),
        "nope": startup("Nope", "fintech", "seed"),
        "closed": startup("Closed", "fintech", "seed", status="closed"),
        "private": startup("Private", "fintech", "seed", isPublic=False),
        "mine": startup("Mine", "fintech", "seed"),
    })
    ctx = investor_ctx(FINTECH_SEED, bookmarks={"s-saved": NOW}, dislikes={"s-nope": NOW}, own={"mine": {}})
    assert [p.id for p in for_you(ctx, s, NOW)] == ["fin"]


def test_bookmark_to_missing_startup_is_ignored():
    s = snap({"fin": startup("Payly", "fintech", "seed"), "health": startup("MediBook", "healthtech", "seed", "b2c")})
    plain = for_you(investor_ctx(FINTECH_SEED), s, NOW)
    with_gone = for_you(investor_ctx(FINTECH_SEED, bookmarks={"s-gone": NOW}), s, NOW)
    assert [(p.id, p.score) for p in with_gone] == [(p.id, p.score) for p in plain]


def test_new_user_gets_empty_list():
    s = snap({"fin": startup("Payly", "fintech", "seed")})
    assert for_you(investor_ctx(), s, NOW) == []


def test_band_minimum_above_what_is_left_filters_the_startup():
    nearly_done = startup("Late", "fintech", "seed", fundingRequirement=2_000_000, raisedInRound=1_800_000)
    s = snap({"late": nearly_done, "fin": startup("Payly", "fintech", "seed")})
    ctx = investor_ctx({**FINTECH_SEED, "ticketSize": "SAR 500K – 1M"})
    assert [p.id for p in for_you(ctx, s, NOW)] == ["fin"]  # Late has only SAR 200K left


def test_stale_vector_is_ignored():
    bio = {"fullName": "Nora", "bio": "Clinic software investor"}
    fin = startup("Payly", "fintech", "seed", description="Payroll")
    health = startup("MediBook", "healthtech", "seed", "b2c", description="Clinic booking")
    base_vectors = {
        "i-inv1": {"v": pack([1.0] + [0.0] * 383), "model": MODEL_NAME, "fingerprint": fingerprint(bio, "investor")},
        "s-health": {"v": pack([0.6, 0.8] + [0.0] * 382), "model": MODEL_NAME, "fingerprint": fingerprint(health, "startup")},
    }
    stale = {"v": pack([1.0] + [0.0] * 383), "model": MODEL_NAME, "fingerprint": "an older text"}
    with_stale = snap({"fin": fin, "health": health}, {"inv1": bio}, vectors={**base_vectors, "s-fin": stale})
    without = snap({"fin": fin, "health": health}, {"inv1": bio}, vectors=base_vectors)
    a = for_you(investor_ctx(FINTECH_SEED), with_stale, NOW)
    b = for_you(investor_ctx(FINTECH_SEED), without, NOW)
    assert [(p.id, p.score) for p in a] == [(p.id, p.score) for p in b]


def test_open_ticket_adds_the_bonus():
    s = snap({"fin": startup("Payly", "fintech", "seed")},
             tickets=[{"investorId": "inv1", "name": "T1", "status": "open", "amountMin": 100_000, "amountMax": 2_000_000,
                       "sectors": ["Fintech"], "stages": ["Seed"], "createdAt": NOW}])
    picks = for_you(investor_ctx(FINTECH_SEED), s, NOW)
    assert picks[0].id == "fin" and picks[0].score == pytest.approx(1.3)


def test_founder_amount_filter_and_best_taste():
    own = {
        "o1": startup("Mine1", "fintech", "seed", fundingRequirement=2_000_000, raisedInRound=1_500_000),  # 500K left
        "o2": startup("Mine2", "healthtech", "series_a", "b2c", fundingRequirement=3_000_000),
    }
    investors = {
        "big": {"fullName": "Big Ticket", "preferredSectors": ["Fintech"], "preferredStages": ["Seed"], "ticketSize": "SAR 1M – 5M"},
        "ok": {"fullName": "Health Angel", "preferredSectors": ["HealthTech"], "preferredStages": ["Series A"], "ticketSize": "SAR 100K – 500K"},
        "nameless": {"preferredSectors": ["Fintech"], "preferredStages": ["Seed"]},
    }
    ctx = UserContext("f1", "founder", {"role": "founder"}, {}, {}, own)
    picks = for_you(ctx, snap(investors=investors), NOW)
    assert [p.id for p in picks] == ["ok"] and picks[0].score == pytest.approx(1.0)


def test_unparseable_startups_are_never_recommended():
    s = snap({"fin": startup("Payly", "fintech", "seed"), "broken": startup("Broken", "space", "seed"),
              "nowhere": startup("Nowhere", "fintech", "seed", location=None)})
    assert [p.id for p in for_you(investor_ctx(FINTECH_SEED), s, NOW)] == ["fin"]


def test_legacy_values_score_like_the_app():
    s = snap({"legacy": startup("CloudCo", "software_cloud", "mvp", "b2b")})
    ctx = investor_ctx({**FINTECH_SEED, "preferredCommerceModels": ["B2B"]})
    assert for_you(ctx, s, NOW)[0].score == pytest.approx(0.18 / 0.88)  # saas / pre-seed: only the model matches


def test_closed_bookmarks_do_not_shape_the_taste():
    s = snap({"fin": startup("Payly", "fintech", "seed"), "ai": startup("Botly", "ai", "seed"),
              "gone": startup("Gone", "ai", "seed", status="closed")})
    plain = for_you(investor_ctx(FINTECH_SEED), s, NOW)
    with_closed = for_you(investor_ctx(FINTECH_SEED, bookmarks={"s-gone": NOW}), s, NOW)
    assert [(p.id, p.score) for p in with_closed] == [(p.id, p.score) for p in plain]


def test_bad_numbers_and_vectors_do_not_crash():
    fin = startup("Payly", "fintech", "seed", fundingRequirement=float("nan"), description="Payroll")
    s = snap({"fin": fin}, vectors={"s-fin": {"v": b"broken", "model": MODEL_NAME,
                                              "fingerprint": fingerprint(fin, "startup")}})
    assert [p.id for p in for_you(investor_ctx(FINTECH_SEED), s, NOW)] == ["fin"]


def test_malformed_tickets_are_ignored():
    good = [{"investorId": "inv1", "name": "T1", "status": "open", "amountMin": 100_000, "amountMax": 2_000_000,
             "sectors": ["Fintech"], "stages": ["Seed"], "createdAt": NOW}]
    bad = [{"investorId": "inv1", "status": "open", "amountMin": "lots", "amountMax": 2_000_000,  # no name, text amount
            "sectors": ["HealthTech"], "stages": ["Series B"], "createdAt": NOW}]
    s_plain = snap({"fin": startup("Payly", "fintech", "seed")})
    s_bad = snap({"fin": startup("Payly", "fintech", "seed")}, tickets=bad)
    plain = for_you(investor_ctx(FINTECH_SEED), s_plain, NOW)
    assert [(p.id, p.score) for p in for_you(investor_ctx(FINTECH_SEED), s_bad, NOW)] == [(p.id, p.score) for p in plain]
    with_good = for_you(investor_ctx(FINTECH_SEED), snap({"fin": startup("Payly", "fintech", "seed")}, tickets=good), NOW)
    assert with_good[0].score == pytest.approx(1.3)


def test_investor_main_sector_matches_the_app():
    assert investor_main_sector({"preferredSectors": ["Other", "Fintech"]}) == "other"
    assert investor_main_sector({"preferredSectors": ["Fintech"]}) == "fintech"
    assert investor_main_sector({"preferredSectors": []}) is None and investor_main_sector({}) is None
