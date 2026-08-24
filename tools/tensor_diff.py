"""Compare one A7-LM-02 case: host ref only. Board compare is a7lm02_close_ladder."""
from python.ref.fixed_gemm import run_case

if __name__ == "__main__":
    import json, sys
    i = int(sys.argv[1]) if len(sys.argv) > 1 else 0
    r = run_case(i)
    r.pop("P", None)
    print(json.dumps(r, indent=2))
