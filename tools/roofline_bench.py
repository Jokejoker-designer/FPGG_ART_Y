"""Print compute/DDR roofline numbers used by A7-LM-02."""
UI_HZ = 83_333_333.0
print("compute_peak_gmac", 128 * UI_HZ / 1e9)
print("ddr_peak_gmac_per_GBps", 1.0)
print("ddr_target_gbps", 0.85)
