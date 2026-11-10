// Flight path controller, digital core (one axis).
//
//  [future analog / mixed-signal]          [this digital core]            [future analog]
//   IMU / ADC front end  --sample_valid-->  estimator -> PID -> PWM  --> gate driver / H-bridge
//                           gyro, meas_angle                  pwm, dir
//                                     safety monitor (watchdog + limits)
//
// The ports marked BOUNDARY are the contract for the analog / mixed-signal blocks.
module fpc_top #(
  parameter integer TIMEOUT = 100000,
  parameter integer TW      = 20
)(
  input  wire               clk,           // BOUNDARY: from future PLL / oscillator
  input  wire               rst_n,         // BOUNDARY: from future power-on-reset cell
  // BOUNDARY: sensor side (digital words from a future ADC / SPI IMU interface)
  input  wire               sample_valid,  // 1-clk pulse, 1024 Hz
  input  wire signed [15:0] gyro,          // Q5.11 rad/s
  input  wire signed [15:0] meas_angle,    // Q3.13 rad (accelerometer-derived)
  // command
  input  wire signed [15:0] setpoint,      // Q3.13 rad
  input  wire               fault_clear,
  // BOUNDARY: actuator side (to a future gate driver)
  output wire               pwm,
  output wire               dir,
  // status
  output wire               fault,
  output wire [1:0]         fault_cause,
  output wire signed [15:0] angle_est,
  output wire signed [11:0] ctrl_out
);
  wire rst_n_s;
  fpc_rst_sync u_rst (.clk(clk), .rst_n_in(rst_n), .rst_n_out(rst_n_s));

  wire signed [15:0] rate;
  wire est_valid, pid_valid, enable;

  fpc_attitude_est u_est (
    .clk(clk), .rst_n(rst_n_s), .in_valid(sample_valid),
    .gyro(gyro), .meas(meas_angle),
    .out_valid(est_valid), .angle(angle_est), .rate(rate));

  fpc_pid u_pid (
    .clk(clk), .rst_n(rst_n_s), .en(enable), .in_valid(est_valid),
    .setpoint(setpoint), .angle(angle_est), .rate(rate),
    .out_valid(pid_valid), .u(ctrl_out));

  fpc_pwm u_pwm (
    .clk(clk), .rst_n(rst_n_s), .en(enable), .u(ctrl_out), .pwm(pwm), .dir(dir));

  fpc_safety #(.TIMEOUT(TIMEOUT), .TW(TW)) u_safe (
    .clk(clk), .rst_n(rst_n_s), .sample_valid(sample_valid), .angle(angle_est),
    .fault_clear(fault_clear), .enable(enable), .fault(fault), .cause(fault_cause));
endmodule
