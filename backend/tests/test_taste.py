from datetime import datetime, timedelta, timezone

import numpy as np
import pytest

from app.catalog import SECTORS
from app.features import encode
from app.taste import Signal, build_taste, decay_weight

NOW = datetime(2026, 11, 21, tzinfo=timezone.utc)


def i(value: str) -> int:
    return SECTORS.index(value)


def base_fintech():
    return encode({"sector": ["fintech"]})


def base_fintech_and_ai():
    return encode({"sector": ["fintech", "ai"]})


def like_ai(at: datetime) -> Signal:
    return Signal(encode({"sector": ["ai"]}), at)


def test_decay_weight():
    assert decay_weight(NOW, NOW) == 1.0
    assert decay_weight(NOW - timedelta(days=90), NOW) == pytest.approx(0.5)
    assert decay_weight(NOW - timedelta(days=30), NOW) == pytest.approx(0.5 ** (1 / 3))
    assert decay_weight(NOW - timedelta(days=365), NOW) == 0.4
    assert decay_weight(NOW, NOW, strength=1.5) == 1.5
    assert decay_weight(NOW + timedelta(days=2), NOW) == 1.0
    assert decay_weight(NOW - timedelta(days=89, hours=23, minutes=59), NOW) == pytest.approx(0.5 ** (2159 / 24 / 90))


def test_share_grows_with_bookmarks():
    one = build_taste(base_fintech(), [like_ai(NOW)], [], NOW)
    two = build_taste(base_fintech(), [like_ai(NOW), like_ai(NOW)], [], NOW)
    assert one.learned_share == pytest.approx(0.2) and two.learned_share == pytest.approx(0.3)
    assert build_taste(base_fintech(), [], [], NOW).learned_share == 0


def test_blend_moves_toward_bookmarks():
    t = build_taste(base_fintech(), [like_ai(NOW)], [], NOW)
    assert t.groups["sector"][i("fintech")] == pytest.approx(0.8) and t.groups["sector"][i("ai")] == pytest.approx(0.2)


def test_empty_base_uses_bookmarks_alone():
    t = build_taste({}, [like_ai(NOW - timedelta(days=200))], [], NOW)
    assert t.groups["sector"][i("ai")] == pytest.approx(1.0) and t.groups["sector"].sum() == pytest.approx(1.0)


def test_dislike_subtracts_and_clips_label_groups():
    t = build_taste(base_fintech_and_ai(), [], [like_ai(NOW)], NOW)  # the ai item is disliked here
    assert t.groups["sector"][i("ai")] == pytest.approx(0.7071068 - 0.2, abs=1e-6)
    t2 = build_taste(base_fintech(), [], [like_ai(NOW)], NOW)
    assert t2.groups["sector"].min() == 0  # no negative label weights


def test_text_keeps_negatives_and_empty_taste_ignores_dislikes():
    t = build_taste({"text": np.array([1.0, 0.0])}, [], [Signal({"text": np.array([0.0, 1.0])}, NOW)], NOW)
    assert t.groups["text"][1] == pytest.approx(-0.2)
    empty = build_taste({}, [], [Signal({"text": np.array([0.0, 1.0])}, NOW)], NOW)
    assert not np.any(empty.groups.get("text", np.zeros(2)))


def test_target_mix_blends_the_base_sectors_with_the_liked_ones():
    base = {"sector": np.array([1.0, 1.0, 0.0])}  # fintech, healthtech chosen at onboarding
    like = Signal({"sector": np.array([0.0, 0.0, 1.0])}, NOW)  # one saas bookmark, made now
    taste = build_taste(base, [like], [], NOW)
    share = taste.learned_share
    assert share == pytest.approx(0.2)
    assert taste.target == pytest.approx([(1 - share) / 2, (1 - share) / 2, share])


def test_target_mix_without_likes_is_the_base_and_without_a_base_the_likes():
    base = {"sector": np.array([1.0, 1.0, 0.0])}
    assert build_taste(base, [], [], NOW).target == pytest.approx([0.5, 0.5, 0.0])
    like = Signal({"sector": np.array([0.0, 1.0, 1.0])}, NOW)
    assert build_taste({}, [like], [], NOW).target == pytest.approx([0.0, 0.5, 0.5])
    assert build_taste({}, [], [], NOW).target is None


def test_dislikes_do_not_change_the_target_mix():
    base = {"sector": np.array([1.0, 1.0, 0.0])}
    nope = Signal({"sector": np.array([1.0, 0.0, 0.0])}, NOW)
    assert build_taste(base, [], [nope], NOW).target == pytest.approx([0.5, 0.5, 0.0])
