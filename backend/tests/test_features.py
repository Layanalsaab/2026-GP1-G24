import numpy as np

from app.catalog import MODELS, SECTORS, STAGES
from app.features import (
    criteria_amounts,
    criteria_groups,
    investor_groups,
    investor_rows,
    investor_values,
    parseable_startup,
    startup_groups,
    startup_rows,
    startup_values,
    ticket_values,
    ticket_groups,
)


def test_startup_counts_other_sectors_and_keeps_other_as_a_value():
    g = startup_groups({"sector": "fintech", "otherSectors": ["AI", "Other"], "stage": "seed", "commerceModel": "b2b"})
    assert g["sector"].sum() == 3 and g["sector"][SECTORS.index("ai")] == 1
    assert g["stage"][STAGES.index("seed")] == 1 and g["model"][MODELS.index("b2b")] == 1


def test_unknown_values_give_empty_groups():
    g = startup_groups({"sector": "space", "stage": None})
    assert g["sector"].sum() == 0 and g["stage"].sum() == 0 and g["model"].sum() == 0
    bad = startup_groups({"sector": 5, "otherSectors": "AI", "commerceModel": ["b2b"]})
    assert bad["sector"].sum() == 0 and bad["model"].sum() == 0


def test_investor_labels():
    g = investor_groups({"preferredSectors": ["HR Tech", "Other"], "preferredStages": ["Series A"],
                         "preferredCommerceModels": ["Business-to-Consumer (B2C)"]})
    assert g["sector"][SECTORS.index("hr_tech")] == 1 and g["sector"].sum() == 2  # "Other" counts too
    assert g["stage"][STAGES.index("series_a")] == 1 and g["model"][MODELS.index("b2c")] == 1


def test_criteria_fall_back_to_nested_map():
    g = criteria_groups({"investorCriteria": {"sectors": ["Fintech"], "stages": ["Seed"], "commerceModels": ["B2B"]}})
    assert g["sector"][SECTORS.index("fintech")] == 1 and g["model"][MODELS.index("b2b")] == 1


def test_ticket_has_no_model():
    g = ticket_groups({"sectors": ["Logistics", "drones"], "stages": ["Seed"]})
    assert g["sector"].sum() == 2 and g["model"].sum() == 0  # "drones" was written in


def test_criteria_amounts():
    assert criteria_amounts({"ticketSize": "SAR 1M – 5M", "roundSizeMin": 1_000_000}) == ("SAR 1M – 5M", 1_000_000, None)
    assert criteria_amounts({"investorCriteria": {"ticketBand": "Other", "roundMax": 9}}) == ("Other", None, 9)


def test_legacy_values_are_read_like_the_app():
    g = startup_groups({"sector": "software_cloud", "otherSectors": ["AI"], "stage": "mvp", "commerceModel": "marketplace"})
    assert g["sector"][SECTORS.index("saas")] == 1 and g["sector"].sum() == 2
    assert g["stage"][STAGES.index("pre_seed")] == 1
    assert g["model"].sum() == 1 and g["model"][len(MODELS)] == 1  # "marketplace" is read as "Other": its own value


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



def test_written_other_counts_as_what_was_written():
    v = startup_values({"sector": "other", "sectorOther": "Space tech", "otherSectors": ["AI", "Drones"],
                        "stage": "seed", "commerceModel": "other", "commerceModelOther": "Subscription"})
    assert v == {"sector": ["other:spacetech", "ai", "other:drone"], "stage": ["seed"], "model": ["other:subscription"]}


def test_other_with_nothing_written_is_its_own_value():
    v = startup_values({"sector": "other", "stage": "seed", "commerceModel": "b2b"})
    assert v["sector"] == ["other"]
    g = startup_groups({"sector": "other", "stage": "seed", "commerceModel": "b2b"})
    assert g["sector"].sum() == 1  # not an empty group any more


def test_investor_written_other_top_level_and_nested():
    top = investor_values({"preferredSectors": ["Other", "Fintech"], "sectorsOther": "Space Tech",
                           "preferredStages": ["Seed"], "preferredCommerceModels": ["Other"],
                           "preferredCommerceModelsOther": "Subscription"})
    assert top == {"sector": ["other:spacetech", "fintech"], "stage": ["seed"], "model": ["other:subscription"]}
    nested = criteria_groups({"investorCriteria": {"sectors": ["Other"], "sectorsOther": "space-tech",
                                                   "commerceModels": ["Other"], "commerceModelsOther": "subscriptions"}})
    assert nested["sector"].sum() == 1 and nested["model"].sum() == 1


def test_ticket_written_sectors():
    assert ticket_values({"sectors": ["Space tech", "Logistics", "Other"], "stages": ["Seed"]}) == {
        "sector": ["other:spacetech", "logistics", "other"], "stage": ["seed"], "model": []}
