# Frozen qse-v1-lexicon-hdc-00 table. Must match _PREREG.md.
LAW = "qse-v1-lexicon-hdc-00"
MAX_WORD = 12
MAX_BYTES = 48
MAX_WORDS = 8

# (word, class, id) class: 1 entity 2 intent 3 relation 4 context
LEX = [
    ("chiller", 1, 1), ("condenser", 1, 2), ("condensing", 1, 2),
    ("evaporator", 1, 3), ("evap", 1, 3), ("compressor", 1, 4),
    ("refrigerant", 1, 5), ("r410a", 1, 5), ("r32", 1, 5),
    ("ahu", 1, 6), ("handler", 1, 6), ("handling", 1, 6),
    ("duct", 1, 7), ("ductwork", 1, 7), ("vav", 1, 8), ("variable", 1, 8),
    ("tower", 1, 9), ("ct", 1, 9), ("pump", 1, 10),
    ("valve", 1, 11), ("txv", 1, 11), ("sensor", 1, 12),
    ("install", 2, 1), ("mount", 2, 1), ("installation", 2, 1),
    ("leak", 2, 2), ("balance", 2, 3), ("tab", 2, 3),
    ("insulate", 2, 4), ("insulation", 2, 4), ("wrap", 2, 4),
    ("startup", 2, 5), ("commission", 2, 5), ("start", 2, 5),
    ("replace", 2, 6), ("swap", 2, 6),
    ("line", 3, 1), ("pipe", 3, 1), ("coil", 3, 1),
    ("unit", 3, 2), ("plant", 3, 2), ("box", 3, 2),
    ("gas", 3, 3), ("airflow", 3, 3),
    ("water", 4, 1), ("air", 4, 1), ("dx", 4, 1), ("scroll", 4, 1),
    ("supply", 4, 1), ("return", 4, 1), ("chilled", 4, 1),
    ("pressure", 4, 1), ("temp", 4, 1), ("dp", 4, 1),
    ("expansion", 4, 1), ("solenoid", 4, 1), ("cooling", 4, 1),
    ("cell", 4, 1), ("fan", 4, 1), ("test", 4, 1),
]

ENTITY_CANON = {
    "chiller": ["chiller", "water chiller", "chiller unit", "chiller plant"],
    "condenser": ["condenser", "condensing unit", "air condenser", "condenser coil"],
    "evaporator": ["evaporator", "evap coil", "evaporator coil", "dx evaporator"],
    "compressor": ["compressor", "scroll compressor", "compressor unit"],
    "refrigerant": ["refrigerant", "r410a", "r32 gas", "refrigerant line"],
    "ahu": ["ahu", "air handler", "ahu unit", "air handling"],
    "duct": ["duct", "supply duct", "return duct", "ductwork"],
    "vav": ["vav", "vav box", "variable air"],
    "cooling_tower": ["cooling tower", "tower cell", "ct fan"],
    "pump": ["chilled pump", "condenser pump", "water pump"],
    "valve": ["expansion valve", "txv valve", "solenoid valve"],
    "sensor": ["temp sensor", "pressure sensor", "dp sensor"],
}

INTENT_CANON = {
    "install": ["install chiller", "mount chiller", "chiller installation"],
    "leak": ["leak check", "check leak", "gas leak test"],
    "balance": ["air balance", "balance airflow", "tab balance"],
    "insulate": ["insulate pipe", "pipe insulation", "wrap pipe"],
    "startup": ["startup ahu", "commission ahu", "ahu start"],
    "replace": ["replace compressor", "swap compressor", "compressor swap"],
}

SAME_ENT_DIFF_INT = ["install chiller", "leak chiller", "replace chiller"]
UNRELATED = [
    "payroll tax form", "weather forecast", "soccer match score", "cookie recipe",
    "piano lesson", "airport delay", "stock ticker", "garden soil",
]
PERTURB_BASE = ["chiller", "condenser", "evaporator", "compressor", "ahu"]
ADV_SEED = 0xA7FE03
ADV_N = 20
