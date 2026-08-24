from python.ref.a7lm03_fixed_ref import (
    HEAD_EPOCHS,
    PARAM_COUNT,
    TinyGPT25k,
    WMEM_WORDS,
    bank_slices,
    board_corpus,
    fold_bytes,
    train_full_sgd,
)


def test_param_count():
    assert PARAM_COUNT == 25088
    assert len(TinyGPT25k(2).flat_i8()) == WMEM_WORDS


def test_forward_stable():
    m = TinyGPT25k(2)
    z0, p0 = m.forward([1])
    z1, p1 = m.forward([1])
    assert z0 == z1 and p0 == p1


def test_train_schedule_ce_and_banks():
    r = train_full_sgd(TinyGPT25k(2), board_corpus(8), epochs=HEAD_EPOCHS, lr=3)
    assert r["all_moved"]
    assert r["drop"] >= 0.30
    assert r["fold"]["nbytes"] == 25088


def test_fold_deterministic():
    a = TinyGPT25k(2).fold()
    b = TinyGPT25k(2).fold()
    assert a == b


def test_bank_slices_cover_flat():
    slices = bank_slices()
    assert sum(n for _n, _o, n in slices) == 25088
    assert slices[0][0] == "tok" and slices[0][1] == 0
    assert slices[-1][0] == "head" and slices[-1][1] == 20992
    m = TinyGPT25k(2)
    assert fold_bytes(m.flat_i8())["add32"] == m.fold()["add32"]


def test_one_full_oracle_fold():
    m = TinyGPT25k(2)
    assert m.fold() == {"xor32": 0, "add32": 2958688, "nbytes": 25088}
    m.backward_full([1], 16, lr=3, apply=True)
    assert m.fold()["xor32"] == 255
    assert m.fold()["add32"] == 2943381
