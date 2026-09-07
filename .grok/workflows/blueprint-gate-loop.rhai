let meta = #{
    name: "blueprint-gate-loop",
    description: "V31 PLAN C00 parent: lock requested U9R, reject stale U8-R3, qa-only audit, never patch frozen RTL in same bag, never BIT/PROGRAM",
    when_to_use: "P10/U9R per docs/native_graph/V31_CLOSURE_PLAN_20260907. Do not rewind accepted gates.",
    phases: [
        #{ title: "Identify", detail: "next lake from CLOSE_NATIVE_V1_DAG, never invent" },
        #{ title: "Implement", detail: "one FPGA-owned gate" },
        #{ title: "Audit", detail: "independent qa-only: FAIL, overclaim, fraud, logic" },
        #{ title: "Repair", detail: "one causal patch then re-audit" },
        #{ title: "Advance", detail: "next lake or hard-stop" },
    ],
};

let impl_schema = #{
    "type": "object",
    "required": ["status", "gate", "bag", "summary"],
    "properties": #{
        "status": #{ "type": "string" },
        "gate": #{ "type": "string" },
        "bag": #{ "type": "string" },
        "summary": #{ "type": "string" },
        "blocked_reason": #{ "type": "string" },
        "head": #{ "type": "string" },
        "xsim": #{ "type": "string" },
        "next_gate": #{ "type": "string" },
    },
};

let audit_schema = #{
    "type": "object",
    "required": ["verdict", "overclaim", "fraud", "evidence"],
    "properties": #{
        "verdict": #{ "type": "string" },
        "overclaim": #{ "type": "boolean" },
        "fraud": #{ "type": "boolean" },
        "first_divergence": #{ "type": "string" },
        "evidence": #{ "type": "string" },
        "fix_hint": #{ "type": "string" },
        "logic_bug": #{ "type": "boolean" },
    },
};

fn as_str(x) {
    if x == () { return ""; }
    if type_of(x) == "string" { return x; }
    return "";
}

fn is_hard_stop_gate(g) {
    if g == "U9S" { return true; }
    if g == "U9I" { return true; }
    if g == "U9P-PREPROGRAM-CLOSURE-00" { return true; }
    if g == "U10" { return true; }
    if g == "P11" { return true; }
    if g == "P12" { return true; }
    if g == "P13" { return true; }
    if g == "P14" { return true; }
    return false;
}

fn is_stale_accepted(g) {
    if g == "U8-R3" { return true; }
    if g == "U8-R3-TYPECLASS-TOPK-TO-LM-00" { return true; }
    if g == "U8R" { return true; }
    if g == "U8R-REMOVE-SYNTHETIC-PRODUCTION" { return true; }
    if g == "U8R-REMOVE-SYNTHETIC-PRODUCTION-00" { return true; }
    if g == "U9" { return true; }
    if g == "U9-FINAL-SOURCE-FREEZE-00" { return true; }
    if g == "U8-SOC-ROOTB-WDMA-00" { return true; }
    return false;
}

fn is_u9r(g) {
    if g == "U9R" { return true; }
    if g == "U9R-FINAL-REGRESSION-00" { return true; }
    return false;
}

let root = "D:/Jetking_sem4/SEM_4/arty-a7-online-lm-g14-preboard-00";
let skill = root + "/.agents/skills/gstack-acceptance-auditor/SKILL.md";
let dag = root + "/docs/native_graph/CLOSE_NATIVE_V1_DAG.md";
let plan = root + "/docs/native_graph/V31_CLOSURE_PLAN_20260907/PLAN.md";
let u9r_prompt = root + "/docs/native_graph/V31_CLOSURE_PLAN_20260907/PROMPT_GROK_U9R.md";
let ledger = root + "/docs/native_graph/V31_LEDGER.md";

let max_gates = 1;
if args != () && args.max_gates != () {
    max_gates = args.max_gates;
}

let start_gate = "U9R-FINAL-REGRESSION-00";
if args != () && args.start_gate != () {
    start_gate = args.start_gate;
}

let hard = "HARD STOPS: BIT=NO PROGRAM=NO REPROGRAM_AGAIN=NO QHEAD=NO HOLD_A_ORACLE_RETARGET=NO. ";
hard += "Never reseat 1F0F2ABB/9CA2B30D/F24150BD/3A7EF204 as the close bit. ";
hard += "Never force-push. Never invent CLASS_ID as NID or as an LM token. Never first-member. ";
hard += "Never retarget HOLD_A OUT 653/689/237/60. Semantic LM stays LM_CHECKPOINT_CONTEXT_MISMATCH. ";
hard += "Do not auto-open U9S/U9I/U9P/U10. Do not declare BOARD_PASS or GATE14_PASS. ";
hard += "Do not git add MIG or a7lm06_wmem.hex. Cycle watchdog, not ns overflow. ";
hard += "TRUTH > PROGRESS. Stop at first divergence. Do not ask the owner mid-lake; the DAG is already locked.";

let lakes = [];
let round = 0;
let current = start_gate;

while round < max_gates {
    round += 1;
    phase("Identify");
    log("gstack /autoplan analog. Round " + round.to_string() + " proposed=" + current);

    let idp = "You are the gstack identify scout (read-only). NEVER edit files. ";
    idp += "Repo " + root + " branch grok-orch/v31-canonical-00. ";
    idp += "MUST use git log, read_file, grep. Do not answer from memory. ";
    idp += "READ FIRST: " + plan + " ; " + u9r_prompt + " ; " + ledger + " ; " + dag + ". ";
    idp += "C00: requested start_gate=" + current + " is LOCKED. ";
    idp += "U8-R3 / U8R / U9 freeze / P7b are ACCEPTED history. Do not return them as gate. ";
    idp += "Note in U8-R3 CLOSEOUT 'do not open U8R/U9' is historical bag scope, not the next pointer. ";
    idp += "Pred 861 is known LM_CHECKPOINT_CONTEXT_MISMATCH, not a new transport bug. ";
    idp += "If requested is U9R-FINAL-REGRESSION-00, gate MUST be U9R-FINAL-REGRESSION-00. ";
    idp += "If next is U9S/U9I/U9P/U10, status=BLOCKED. Allowed now: U9R-FINAL-REGRESSION-00 only. ";
    idp += "Return status PASS or BLOCKED, gate=the lake to run now, bag=absolute bag dir, next_gate, summary. ";
    idp += hard;
    let idr = agent(idp, #{
        label: "identify-r" + round.to_string(),
        capability_mode: "read-only",
        output_schema: impl_schema,
    });
    if idr == () || !idr.success {
        complete(#{ status: "BLOCKED", reason: "identify failed", round: round, lakes: lakes });
    }
    let id_status = "";
    let gate = current;
    let bag = root + "/results/A7-NATIVE-GRAPH/GROK-ORCH-00/" + current;
    if idr.output != () {
        id_status = as_str(idr.output.status);
        if as_str(idr.output.gate) != "" { gate = as_str(idr.output.gate); }
        if as_str(idr.output.bag) != "" { bag = as_str(idr.output.bag); }
    }
    if is_stale_accepted(gate) {
        log("C00 reject stale scout gate=" + gate + " keep requested=" + current);
        gate = current;
        bag = root + "/results/A7-NATIVE-GRAPH/GROK-ORCH-00/" + current;
        id_status = "PASS";
    }
    if is_hard_stop_gate(gate) {
        complete(#{
            status: "BLOCKED",
            gate: gate,
            reason: "hard-stop class BIT/PROGRAM",
            lakes: lakes,
        });
    }
    if id_status == "BLOCKED" && !is_u9r(current) {
        complete(#{
            status: "BLOCKED",
            gate: gate,
            reason: as_str(idr.output.blocked_reason),
            summary: as_str(idr.output.summary),
            lakes: lakes,
            note: "Parent stopped before BIT/PROGRAM. Owner DAG remains.",
        });
    }

    phase("Implement");
    log("gstack eng analog. Implement " + gate + " one unknown.");

    let ip = "You are the gstack implementer for Native V1 on Digilent Arty A7-100T. ";
    ip += "Worktree: " + root + " . Branch grok-orch/v31-canonical-00. ";
    ip += "Execute ONE lake only: " + gate + ". Bag dir: " + bag + " . ";
    ip += "MUST use read_file, grep, list_dir, run_terminal_command, search_replace. Do not answer from memory. ";
    ip += "READ FIRST: " + plan + " ; " + u9r_prompt + " ; " + ledger + " ; " + dag + " ; " + skill + ". ";
    ip += "Pin PRODUCTION_RTL=bdddbd68. Do not rewind U8-R3. ";
    ip += "XSim via C:/2026.1/Vivado/bin xvlog/xelab/xsim. License D:\\Xilinx\\licenses\\vivado_basic.lic. ";
    ip += "If gate is U9R-FINAL-REGRESSION-00: execute R0-R9 from PLAN. ";
    ip += "Do NOT edit frozen RTL in this same bag to flip FAIL to PASS. ";
    ip += "Missing wiring = INTEGRATION_GAP. Narrow PASS must not open U9S. ";
    ip += "Required CLOSEOUT fields: REGRESSION_RESULT FULL_SOC_RESULT M10_SCOPE ROOT_B_SCOPE ";
    ip += "LM_ORACLE_COMPATIBILITY READY_FOR_FINAL_SYNTH NEXT. ";
    ip += "Do not claim silicon, Gate14, BOARD_PASS, OUT=653, or LM understands TYPE_CLASS. ";
    ip += "Do not instantiate MIG churn. Do not program. ";
    ip += hard;
    ip += " Return JSON status PASS FAIL or BLOCKED, gate, bag absolute path, summary, xsim line.";
    let impl = agent(ip, #{
        label: "implement:" + gate,
        capability_mode: "all",
        output_schema: impl_schema,
    });
    if impl == () || !impl.success {
        complete(#{ status: "BLOCKED", reason: "implementer failed schema", gate: gate, lakes: lakes });
    }
    let impl_status = "";
    let impl_bag = bag;
    if impl.output != () {
        impl_status = as_str(impl.output.status);
        if as_str(impl.output.bag) != "" { impl_bag = as_str(impl.output.bag); }
    }
    if impl_status == "BLOCKED" {
        lakes.push(#{ gate: gate, status: "BLOCKED", bag: impl_bag, summary: as_str(impl.output.summary) });
        complete(#{ status: "BLOCKED", gate: gate, lakes: lakes, impl: impl.output });
    }

    phase("Audit");
    log("gstack /qa-only analog. Independent nghiem-thu. Never patches.");

    let ap = "You are the independent gstack acceptance auditor (qa-only / nghiem-thu). ";
    ap += "NEVER patch RTL, TB, or CLOSEOUT claims. NEVER soften FAIL to keep the DAG moving. ";
    ap += "Repo " + root + ". Gate " + gate + ". Bag " + impl_bag + ". ";
    ap += "Read skill " + skill + " in full. Analog: E:/agents/gstack/qa-only (report only). ";
    ap += "MUST use read_file and grep on CLOSEOUT.md RESULTS.md xsim.log SHA256.txt RTL TB. ";
    ap += "Fail closed if xsim.log missing, SHA missing, or PASS asserted without a matching log marker. ";
    ap += "Hunt FAIL hidden as PASS; overclaim (silicon, Gate14, Q-head, NLU, OUT=653, LM understands TYPE_CLASS, ";
    ap += "SoC top instantiated when it was not, WDMA ACK=commit when only store XSim ran); ";
    ap += "fraud (TB inspects CLASS_ID to pick reward, host builds learn key, first-member); ";
    ap += "logic (lookup after heap, CLASS_ID as LM token, low8 CLASS_ID, NID bind on TYPE_CLASS path, host counters nonzero); ";
    ap += "BIT/PROGRAM/QHEAD performed; history rewrite. ";
    ap += "Write ACCEPTANCE.md in the bag only. verdict PASS FAIL BLOCKED or OVERCLAIM. ";
    ap += "overclaim=true if CLOSEOUT claims more than the log supports. fraud=true if TB cheats. ";
    ap += "logic_bug=true if CLASS_ID used as token or native_ctx_bind packs global_id low8 as the TYPE_CLASS stream. ";
    ap += hard;
    let aud = agent(ap, #{
        label: "audit:" + gate,
        capability_mode: "read-only",
        output_schema: audit_schema,
    });
    if aud == () || !aud.success {
        complete(#{ status: "BLOCKED", reason: "auditor failed", gate: gate, impl: impl.output, lakes: lakes });
    }
    let v = "";
    let oc = false;
    let fr = false;
    let lb = false;
    if aud.output != () {
        v = as_str(aud.output.verdict);
        if aud.output.overclaim == true { oc = true; }
        if aud.output.fraud == true { fr = true; }
        if aud.output.logic_bug == true { lb = true; }
    }
    log("Auditor verdict=" + v + " overclaim=" + oc.to_string());

    let lake_ok = (v == "PASS" && oc == false && fr == false && lb == false);
    if !lake_ok && is_u9r(gate) {
        lakes.push(#{ gate: gate, status: "FAIL", bag: impl_bag, verdict: v });
        complete(#{
            status: "FAIL",
            gate: gate,
            first_divergence: as_str(aud.output.first_divergence),
            evidence: as_str(aud.output.evidence),
            lakes: lakes,
            note: "U9R must not patch frozen RTL in this bag. Keep U9 freeze. Manager assigns C00-C13 revision.",
        });
    }
    if !lake_ok && v != "BLOCKED" {
        phase("Repair");
        log("One causal patch. Auditor never patches. gstack /review auto-fix analog then re-QA.");
        let rp = "You are the gstack patch implementer. ONE causal fix only. Stop at first divergence. ";
        rp += "Repo " + root + ". Gate " + gate + ". Bag " + impl_bag + ". ";
        rp += "MUST use read_file grep run_terminal_command. Do not answer from memory. ";
        rp += "Auditor verdict: " + v + ". first_divergence: " + as_str(aud.output.first_divergence) + ". ";
        rp += "fix_hint: " + as_str(aud.output.fix_hint) + ". evidence: " + as_str(aud.output.evidence) + ". ";
        rp += "Fix only that divergence. Re-run XSim. Update CLOSEOUT honestly. Do not relabel FAIL as PASS. ";
        rp += "Do not expand to U9S/PROGRAM. " + hard;
        let fix = agent(rp, #{
            label: "patch:" + gate,
            capability_mode: "all",
            output_schema: impl_schema,
        });
        if fix == () || !fix.success {
            complete(#{ status: "FAIL", reason: "patch agent failed", gate: gate, audit: aud.output, lakes: lakes });
        }
        let fix_bag = impl_bag;
        if fix.output != () && as_str(fix.output.bag) != "" {
            fix_bag = as_str(fix.output.bag);
        }
        let ap2 = "Independent re-audit after one patch. NEVER patch. qa-only. Repo " + root + ". ";
        ap2 += "Bag " + fix_bag + ". Read new xsim.log CLOSEOUT. Fail closed if log missing. ";
        ap2 += "Same hunt: FAIL-as-PASS, overclaim, fraud, CLASS_ID-as-token, BIT/PROGRAM, WDMA overclaim. ";
        ap2 += "Write ACCEPTANCE.md. " + hard;
        let aud2 = agent(ap2, #{
            label: "reaudit:" + gate,
            capability_mode: "read-only",
            output_schema: audit_schema,
        });
        if aud2 == () || !aud2.success {
            complete(#{ status: "FAIL", reason: "reaudit failed", gate: gate, lakes: lakes });
        }
        let v2 = "";
        let oc2 = false;
        let fr2 = false;
        let lb2 = false;
        if aud2.output != () {
            v2 = as_str(aud2.output.verdict);
            if aud2.output.overclaim == true { oc2 = true; }
            if aud2.output.fraud == true { fr2 = true; }
            if aud2.output.logic_bug == true { lb2 = true; }
        }
        lake_ok = (v2 == "PASS" && oc2 == false && fr2 == false && lb2 == false);
        impl_bag = fix_bag;
        if !lake_ok {
            lakes.push(#{ gate: gate, status: "FAIL", bag: impl_bag, verdict: v2 });
            complete(#{
                status: "FAIL",
                gate: gate,
                first_audit: aud.output,
                reaudit: aud2.output,
                lakes: lakes,
                note: "Stopped after one repair round. Parent must not invent a second causal patch or open BIT.",
            });
        }
        lakes.push(#{ gate: gate, status: "PASS_AFTER_PATCH", bag: impl_bag });
    } else if v == "BLOCKED" {
        lakes.push(#{ gate: gate, status: "BLOCKED", bag: impl_bag, audit: aud.output });
        complete(#{ status: "BLOCKED", gate: gate, audit: aud.output, lakes: lakes });
    } else if lake_ok {
        lakes.push(#{ gate: gate, status: "PASS", bag: impl_bag, summary: as_str(impl.output.summary) });
    } else {
        lakes.push(#{ gate: gate, status: v, bag: impl_bag });
        complete(#{ status: v, gate: gate, audit: aud.output, lakes: lakes });
    }

    phase("Advance");
    let nxt = as_str(idr.output.next_gate);
    if nxt == "" { nxt = "STOP"; }
    if is_hard_stop_gate(nxt) {
        complete(#{
            status: "PASS",
            lakes: lakes,
            next: nxt,
            note: "Next lake is BIT/PROGRAM class. Parent stops. Owner must authorize U9P separately.",
        });
    }
    current = nxt;
    if current == "STOP" {
        complete(#{ status: "PASS", lakes: lakes, note: "Identify did not name a further auto lake." });
    }
}

complete(#{
    status: "PASS",
    lakes: lakes,
    rounds: round,
    note: "Hit max_gates. Re-run /blueprint-gate-loop with the next start_gate. BIT=NO PROGRAM=NO.",
});
