// One-axis attitude estimator: fixed-gain Kalman (alpha-beta) filter that fuses
// gyro rate with an angle measurement and estimates the gyro bias.
// shortcut: steady-state gains (power-of-two shifts), not a full covariance EKF;
//           upgrade when the noise model is characterised on real sensor data.
// shortcut: no saturation on the 32-bit state; the safety monitor trips well
//           before |angle| nears the +-4 rad range of Q3.29.
// Formats: angle Q3.13 rad, rate Q5.11 rad/s, internal angle/bias Q3.29.
// Sample rate is fixed at 1024 Hz, so dt = 2^-10 is a shift.
module fpc_attitude_est #(
  parameter integer KA_SHIFT = 4,   // angle gain 2^-4
  parameter integer KB_SHIFT = 9    // bias gain  2^-9 (about alpha^2/2, well damped)
)(
  input  wire               clk,
  input  wire               rst_n,
  input  wire               in_valid,
  input  wire signed [15:0] gyro,       // Q5.11 rad/s
  input  wire signed [15:0] meas,       // Q3.13 rad
  output reg                out_valid,
  output wire signed [15:0] angle,      // Q3.13 rad
  output wire signed [15:0] rate        // Q5.11 rad/s, bias removed
);
  reg signed [31:0] ang_q, bias_q;      // Q3.29 (bias is angle per sample)
  reg signed [15:0] gyro_r;

  wire signed [32:0] gyro_q = {{17{gyro[15]}}, gyro} <<< 8;   // rad/s*2^-10 in Q3.29
  wire signed [32:0] meas_q = {{17{meas[15]}}, meas} <<< 16;  // Q3.13 -> Q3.29
  wire signed [32:0] pred   = {ang_q[31], ang_q} + gyro_q - {bias_q[31], bias_q};
  wire signed [32:0] res    = meas_q - pred;
  // separate signed wires: a part-select in the same expression would make the shift logical
  wire signed [32:0] da     = res >>> KA_SHIFT;
  wire signed [32:0] db     = res >>> KB_SHIFT;

  always @(posedge clk or negedge rst_n)
    if (!rst_n) begin
      ang_q <= 32'sd0; bias_q <= 32'sd0; gyro_r <= 16'sd0; out_valid <= 1'b0;
    end else begin
      out_valid <= in_valid;
      if (in_valid) begin
        gyro_r <= gyro;
        ang_q  <= pred[31:0] + da[31:0];
        bias_q <= bias_q     - db[31:0];
      end
    end

  assign angle = ang_q[31:16];
  assign rate  = gyro_r - (bias_q >>> 8);   // bias back in gyro units (Q5.11)
endmodule
