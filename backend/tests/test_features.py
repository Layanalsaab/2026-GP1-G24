from app.catalog import MODELS, SECTORS, STAGES
from app.features import (
    criteria_amounts,
    criteria_groups,
    investor_groups,
    startup_groups,
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
