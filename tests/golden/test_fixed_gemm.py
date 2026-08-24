from python.ref.fixed_gemm import (
    batch_fold,
    case_params,
    requant_hw_fold,
    run_case,
    run_explicit,
    sat16,
    sat32,
)


def test_batch_stable():
    a = batch_fold(64, 0xC0FFEE00)
    b = batch_fold(64, 0xC0FFEE00)
    assert a == b
    assert a["macs"] > 0


def test_corners_and_sat_present():
    kinds = {run_case(i)["corner"] for i in range(34)}
    sats = {run_case(i)["sat"] for i in range(38)}
    assert True in kinds
    assert True in sats


def test_int8_minmax_case0():
    hit = next(run_case(i) for i in range(64) if run_case(i)["corner"])
    assert hit["corner"]
    assert isinstance(hit["P"][0][0], int)


def test_sat16_helper():
    assert sat16(40000) == 32767
    assert sat16(-40000) == -32768
    assert sat32(1 << 40) == 2147483647


def test_case8_is_sat_case13_is_corner():
    assert case_params(8)["sat"] and not case_params(8)["corner"]
    assert case_params(13)["corner"] and not case_params(13)["sat"]
    for i in (0, 1, 7, 17, 19):
        p = case_params(i)
        assert not p["sat"] and not p["corner"]


def test_k_gt_256_fold_stable():
    a = run_explicit(0, 1, 128, 257)
    b = run_explicit(0, 1, 128, 257)
    assert a["xor32"] == b["xor32"] and a["macs"] == 257 * 128
    for k in (257, 511, 513):
        r = run_explicit(0, 1, 128, k)
        assert r["macs"] == k * 128


def test_requant_hw_fold_shift0():
    r = run_case(8)
    x, a = requant_hw_fold(r["P"], r["mode"], r["M"], r["N"], 0)
    assert isinstance(x, int) and isinstance(a, int)


def test_nonmultiple_shapes():
    seen = set()
    for i in range(80):
        r = run_case(i)
        seen.add((r["mode"], r["M"], r["N"], r["K"]))
    assert any(n not in (16, 128) for _, _, n, _ in seen)
    assert any(k not in (64, 128, 256) for _, _, _, k in seen)
