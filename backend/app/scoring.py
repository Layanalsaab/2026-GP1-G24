"""Weighted cosine between the taste and each candidate (design PDF 2.5)."""

from __future__ import annotations

import numpy as np
from sklearn.metrics.pairwise import cosine_similarity
from sklearn.preprocessing import minmax_scale

from .taste import Taste

GROUP_WEIGHTS = {"sector": 0.41, "stage": 0.29, "model": 0.18, "text": 0.15}


def score_candidates(taste: Taste, candidates: dict[str, np.ndarray]) -> np.ndarray:
    """Σ weight × cosine ÷ Σ weights of the groups both sides have, per candidate row."""
    n = next((len(m) for m in candidates.values()), 0)
    numerator = np.zeros(n)
    denominator = np.zeros(n)
    for group, weight in GROUP_WEIGHTS.items():
        wanted = taste.groups.get(group)
        rows = candidates.get(group)
        if wanted is None or rows is None or not np.any(wanted):
            continue
        present = np.any(rows != 0, axis=1)
        if not present.any():
            continue
        cosines = cosine_similarity(wanted.reshape(1, -1), rows)[0]
        if group == "text":
            rescaled = np.zeros(n)
            rescaled[present] = minmax_scale(cosines[present])
            cosines = rescaled
        numerator += weight * cosines * present
        denominator += weight * present
    return np.divide(numerator, denominator, out=np.zeros(n), where=denominator > 0)
