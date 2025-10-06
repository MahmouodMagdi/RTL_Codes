// SPDX-License-Identifier: MIT
`timescale 1ns/1ps

module cordic_rot_wrap #(
  parameter int XYW         = 24,
  parameter int ZW          = 32,
  parameter int XY_FRAC     = 16,
  parameter int Z_FRAC      = 28,
  parameter int ITER_MAX    = 24,
  parameter int GROUP_SIZE  = 3,
  parameter bit PRE_SCALE   = 1'b1
) (
  input  logic                      clk,
  input  logic                      rst_n,
  input  logic                      in_valid,
  input  logic signed [XYW-1:0]     x_in,
  input  logic signed [XYW-1:0]     y_in,
  input  logic signed [ZW-1:0]      z_in, // angle in Q(Z_FRAC)
  output logic                      out_valid,
  output logic signed [XYW-1:0]     x_out,
  output logic signed [XYW-1:0]     y_out
);
  // Core latency
  localparam int NUM_STAGES = (ITER_MAX + GROUP_SIZE - 1) / GROUP_SIZE;

  // Scale constants from Q30 into Q(Z_FRAC)
  localparam int SHIFT_RIGHT = (30 > Z_FRAC) ? (30 - Z_FRAC) : 0;
  localparam int SHIFT_LEFT  = (Z_FRAC > 30) ? (Z_FRAC - 30) : 0;
  function automatic logic signed [ZW-1:0] from_q30 (input int unsigned v30);
    logic signed [ZW-1:0] tmp;
    if (SHIFT_RIGHT != 0)       tmp = $signed(v30) >>> SHIFT_RIGHT;
    else if (SHIFT_LEFT != 0)   tmp = $signed(v30) <<< SHIFT_LEFT;
    else                        tmp = $signed(v30);
    return tmp;
  endfunction

  // pi/2 in Q30 fits in 32-bit signed
  localparam logic signed [ZW-1:0] PI_OVER_2_Q = from_q30(32'd1686629713);
  localparam logic signed [ZW-1:0] PI_Q       = (PI_OVER_2_Q <<< 1);

  // Map z into [-pi/2, pi/2] by folding ±pi as needed; count flips
  logic signed [ZW-1:0] z_fold0, z_fold1, z_fold2, z_mapped;
  logic negate0, negate1, negate2, negate;
  always_comb begin
    // start
    z_fold0  = z_in;
    negate0  = 1'b0;

    // First positive fold
    if (z_fold0 >= PI_OVER_2_Q) begin
      z_fold1 = z_fold0 - PI_Q;
      negate1 = ~negate0;
    end else begin
      z_fold1 = z_fold0;
      negate1 = negate0;
    end

    // Second positive fold (handle 3*pi/2)
    if (z_fold1 >= PI_OVER_2_Q) begin
      z_fold2 = z_fold1 - PI_Q;
      negate2 = ~negate1;
    end else begin
      z_fold2 = z_fold1;
      negate2 = negate1;
    end

    // Negative side fold 1
    if (z_fold2 <= -PI_OVER_2_Q) begin
      z_mapped = z_fold2 + PI_Q;
      negate   = ~negate2;
    end else begin
      z_mapped = z_fold2;
      negate   = negate2;
    end
  end

  // Pipeline the negate flag alongside valid
  logic v_pipe   [0:NUM_STAGES];
  logic n_pipe   [0:NUM_STAGES];
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      v_pipe[0] <= 1'b0;
      n_pipe[0] <= 1'b0;
    end else begin
      v_pipe[0] <= in_valid;
      if (in_valid) n_pipe[0] <= negate;
    end
  end
  genvar i;
  generate
    for (i = 0; i < NUM_STAGES; i++) begin : g_delay
      always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
          v_pipe[i+1] <= 1'b0;
          n_pipe[i+1] <= 1'b0;
        end else begin
          v_pipe[i+1] <= v_pipe[i];
          n_pipe[i+1] <= n_pipe[i];
        end
      end
    end
  endgenerate

  // Core instance
  logic                      core_valid;
  logic signed [XYW-1:0]     core_x, core_y;
  logic signed [ZW-1:0]      core_z;
  cordic_radix8_core #(
    .XYW(XYW), .ZW(ZW), .XY_FRAC(XY_FRAC), .Z_FRAC(Z_FRAC),
    .ITER_MAX(ITER_MAX), .GROUP_SIZE(GROUP_SIZE), .PRE_SCALE(PRE_SCALE)
  ) core (
    .clk, .rst_n,
    .in_valid,
    .x_in, .y_in,
    .z_in(z_mapped),
    .out_valid(core_valid),
    .x_out(core_x), .y_out(core_y), .z_out(core_z)
  );

  // Apply final sign
  assign out_valid = core_valid;
  assign x_out = n_pipe[NUM_STAGES] ? -core_x : core_x;
  assign y_out = n_pipe[NUM_STAGES] ? -core_y : core_y;

endmodule
