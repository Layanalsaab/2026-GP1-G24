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
    typed_token,
)

GroupVectors = dict[str, np.ndarray]
Values = dict[str, list[str | None]]

LABEL_GROUPS: tuple[str, ...] = ("sector", "stage", "model")
# The app's options; written-in "Other" answers ("other:spacetech") are added per request.
BASE_VOCAB: dict[str, tuple[str, ...]] = {"sector": SECTORS, "stage": STAGES, "model": MODELS}

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


class Encoder:
    """Binary vectors per label group with scikit-learn's MultiLabelBinarizer.

    The vocabulary is the app's fixed options plus every written-in answer the request contains, so a taste and its candidates are always encoded with the same columns.
    """

    def __init__(self, extra: dict[str, set[str]] | None = None):
        extra = extra or {}
        self.classes = {
            g: list(BASE_VOCAB[g]) + sorted(set(extra.get(g, ())) - set(BASE_VOCAB[g])) for g in LABEL_GROUPS
        }
        self._known = {g: set(c) for g, c in self.classes.items()}
        self._binarizers = {g: MultiLabelBinarizer(classes=c).fit([c]) for g, c in self.classes.items()}

    @classmethod
    def covering(cls, values: Iterable[Values]) -> "Encoder":
        extra: dict[str, set[str]] = {g: set() for g in LABEL_GROUPS}
        for item in values:
            for g in LABEL_GROUPS:
                extra[g].update(v for v in item.get(g, ()) if isinstance(v, str))
        return cls(extra)

    def _known_values(self, item: Values, group: str) -> list[str]:
        return sorted({v for v in item.get(group, ()) if v in self._known[group]})

    def encode(self, item: Values) -> GroupVectors:
        return {g: b.transform([self._known_values(item, g)])[0].astype(float) for g, b in self._binarizers.items()}

    def encode_many(self, items: list[Values]) -> dict[str, np.ndarray]:
        if not items:
            return {g: np.zeros((0, len(c))) for g, c in self.classes.items()}
        return {g: b.transform([self._known_values(i, g) for i in items]).astype(float) for g, b in self._binarizers.items()}


def encode(values: Values) -> GroupVectors:
    return Encoder.covering([values]).encode(values)


def encode_many(values: list[Values]) -> dict[str, np.ndarray]:
    return Encoder.covering(values).encode_many(values)


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


def sector_answer(label: str, written: object = None) -> str | None:
    """An answer from the sector list: "Other" counts as what was written; a written-in entry as itself."""
    if label == "Other":
        return typed_token(written, "sector")
    return sector_value(label) or typed_token(label, "sector")


def _stage_of(label: str) -> str | None:
    return stage_value(label)  # the app offers no "Other" stage


def _model_of(label: str, written: object = None) -> str | None:
    if label == "Other":
        return typed_token(written, "model")
    return model_value(label) or typed_token(label, "model")


def startup_values(doc: dict) -> Values:
    sector = stored_sector(doc.get("sector"))
    if sector == "other":
        sector = typed_token(doc.get("sectorOther"), "sector")
    model = stored_model(doc.get("commerceModel"))
    if model == "other":
        model = typed_token(doc.get("commerceModelOther"), "model")
    stage = stored_stage(doc.get("stage"))
    return _present({
        "sector": [sector] + [sector_answer(l) for l in _strings(doc.get("otherSectors"))],
        "stage": [None if stage == "other" else stage],
        "model": [model],
    })


def _present(values: Values) -> Values:
    return {g: [v for v in vs if v] for g, vs in values.items()}


def _label_values(sectors: list[str], stages: list[str], models: list[str],
                  sectors_written: object = None, models_written: object = None) -> Values:
    return _present({
        "sector": [sector_answer(l, sectors_written) for l in sectors],
        "stage": [_stage_of(l) for l in stages],
        "model": [_model_of(l, models_written) for l in models],
    })


def investor_values(doc: dict) -> Values:
    return _label_values(
        _strings(doc.get("preferredSectors")),
        _strings(doc.get("preferredStages")),
        _strings(doc.get("preferredCommerceModels")),
        doc.get("sectorsOther"),
        doc.get("preferredCommerceModelsOther"),
    )


def criteria_values(user_doc: dict) -> Values:
    nested = _nested(user_doc)
    if nested is None:
        return investor_values(user_doc)
    return _label_values(
        _strings(nested.get("sectors")),
        _strings(nested.get("stages")),
        _strings(nested.get("commerceModels")),
        nested.get("sectorsOther"),
        nested.get("commerceModelsOther"),
    )


def ticket_values(doc: dict) -> Values:
    return _present({
        "sector": [sector_answer(l) for l in _strings(doc.get("sectors"))],
        "stage": [_stage_of(l) for l in _strings(doc.get("stages"))],
        "model": [],
    })


def startup_groups(doc: dict) -> GroupVectors:
    return encode(startup_values(doc))


def startup_rows(docs: list[dict]) -> dict[str, np.ndarray]:
    return encode_many([startup_values(d) for d in docs])


def investor_groups(doc: dict) -> GroupVectors:
    return encode(investor_values(doc))


def investor_rows(docs: list[dict]) -> dict[str, np.ndarray]:
    return encode_many([investor_values(d) for d in docs])


def _nested(user_doc: dict) -> dict | None:
    if any(user_doc.get(k) is not None for k in _TOP_LEVEL_CRITERIA):
        return None
    nested = user_doc.get("investorCriteria")
    return nested if isinstance(nested, dict) else {}


def criteria_groups(user_doc: dict) -> GroupVectors:
    return encode(criteria_values(user_doc))


def criteria_amounts(user_doc: dict) -> tuple[str | None, int | None, int | None]:
    nested = _nested(user_doc)
    if nested is None:
        return (_text(user_doc.get("ticketSize")), _int(user_doc.get("roundSizeMin")), _int(user_doc.get("roundSizeMax")))
    return (_text(nested.get("ticketBand")), _int(nested.get("roundMin")), _int(nested.get("roundMax")))


def ticket_groups(doc: dict) -> GroupVectors:
    return encode(ticket_values(doc))
