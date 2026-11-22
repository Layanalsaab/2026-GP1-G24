"""The Python matching reference against the app's real-data fixture (test/recommender/matching_fixture.json)."""

from __future__ import annotations

from pathlib import Path

import pytest

from tests.matching_reference import (
    investor_models,
    load_fixture,
    matches_for_startup,
    matches_for_ticket,
)

FIXTURE = Path(__file__).resolve().parents[2] / "test/recommender/matching_fixture.json"


@pytest.fixture(scope="module")
def fixture() -> dict:
    return load_fixture(FIXTURE)


def _same(got: list[dict], want: list[dict], who: str) -> None:
    assert [g["id"] for g in got] == [w["id"] for w in want], f"order, {who}"
    for n, (g, w) in enumerate(zip(got, want)):
        assert g["percent"] == w["percent"], f"percent, {who} #{n}"
        assert g["close"] == w["close"], f"close, {who} #{n}"
        assert g["ticketId"] == w["ticketId"], f"ticket, {who} #{n}"
        assert g["score"] == pytest.approx(w["score"], abs=1e-8), f"score, {who} #{n}"


def _startup(**over) -> dict:
    return {
        "id": "s1", "name": "Acme", "sector": "fintech", "stage": "seed", "commerceModel": "b2b",
        "lookingFor": ["funding"], "fundingRequirement": 2_000_000, "raisedInRound": 0, "isPublic": True,
        **over,
    }


def _investor(**over) -> dict:
    return {
        "id": "i1", "fullName": "Sara Example", "preferredSectors": ["Fintech"], "preferredStages": ["Seed"],
        "preferredCommerceModels": ["Business-to-Business (B2B)"], "ticketSize": "SAR 100K – 500K", **over,
    }


def _ticket(**over) -> dict:
    return {
        "id": "i1-T1", "investorId": "i1", "name": "Ticket 1", "sectors": ["Fintech"], "stages": ["Seed"],
        "amountMin": 100_000, "amountMax": 500_000, "status": "open", **over,
    }


def test_reference_matches_criterion_satisfaction():
    wide = _investor(
        preferredSectors=["Fintech", "AI", "SaaS"],
        preferredStages=["Seed", "Series A"],
        preferredCommerceModels=["Business-to-Business (B2B)", "Business-to-Consumer (B2C)"],
    )
    (a,) = matches_for_startup(_startup(), [wide], [])
    assert (a["percent"], a["close"]) == (100, False)  # worked example A
    (b,) = matches_for_startup(_startup(stage="series_b", commerceModel="b2c"), [wide], [])
    assert (b["percent"], b["close"]) == (67, True)  # worked example B
    (c,) = matches_for_ticket(_ticket(), {"b2b"}, [_startup(fundingRequirement=1_000_000)])
    assert c["percent"] == 94  # worked example C


def test_reference_tie_breakers():
    def ids(results):
        return [r["id"] for r in results]

    profile = [_investor(id="a", fullName="Aa", investmentsCount="0"),
               _investor(id="z", fullName="Zz", investmentsCount="10+")]
    assert ids(matches_for_startup(_startup(), profile, [])) == ["z", "a"]  # activity, profile matches

    covering = {"amountMax": 3_000_000}  # more than the 2M left: fit 1
    by_ticket = [_investor(id="a", fullName="Aa", investmentsCount="1–3"),
                 _investor(id="z", fullName="Zz", investmentsCount="4–6")]
    tickets = [_ticket(id="a-T1", investorId="a", **covering), _ticket(id="z-T1", investorId="z", **covering)]
    assert ids(matches_for_startup(_startup(), by_ticket, tickets)) == ["z", "a"]  # activity, ticket matches

    picks = [_investor(id="a", fullName="Aa", preferredSectors=["Fintech", "AI", "SaaS"],
                       preferredStages=["Seed", "Series A"]),
             _investor(id="z", fullName="Zz")]
    assert ids(matches_for_startup(_startup(), picks, [])) == ["z", "a"]  # fewer picks

    tiers = [_investor(id="p", fullName="Zz exact profile"), _investor(id="e", fullName="Zz exact ticket"),
             _investor(id="c", fullName="Aa close ticket")]
    tier_tickets = [_ticket(id="e-T1", investorId="e", **covering),
                    _ticket(id="c-T1", investorId="c", stages=["Series A"])]
    assert ids(matches_for_startup(_startup(), tiers, tier_tickets)) == ["e", "p", "c"]  # close after every exact

    two = [_ticket(id="i1-T2", **covering), _ticket(id="i1-T1", **covering)]
    (best,) = matches_for_startup(_startup(), [_investor()], two)
    assert best["ticketId"] == "i1-T1"  # deterministic best ticket


def test_reference_reproduces_the_committed_fixture(fixture):
    investors = {i["id"]: i for i in fixture["investors"]}
    startups = {s["id"]: s for s in fixture["startups"]}
    assert len(fixture["forTicket"]) == len(fixture["tickets"])
    for t in fixture["tickets"]:
        got = matches_for_ticket(t, investor_models(investors[t["investorId"]]), fixture["startups"])
        _same(got, fixture["forTicket"][t["id"]], t["id"])
    for sid, want in fixture["forStartup"].items():
        got = matches_for_startup(startups[sid], fixture["investors"], fixture["tickets"])
        _same(got, want, sid)
