// Signed-magnitude PWM for an H-bridge. dir = 1 for negative u.
// Duty is latched at the period boundary so it never glitches mid-period.
// Max duty is 2047/2048 (a counter compare limit, fine for a bootstrap gate driver).
module fpc_pwm (
  input  wire               clk,
  input  wire               rst_n,
  input  wire               en,
  input  wire signed [11:0] u,
  output reg                pwm,
  output reg                dir
);
  reg  [10:0] cnt, duty;
  wire [11:0] mag = u[11] ? (~u + 12'd1) : u;

  always @(posedge clk or negedge rst_n)
    if (!rst_n) begin
      cnt <= 11'd0; duty <= 11'd0; dir <= 1'b0; pwm <= 1'b0;
    end else begin
      cnt <= cnt + 11'd1;
      if (&cnt) begin duty <= mag[10:0]; dir <= u[11]; end
      pwm <= en && (cnt < duty);
    end
endmodule
