# Moving to Synopsys tools

Nothing in this file has been run: there is no Synopsys licence on the development machine. The repo is arranged so
each step is a swap of one command, and the inputs are the standard formats those tools read.

| Step | Today (works here) | Synopsys equivalent | Inputs already in the repo |
|---|---|---|---|
| Simulation | `iverilog` (`make sim`) | VCS: `make sim SIM=vcs`; waveforms in Verdi | `flist/rtl.f`, `flist/tb.f` (plain `-f` file lists) |
| Lint | Verilator | SpyGlass or VC Static | same file lists |
| Synthesis | Yosys (generic gates) | Design Compiler or Fusion Compiler: `synth/dc_synth.tcl` | RTL + `constraints/fpc_top.sdc` |
| Timing | none | PrimeTime | SDC plus the synthesised netlist |
| Equivalence | none | Formality | RTL vs netlist |
| Place and route | none | Fusion Compiler / IC Compiler II | netlist, SDC, a PDK (not available here) |
| Power intent | none | UPF in the above | to be written once there are power domains |

## What to do first on a Synopsys machine
1. `make sim SIM=vcs` and confirm `TB_RESULT: PASS`. The testbench uses `real` and `$random`; both are standard.
2. Fill in `target_library` in `synth/dc_synth.tcl` and run `make synth_dc`. Expect to edit the SDC numbers.
3. Compare the area and gate count with `build/synth_stat.txt` as a sanity check, not as a target: Yosys generic gates
   and a real library are different units.

## Keeping it portable
Use only synthesisable Verilog-2001 style in `rtl/`, no vendor primitives, no `initial` blocks in RTL, and keep every
file listed in `flist/rtl.f`.
