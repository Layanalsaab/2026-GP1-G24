import json

import pytest

from tests.make_parity_fixture import FIXTURE, compute_expected


def test_fixture_matches_python():
    data = json.loads(FIXTURE.read_text())
    expected = data.pop("expected")
    got = compute_expected(data)
    assert [g["id"] for g in got] == [e["id"] for e in expected]
    assert [g["score"] for g in got] == pytest.approx([e["score"] for e in expected], abs=1e-9)
