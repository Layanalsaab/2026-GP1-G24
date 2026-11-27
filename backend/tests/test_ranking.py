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


def test_legacy_sector_and_stage_match_ticket_labels():
    legacy = {**RAISING, "sector": "software_cloud", "stage": "early_revenue"}
    assert ticket_fits(legacy, [{"amountMin": 0, "amountMax": 600_000, "sectors": ["SaaS"], "stages": ["Seed"]}])


def test_non_finite_amounts_do_not_crash():
    assert remaining({**RAISING, "fundingRequirement": float("nan")}) == 0
    assert ticket_bonus(RAISING, [{"amountMin": float("inf"), "amountMax": 600_000, "sectors": [], "stages": []}]) == 0.0


# Calibration (Steck, "Calibrated Recommendations", RecSys 2018): the main places follow the
# target sector mix instead of letting the best-scoring sector take them all.
def _two_sectors(n_each: int, gap: float = 0.02):
    """n_each fintech candidates scoring a little above n_each saas candidates (by gap);
    sector rows [fintech, saas]."""
    ids = [f"f{k}" for k in range(n_each)] + [f"s{k}" for k in range(n_each)]
    names = list(ids)
    scores = np.array([[0.8 - k / 1000 for k in range(n_each)] + [0.8 - gap - k / 1000 for k in range(n_each)]])
    sectors = np.array([[1.0, 0.0]] * n_each + [[0.0, 1.0]] * n_each)
    return ids, names, scores, sectors


def test_calibration_follows_the_target_mix():
    ids, names, scores, sectors = _two_sectors(10)
    picks = recommend_best(ids, names, ["fintech"] * 10 + ["saas"] * 10, scores, np.ones_like(scores, dtype=bool),
                           np.zeros_like(scores), limit=12, sectors=sectors, target=np.array([0.8, 0.2]))
    top10 = [p.id for p in picks[:10]]
    assert sum(i.startswith("s") for i in top10) == 2
    assert [i for i in top10 if i.startswith("f")] == [f"f{k}" for k in range(8)]  # score order within a sector


def test_calibration_trades_closeness_for_score_when_scores_are_far_apart():
    # Steck's method balances the two (CALIBRATION_WEIGHT): a much weaker sector gets fewer places.
    ids, names, scores, sectors = _two_sectors(10, gap=0.3)
    picks = recommend_best(ids, names, ["fintech"] * 10 + ["saas"] * 10, scores, np.ones_like(scores, dtype=bool),
                           np.zeros_like(scores), limit=12, sectors=sectors, target=np.array([0.8, 0.2]))
    assert sum(p.id.startswith("s") for p in picks[:10]) == 1


def test_calibration_with_only_the_onboarding_sector_keeps_other_sectors_out_of_the_main_places():
    ids, names, scores, sectors = _two_sectors(10)
    picks = recommend_best(ids, names, ["fintech"] * 10 + ["saas"] * 10, scores, np.ones_like(scores, dtype=bool),
                           np.zeros_like(scores), limit=12, sectors=sectors, target=np.array([1.0, 0.0]))
    assert [p.id for p in picks[:10]] == [f"f{k}" for k in range(10)]
    assert picks[10].id == "s0"  # the other-sector places still offer something new


def test_without_a_target_the_order_is_by_score():
    ids, names, scores, sectors = _two_sectors(10)
    plain = recommend_best(ids, names, ["fintech"] * 10 + ["saas"] * 10, scores, np.ones_like(scores, dtype=bool),
                           np.zeros_like(scores), limit=12)
    no_target = recommend_best(ids, names, ["fintech"] * 10 + ["saas"] * 10, scores, np.ones_like(scores, dtype=bool),
                               np.zeros_like(scores), limit=12, sectors=sectors, target=None)
    assert [p.id for p in plain] == [p.id for p in no_target]
    assert [p.id for p in plain[:10]] == [f"f{k}" for k in range(10)]


def test_calibration_ties_go_to_the_earliest_candidate():
    # Equal scores and a uniform target over k sectors: the order given wins every tie, never rounding
    # noise in the sums (which broke it for 4, 6, 8, 9 and 10 sectors).
    for k in (3, 4, 6, 8, 9, 10, 12):
        ids = [f"c{i:02d}" for i in range(2 * k)]
        scores = np.array([[0.7] * (2 * k)])
        sectors = np.array([np.eye(k)[i % k] for i in range(2 * k)])
        picks = recommend_best(ids, ids, [str(i % k) for i in range(2 * k)], scores, np.ones_like(scores, dtype=bool),
                               np.zeros_like(scores), limit=2 * k + 2, sectors=sectors, target=np.ones(k) / k)
        assert [p.id for p in picks] == ids, k


def test_an_items_sectors_outside_the_target_do_not_count():
    # A broad item (fintech plus sectors the user did not choose) counts as fintech for the mix.
    ids = ["broad", "f1", "f2"]
    scores = np.array([[0.77, 0.59, 0.58]])
    sectors = np.array([[1, 1, 1, 1], [1, 0, 0, 0], [1, 0, 0, 0]], dtype=float)  # fintech, gaming, media, sports
    picks = recommend_best(ids, ids, ["fintech"] * 3, scores, np.ones_like(scores, dtype=bool),
                           np.zeros_like(scores), limit=5, sectors=sectors, target=np.array([1.0, 0, 0, 0]))
    assert [p.id for p in picks] == ["broad", "f1", "f2"]
