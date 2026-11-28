"""The user's taste: onboarding answers moved toward bookmarks and away from dislikes (design PDF 2.4)."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime

import numpy as np
from sklearn.preprocessing import normalize

from .features import LABEL_GROUPS, GroupVectors

HALF_LIFE_DAYS = 90
OLDEST_WEIGHT = 0.4
MAX_LEARNED_SHARE = 0.6
HALF_PULL = 2
TICKET_STRENGTH = 1.5
DISLIKE_WEIGHT = 0.2


@dataclass
class Signal:
    """Something the user bookmarked, disliked or opened as a ticket, and when."""

    groups: GroupVectors
    at: datetime
    strength: float = 1.0
    # The sectors it adds to the calibration target (a startup: its main sector only);
    # None: its sector feature.
    sectors: np.ndarray | None = None


@dataclass
class Taste:
    groups: GroupVectors
    learned_share: float
    # The sector mix the list should follow (calibration, Steck 2018): the base's sectors
    # blended with the sectors of bookmarks and tickets by the learned share. None: no sectors.
    target: np.ndarray | None = None


def _mix(vector: np.ndarray | None) -> np.ndarray | None:
    """A sector vector as shares that add up to 1 (None when it has no sector)."""
    if vector is None:
        return None
    total = float(np.sum(vector))
    return vector / total if total > 0 else None


def _inside(vector: np.ndarray | None, base: np.ndarray | None) -> np.ndarray | None:
    """Only the base's sectors when the vector has some of them (else all of its sectors)."""
    if vector is None or base is None:
        return vector
    inside = vector * (base > 0)
    return inside if np.any(inside) else vector


def _target(base: GroupVectors, likes: list[Signal], weights: list[float], share: float) -> np.ndarray | None:
    from_base = _mix(base.get("sector"))
    liked = [(w, _mix(_inside(s.sectors if s.sectors is not None else s.groups.get("sector"), base.get("sector"))))
             for s, w in zip(likes, weights)]
    liked = [(w, m) for w, m in liked if m is not None and w > 0]
    from_likes = sum(w * m for w, m in liked) / sum(w for w, _ in liked) if liked else None
    if from_base is None:
        return from_likes
    if from_likes is None:
        return from_base
    return (1 - share) * from_base + share * from_likes


def decay_weight(at: datetime, now: datetime, strength: float = 1.0) -> float:
    """strength × max(0.4, 0.5^(whole hours ÷ 24 ÷ 90)); future dates count as now."""
    hours = max(0, int((now - at).total_seconds() // 3600))
    return strength * max(OLDEST_WEIGHT, 0.5 ** (hours / 24 / HALF_LIFE_DAYS))


def _unit(v: np.ndarray) -> np.ndarray:
    return normalize(v.reshape(1, -1))[0]


def _weighted_unit(signals: list[Signal], weights: list[float], group: str, size: int) -> np.ndarray:
    total = np.zeros(size)
    for signal, weight in zip(signals, weights):
        vector = signal.groups.get(group)
        if vector is not None:
            total += weight * _unit(vector)
    return _unit(total)


def build_taste(base: GroupVectors, likes: list[Signal], dislikes: list[Signal], now: datetime) -> Taste:
    like_weights = [decay_weight(s.at, now, s.strength) for s in likes]
    dislike_weights = [decay_weight(s.at, now, s.strength) for s in dislikes]
    fresh = sum(like_weights)
    share = MAX_LEARNED_SHARE * fresh / (fresh + HALF_PULL)

    sizes: dict[str, int] = {}
    for source in [base, *(s.groups for s in likes), *(s.groups for s in dislikes)]:
        for group, vector in source.items():
            sizes.setdefault(group, len(vector))

    groups: GroupVectors = {}
    for group, size in sizes.items():
        start = _unit(base[group]) if group in base else np.zeros(size)
        toward = _weighted_unit(likes, like_weights, group, size)
        if not toward.any():
            blended = start
        elif not start.any():
            blended = toward
        else:
            blended = (1 - share) * start + share * toward
        away = _weighted_unit(dislikes, dislike_weights, group, size)
        if blended.any() and away.any():
            blended = blended - DISLIKE_WEIGHT * away
        if group in LABEL_GROUPS:
            blended = np.maximum(blended, 0.0)
        groups[group] = blended
    return Taste(groups, share if likes else 0.0, _target(base, likes, like_weights, share))
