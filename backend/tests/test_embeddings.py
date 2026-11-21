import numpy as np
import pytest

from app.embeddings import MODEL_NAME, Embedder, fingerprint, profile_texts


def test_fingerprint_changes_only_with_text():
    doc = {"description": "Payroll for clinics", "problem": "", "solution": "App"}
    assert fingerprint(doc, "startup") == fingerprint({**doc, "name": "Renamed"}, "startup")
    assert fingerprint(doc, "startup") != fingerprint({**doc, "solution": "App v2"}, "startup")


def test_fingerprint_ignores_surrounding_spaces_but_not_field_order():
    assert fingerprint({"bio": " Angel investor "}, "investor") == fingerprint({"bio": "Angel investor"}, "investor")
    assert fingerprint({"bio": "x"}, "investor") != fingerprint({"offer": "x"}, "investor")


def test_profile_texts_keep_field_order():
    doc = {"differentiation": "Fast", "description": " Payroll ", "problem": None, "targetCustomers": "SMEs"}
    assert profile_texts(doc, "startup") == ["Payroll", "SMEs", "Fast"]


def test_empty_profile_has_no_texts():
    assert profile_texts({"bio": "  ", "offer": None}, "investor") == []
    assert Embedder.__new__(Embedder).profile_vector([]) is None  # no model needed for empty input


@pytest.mark.slow
def test_vector_shape_and_length():
    v = Embedder().profile_vector(["Clinic appointment booking", "Patients book online"])
    assert v.shape == (384,) and np.linalg.norm(v) == pytest.approx(1.0)


@pytest.mark.parity
def test_matches_sentence_transformers():
    # This test is the gate for using FastEmbed, so a missing package must fail it, not skip it.
    try:
        from sentence_transformers import SentenceTransformer
    except ModuleNotFoundError:
        pytest.fail("sentence-transformers is needed for the parity test: pip install -r requirements-dev.txt")
    # CPU: PyTorch's Apple-GPU backend aborts on some Macs, and the server never uses PyTorch anyway.
    st = SentenceTransformer(MODEL_NAME, device="cpu")
    texts = ["Payroll software for SMEs", "Crypto wallet", "Clinic appointment booking", "Logistics for e-commerce", "Solar panels for farms"]
    ours = np.stack([Embedder().profile_vector([t]) for t in texts])
    ref = st.encode(texts, normalize_embeddings=True)
    assert np.all(np.sum(ours * ref, axis=1) >= 0.999)
