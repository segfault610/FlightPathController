# Standard SDC: usable by Design Compiler, Fusion Compiler, PrimeTime and OpenSTA.
# Placeholder numbers, to be replaced once the target clock and I/O timing are known.
create_clock -name clk -period 20.0 [get_ports clk]          ;# 50 MHz
set_clock_uncertainty 0.5 [get_clocks clk]
set_clock_transition  0.2 [get_clocks clk]

# rst_n is asynchronous; it is re-timed inside fpc_rst_sync
set_false_path -from [get_ports rst_n]

# digital boundary to the (future) sensor front end and gate driver
set sens_in [get_ports {sample_valid gyro[*] meas_angle[*]}]
set_input_delay  -clock clk 6.0 $sens_in
set_input_delay  -clock clk 6.0 [get_ports {setpoint[*] fault_clear}]
set_output_delay -clock clk 6.0 [get_ports {pwm dir fault fault_cause[*] angle_est[*] ctrl_out[*]}]
