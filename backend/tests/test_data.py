import threading
import time
from datetime import datetime, timedelta, timezone

from app.data import DataStore
from app.vector_store import pack, write
from tests.fakes import FakeSource

T0 = datetime(2026, 11, 21, 9, 0, tzinfo=timezone.utc)


class Clock:
    def __init__(self, now: datetime):
        self.now = now

    def __call__(self) -> datetime:
        return self.now


def _seeded() -> FakeSource:
    return FakeSource({
        "startups/s1": {"name": "Payly", "isPublic": True, "founderId": "f1", "sector": "fintech"},
        "startups/s2": {"name": "Hidden", "isPublic": False, "founderId": "f1", "memberIds": ["u9"]},
        "startups/s3": {"name": "Shared", "isPublic": True, "founderId": "f2", "memberIds": ["f1"]},
        "investors/i1": {"fullName": "Nora", "preferredSectors": ["Fintech"]},
        "tickets/i1-T1": {"investorId": "i1", "status": "open", "amountMin": 1, "amountMax": 2},
        "tickets/i1-T2": {"investorId": "i1", "status": "closed", "amountMin": 1, "amountMax": 2},
        "users/f1": {"role": "founder"},
        "users/f1/bookmarks/i-i1": {"type": "i", "targetId": "i1", "createdAt": T0 - timedelta(days=3)},
        "users/f1/notInterested/i-i2": {"type": "i", "targetId": "i2", "createdAt": T0 - timedelta(days=1)},
        "users/x1": {"fullName": "No role"},
    })


def seeded() -> FakeSource:
    source = _seeded()
    write(source, "s-s1", {"v": pack([0.0] * 384), "model": "m", "fingerprint": "abc"})
    return source


def test_snapshot_is_cached_for_30_minutes():
    source, clock = seeded(), Clock(T0)
    store = DataStore(source, clock=clock)
    store.snapshot()
    reads = source.stream_calls
    clock.now = T0 + timedelta(minutes=29)
    store.snapshot()
    assert source.stream_calls == reads
    clock.now = T0 + timedelta(minutes=31)
    assert store.snapshot().loaded_at == T0 + timedelta(minutes=31)
    assert source.stream_calls == 2 * reads


def test_snapshot_keeps_public_startups_and_open_tickets():
    snap = DataStore(seeded(), clock=Clock(T0)).snapshot()
    assert set(snap.startups) == {"s1", "s3"}
    assert [t["investorId"] for t in snap.tickets] == ["i1"] and snap.tickets[0]["status"] == "open"
    assert set(snap.investors) == {"i1"} and set(snap.vectors) == {"s-s1"}


def test_user_context_reads_bookmarks_dislikes_and_own_startups():
    ctx = DataStore(seeded(), clock=Clock(T0)).user_context("f1")
    assert ctx.role == "founder" and ctx.uid == "f1"
    assert ctx.bookmarks == {"i-i1": T0 - timedelta(days=3)}
    assert ctx.dislikes == {"i-i2": T0 - timedelta(days=1)}
    assert set(ctx.own_startups) == {"s1", "s2", "s3"}  # founder of s1, s2; member of s3


def test_user_context_reads_the_investors_open_tickets_fresh():
    source = seeded()
    source.docs["users/inv1"] = {"role": "investor"}
    store = DataStore(source, clock=Clock(T0))
    store.snapshot()  # cached for 30 minutes from here
    source.docs["tickets/inv1-T1"] = {"investorId": "inv1", "status": "open", "name": "New", "amountMin": 1, "amountMax": 2}
    source.docs["tickets/inv1-T2"] = {"investorId": "inv1", "status": "closed", "name": "Old", "amountMin": 1, "amountMax": 2}
    ctx = store.user_context("inv1")
    assert [t["name"] for t in ctx.own_tickets] == ["New"]
    assert store.snapshot().tickets == [source.docs["tickets/i1-T1"]]  # the shared snapshot is unchanged
    assert store.user_context("f1").own_tickets is None  # founders: tickets come from the snapshot


def test_user_without_role_has_no_context():
    store = DataStore(seeded(), clock=Clock(T0))
    assert store.user_context("x1") is None
    assert store.user_context("missing") is None


def test_documents_with_bad_types_are_skipped():
    source = seeded()
    source.docs["startups/s4"] = {"name": "Odd", "isPublic": True, "sector": 5}
    source.docs["users/f1/bookmarks/s-s4"] = {"createdAt": "yesterday"}
    source.docs["users/f1/bookmarks/s-s5"] = {"createdAt": datetime(2026, 11, 1, 8, 0)}  # no timezone
    store = DataStore(source, clock=Clock(T0))
    assert "s4" in store.snapshot().startups
    ctx = store.user_context("f1")
    assert ctx.bookmarks["s-s4"] == T0
    assert ctx.bookmarks["s-s5"] == datetime(2026, 11, 1, 8, 0, tzinfo=timezone.utc)


class SlowSource(FakeSource):
    def stream(self, *args, **kwargs):
        time.sleep(0.05)
        return super().stream(*args, **kwargs)


def test_snapshot_loads_once_when_two_requests_arrive_together():
    source = SlowSource(seeded().docs)
    store = DataStore(source, clock=Clock(T0))
    threads = [threading.Thread(target=store.snapshot) for _ in range(2)]
    for t in threads:
        t.start()
    for t in threads:
        t.join()
    assert source.stream_calls == 4


def test_remember_profile_leaves_a_snapshot_in_use_unchanged():
    store = DataStore(seeded(), clock=Clock(T0))
    before = store.snapshot()
    store.remember_profile("startup", "new", {"name": "New", "isPublic": True},
                           {"vector": [0.0] * 384, "model": "m", "fingerprint": "f"})
    assert "new" not in before.startups and "s-new" not in before.vectors
    after = store.snapshot()
    assert "new" in after.startups and "s-new" in after.vectors


def test_snapshot_reads_few_documents_for_many_vectors():
    source = seeded()
    for k in range(300):
        write(source, f"s-x{k}", {"v": pack([0.0] * 384), "model": "m", "fingerprint": str(k)})
    source.docs_read = 0
    snap = DataStore(source, clock=Clock(T0)).snapshot()
    assert len(snap.vectors) == 301
    assert source.docs_read <= len(snap.startups) + len(snap.investors) + 2 + 16  # 2 tickets (open + closed) read


def test_remember_profile_drops_a_startup_made_private():
    store = DataStore(seeded(), clock=Clock(T0))
    store.snapshot()
    store.remember_profile("startup", "s1", {"name": "Payly", "isPublic": False}, None)
    assert "s1" not in store.snapshot().startups


def test_role_of_reads_one_document():
    source = seeded()
    store = DataStore(source, clock=Clock(T0))
    source.docs_read = 0
    assert store.role_of("f1") == "founder" and source.docs_read == 1
    assert store.role_of("x1") is None and store.role_of("missing") is None
