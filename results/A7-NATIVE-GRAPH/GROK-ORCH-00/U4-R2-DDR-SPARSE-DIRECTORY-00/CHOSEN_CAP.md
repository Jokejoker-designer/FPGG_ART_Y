# CAND_CAP note — U4-R2 protocol TB vs U4A-R2 Pareto

U4-R2 XSim uses **CAND_CAP=8** to force truncation and stall (protocol).
U4A-R2 HOST_MODEL Pareto chose **CAND_CAP=192** for 800k recall/bytes.
Do not hard-code 256 in the walker. Parameter stays free.
SoC integration = NO.
