"""An in-memory stand-in for Firestore, with the same Source interface as app.data.FirestoreSource."""

from __future__ import annotations

from datetime import datetime, timezone

from google.cloud.firestore_v1.base_query import FieldFilter


def _check_operator(field: str, op: str | None, value: object) -> None:
    """Fail like the real client does on an operator it does not know (e.g. the JavaScript spelling
    "array-contains"): FirestoreSource builds the same FieldFilter, and turning it into a request
    is where the Python client checks the operator."""
    FieldFilter(field, op, value)._to_pb()


class FakeSource:
    def __init__(self, docs: dict[str, dict] | None = None):
        self.docs: dict[str, dict] = dict(docs or {})
        self.stream_calls = 0
        self.docs_read = 0

    def stream(self, collection: str, field: str | None = None, op: str | None = None, value: object = None) -> list[tuple[str, dict]]:
        self.stream_calls += 1
        if field is not None:
            _check_operator(field, op, value)
        prefix = collection.rstrip("/") + "/"
        out = []
        for path, data in self.docs.items():
            if not path.startswith(prefix) or "/" in path[len(prefix):]:
                continue
            if field is not None:
                current = data.get(field)
                if op == "==" and current != value:
                    continue
                if op == "array_contains" and not (isinstance(current, list) and value in current):
                    continue
            out.append((path[len(prefix):], dict(data)))
        self.docs_read += len(out)
        return out

    def get(self, path: str) -> dict | None:
        self.docs_read += 1
        data = self.docs.get(path)
        return dict(data) if data is not None else None

    def set(self, path: str, data: dict) -> None:
        self.docs[path] = {**data, "updatedAt": datetime.now(timezone.utc)}

    def delete(self, path: str) -> None:
        self.docs.pop(path, None)

    def merge(self, path: str, data: dict) -> None:
        self.docs.setdefault(path, {}).update(data)

    def delete_field(self, path: str, field: str) -> None:
        if path in self.docs:
            self.docs[path].pop(field, None)
