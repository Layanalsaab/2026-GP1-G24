"""Amount filters, the ticket bonus and the final top-20 list (design PDF 2.6)."""

from __future__ import annotations

from dataclasses import dataclass

import numpy as np

from .catalog import finite_int, sector_label, stage_label, stored_sector, stored_stage, ticket_min

# Calibration (Steck, "Calibrated Recommendations", RecSys 2018): relevance against
# closeness to the user's sector mix, and the smoothing of the list's mix.
CALIBRATION_WEIGHT = 0.5
CALIBRATION_ALPHA = 0.01

TICKET_FIT_BONUS = 0.3
TICKET_AMOUNT_BONUS = 0.1
DEFAULT_LIMIT = 20
EXPLORE_SLOTS = 2


@dataclass
class Pick:
    id: str
    score: float


_int = finite_int


def _strings(raw: object) -> list[str]:
    return [v.strip() for v in raw if isinstance(v, str) and v.strip()] if isinstance(raw, list) else []


def remaining(startup: dict) -> int:
    """What the open round still needs (SAR); 0 when funding isn't ticked."""
    looking = startup.get("lookingFor")
    if not isinstance(looking, list) or "funding" not in looking:
        return 0
    left = (_int(startup.get("fundingRequirement")) or 0) - (_int(startup.get("raisedInRound")) or 0)
    return max(0, left)


def sizes_fit(startup: dict, ticket_band: str | None, round_min: int | None, round_max: int | None) -> bool:
    """The onboarding amount check: band minimum vs what's left, round range vs the full round."""
    left = remaining(startup)
    if left <= 0:
        return True
    minimum = ticket_min(ticket_band)
    if minimum is not None and minimum > left:
        return False
    full = _int(startup.get("fundingRequirement")) or 0
    if round_min is not None and full < round_min:
        return False
    if round_max is not None and full > round_max:
        return False
    return True


def _sector_labels(startup: dict) -> set[str]:
    labels = set(_strings(startup.get("otherSectors")))
    sector = stored_sector(startup.get("sector"))
    if sector == "other":
        labels.add("Other")
        typed = startup.get("sectorOther")
        if isinstance(typed, str) and typed.strip():
            labels.add(typed.strip())
    elif sector_label(sector):
        labels.add(sector_label(sector))
    return labels


def _in_range(ticket: dict, amount: int) -> bool:
    low, high = _int(ticket.get("amountMin")), _int(ticket.get("amountMax"))
    return low is not None and high is not None and low <= amount <= high


def ticket_fits(startup: dict, tickets: list[dict]) -> bool:
    need = remaining(startup)
    if need <= 0:
        return False
    sectors = _sector_labels(startup)
    stage = stage_label(stored_stage(startup.get("stage")))
    for ticket in tickets:
        wanted_sectors = _strings(ticket.get("sectors"))
        wanted_stages = _strings(ticket.get("stages"))
        if (
            _in_range(ticket, need)
            and (not wanted_sectors or any(s in sectors for s in wanted_sectors))
            and (not wanted_stages or stage in wanted_stages)
        ):
            return True
    return False


def ticket_bonus(startup: dict, tickets: list[dict]) -> float:
    need = remaining(startup)
    if need <= 0 or not tickets:
        return 0.0
    if ticket_fits(startup, tickets):
        return TICKET_FIT_BONUS
    return TICKET_AMOUNT_BONUS if any(_in_range(t, need) for t in tickets) else 0.0


def amount_fits(startup: dict, tickets: list[dict], ticket_band: str | None, round_min: int | None, round_max: int | None) -> bool:
    return sizes_fit(startup, ticket_band, round_min, round_max) or ticket_fits(startup, tickets)


def recommend_best(
    ids: list[str],
    names: list[str],
    main_sectors: list[str | None],
    scores: np.ndarray,
    allowed: np.ndarray,
    bonus: np.ndarray,
    limit: int = DEFAULT_LIMIT,
    explore_slots: int = EXPLORE_SLOTS,
    sectors: np.ndarray | None = None,
    target: np.ndarray | None = None,
) -> list[Pick]:
    """Best score over the tastes a candidate fits; the main places follow the target sector
    mix (calibration) when one is given, else the score order; last places kept for new sectors.

    sectors: one row per candidate over the same sector values as target.
    """
    counts = (allowed & (scores > 0))
    fits = counts.sum(axis=0)
    totals = np.where(counts, scores + bonus, -np.inf).max(axis=0, initial=-np.inf)
    scored = [k for k in range(len(ids)) if fits[k] > 0 and totals[k] > 0]
    scored.sort(key=lambda k: (-totals[k], -fits[k], names[k]))

    places = max(0, limit - explore_slots)
    if target is not None and sectors is not None and float(np.sum(target)) > 0:
        main = _calibrated(scored, totals, sectors, target, places)
    else:
        main = scored[:places]
    taken = set(main)
    rest = [k for k in scored if k not in taken]
    sectors = {main_sectors[k] for k in main}
    picked = list(main)
    for k in rest:
        if len(picked) >= limit:
            break
        if main_sectors[k] not in sectors:
            picked.append(k)
            sectors.add(main_sectors[k])
    for k in rest:
        if len(picked) >= limit:
            break
        if k not in picked:
            picked.append(k)
    return [Pick(ids[k], float(totals[k])) for k in picked]


def _calibrated(order: list[int], totals: np.ndarray, sectors: np.ndarray, target: np.ndarray, places: int) -> list[int]:
    """Steck's greedy calibration: each place goes to the candidate with the best
    (1 - w) * score - w * KL(target || mix of the list with it), mix smoothed by alpha.
    Ties go to the earliest candidate in order (score, fits, name)."""
    if not order or places <= 0:
        return []
    rows = sectors[order].astype(float)
    sums = rows.sum(axis=1, keepdims=True)
    mixes = np.divide(rows, sums, out=np.zeros_like(rows), where=sums > 0)
    scores = totals[order]
    wanted = target > 0
    p = target[wanted]
    counts = np.zeros(len(target))
    left = list(range(len(order)))
    chosen: list[int] = []
    for size in range(1, min(places, len(order)) + 1):
        cand = np.array(left)
        q = (counts + mixes[cand]) / size
        smoothed = (1 - CALIBRATION_ALPHA) * q[:, wanted] + CALIBRATION_ALPHA * p
        kl = np.sum(p * np.log(p / smoothed), axis=1)
        value = (1 - CALIBRATION_WEIGHT) * scores[cand] - CALIBRATION_WEIGHT * kl
        best = int(cand[int(np.argmax(value))])
        chosen.append(best)
        counts += mixes[best]
        left.remove(best)
    return [order[k] for k in chosen]
