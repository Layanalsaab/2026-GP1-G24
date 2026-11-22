"""Rewrites the expected lists in test/recommender/matching_fixture.json with the Python reference.

Run from backend/:  .venv/bin/python -m tests.make_matching_fixture

Only "forTicket" and "forStartup" change; the input lists ("startups", "investors", "tickets") are kept
as they are. Each entry keeps its explanation "rows" from the previous file when the same list has an
entry with the same id and ticket (rows do not depend on the score).
"""

from __future__ import annotations

import json
from pathlib import Path

from tests.matching_reference import investor_models, load_fixture, matches_for_startup, matches_for_ticket

FIXTURE = Path(__file__).resolve().parents[2] / "test/recommender/matching_fixture.json"


def _with_rows(new: list[dict], old: list[dict]) -> tuple[list[dict], int]:
    rows = {(o["id"], o.get("ticketId")): o["rows"] for o in old if "rows" in o}
    kept = 0
    out = []
    for entry in new:
        entry = {**entry, "score": round(entry["score"], 9)}
        key = (entry["id"], entry["ticketId"])
        if key in rows:
            entry["rows"] = rows[key]
            kept += 1
        out.append(entry)
    return out, kept


def regenerate(data: dict) -> tuple[dict, int, int]:
    """The fixture with both expected maps recomputed; also how many entries kept rows, and how many had them."""
    investors = {i["id"]: i for i in data["investors"]}
    startups = {s["id"]: s for s in data["startups"]}
    kept = before = 0
    for_ticket = {}
    for t in data["tickets"]:
        old = data["forTicket"].get(t["id"], [])
        before += sum(1 for o in old if "rows" in o)
        new = matches_for_ticket(t, investor_models(investors[t["investorId"]]), data["startups"])
        for_ticket[t["id"]], n = _with_rows(new, old)
        kept += n
    for_startup = {}
    for sid, old in data["forStartup"].items():
        before += sum(1 for o in old if "rows" in o)
        new = matches_for_startup(startups[sid], data["investors"], data["tickets"])
        for_startup[sid], n = _with_rows(new, old)
        kept += n
    return {**data, "forTicket": for_ticket, "forStartup": for_startup}, kept, before


def main() -> None:
    data, kept, before = regenerate(load_fixture(FIXTURE))
    # Same layout as the committed file: compact, Unicode written as is.
    FIXTURE.write_text(json.dumps(data, separators=(",", ":"), ensure_ascii=False), encoding="utf-8")
    print(f"wrote {FIXTURE.name}: {len(data['forTicket'])} ticket lists, {len(data['forStartup'])} founder lists; "
          f"rows kept on {kept} of {before} entries that had them")


if __name__ == "__main__":
    main()
