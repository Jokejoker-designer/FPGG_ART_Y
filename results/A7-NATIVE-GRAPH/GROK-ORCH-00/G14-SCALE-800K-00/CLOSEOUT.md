# CLOSEOUT — G14-SCALE-800K-00

```text
RTL_EDIT          = NO
BIT               = NO
PROGRAM           = NO

N=64   cands=64    bytes=1024     full_scan=YES  MIG_XSIM
N=256  cands=256   bytes=4096     full_scan=YES  MIG_XSIM
N=800k cands=800k  bytes=12.8e6   full_scan=YES  EXTRAPOLATED

HS13_SOA_800K     = FAIL
C9_800K_STORE     = NOT_IMPLEMENTED (DEPTH=32, K=8)
M10               = OPEN
GATE14_PASS       = NO
```

Next (if M10 must PASS): a **bounded** retrieval (not fetch-all-N), still
RTL/bit/program only after a new prereg. Or keep M10 OPEN and ship Native V1
without an 800k store claim.
