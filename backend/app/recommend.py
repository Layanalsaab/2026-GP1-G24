"""For You: startups for investors and investors for founders (design PDF section 2)."""

from __future__ import annotations

from datetime import datetime

import numpy as np

from .catalog import sector_value
from .data import Snapshot, UserContext, _as_time
from .embeddings import DIM, MODEL_NAME, fingerprint
from .features import (
    LABEL_GROUPS,
    GroupVectors,
    criteria_amounts,
    criteria_groups,
    investor_groups,
    startup_groups,
    ticket_groups,
)
from .ranking import DEFAULT_LIMIT, Pick, amount_fits, recommend_best, ticket_bonus
from .scoring import score_candidates
from .taste import TICKET_STRENGTH, Signal, build_taste


def fresh_vector(key: str, doc: dict, kind: str, snap: Snapshot) -> np.ndarray | None:
    """The stored text vector, only if it was made by our model from the profile's current text."""
    stored = snap.vectors.get(key)
    if not isinstance(stored, dict) or stored.get("model") != MODEL_NAME:
        return None
    if stored.get("fingerprint") != fingerprint(doc, kind):
        return None
    vector = stored.get("vector")
    if not isinstance(vector, list) or len(vector) != DIM:
        return None
    return np.asarray(vector, dtype=float)


def _with_text(groups: GroupVectors, vector: np.ndarray | None) -> GroupVectors:
    return {**groups, "text": vector} if vector is not None else groups


def _rows(items: list[GroupVectors]) -> dict[str, np.ndarray]:
    rows = {g: np.stack([item[g] for item in items]) for g in LABEL_GROUPS}
    if any("text" in item for item in items):
        rows["text"] = np.stack([item.get("text", np.zeros(DIM)) for item in items])
    return rows


def _listed_startup(doc: dict) -> bool:
    return isinstance(doc.get("name"), str) and doc.get("isPublic") is True and doc.get("status") != "closed"


def _signals(keys: dict[str, datetime], prefix: str, docs: dict[str, dict], kind: str, snap: Snapshot) -> list[Signal]:
    build = startup_groups if kind == "startup" else investor_groups
    out = []
    for key, at in keys.items():
        doc = docs.get(key[len(prefix):]) if key.startswith(prefix) else None
        if doc is not None:
            out.append(Signal(_with_text(build(doc), fresh_vector(key, doc, kind, snap)), at))
    return out


def for_you(ctx: UserContext, snap: Snapshot, now: datetime, limit: int = DEFAULT_LIMIT) -> list[Pick]:
    if ctx.role == "investor":
        return _for_investor(ctx, snap, now, limit)
    return _for_founder(ctx, snap, now, limit)


def _for_investor(ctx: UserContext, snap: Snapshot, now: datetime, limit: int) -> list[Pick]:
    tickets = [t for t in snap.tickets if t.get("investorId") == ctx.uid]
    base = criteria_groups(ctx.user_doc)
    own_profile = snap.investors.get(ctx.uid)
    if own_profile is not None:
        base = _with_text(base, fresh_vector(f"i-{ctx.uid}", own_profile, "investor", snap))
    likes = _signals(ctx.bookmarks, "s-", snap.startups, "startup", snap)
    likes += [Signal(ticket_groups(t), _as_time(t.get("createdAt"), now), TICKET_STRENGTH) for t in tickets]
    dislikes = _signals(ctx.dislikes, "s-", snap.startups, "startup", snap)
    taste = build_taste(base, likes, dislikes, now)

    band, round_min, round_max = criteria_amounts(ctx.user_doc)
    ids = [
        sid for sid, doc in snap.startups.items()
        if _listed_startup(doc)
        and sid not in ctx.own_startups
        and f"s-{sid}" not in ctx.bookmarks
        and f"s-{sid}" not in ctx.dislikes
        and amount_fits(doc, tickets, band, round_min, round_max)
    ]
    if not ids:
        return []
    docs = [snap.startups[sid] for sid in ids]
    items = [_with_text(startup_groups(d), fresh_vector(f"s-{sid}", d, "startup", snap)) for sid, d in zip(ids, docs)]
    scores = score_candidates(taste, _rows(items))[None, :]
    bonus = np.array([[ticket_bonus(d, tickets) for d in docs]])
    return recommend_best(
        ids, [d["name"] for d in docs], [d.get("sector") for d in docs],
        scores, np.ones_like(scores, dtype=bool), bonus, limit=limit,
    )


def _for_founder(ctx: UserContext, snap: Snapshot, now: datetime, limit: int) -> list[Pick]:
    likes = _signals(ctx.bookmarks, "i-", snap.investors, "investor", snap)
    dislikes = _signals(ctx.dislikes, "i-", snap.investors, "investor", snap)
    own = list(ctx.own_startups.items())
    bases = [_with_text(startup_groups(doc), fresh_vector(f"s-{sid}", doc, "startup", snap)) for sid, doc in own] or [{}]
    tastes = [build_taste(base, likes, dislikes, now) for base in bases]

    ids = [
        iid for iid, doc in snap.investors.items()
        if isinstance(doc.get("fullName"), str) and doc["fullName"].strip()
        and f"i-{iid}" not in ctx.bookmarks
        and f"i-{iid}" not in ctx.dislikes
    ]
    if not ids:
        return []
    docs = [snap.investors[iid] for iid in ids]
    items = [_with_text(investor_groups(d), fresh_vector(f"i-{iid}", d, "investor", snap)) for iid, d in zip(ids, docs)]
    rows = _rows(items)
    scores = np.stack([score_candidates(taste, rows) for taste in tastes])

    tickets_of: dict[str, list[dict]] = {}
    for ticket in snap.tickets:
        tickets_of.setdefault(ticket.get("investorId"), []).append(ticket)
    allowed = np.ones_like(scores, dtype=bool)
    bonus = np.zeros_like(scores)
    for t, (_, startup) in enumerate(own):
        for k, (iid, doc) in enumerate(zip(ids, docs)):
            theirs = tickets_of.get(iid, [])
            allowed[t, k] = amount_fits(startup, theirs, *criteria_amounts(doc))
            bonus[t, k] = ticket_bonus(startup, theirs)

    def main_sector(doc: dict) -> str | None:
        sectors = doc.get("preferredSectors")
        return sector_value(sectors[0]) if isinstance(sectors, list) and sectors and isinstance(sectors[0], str) else None

    return recommend_best(
        ids, [d["fullName"] for d in docs], [main_sector(d) for d in docs],
        scores, allowed, bonus, limit=limit,
    )
