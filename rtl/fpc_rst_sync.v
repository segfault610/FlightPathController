// Reset synchroniser: asynchronous assert, synchronous release.
// The external rst_n will later come from an analog power-on-reset (POR) cell.
module fpc_rst_sync (
  input  wire clk,
  input  wire rst_n_in,
  output wire rst_n_out
);
  reg [1:0] sr;
  always @(posedge clk or negedge rst_n_in)
    if (!rst_n_in) sr <= 2'b00;
    else           sr <= {sr[0], 1'b1};
  assign rst_n_out = sr[1];
endmodule
