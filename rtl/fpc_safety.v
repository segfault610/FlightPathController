// Safety monitor (hardware analogue of the E51 watchdog in the PolarFire design).
// Latches a fault on sensor timeout or over-angle; fault_clear (pulse) releases it
// only if the cause is gone. enable = 0 while faulted.
module fpc_safety #(
  parameter integer TIMEOUT   = 100000,   // clk cycles without a sample
  parameter integer TW        = 20,       // watchdog counter width, must hold TIMEOUT
  parameter integer ANGLE_LIM = 6144      // Q3.13, 0.75 rad
)(
  input  wire               clk,
  input  wire               rst_n,
  input  wire               sample_valid,
  input  wire signed [15:0] angle,
  input  wire               fault_clear,
  output wire               enable,
  output wire               fault,
  output wire [1:0]         cause         // bit0 timeout, bit1 over-angle
);
  reg [TW-1:0] wd;
  reg          armed, fault_r;
  reg [1:0]    cause_r;
  wire timeout = armed && (wd >= TIMEOUT);
  wire over    = (angle > ANGLE_LIM) || (angle < -ANGLE_LIM);

  always @(posedge clk or negedge rst_n)
    if (!rst_n) begin
      wd <= {TW{1'b0}}; armed <= 1'b0; fault_r <= 1'b0; cause_r <= 2'b00;
    end else begin
      if (sample_valid) begin wd <= {TW{1'b0}}; armed <= 1'b1; end
      else if (wd < TIMEOUT) wd <= wd + 1'b1;   // stops at TIMEOUT
      if (timeout || over) begin
        fault_r <= 1'b1;
        cause_r <= cause_r | {over, timeout};
      end else if (fault_clear) begin
        fault_r <= 1'b0; cause_r <= 2'b00;
      end
    end

  assign fault  = fault_r;
  assign enable = !fault_r;
  assign cause  = cause_r;
endmodule
