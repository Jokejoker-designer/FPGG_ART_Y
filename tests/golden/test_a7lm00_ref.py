from python.ref.lm05_fixed_ref import LAW_ID, PARAM_COUNT, TinyGPT, train_full_sgd, micro_corpus


def test_law_and_param_count():
    assert LAW_ID == "lm05-signsgd-v1"
    assert PARAM_COUNT == 3200


def test_seed2_sha_stable():
    a = TinyGPT(seed=2).tensor_sha()
    b = TinyGPT(seed=2).tensor_sha()
    assert a == b
    assert len(a) == 9


def test_host_ce_drop_still_ge_30():
    rec = train_full_sgd(TinyGPT(seed=2), micro_corpus(32), epochs=8, lr=8)
    assert rec["drop"] >= 0.30
    assert rec["all_moved"]
