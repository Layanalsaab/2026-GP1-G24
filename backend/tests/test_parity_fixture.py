import json

import pytest

from tests.make_parity_fixture import FIXTURE, TIES_FIXTURE, compute_expected


@pytest.mark.parametrize("fixture", [FIXTURE, TIES_FIXTURE])
def test_fixture_matches_python(fixture):
    data = json.loads(fixture.read_text())
    expected = data.pop("expected")
    got = compute_expected(data)
    assert [g["id"] for g in got] == [e["id"] for e in expected]
    assert [g["score"] for g in got] == pytest.approx([e["score"] for e in expected], abs=1e-9)
