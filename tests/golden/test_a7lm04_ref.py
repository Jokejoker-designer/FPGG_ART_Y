from python.ref.a7lm04_fixed_ref import (
    HELDOUT,
    HELDOUT_R3,
    HELDOUT_R3_N,
    HELDOUT_R3_SEED,
    HELDOUT_R3_SHA256,
    HELDOUT_SHA256,
    HELDOUT_V1_INVALID_SHA256,
    HEAD_EPOCHS,
    INIT_SEEDS_R3,
    PARAM_COUNT,
    RECIPE_R3,
    RECIPE_R3_SHA256,
    TinyGPT100k,
    WMEM_WORDS,
    bank_slices,
    board_corpus,
    corpus_sha256,
    fold_bytes,
    heldout_ce,
    heldout_corpus_r3,
    heldout_corpus_v1_invalid,
    recipe_sha256,
    train_full_sgd,
)


def test_param_count():
    assert PARAM_COUNT == 100352
    assert len(TinyGPT100k(2).flat_i8()) == WMEM_WORDS


def test_law_id_unchanged():
    r = train_full_sgd(TinyGPT100k(2), board_corpus(8), epochs=1, lr=3)
    assert r["law_id"] == "lm05-signsgd-v1"


def test_forward_stable():
    m = TinyGPT100k(2)
    z0, p0 = m.forward([1])
    z1, p1 = m.forward([1])
    assert z0 == z1 and p0 == p1


def test_fold_deterministic():
    assert TinyGPT100k(2).fold() == TinyGPT100k(2).fold()


def test_bank_slices_cover_flat():
    slices = bank_slices()
    assert sum(n for _n, _o, n in slices) == 100352
    assert slices[0] == ("tok", 0, 16384)
    assert slices[-1][0] == "head" and slices[-1][1] == 83968
    m = TinyGPT100k(2)
    assert fold_bytes(m.flat_i8())["add32"] == m.fold()["add32"]


def test_heldout_v1_invalid_archived():
    assert corpus_sha256(heldout_corpus_v1_invalid()) == HELDOUT_V1_INVALID_SHA256
    assert HELDOUT_V1_INVALID_SHA256 == "29d56dccf88a3e315ddfde8e65c4912041b4d5d68a99fd3dd5100ef8881873ba"


def test_heldout_hash_frozen():
    assert corpus_sha256(HELDOUT) == HELDOUT_SHA256
    assert len(HELDOUT) == 24
    assert HELDOUT_SHA256 == "941a7b243e1c1fcaf5f920978067e4c5b8190342600a1374a54e94208d6c4d3c"
    lasts = [p[-1] for p, _t in HELDOUT]
    assert set(lasts) == set(range(1, 9))
    assert all(2 <= len(p) <= 4 for p, _ in HELDOUT)
    assert all(all(x >= 9 for x in pref[:-1]) for pref, _ in HELDOUT)
    assert all(t == 32 + (pref[-1] - 1) for pref, t in HELDOUT)
    assert all(len(p) > 1 for p, _ in HELDOUT)


def test_heldout_r3_preregister():
    assert HELDOUT_R3_SEED == 41
    assert HELDOUT_R3_N == 128
    assert len(HELDOUT_R3) == 128
    assert corpus_sha256(HELDOUT_R3) == HELDOUT_R3_SHA256
    assert HELDOUT_R3_SHA256 == "b77c4635971cc2a8ebf2f49b629aff4704c10f42bed174fbdb70f05dc8802294"
    assert HELDOUT_R3_SHA256 == corpus_sha256(heldout_corpus_r3())
    lasts = [p[-1] for p, _t in HELDOUT_R3]
    assert set(lasts) == set(range(1, 9))
    assert all(lasts.count(k) == 16 for k in range(1, 9))
    assert all(2 <= len(p) <= 4 for p, _ in HELDOUT_R3)
    assert all(all(x >= 9 for x in pref[:-1]) for pref, _ in HELDOUT_R3)
    assert all(t == 32 + (pref[-1] - 1) for pref, t in HELDOUT_R3)
    r2_prefs = {tuple(p) for p, _ in HELDOUT}
    r3_prefs = {tuple(p) for p, _ in HELDOUT_R3}
    assert r2_prefs.isdisjoint(r3_prefs)
    assert INIT_SEEDS_R3 == (17, 19, 23)
    assert set(INIT_SEEDS_R3).isdisjoint({2, 3, 5})


def test_recipe_r3_frozen():
    assert RECIPE_R3["recipe_id"] == "A7-LM-04-R3-TRAIN-v1"
    assert RECIPE_R3["head_epochs"] == HEAD_EPOCHS == 24
    assert RECIPE_R3["head_lr"] == 3
    assert RECIPE_R3["extra_full_passes"] == 2
    assert RECIPE_R3["early_stop"] is False
    assert RECIPE_R3["no_ce_retry"] is True
    assert RECIPE_R3["heldout_used_for_tuning"] is False
    assert recipe_sha256(RECIPE_R3) == RECIPE_R3_SHA256
    assert RECIPE_R3_SHA256 == "d1be0eee2235f30abd48788199b8eabe2b07e8b1b0d53b5d2fdc3086eb9aa7e3"


def test_one_full_oracle_fold():
    m = TinyGPT100k(2)
    assert m.forward([1])[1] == 167
    assert m.last_loss([1], 32) == 16
    assert m.fold() == {"xor32": 2, "add32": 11803320, "nbytes": 100352}
    m.backward_full([1], 32, lr=3, apply=True)
    assert m.fold() == {"xor32": 7, "add32": 11822211, "nbytes": 100352}


def test_lm04_uart_frames():
    from python.uart_frames import lm04_payload_frame, lm04_read_frame, lm04_write_frame, parse_frame

    wr = lm04_write_frame(100344, bytes([1, 2, 3, 4, 5, 6, 7, 8]))
    assert wr[0] == 0xA5 and wr[1] == 0x84 and wr[2] == 0x30
    assert wr[3] == (100344 & 0xFF)
    assert wr[5] == (8 | (1 << 4))
    rd = lm04_read_frame(83968)
    rec = parse_frame(
        lm04_payload_frame(bytes([0x35]) + bytes(11))
    )
    assert rec["ok"] and rec["kind"] == 0x84
    a4 = bytearray(15)
    a4[0] = 0xA5
    a4[1] = 0xA4
    a4[2] = 0x40
    a4[3] = 0x48
    a4[12] = 0x01
    chk = 0
    for b in a4[:14]:
        chk ^= b
    a4[14] = chk
    parsed = parse_frame(bytes(a4))
    assert parsed["ok"] and parsed["addr"] == 0x14840
    assert rd[1] == 0x84 and rd[2] == 0x31
