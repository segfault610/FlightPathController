// PID with derivative on measurement (uses the bias-corrected rate) and a
// clamped integrator (anti-windup). Output u is signed 12 bit, saturated to +-2047.
// shortcut: gains are static parameters; add a register bank when a CPU is attached.
module fpc_pid #(
  parameter integer KP    = 256,     // u = err_counts when KP = 256 (gain shift 8)
  parameter integer KI    = 1,
  parameter integer KD    = 160,
  parameter integer I_LIM = 131072   // integrator clamp, +-2^17
)(
  input  wire               clk,
  input  wire               rst_n,
  input  wire               en,         // 0 = hold output at zero, clear integrator
  input  wire               in_valid,
  input  wire signed [15:0] setpoint,   // Q3.13 rad
  input  wire signed [15:0] angle,      // Q3.13 rad
  input  wire signed [15:0] rate,       // Q5.11 rad/s
  output reg                out_valid,
  output reg  signed [11:0] u
);
  localparam signed [19:0] ILIM = I_LIM;
  reg  signed [19:0] integ;
  wire signed [16:0] err      = {setpoint[15], setpoint} - {angle[15], angle};
  wire signed [19:0] isum     = integ + {{3{err[16]}}, err};
  wire signed [19:0] integ_nx = (isum >  ILIM) ?  ILIM :
                                (isum < -ILIM) ? -ILIM : isum;
  wire signed [39:0] sum   = KP * err + KI * integ_nx - KD * rate;
  wire signed [39:0] scaled = sum >>> 8;
  wire signed [11:0] u_nx  = (scaled >  40'sd2047) ?  12'sd2047 :
                             (scaled < -40'sd2047) ? -12'sd2047 : scaled[11:0];

  always @(posedge clk or negedge rst_n)
    if (!rst_n) begin
      integ <= 20'sd0; u <= 12'sd0; out_valid <= 1'b0;
    end else begin
      out_valid <= in_valid;
      if (!en) begin
        integ <= 20'sd0; u <= 12'sd0;
      end else if (in_valid) begin
        integ <= integ_nx; u <= u_nx;
      end
    end
endmodule
