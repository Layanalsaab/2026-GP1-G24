import numpy as np
import pytest

from app.features import encode
from app.scoring import score_candidates
from app.taste import Taste

LABELS = {"sector": ["fintech"], "stage": ["seed"], "model": ["b2b"]}


def _rows(n: int) -> dict[str, np.ndarray]:
    one = encode(LABELS)
    return {g: np.tile(one[g], (n, 1)) for g in one}


def text_taste() -> Taste:
    return Taste({**encode(LABELS), "text": np.array([1.0, 0.0])}, 0)


def text_candidates() -> dict[str, np.ndarray]:
    text = np.array([[c, (1 - c * c) ** 0.5] for c in (0.2, 0.5, 0.8)] + [[0.0, 0.0]])
    return {**_rows(4), "text": text}


def same_text_candidates() -> dict[str, np.ndarray]:
    return {**_rows(2), "text": np.array([[0.6, 0.8], [0.6, 0.8]])}


def some_candidates() -> dict[str, np.ndarray]:
    return _rows(3)


def test_design_doc_example():
    taste = Taste(encode({"sector": ["fintech", "ai", "saas"], "stage": ["seed", "series_a"], "model": ["b2b", "b2c"]}), 0)
    cand = encode({"sector": ["fintech"], "stage": ["seed"], "model": ["b2b"]})
    s = score_candidates(taste, {g: cand[g][None, :] for g in cand})
    expected = (0.41 / 3 ** 0.5 + 0.29 / 2 ** 0.5 + 0.18 / 2 ** 0.5) / 0.88
    assert s[0] == pytest.approx(expected, abs=1e-9)  # ≈ 0.6467


def test_empty_group_leaves_the_denominator():
    taste = Taste(encode({"sector": ["fintech"], "stage": ["seed"], "model": ["b2b"]}), 0)
    cand = encode({"sector": ["fintech"], "stage": ["seed"], "model": []})
    assert score_candidates(taste, {g: cand[g][None, :] for g in cand})[0] == pytest.approx(1.0)


def test_mismatched_group_still_counts_in_the_denominator():
    taste = Taste(encode({"sector": ["fintech"], "stage": ["seed"], "model": ["b2b"]}), 0)
    cand = encode({"sector": ["fintech"], "stage": ["series_b"], "model": ["b2b"]})
    assert score_candidates(taste, {g: cand[g][None, :] for g in cand})[0] == pytest.approx(0.59 / 0.88)


def test_text_minmax_and_missing_vectors():
    # three candidates with text cosines 0.2, 0.5, 0.8 and one with no vector; label groups identical (cosine 1)
    s = score_candidates(text_taste(), text_candidates())
    assert s[:3] == pytest.approx([(0.88 + 0.15 * x) / 1.03 for x in (0.0, 0.5, 1.0)])
    assert s[3] == pytest.approx(1.0)


def test_equal_text_cosines_do_not_produce_nan():
    assert not np.isnan(score_candidates(text_taste(), same_text_candidates())).any()


def test_empty_taste_scores_zero():
    assert np.all(score_candidates(Taste({}, 0), some_candidates()) == 0)
