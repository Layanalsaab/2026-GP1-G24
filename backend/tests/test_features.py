import numpy as np

from app.catalog import MODELS, SECTORS, STAGES
from app.features import (
    criteria_amounts,
    criteria_groups,
    investor_groups,
    investor_rows,
    parseable_startup,
    startup_groups,
    startup_rows,
    ticket_groups,
)


def test_startup_counts_other_sectors_and_drops_other():
    g = startup_groups({"sector": "fintech", "otherSectors": ["AI", "Other"], "stage": "seed", "commerceModel": "b2b"})
    assert g["sector"].sum() == 2 and g["sector"][SECTORS.index("ai")] == 1
    assert g["stage"][STAGES.index("seed")] == 1 and g["model"][MODELS.index("b2b")] == 1


def test_unknown_values_give_empty_groups():
    g = startup_groups({"sector": "space", "stage": None})
    assert g["sector"].sum() == 0 and g["stage"].sum() == 0 and g["model"].sum() == 0
    bad = startup_groups({"sector": 5, "otherSectors": "AI", "commerceModel": ["b2b"]})
    assert bad["sector"].sum() == 0 and bad["model"].sum() == 0


def test_investor_labels():
    g = investor_groups({"preferredSectors": ["HR Tech", "Other"], "preferredStages": ["Series A"],
                         "preferredCommerceModels": ["Business-to-Consumer (B2C)"]})
    assert g["sector"][SECTORS.index("hr_tech")] == 1 and g["sector"].sum() == 1
    assert g["stage"][STAGES.index("series_a")] == 1 and g["model"][MODELS.index("b2c")] == 1


def test_criteria_fall_back_to_nested_map():
    g = criteria_groups({"investorCriteria": {"sectors": ["Fintech"], "stages": ["Seed"], "commerceModels": ["B2B"]}})
    assert g["sector"][SECTORS.index("fintech")] == 1 and g["model"][MODELS.index("b2b")] == 1


def test_ticket_has_no_model():
    g = ticket_groups({"sectors": ["Logistics", "drones"], "stages": ["Seed"]})
    assert g["sector"].sum() == 1 and g["model"].sum() == 0


def test_criteria_amounts():
    assert criteria_amounts({"ticketSize": "SAR 1M – 5M", "roundSizeMin": 1_000_000}) == ("SAR 1M – 5M", 1_000_000, None)
    assert criteria_amounts({"investorCriteria": {"ticketBand": "Other", "roundMax": 9}}) == ("Other", None, 9)


def test_legacy_values_are_read_like_the_app():
    g = startup_groups({"sector": "software_cloud", "otherSectors": ["AI"], "stage": "mvp", "commerceModel": "marketplace"})
    assert g["sector"][SECTORS.index("saas")] == 1 and g["sector"].sum() == 2
    assert g["stage"][STAGES.index("pre_seed")] == 1 and g["model"].sum() == 0


def test_parseable_startup_matches_the_app():
    ok = {"name": "Payly", "founderId": "f1", "sector": "fintech", "stage": "seed", "commerceModel": "b2b", "location": "riyadh"}
    assert parseable_startup(ok)
    assert parseable_startup({**ok, "sector": "hrtech", "stage": "growth", "location": "khobar"})
    for broken in ({"sector": "space"}, {"stage": None}, {"commerceModel": "b2x"}, {"location": "Riyadh City"},
                   {"location": None}, {"founderId": None}, {"name": 7}):
        assert not parseable_startup({**ok, **broken}), broken


def test_rows_for_many_documents_match_one_by_one():
    startups = [{"sector": "fintech", "otherSectors": ["AI"], "stage": "seed", "commerceModel": "b2b"},
                {"sector": "software_cloud", "stage": "mvp", "commerceModel": "marketplace"},
                {"sector": 5}]
    rows = startup_rows(startups)
    for g in ("sector", "stage", "model"):
        assert np.array_equal(rows[g], np.stack([startup_groups(d)[g] for d in startups]))
    investors = [{"preferredSectors": ["HR Tech"], "preferredStages": ["Seed"], "preferredCommerceModels": ["B2C"]}, {}]
    irows = investor_rows(investors)
    for g in ("sector", "stage", "model"):
        assert np.array_equal(irows[g], np.stack([investor_groups(d)[g] for d in investors]))
