"""For You: startups for investors and investors for founders (design PDF section 2)."""

from __future__ import annotations

from datetime import datetime

import numpy as np

from .catalog import finite_int
from .data import Snapshot, UserContext, _as_time
from .embeddings import DIM, MODEL_NAME, fingerprint
from .features import (
    Encoder,
    GroupVectors,
    Values,
    criteria_amounts,
    criteria_values,
    investor_values,
    parseable_startup,
    sector_answer,
    startup_values,
    ticket_values,
)
from .ranking import DEFAULT_LIMIT, Pick, amount_fits, recommend_best, ticket_bonus
from .scoring import score_candidates
from .taste import TICKET_STRENGTH, Signal, build_taste
from .vector_store import unpack

Part = tuple[Values, "np.ndarray | None", datetime]


def fresh_vector(key: str, doc: dict, kind: str, snap: Snapshot) -> np.ndarray | None:
    """The stored text vector, only if it was made by our model from the profile's current text."""
    stored = snap.vectors.get(key)
    if not isinstance(stored, dict) or stored.get("model") != MODEL_NAME:
        return None
    if stored.get("fingerprint") != fingerprint(doc, kind):
        return None
    return unpack(stored.get("v"))


def _with_text(groups: GroupVectors, vector: np.ndarray | None) -> GroupVectors:
    return {**groups, "text": vector} if vector is not None else groups


def _with_text_rows(rows: dict[str, np.ndarray], vectors: list[np.ndarray | None]) -> dict[str, np.ndarray]:
    if any(v is not None for v in vectors):
        rows = {**rows, "text": np.stack([v if v is not None else np.zeros(DIM) for v in vectors])}
    return rows


def valid_ticket(ticket: dict) -> bool:
    """InvestmentTicket.fromMap in the app drops tickets without these."""
    return (
        isinstance(ticket.get("investorId"), str)
        and isinstance(ticket.get("name"), str)
        and finite_int(ticket.get("amountMin")) is not None
        and finite_int(ticket.get("amountMax")) is not None
    )


def investor_main_sector(doc: dict) -> str | None:
    """The investor's first sector, as For You groups sectors for the other-sector places."""
    sectors = doc.get("preferredSectors")
    if not isinstance(sectors, list) or not sectors or not isinstance(sectors[0], str):
        return None
    return sector_answer(sectors[0], doc.get("sectorsOther"))


def _listed_startup(doc: dict) -> bool:
    """Shown in the app: loadable by Startup.fromMap, public and not closed."""
    return parseable_startup(doc) and doc.get("isPublic") is True and doc.get("status") != "closed"


def _listed_investor(doc: dict) -> bool:
    return isinstance(doc.get("fullName"), str) and bool(doc["fullName"].strip())


def _parts(keys: dict[str, datetime], prefix: str, docs: dict[str, dict], kind: str, snap: Snapshot) -> list[Part]:
    values_of = startup_values if kind == "startup" else investor_values
    listed = _listed_startup if kind == "startup" else _listed_investor
    out: list[Part] = []
    for key, at in keys.items():
        doc = docs.get(key[len(prefix):]) if key.startswith(prefix) else None
        if doc is not None and listed(doc):
            out.append((values_of(doc), fresh_vector(key, doc, kind, snap), at))
    return out


def _signals(parts: list[Part], encoder: Encoder, strength: float = 1.0) -> list[Signal]:
    return [Signal(_with_text(encoder.encode(values), vector), at, strength) for values, vector, at in parts]


def for_you(ctx: UserContext, snap: Snapshot, now: datetime, limit: int = DEFAULT_LIMIT) -> list[Pick]:
    if ctx.role == "investor":
        return _for_investor(ctx, snap, now, limit)
    return _for_founder(ctx, snap, now, limit)


def _for_investor(ctx: UserContext, snap: Snapshot, now: datetime, limit: int) -> list[Pick]:
    tickets = [t for t in snap.tickets if t.get("investorId") == ctx.uid and valid_ticket(t)]
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
    candidates = [startup_values(d) for d in docs]

    base_values = criteria_values(ctx.user_doc)
    own_profile = snap.investors.get(ctx.uid)
    base_text = fresh_vector(f"i-{ctx.uid}", own_profile, "investor", snap) if own_profile is not None else None
    likes = _parts(ctx.bookmarks, "s-", snap.startups, "startup", snap)
    ticket_likes: list[Part] = [(ticket_values(t), None, _as_time(t.get("createdAt"), now)) for t in tickets]
    dislikes = _parts(ctx.dislikes, "s-", snap.startups, "startup", snap)

    # One vocabulary for the taste and the candidates, written-in answers included.
    encoder = Encoder.covering([base_values, *candidates, *(p[0] for p in likes + ticket_likes + dislikes)])
    taste = build_taste(
        _with_text(encoder.encode(base_values), base_text),
        _signals(likes, encoder) + _signals(ticket_likes, encoder, TICKET_STRENGTH),
        _signals(dislikes, encoder),
        now,
    )
    rows = _with_text_rows(encoder.encode_many(candidates), [fresh_vector(f"s-{sid}", d, "startup", snap) for sid, d in zip(ids, docs)])
    scores = score_candidates(taste, rows)[None, :]
    bonus = np.array([[ticket_bonus(d, tickets) for d in docs]])
    return recommend_best(
        ids, [d["name"] for d in docs], [v["sector"][0] if v["sector"] else None for v in candidates],
        scores, np.ones_like(scores, dtype=bool), bonus, limit=limit,
    )


def _for_founder(ctx: UserContext, snap: Snapshot, now: datetime, limit: int) -> list[Pick]:
    ids = [
        iid for iid, doc in snap.investors.items()
        if _listed_investor(doc)
        and f"i-{iid}" not in ctx.bookmarks
        and f"i-{iid}" not in ctx.dislikes
    ]
    if not ids:
        return []
    docs = [snap.investors[iid] for iid in ids]
    candidates = [investor_values(d) for d in docs]

    # A closed startup never needs investors, so it is not a base, whether
    # founded or joined (all closed: ranked as a founder with no startup).
    # Open startups joined as a team member stay bases.
    own = [(sid, doc) for sid, doc in ctx.own_startups.items() if doc.get("status") != "closed"]
    own_values = [startup_values(doc) for _, doc in own]
    likes = _parts(ctx.bookmarks, "i-", snap.investors, "investor", snap)
    dislikes = _parts(ctx.dislikes, "i-", snap.investors, "investor", snap)

    encoder = Encoder.covering([*own_values, *candidates, *(p[0] for p in likes + dislikes)])
    bases = [
        _with_text(encoder.encode(values), fresh_vector(f"s-{sid}", doc, "startup", snap))
        for (sid, doc), values in zip(own, own_values)
    ] or [{}]
    like_signals, dislike_signals = _signals(likes, encoder), _signals(dislikes, encoder)
    tastes = [build_taste(base, like_signals, dislike_signals, now) for base in bases]

    rows = _with_text_rows(encoder.encode_many(candidates), [fresh_vector(f"i-{iid}", d, "investor", snap) for iid, d in zip(ids, docs)])
    scores = np.stack([score_candidates(taste, rows) for taste in tastes])

    tickets_of: dict[str, list[dict]] = {}
    for ticket in snap.tickets:
        if valid_ticket(ticket):
            tickets_of.setdefault(ticket["investorId"], []).append(ticket)
    allowed = np.ones_like(scores, dtype=bool)
    bonus = np.zeros_like(scores)
    for t, (_, startup) in enumerate(own):
        for k, (iid, doc) in enumerate(zip(ids, docs)):
            theirs = tickets_of.get(iid, [])
            allowed[t, k] = amount_fits(startup, theirs, *criteria_amounts(doc))
            bonus[t, k] = ticket_bonus(startup, theirs)

    return recommend_best(
        ids, [d["fullName"] for d in docs], [investor_main_sector(d) for d in docs],
        scores, allowed, bonus, limit=limit,
    )
