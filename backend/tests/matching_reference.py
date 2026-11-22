"""An independent Python reference for the app's Matching (lib/recommender/knowledge_filter.dart
and content_ranker.dart): the same filters, scores and order, without the explanation rows.

test/recommender/matching_test.dart compares the app with test/recommender/matching_fixture.json;
this module writes and checks that file's expected lists (tests/make_matching_fixture.py).
"""

from __future__ import annotations

import json
import math
import re
from dataclasses import dataclass
from pathlib import Path

WEIGHTS = {"sector": 0.41, "stage": 0.29, "model": 0.18, "fit": 0.12}
TOP_N = 20
OTHER_SECTOR_FACTOR = 0.5

# Copied from lib/recommender/knowledge_filter.dart (it keeps "Other", unlike backend/app/catalog.py).
SECTOR_VALUE = {
    "HealthTech": "healthtech", "Fintech": "fintech", "EdTech": "edtech", "E-commerce": "ecommerce",
    "Logistics": "logistics", "AgriTech": "agritech", "PropTech": "proptech", "CleanTech": "cleantech",
    "Tourism": "tourism", "SaaS": "saas", "AI": "ai", "Cybersecurity": "cybersecurity",
    "Gaming": "gaming", "Media": "media", "FoodTech": "foodtech", "Mobility": "mobility",
    "Retail": "retail", "Energy": "energy", "InsurTech": "insurtech", "LegalTech": "legaltech",
    "HR Tech": "hr_tech", "Biotech": "biotech", "Manufacturing": "manufacturing", "Sports": "sports",
    "Other": "other",
}
STAGE_VALUE = {
    "Pre-seed": "pre_seed", "Seed": "seed", "Series A": "series_a", "Series B": "series_b",
    "Series C": "series_c", "Other": "other",
}
MODEL_VALUE = {
    "Business-to-Government (B2G)": "b2g", "Business-to-Business (B2B)": "b2b",
    "Business-to-Business-to-Consumer (B2B2C)": "b2b2c", "Direct-to-Consumer (D2C)": "d2c",
    "Business-to-Consumer (B2C)": "b2c", "Consumer-to-Consumer (C2C)": "c2c",
    "Business-to-Employee (B2E)": "b2e", "Consumer-to-Business (C2B)": "c2b",
    "Government-to-Citizen (G2C)": "g2c", "Government-to-Government (G2G)": "g2g", "Other": "other",
}
TICKET_MIN = {
    "Under SAR 100K": 0, "SAR 100K – 500K": 100_000, "SAR 500K – 1M": 500_000,
    "SAR 1M – 5M": 1_000_000, "Over SAR 5M": 5_000_000, "Other": None,
}
SECTOR_LABEL = {v: k for k, v in SECTOR_VALUE.items()}
# InvestorCriteria.dealsOptions: "How many startups have you invested in?" (the index is the activity rank).
DEALS_OPTIONS = ("0", "1–3", "4–6", "7–9", "10+")

_NOT_LETTER_OR_DIGIT = re.compile(r"[\W_]", re.UNICODE)


def load_fixture(path: Path) -> dict:
    return json.loads(Path(path).read_text(encoding="utf-8"))


def _round(x: float) -> int:
    """Dart's num.round(): halves away from zero (Python's round() goes to even)."""
    return int(math.floor(x + 0.5)) if x >= 0 else -int(math.floor(-x + 0.5))


def _int(raw: object) -> int | None:
    if isinstance(raw, bool) or not isinstance(raw, (int, float)):
        return None
    return int(raw)


def _text(raw: object) -> str | None:
    return raw.strip() if isinstance(raw, str) and raw.strip() else None


def _other_key(text: str) -> str:
    key = _NOT_LETTER_OR_DIGIT.sub("", text.lower())
    return key[:-1] if len(key) > 1 and key.endswith("s") else key


def same(a: str | None, b: str | None) -> bool:
    """OtherCheck.same (lib/helpers/other_check.dart)."""
    x, y = (a or "").strip(), (b or "").strip()
    return bool(x) and bool(y) and _other_key(x) == _other_key(y)


def _values(raw: object, to_value: dict[str, str]) -> set[str]:
    if not isinstance(raw, list):
        return set()
    return {to_value[label] for label in raw if isinstance(label, str) and label in to_value}


@dataclass(frozen=True)
class Startup:
    id: str
    name: str
    sector: str | None
    sector_other: str | None
    other_sectors: frozenset[str]
    stage: str | None
    commerce_model: str | None
    looking_for: tuple[str, ...]
    funding_requirement: int | None
    raised_in_round: int | None
    is_public: bool
    is_closed: bool

    @classmethod
    def of(cls, d: dict) -> "Startup":
        return cls(
            id=d["id"],
            name=d.get("name") or "",
            sector=d.get("sector") if isinstance(d.get("sector"), str) else None,
            sector_other=_text(d.get("sectorOther")),
            other_sectors=frozenset(
                SECTOR_VALUE[v] for v in (d.get("otherSectors") or []) if isinstance(v, str) and v in SECTOR_VALUE
            ),
            stage=d.get("stage") if isinstance(d.get("stage"), str) else None,
            commerce_model=d.get("commerceModel") if isinstance(d.get("commerceModel"), str) else None,
            looking_for=tuple(v for v in (d.get("lookingFor") or []) if isinstance(v, str)),
            funding_requirement=_int(d.get("fundingRequirement")),
            raised_in_round=_int(d.get("raisedInRound")),
            is_public=d.get("isPublic") is True,
            is_closed=d.get("status") == "closed",
        )

    @property
    def is_listed(self) -> bool:
        return self.is_public and not self.is_closed

    @property
    def remaining(self) -> int:
        if "funding" not in self.looking_for:
            return 0
        left = (self.funding_requirement or 0) - (self.raised_in_round or 0)
        return left if left > 0 else 0

    @property
    def is_raising(self) -> bool:
        return not self.is_closed and self.remaining > 0

    @property
    def sector_label(self) -> str:
        if self.sector == "other":
            return self.sector_other or "Other"
        return SECTOR_LABEL.get(self.sector or "") or self.sector or ""


@dataclass(frozen=True)
class Investor:
    id: str
    name: str
    sectors: frozenset[str]
    stages: frozenset[str]
    models: frozenset[str]
    ticket_size: str | None
    round_size_min: int | None
    round_size_max: int | None
    activity: int

    @classmethod
    def of(cls, d: dict) -> "Investor":
        deals = d.get("investmentsCount")
        return cls(
            id=d["id"],
            name=d.get("fullName") or "",
            sectors=frozenset(_values(d.get("preferredSectors"), SECTOR_VALUE)),
            stages=frozenset(_values(d.get("preferredStages"), STAGE_VALUE)),
            models=frozenset(_values(d.get("preferredCommerceModels"), MODEL_VALUE)),
            ticket_size=d.get("ticketSize") if isinstance(d.get("ticketSize"), str) else None,
            round_size_min=_int(d.get("roundSizeMin")),
            round_size_max=_int(d.get("roundSizeMax")),
            activity=DEALS_OPTIONS.index(deals.strip()) if isinstance(deals, str) and deals.strip() in DEALS_OPTIONS else -1,
        )

    @property
    def interests_complete(self) -> bool:
        return bool(self.sectors) and bool(self.stages)

    @property
    def picks(self) -> int:
        return len(self.sectors) + len(self.stages)


@dataclass(frozen=True)
class Ticket:
    id: str
    investor_id: str
    sectors: tuple[str, ...]
    stages: frozenset[str]
    amount_min: int
    amount_max: int
    is_open: bool

    @classmethod
    def of(cls, d: dict) -> "Ticket":
        status = d.get("status")
        return cls(
            id=d["id"],
            investor_id=d.get("investorId") or "",
            sectors=tuple(v.strip() for v in (d.get("sectors") or []) if isinstance(v, str) and v.strip()),
            stages=frozenset(
                STAGE_VALUE[v.strip()] for v in (d.get("stages") or []) if isinstance(v, str) and v.strip() in STAGE_VALUE
            ),
            amount_min=_int(d.get("amountMin")) or 0,
            amount_max=_int(d.get("amountMax")) or 0,
            is_open=("open" if status is None else status) == "open",
        )

    @property
    def picks(self) -> int:
        return len(self.sectors) + len(self.stages)

    @property
    def sector_values(self) -> set[str]:
        return {v for x in self.sectors for k, v in SECTOR_VALUE.items() if k != "Other" and same(x, k)}


# --- Hard constraints (knowledge_filter.dart) ---


def ticket_fits(i: Investor, s: Startup) -> bool | None:
    if not s.is_raising:
        return None
    lo = TICKET_MIN.get(i.ticket_size or "")
    if lo is None:
        return None
    return lo <= s.remaining


def round_size_fits(i: Investor, s: Startup) -> bool | None:
    lo, hi = i.round_size_min, i.round_size_max
    if not s.is_raising or (lo is None and hi is None):
        return None
    size = s.funding_requirement
    return (lo is None or size >= lo) and (hi is None or size <= hi)


def shares_other_sector(i: Investor, s: Startup) -> bool:
    return any(v in i.sectors for v in s.other_sectors)


def failed_filters(i: Investor, s: Startup) -> list[str]:
    failed = []
    if s.sector not in i.sectors:
        failed.append("sector")
    if s.stage not in i.stages:
        failed.append("stage")
    if ticket_fits(i, s) is False:
        failed.append("ticket")
    if round_size_fits(i, s) is False:
        failed.append("round size")
    return failed


def _one_of_sector_or_stage(failed: list[str]) -> bool:
    return len(failed) == 1 and failed[0] in ("sector", "stage")


def is_close(i: Investor, s: Startup) -> bool:
    return _one_of_sector_or_stage(failed_filters(i, s))


def ticket_sector_fits(t: Ticket, s: Startup) -> bool:
    return any(same(x, s.sector_label) or (x == "Other" and s.sector == "other") for x in t.sectors)


def ticket_shares_other_sector(t: Ticket, s: Startup) -> bool:
    values = t.sector_values
    return any(v in values for v in s.other_sectors)


def ticket_amount_fits(t: Ticket, s: Startup) -> bool:
    return s.is_raising and t.amount_min <= s.remaining


def failed_ticket_filters(t: Ticket, s: Startup) -> list[str]:
    failed = []
    if not ticket_sector_fits(t, s):
        failed.append("sector")
    if s.stage not in t.stages:
        failed.append("stage")
    if not ticket_amount_fits(t, s):
        failed.append("amount")
    return failed


def is_close_for_ticket(t: Ticket, s: Startup) -> bool:
    return _one_of_sector_or_stage(failed_ticket_filters(t, s))


# --- Scores (content_ranker.dart) ---


def _overlap(chosen: frozenset[str], value: str | None) -> float | None:
    """Met (1) or not met (0); None = blank, skipped."""
    if not chosen or not value:
        return None
    return 1.0 if value in chosen else 0.0


def _sector(picks: int, main: bool, other: bool, s: Startup) -> float | None:
    """Met (1), partly met through another sector (0.5) or not met (0)."""
    if picks == 0 or not s.sector:
        return None
    if main:
        return 1.0
    if other:
        return OTHER_SECTOR_FACTOR
    return 0.0


def score_parts(i: Investor, s: Startup) -> dict[str, float | None]:
    return {
        "sector": _sector(len(i.sectors), s.sector in i.sectors, shares_other_sector(i, s), s),
        "stage": _overlap(i.stages, s.stage),
        "model": _overlap(i.models, s.commerce_model),
    }


def round_fit(t: Ticket, s: Startup) -> float | None:
    left = s.remaining
    if left <= 0:
        return None
    return min(1.0, t.amount_max / left)


def ticket_score_parts(t: Ticket, models: frozenset[str], s: Startup) -> dict[str, float | None]:
    return {
        "sector": _sector(len(t.sectors), ticket_sector_fits(t, s), ticket_shares_other_sector(t, s), s),
        "stage": _overlap(t.stages, s.stage),
        "model": _overlap(models, s.commerce_model),
        "fit": round_fit(t, s),
    }


def weighted_score(parts: dict[str, float | None]) -> float:
    total = used = 0.0
    for key, value in parts.items():
        if value is None:
            continue
        total += WEIGHTS[key] * value
        used += WEIGHTS[key]
    return 0.0 if used == 0 else total / used


def _percent(x: float) -> int:
    return min(100, _round(x * 100))


# --- Order ---


@dataclass(frozen=True)
class _Result:
    id: str
    name: str
    score: float
    close: bool
    ticket_id: str | None = None
    fit: float | None = None  # tie-breakers (PDF 1.7)
    activity: int = -1
    picks: int = 0

    def out(self) -> dict:
        return {
            "id": self.id,
            "percent": _percent(self.score),
            "score": self.score,
            "close": self.close,
            "ticketId": self.ticket_id,
        }


def _key(x: float) -> int:
    """Differences below 1e-9 do not count."""
    return _round(x * 1e9)


def _score_key(r: _Result) -> int:
    return _key(r.score)


def _sort_key(r: _Result) -> tuple:
    """Score, round fit, activity (higher first); picks (fewer first); name; id."""
    return (-_score_key(r), -_key(r.fit or 0.0), -r.activity, r.picks, r.name.lower(), r.id)


def _better_ticket(m: _Result, best: _Result) -> bool:
    """Exact beats close, then the higher score, then the higher round fit, then the smaller ticket id."""
    if m.close != best.close:
        return not m.close
    return (-_score_key(m), -_key(m.fit or 0.0), m.ticket_id) < (-_score_key(best), -_key(best.fit or 0.0), best.ticket_id)


def _ordered(results: list[_Result]) -> list[_Result]:
    exact = sorted((r for r in results if not r.close), key=_sort_key)
    close = sorted((r for r in results if r.close), key=_sort_key)
    return exact + close


def investor_models(investor: dict) -> set[str]:
    return set(Investor.of(investor).models)


def matches_for_ticket(ticket: dict, models: set[str], startups: list[dict]) -> list[dict]:
    t = Ticket.of(ticket)
    chosen = frozenset(models)
    results = []
    for raw in startups:
        s = Startup.of(raw)
        if not t.is_open or not s.is_listed or not s.is_raising:
            continue
        exact = not failed_ticket_filters(t, s)
        if not exact and not is_close_for_ticket(t, s):
            continue
        score = weighted_score(ticket_score_parts(t, chosen, s))
        results.append(_Result(s.id, s.name, score, not exact, fit=round_fit(t, s)))
    return [r.out() for r in _ordered(results)]


def matches_for_startup(startup: dict, investors: list[dict], tickets: list[dict], limit: int = TOP_N) -> list[dict]:
    s = Startup.of(startup)
    if s.is_closed or not s.is_raising:
        return []
    tickets_of: dict[str, list[Ticket]] = {}
    for raw in tickets:
        t = Ticket.of(raw)
        if t.is_open:
            tickets_of.setdefault(t.investor_id, []).append(t)
    via_ticket: list[_Result] = []
    via_profile: list[_Result] = []
    for raw in investors:
        i = Investor.of(raw)
        best: _Result | None = None
        for t in tickets_of.get(i.id, []):
            exact = not failed_ticket_filters(t, s)
            if not exact and not is_close_for_ticket(t, s):
                continue
            score = weighted_score(ticket_score_parts(t, i.models, s))
            m = _Result(i.id, i.name, score, not exact, t.id, round_fit(t, s), i.activity, t.picks)
            if best is None or _better_ticket(m, best):
                best = m
        if best is not None:
            via_ticket.append(best)
            continue
        if not i.interests_complete:
            continue
        exact = not failed_filters(i, s)
        if not exact and not is_close(i, s):
            continue
        score = weighted_score(score_parts(i, s))
        via_profile.append(_Result(i.id, i.name, score, not exact, activity=i.activity, picks=i.picks))
    return [r.out() for r in (_ordered(via_ticket) + _ordered(via_profile))[:limit]]
