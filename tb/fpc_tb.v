// Closed-loop self-checking testbench. The plant (a damped rotating body with a
// noisy, biased gyro) is a behavioural model; it is the stand-in for the analog
// side (sensor + motor) until real front-end models exist.
`timescale 1ns/1ps
module fpc_tb;
  localparam integer N = 64;            // clk cycles per 1024 Hz sample (sim only)
  localparam integer TIMEOUT = 5*N;
  real DT, T_GAIN, DAMP, GYRO_BIAS;
  initial begin DT = 1.0/1024.0; T_GAIN = 20.0; DAMP = 0.5; GYRO_BIAS = 0.05; end

  reg clk = 0, rst_n = 0, sample_valid = 0, fault_clear = 0;
  reg signed [15:0] gyro = 0, meas_angle = 0, setpoint = 0;
  wire pwm, dir, fault;
  wire [1:0] fault_cause;
  wire signed [15:0] angle_est;
  wire signed [11:0] ctrl_out;

  fpc_top #(.TIMEOUT(TIMEOUT), .TW(12)) dut (
    .clk(clk), .rst_n(rst_n), .sample_valid(sample_valid), .gyro(gyro),
    .meas_angle(meas_angle), .setpoint(setpoint), .fault_clear(fault_clear),
    .pwm(pwm), .dir(dir), .fault(fault), .fault_cause(fault_cause),
    .angle_est(angle_est), .ctrl_out(ctrl_out));

  always #5 clk = ~clk;

  real theta, omega, dtq, meas_offset;
  integer seed, errors, i, pwm_hi;

  function integer clampi(input integer v, input integer lo, input integer hi);
    clampi = (v < lo) ? lo : (v > hi) ? hi : v;
  endfunction

  // one 1024 Hz sample: feed sensors, wait, step the plant with the DUT's output
  task sample;
    real noise, alpha;
    integer k;
    begin
      noise = (($random(seed) % 100) / 100.0) * 0.005;
      gyro       = clampi($rtoi((omega + GYRO_BIAS) * 2048.0), -32768, 32767);
      meas_angle = clampi($rtoi((theta + meas_offset + noise) * 8192.0), -32768, 32767);
      sample_valid = 1; @(posedge clk); sample_valid = 0;
      for (k = 1; k < N; k = k + 1) begin
        @(posedge clk);
        if (pwm) pwm_hi = pwm_hi + 1;
      end
      alpha = T_GAIN * ($itor(ctrl_out) / 2047.0) + dtq - DAMP * omega;
      omega = omega + alpha * DT;
      theta = theta + omega * DT;
    end
  endtask

  task run(input integer n);
    integer j;
    begin for (j = 0; j < n; j = j + 1) sample; end
  endtask

  task check(input cond, input [8*48-1:0] name);
    begin
      if (!cond) begin errors = errors + 1; $display("FAIL: %0s", name); end
      else $display("ok:   %0s", name);
    end
  endtask

  initial begin
    $dumpfile("build/fpc.vcd"); $dumpvars(0, fpc_tb);
    seed = 1; errors = 0; pwm_hi = 0; dtq = 0.0; meas_offset = 0.0;
    theta = 0.3; omega = 0.0;
    repeat (4) @(posedge clk); rst_n = 1; repeat (4) @(posedge clk);

    // T1: recover from a 0.3 rad offset, with gyro bias and sensor noise
    run(3000);
    check(theta < 0.02 && theta > -0.02, "T1 settles to setpoint");
    check((theta - $itor(angle_est)/8192.0) < 0.02 &&
          (theta - $itor(angle_est)/8192.0) > -0.02, "T1 estimator tracks true angle");
    check(pwm_hi > 0 && !fault, "T1 pwm active, no fault");

    // T2: constant disturbance torque; the integrator must remove the offset
    dtq = -3.0;
    run(3000);
    check(theta < 0.015 && theta > -0.015, "T2 integrator rejects disturbance");
    dtq = 0.0; run(1000);

    // T3: sensor dies -> watchdog trips, outputs go dead and stay dead
    repeat (TIMEOUT + 20) @(posedge clk);
    check(fault && fault_cause[0], "T3 timeout fault latched");
    pwm_hi = 0; repeat (5000) @(posedge clk);
    check(pwm_hi == 0 && ctrl_out == 0, "T3 outputs forced off");
    // sensor returns; fault_clear releases it
    run(10); @(posedge clk); fault_clear = 1; @(posedge clk); fault_clear = 0; run(2);
    check(!fault, "T3 fault_clear releases when cause is gone");

    // T4: bogus large angle measurement -> over-angle trip
    meas_offset = 0.9; run(80);
    check(fault && fault_cause[1], "T4 over-angle fault latched");
    meas_offset = 0.0; run(300);
    check(fault, "T4 fault stays latched without clear");
    fault_clear = 1; @(posedge clk); fault_clear = 0; run(2);
    check(!fault, "T4 clear after cause removed");

    if (errors == 0) $display("TB_RESULT: PASS"); else $display("TB_RESULT: FAIL (%0d)", errors);
    $finish;
  end
endmodule
