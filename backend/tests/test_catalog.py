from app.catalog import (
    MODELS,
    SECTORS,
    STAGES,
    model_value,
    sector_label,
    sector_value,
    stage_label,
    stage_value,
    ticket_min,
)


def test_sector_value_maps_labels():
    assert sector_value("Fintech") == "fintech"
    assert sector_value("HR Tech") == "hr_tech"
    assert sector_value("Other") is None
    assert sector_value("Space") is None


def test_stage_and_model_values():
    assert stage_value("Series A") == "series_a"
    assert stage_value("Other") is None
    assert model_value("Business-to-Business (B2B)") == "b2b"
    assert model_value("B2B") == "b2b"
    assert model_value("b2c") == "b2c"
    assert model_value("Other") is None


def test_vocabulary_sizes():
    assert (len(SECTORS), len(STAGES), len(MODELS)) == (24, 5, 10)


def test_labels_from_values():
    assert sector_label("fintech") == "Fintech" and stage_label("series_a") == "Series A"


def test_ticket_min():
    assert ticket_min("SAR 100K – 500K") == 100_000
    assert ticket_min("Over SAR 5M") == 5_000_000
    assert ticket_min("Other") is None and ticket_min(None) is None
