# Board usage — 8-agent

1. Program `build/out/basys3_eight_agent.bit`.
2. LED15 must be on.
3. SW13 ON (dest=1). SW15/14 off. SW8/7/6 off (src=0). SW9 off.
4. SW11 ON.
5. Press **BTNU** once. This resets weights to 0040 and starts EVAL.
6. LED13 on during TRAIN (~80 s at 8 MHz / 78 ms × 1024). Then LED12 on (HOLD).
7. LED7:0 should walk `01 02 04 08 10 20 40 80`.
8. 7-seg for `weight[1][0]` should stop near **0440**, not 07FF.

If you see **07FF**, the clip rail was hit (extra TRAIN without reset).
Press BTNU. Do not toggle SW11 to “run again”.
