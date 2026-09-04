# LAW — qfe-v1-crc16-mix-00

Frozen by U3Q-QUERY-REPRESENTATION-AUTHORITY-00. Do not retarget silently.

```text
INPUT  = raw 8-bit application tokens, L in 1..16
HOST   = tokens + fire only
HOST_FORBIDDEN = hash shard bucket winner address entity intent relation path
CRC    = CRC16-CCITT-FALSE init=FFFF poly=1021 (a7ng_gate14_crc.svh)
```

After L tokens and fire:

```text
xor  = XOR of tokens
sum  = wrapping 16-bit sum
crc  = CRC16 over tokens in order
K0   = crc
K1   = crc ^ {xor, first}
K2   = {sum[7:0], xor} ^ {last, first}
K3   = {L, xor} ^ crc
```

Same tokens => same {K0..K3}. One-token change => CRC/keys change.

Not a learned encoder. Not H5 EAM-03E.
