.PHONY: all lint sim synth synth_dc clean
# Tool-neutral flow. Run from the repo root.  make [lint|sim|synth|all]
# Open-source tools today; SIM=vcs / synth_dc / dc templates are the Synopsys path (see docs/SYNOPSYS_MIGRATION.md).
SIM ?= iverilog
TOP  = fpc_top

all: lint sim synth

lint:
	verilator --lint-only -Wall -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -Wno-UNUSEDSIGNAL -Wno-SYNCASYNCNET -f flist/rtl.f --top-module $(TOP)

sim: | build
ifeq ($(SIM),iverilog)
	iverilog -g2012 -o build/sim -f flist/rtl.f -f flist/tb.f
	vvp build/sim | tee build/sim.log
else ifeq ($(SIM),vcs)
	vcs -full64 -sverilog -timescale=1ns/1ps -f flist/rtl.f -f flist/tb.f -o build/simv
	./build/simv | tee build/sim.log
endif
	@grep -q "TB_RESULT: PASS" build/sim.log

synth: | build
	yosys -q -l build/synth.log -s synth/yosys.ys
	@grep -E " cells$$| DFF" build/synth_stat.txt || true

# Synopsys Design Compiler (template, not yet run: no licence here)
synth_dc: | build
	dc_shell -f synth/dc_synth.tcl | tee build/dc.log

build:
	mkdir -p build

clean:
	rm -rf build
