# Synopsys Design Compiler template. NOT RUN YET (no licence on this machine).
# Fill in the library variables for your PDK before use.
set TOP fpc_top
set_app_var target_library "<std_cell_db>"
set_app_var link_library   "* $target_library"
set files [list rtl/fpc_rst_sync.v rtl/fpc_attitude_est.v rtl/fpc_pid.v \
                rtl/fpc_pwm.v rtl/fpc_safety.v rtl/fpc_top.v]
analyze -format verilog $files
elaborate $TOP
current_design $TOP
link
source constraints/fpc_top.sdc
compile_ultra
report_area   > build/dc_area.rpt
report_timing > build/dc_timing.rpt
report_power  > build/dc_power.rpt
write -format verilog -hierarchy -output build/${TOP}_netlist.v
write_sdc build/${TOP}.sdc
exit
