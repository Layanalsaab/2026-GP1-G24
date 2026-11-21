"""The app's fixed label lists, copied from lib/recommender/knowledge_filter.dart."""

from __future__ import annotations

import re

# Label shown in the app -> value stored in Firestore ("Other" is dropped everywhere).
_SECTOR_VALUE = {
    "HealthTech": "healthtech",
    "Fintech": "fintech",
    "EdTech": "edtech",
    "E-commerce": "ecommerce",
    "Logistics": "logistics",
    "AgriTech": "agritech",
    "PropTech": "proptech",
    "CleanTech": "cleantech",
    "Tourism": "tourism",
    "SaaS": "saas",
    "AI": "ai",
    "Cybersecurity": "cybersecurity",
    "Gaming": "gaming",
    "Media": "media",
    "FoodTech": "foodtech",
    "Mobility": "mobility",
    "Retail": "retail",
    "Energy": "energy",
    "InsurTech": "insurtech",
    "LegalTech": "legaltech",
    "HR Tech": "hr_tech",
    "Biotech": "biotech",
    "Manufacturing": "manufacturing",
    "Sports": "sports",
}

_STAGE_VALUE = {
    "Pre-seed": "pre_seed",
    "Seed": "seed",
    "Series A": "series_a",
    "Series B": "series_b",
    "Series C": "series_c",
}

_MODEL_VALUE = {
    "Business-to-Government (B2G)": "b2g",
    "Business-to-Business (B2B)": "b2b",
    "Business-to-Business-to-Consumer (B2B2C)": "b2b2c",
    "Direct-to-Consumer (D2C)": "d2c",
    "Business-to-Consumer (B2C)": "b2c",
    "Consumer-to-Consumer (C2C)": "c2c",
    "Business-to-Employee (B2E)": "b2e",
    "Consumer-to-Business (C2B)": "c2b",
    "Government-to-Citizen (G2C)": "g2c",
    "Government-to-Government (G2G)": "g2g",
}

# "How much do you usually invest in one startup?" -> the band's minimum in SAR.
_TICKET_MIN = {
    "Under SAR 100K": 0,
    "SAR 100K – 500K": 100_000,
    "SAR 500K – 1M": 500_000,
    "SAR 1M – 5M": 1_000_000,
    "Over SAR 5M": 5_000_000,
}

SECTORS: tuple[str, ...] = tuple(_SECTOR_VALUE.values())
STAGES: tuple[str, ...] = tuple(_STAGE_VALUE.values())
MODELS: tuple[str, ...] = tuple(_MODEL_VALUE.values())

_SECTOR_LABEL = {v: k for k, v in _SECTOR_VALUE.items()}
_STAGE_LABEL = {v: k for k, v in _STAGE_VALUE.items()}
_BRACKETS = re.compile(r"\(([^)]+)\)")


def sector_value(label: str | None) -> str | None:
    return _SECTOR_VALUE.get(label) if isinstance(label, str) else None


def stage_value(label: str | None) -> str | None:
    return _STAGE_VALUE.get(label) if isinstance(label, str) else None


def model_value(label: str | None) -> str | None:
    """Full label, the short form in brackets ("B2B") or the stored value ("b2b")."""
    if not isinstance(label, str):
        return None
    known = _MODEL_VALUE.get(label)
    if known:
        return known
    match = _BRACKETS.search(label)
    value = (match.group(1) if match else label).strip().lower()
    return value if value in MODELS else None


def sector_label(value: str | None) -> str | None:
    return _SECTOR_LABEL.get(value) if isinstance(value, str) else None


def stage_label(value: str | None) -> str | None:
    return _STAGE_LABEL.get(value) if isinstance(value, str) else None


def ticket_min(band: str | None) -> int | None:
    return _TICKET_MIN.get(band) if isinstance(band, str) else None
