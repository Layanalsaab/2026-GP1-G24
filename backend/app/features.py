"""Sector, stage and commerce-model groups as binary vectors (design PDF 2.3)."""

from __future__ import annotations

from typing import Iterable

import numpy as np
from sklearn.preprocessing import MultiLabelBinarizer

from .catalog import (
    MODELS,
    SECTORS,
    STAGES,
    finite_int,
    location_ok,
    model_value,
    sector_value,
    stage_value,
    stored_model,
    stored_sector,
    stored_stage,
)

GroupVectors = dict[str, np.ndarray]

VOCAB: dict[str, tuple[str, ...]] = {"sector": SECTORS, "stage": STAGES, "model": MODELS}
LABEL_GROUPS: tuple[str, ...] = ("sector", "stage", "model")

_BINARIZERS = {g: MultiLabelBinarizer(classes=list(v)).fit([list(v)]) for g, v in VOCAB.items()}

# Any of these fields at the top of users/{uid} means the answers are stored there
# (InvestorCriteria.fromFields in the app); otherwise the nested investorCriteria map is used.
_TOP_LEVEL_CRITERIA = (
    "investmentsCount",
    "yearsInvesting",
    "ticketSize",
    "preferredSectors",
    "preferredStages",
    "preferredCommerceModels",
    "lookingFor",
)


def encode(values: dict[str, Iterable[str | None]]) -> GroupVectors:
    """One binary vector per label group; values outside the vocabulary are ignored."""
    out: GroupVectors = {}
    for group, binarizer in _BINARIZERS.items():
        known = {v for v in values.get(group, ()) if v in VOCAB[group]}
        out[group] = binarizer.transform([sorted(known)])[0].astype(float)
    return out


def encode_many(values: list[dict[str, Iterable[str | None]]]) -> dict[str, np.ndarray]:
    """Like encode, for many documents in one call per group: an (n × vocabulary) matrix each."""
    out: dict[str, np.ndarray] = {}
    for group, binarizer in _BINARIZERS.items():
        known = [sorted({v for v in item.get(group, ()) if v in VOCAB[group]}) for item in values]
        out[group] = binarizer.transform(known).astype(float) if values else np.zeros((0, len(VOCAB[group])))
    return out


def _strings(raw: object) -> list[str]:
    return [v.strip() for v in raw if isinstance(v, str)] if isinstance(raw, list) else []


def _text(raw: object) -> str | None:
    return raw if isinstance(raw, str) else None


_int = finite_int


def parseable_startup(doc: dict) -> bool:
    """True when the app's Startup.fromMap would load this document (otherwise it is never shown)."""
    return (
        stored_sector(doc.get("sector")) is not None
        and stored_stage(doc.get("stage")) is not None
        and stored_model(doc.get("commerceModel")) is not None
        and location_ok(doc.get("location"))
        and isinstance(doc.get("founderId"), str)
        and isinstance(doc.get("name"), str)
    )


def _startup_values(doc: dict) -> dict[str, list[str | None]]:
    return {
        "sector": [stored_sector(doc.get("sector"))] + [sector_value(l) for l in _strings(doc.get("otherSectors"))],
        "stage": [stored_stage(doc.get("stage"))],
        "model": [stored_model(doc.get("commerceModel"))],
    }


def _label_values(sectors: list[str], stages: list[str], models: list[str]) -> dict[str, list[str | None]]:
    return {
        "sector": [sector_value(l) for l in sectors],
        "stage": [stage_value(l) for l in stages],
        "model": [model_value(l) for l in models],
    }


def _investor_values(doc: dict) -> dict[str, list[str | None]]:
    return _label_values(
        _strings(doc.get("preferredSectors")),
        _strings(doc.get("preferredStages")),
        _strings(doc.get("preferredCommerceModels")),
    )


def startup_groups(doc: dict) -> GroupVectors:
    return encode(_startup_values(doc))


def startup_rows(docs: list[dict]) -> dict[str, np.ndarray]:
    return encode_many([_startup_values(d) for d in docs])


def _from_labels(sectors: list[str], stages: list[str], models: list[str]) -> GroupVectors:
    return encode(_label_values(sectors, stages, models))


def investor_groups(doc: dict) -> GroupVectors:
    return encode(_investor_values(doc))


def investor_rows(docs: list[dict]) -> dict[str, np.ndarray]:
    return encode_many([_investor_values(d) for d in docs])


def _nested(user_doc: dict) -> dict | None:
    if any(user_doc.get(k) is not None for k in _TOP_LEVEL_CRITERIA):
        return None
    nested = user_doc.get("investorCriteria")
    return nested if isinstance(nested, dict) else {}


def criteria_groups(user_doc: dict) -> GroupVectors:
    nested = _nested(user_doc)
    if nested is None:
        return investor_groups(user_doc)
    return _from_labels(
        _strings(nested.get("sectors")),
        _strings(nested.get("stages")),
        _strings(nested.get("commerceModels")),
    )


def criteria_amounts(user_doc: dict) -> tuple[str | None, int | None, int | None]:
    nested = _nested(user_doc)
    if nested is None:
        return (_text(user_doc.get("ticketSize")), _int(user_doc.get("roundSizeMin")), _int(user_doc.get("roundSizeMax")))
    return (_text(nested.get("ticketBand")), _int(nested.get("roundMin")), _int(nested.get("roundMax")))


def ticket_groups(doc: dict) -> GroupVectors:
    return _from_labels(_strings(doc.get("sectors")), _strings(doc.get("stages")), [])
