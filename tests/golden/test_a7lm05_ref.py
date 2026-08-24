from python.ref.a7lm05_fixed_ref import (
    BANK_NAMES,
    C,
    D,
    FF,
    H,
    L,
    LAW_ID,
    PARAM_COUNT,
    TinyGPT399k,
    V,
    WMEM_WORDS,
    bank_slices,
    board_corpus,
    fold_bytes,
    train_full_sgd,
)


def test_param_count():
    assert V == 512 and C == 64 and D == 96 and L == 4 and H == 4 and FF == 192
    assert PARAM_COUNT == 399360
    assert len(TinyGPT399k(2).flat_i8()) == WMEM_WORDS == 399360


def test_four_layers_and_banks():
    assert L == 4
    names = [n for n, _o, _s in bank_slices()]
    assert names[0] == "tok" and names[1] == "pos" and names[-1] == "head"
    assert "wq3" in names and "ff2_3" in names
    assert sum(n for _a, _b, n in bank_slices()) == 399360


def test_law_id_unchanged():
    r = train_full_sgd(TinyGPT399k(2), board_corpus(8), epochs=1, lr=3)
    assert r["law_id"] == LAW_ID == "lm05-signsgd-v1"


def test_forward_stable():
    m = TinyGPT399k(2)
    z0, p0 = m.forward([1])
    z1, p1 = m.forward([1])
    assert z0 == z1 and p0 == p1


def test_fold_deterministic():
    assert TinyGPT399k(2).fold() == TinyGPT399k(2).fold()


def test_one_full_moves_all_layers():
    m = TinyGPT399k(2)
    f0 = m.fold()
    sha0 = m.tensor_sha()
    m.backward_full([1], 32, lr=3, apply=True)
    f1 = m.fold()
    sha1 = m.tensor_sha()
    assert f1 != f0
    assert fold_bytes(m.flat_i8())["add32"] == f1["add32"]
    for li in range(L):
        assert any(
            sha0[name] != sha1[name]
            for name in (f"wq{li}", f"wk{li}", f"wv{li}", f"wo{li}", f"ff1_{li}", f"ff2_{li}")
        )
