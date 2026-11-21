import numpy as np

from app.ranking import (
    amount_fits,
    recommend_best,
    remaining,
    sizes_fit,
    ticket_bonus,
    ticket_fits,
)

RAISING = {"sector": "fintech", "stage": "seed", "lookingFor": ["funding"], "fundingRequirement": 2_000_000, "raisedInRound": 1_500_000}
ids22 = [f"s{k:02d}" for k in range(22)]
names22 = [f"Startup {k:02d}" for k in range(22)]


def descending(n: int) -> np.ndarray:
    return np.array([[1.0 - k / 100 for k in range(n)]])


def test_remaining():
    assert remaining(RAISING) == 500_000
    assert remaining({**RAISING, "lookingFor": []}) == 0
    assert remaining({**RAISING, "raisedInRound": 3_000_000}) == 0


def test_sizes_fit_uses_remaining_for_the_band():
    assert sizes_fit(RAISING, "SAR 1M – 5M", None, None) is False  # 1M > 500K left
    assert sizes_fit(RAISING, None, 1_000_000, 3_000_000) is True   # round size uses 2M
    assert sizes_fit({**RAISING, "lookingFor": []}, "SAR 1M – 5M", None, None) is True


def test_ticket_bonus():
    fits = {"amountMin": 100_000, "amountMax": 600_000, "sectors": ["Fintech"], "stages": ["Seed"]}
    assert ticket_fits(RAISING, [fits]) and ticket_bonus(RAISING, [fits]) == 0.3
    assert ticket_bonus(RAISING, [{**fits, "sectors": ["Energy"]}]) == 0.1
    assert ticket_bonus(RAISING, [{**fits, "amountMax": 200_000}]) == 0.0


def test_ticket_matches_typed_other_and_other_sectors():
    other = {**RAISING, "sector": "other", "sectorOther": "Space tech", "otherSectors": ["AI"]}
    base = {"amountMin": 0, "amountMax": 600_000, "stages": []}
    assert ticket_fits(other, [{**base, "sectors": ["Space tech"]}])
    assert ticket_fits(other, [{**base, "sectors": ["AI"]}])
    assert not ticket_fits(other, [{**base, "sectors": ["Fintech"]}])


def test_amount_fits_through_a_ticket_when_the_band_fails():
    ticket = {"amountMin": 100_000, "amountMax": 600_000, "sectors": [], "stages": []}
    assert amount_fits(RAISING, [ticket], "SAR 1M – 5M", None, None) is True
    assert amount_fits(RAISING, [], "SAR 1M – 5M", None, None) is False


def test_order_score_then_fits_then_name():
    picks = recommend_best(["a", "b", "c"], ["Zed", "Amy", "Bob"], ["x", "x", "x"],
                           scores=np.array([[0.5, 0.5, 0.9], [0.5, 0.0, 0.0]]),
                           allowed=np.ones((2, 3), bool), bonus=np.zeros((2, 3)))
    assert [p.id for p in picks] == ["c", "a", "b"]  # a fits two tastes, b one


def test_name_breaks_ties_bonus_counts_and_disallowed_tastes_are_ignored():
    picks = recommend_best(["a", "b", "c", "d"], ["Zed", "Amy", "Bob", "Cat"], ["x"] * 4,
                           scores=np.array([[0.5, 0.5, 0.4, 0.9]]),
                           allowed=np.array([[True, True, True, False]]),
                           bonus=np.array([[0.0, 0.0, 0.3, 0.0]]))
    assert [(p.id, round(p.score, 6)) for p in picks] == [("c", 0.7), ("b", 0.5), ("a", 0.5)]


def test_explore_places():
    picks = recommend_best(ids22, names22, ["fintech"] * 19 + ["ai", "fintech", "health"],
                           scores=descending(22), allowed=np.ones((1, 22), bool), bonus=np.zeros((1, 22)))
    assert len(picks) == 20 and picks[18].id == ids22[19] and picks[19].id == ids22[21]


def test_zero_scores_are_dropped():
    assert recommend_best(["a"], ["A"], [None], scores=np.zeros((1, 1)),
                          allowed=np.ones((1, 1), bool), bonus=np.full((1, 1), 0.3)) == []
