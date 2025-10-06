// SPDX-License-Identifier: MIT
// Pipelined radix-8 (3-microstep grouped) CORDIC rotation core
// - SystemVerilog, synthesizable
// - Parameterized widths, iterations, and grouping
// - Streaming valid pipeline interface, 1 sample/cycle throughput after fill
// - Rotation mode (computes cos/sin when x_in=1.0, y_in=0 and PRE_SCALE=1)

`timescale 1ns/1ps

module cordic_radix8_core #(
  parameter int XYW         = 24,   // x/y total bits (signed)
  parameter int ZW          = 32,   // z total bits (signed)
  parameter int XY_FRAC     = 16,   // x/y fractional bits
  parameter int Z_FRAC      = 30,   // z fractional bits (match constants below)
  parameter int ITER_MAX    = 24,   // number of micro-rotations
  parameter int GROUP_SIZE  = 3,    // micro-rotations per stage (3 => "radix-8" grouping)
  parameter bit PRE_SCALE   = 1'b1  // multiply inputs by overall K_inv for unity gain
) (
  input  logic                          clk,
  input  logic                          rst_n,
  input  logic                          in_valid,
  input  logic signed [XYW-1:0]         x_in,
  input  logic signed [XYW-1:0]         y_in,
  input  logic signed [ZW-1:0]          z_in,
  output logic                          out_valid,
  output logic signed [XYW-1:0]         x_out,
  output logic signed [XYW-1:0]         y_out,
  output logic signed [ZW-1:0]          z_out
);
  // Derived parameters
  localparam int NUM_STAGES = (ITER_MAX + GROUP_SIZE - 1) / GROUP_SIZE;

  // Types for convenience (placed early for function return types)
  typedef logic signed [XYW-1:0] sxy_t;
  typedef logic signed [ZW-1:0]  sz_t;

  // Fixed tables via constant functions (Icarus-friendly)
  // atan_q: QZ_FRAC arctan(2^-k) for k in [0, ITER_MAX-1]; Z_FRAC=30
  function automatic sz_t atan_q (input int idx);
    case (idx)
      0:  atan_q = sz_t'(32'd843314857);
      1:  atan_q = sz_t'(32'd497837829);
      2:  atan_q = sz_t'(32'd263043837);
      3:  atan_q = sz_t'(32'd133525159);
      4:  atan_q = sz_t'(32'd67021687);
      5:  atan_q = sz_t'(32'd33543516);
      6:  atan_q = sz_t'(32'd16775851);
      7:  atan_q = sz_t'(32'd8388437);
      8:  atan_q = sz_t'(32'd4194283);
      9:  atan_q = sz_t'(32'd2097149);
      10: atan_q = sz_t'(32'd1048576);
      11: atan_q = sz_t'(32'd524288);
      12: atan_q = sz_t'(32'd262144);
      13: atan_q = sz_t'(32'd131072);
      14: atan_q = sz_t'(32'd65536);
      15: atan_q = sz_t'(32'd32768);
      16: atan_q = sz_t'(32'd16384);
      17: atan_q = sz_t'(32'd8192);
      18: atan_q = sz_t'(32'd4096);
      19: atan_q = sz_t'(32'd2048);
      20: atan_q = sz_t'(32'd1024);
      21: atan_q = sz_t'(32'd512);
      22: atan_q = sz_t'(32'd256);
      23: atan_q = sz_t'(32'd128);
      default: atan_q = '0;
    endcase
  endfunction

  // K_INV_TABLE: QXY_FRAC product_{i=0..n-1} 1/sqrt(1 + 2^{-2i})
  // Sized to XY_FRAC+1 bits (e.g., 17 for Q16) to accommodate 65536.
  // Index n is cumulative up to n-1. We typically use index ITER_MAX.
  // Gain inverse by constant function, QXY_FRAC
  function automatic logic [XY_FRAC:0] k_inv_q (input int n);
    case (n)
      0:  k_inv_q = 17'd65536;
      1:  k_inv_q = 17'd46341;
      2:  k_inv_q = 17'd41449;
      3:  k_inv_q = 17'd40211;
      4:  k_inv_q = 17'd39901;
      5:  k_inv_q = 17'd39823;
      6:  k_inv_q = 17'd39803;
      7:  k_inv_q = 17'd39799;
      8:  k_inv_q = 17'd39797;
      9:  k_inv_q = 17'd39797;
      10: k_inv_q = 17'd39797;
      11: k_inv_q = 17'd39797;
      12: k_inv_q = 17'd39797;
      13: k_inv_q = 17'd39797;
      14: k_inv_q = 17'd39797;
      15: k_inv_q = 17'd39797;
      16: k_inv_q = 17'd39797;
      17: k_inv_q = 17'd39797;
      18: k_inv_q = 17'd39797;
      19: k_inv_q = 17'd39797;
      20: k_inv_q = 17'd39797;
      21: k_inv_q = 17'd39797;
      22: k_inv_q = 17'd39797;
      23: k_inv_q = 17'd39797;
      24: k_inv_q = 17'd39797;
      default: k_inv_q = 17'd39797;
    endcase
  endfunction

  // Overall gain inverse as QXY_FRAC
  localparam logic [XY_FRAC:0] K_INV_Q = k_inv_q(ITER_MAX);

  // Types were declared above

  // Input pre-scaling by constant K_INV_Q (QXY_FRAC)
  localparam int SCALEW = XYW + (XY_FRAC + 1);
  logic signed [SCALEW-1:0] x_scaled_wide, y_scaled_wide;
  sxy_t x0_pre, y0_pre;

  generate
    if (PRE_SCALE) begin : g_prescale
      always_comb begin
        x_scaled_wide = $signed(x_in) * $signed(K_INV_Q);
        y_scaled_wide = $signed(y_in) * $signed(K_INV_Q);
      end
      // Truncate toward zero
      always_comb begin
        x0_pre = sxy_t'(x_scaled_wide >>> XY_FRAC);
        y0_pre = sxy_t'(y_scaled_wide >>> XY_FRAC);
      end
    end else begin : g_no_prescale
      always_comb begin
        x_scaled_wide = '0;
        y_scaled_wide = '0;
      end
      always_comb begin
        x0_pre = x_in;
        y0_pre = y_in;
      end
    end
  endgenerate

  // Pipeline registers
  sxy_t x_pipe   [0:NUM_STAGES];
  sxy_t y_pipe   [0:NUM_STAGES];
  sz_t  z_pipe   [0:NUM_STAGES];
  logic v_pipe   [0:NUM_STAGES];

  // Stage 0 input register
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      x_pipe[0] <= '0;
      y_pipe[0] <= '0;
      z_pipe[0] <= '0;
      v_pipe[0] <= 1'b0;
    end else begin
      x_pipe[0] <= x0_pre;
      y_pipe[0] <= y0_pre;
      z_pipe[0] <= z_in;
      v_pipe[0] <= in_valid;
    end
  end

  // Stages 1..NUM_STAGES: each applies up to GROUP_SIZE micro-rotations combinationally then registers
  genvar s;
  generate
    for (s = 0; s < NUM_STAGES; s++) begin : g_stage
      // Combinational chain for this stage
      sxy_t x_j0, y_j0; sz_t z_j0;
      sxy_t x_j1, y_j1; sz_t z_j1;
      sxy_t x_j2, y_j2; sz_t z_j2;
      sxy_t x_next, y_next; sz_t z_next;

      localparam int k0 = (s*GROUP_SIZE + 0);
      localparam int k1 = (s*GROUP_SIZE + 1);
      localparam int k2 = (s*GROUP_SIZE + 2);

      // j=0 (if within ITER_MAX)
      always_comb begin
        x_j0 = x_pipe[s];
        y_j0 = y_pipe[s];
        z_j0 = z_pipe[s];
        if (k0 < ITER_MAX) begin
          logic signed [XYW-1:0] x_tmp, y_tmp;
          logic signed [ZW-1:0]  z_tmp;
          logic dir; // 1 => z>=0
          dir = (z_j0 >= 0);
          // x' = x - d * (y >>> k)
          if (dir) x_tmp = x_j0 - (y_j0 >>> k0);
          else     x_tmp = x_j0 + (y_j0 >>> k0);
          // y' = y + d * (x >>> k)
          if (dir) y_tmp = y_j0 + (x_j0 >>> k0);
          else     y_tmp = y_j0 - (x_j0 >>> k0);
          // z' = z - d * atan(2^-k)
          if (dir) z_tmp = z_j0 - atan_q(k0);
          else     z_tmp = z_j0 + atan_q(k0);
          x_j1 = x_tmp; y_j1 = y_tmp; z_j1 = z_tmp;
        end else begin
          x_j1 = x_j0; y_j1 = y_j0; z_j1 = z_j0;
        end
      end

      // j=1
      always_comb begin
        if (k1 < ITER_MAX) begin
          logic signed [XYW-1:0] x_tmp, y_tmp;
          logic signed [ZW-1:0]  z_tmp;
          logic dir;
          dir = (z_j1 >= 0);
          if (dir) x_tmp = x_j1 - (y_j1 >>> k1);
          else     x_tmp = x_j1 + (y_j1 >>> k1);
          if (dir) y_tmp = y_j1 + (x_j1 >>> k1);
          else     y_tmp = y_j1 - (x_j1 >>> k1);
          if (dir) z_tmp = z_j1 - atan_q(k1);
          else     z_tmp = z_j1 + atan_q(k1);
          x_j2 = x_tmp; y_j2 = y_tmp; z_j2 = z_tmp;
        end else begin
          x_j2 = x_j1; y_j2 = y_j1; z_j2 = z_j1;
        end
      end

      // j=2
      always_comb begin
        if (k2 < ITER_MAX) begin
          logic signed [XYW-1:0] x_tmp, y_tmp;
          logic signed [ZW-1:0]  z_tmp;
          logic dir;
          dir = (z_j2 >= 0);
          if (dir) x_tmp = x_j2 - (y_j2 >>> k2);
          else     x_tmp = x_j2 + (y_j2 >>> k2);
          if (dir) y_tmp = y_j2 + (x_j2 >>> k2);
          else     y_tmp = y_j2 - (x_j2 >>> k2);
          if (dir) z_tmp = z_j2 - atan_q(k2);
          else     z_tmp = z_j2 + atan_q(k2);
          x_next = x_tmp; y_next = y_tmp; z_next = z_tmp;
        end else begin
          x_next = x_j2; y_next = y_j2; z_next = z_j2;
        end
      end

      // Register to next stage
      always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
          x_pipe[s+1] <= '0;
          y_pipe[s+1] <= '0;
          z_pipe[s+1] <= '0;
          v_pipe[s+1] <= 1'b0;
        end else begin
          x_pipe[s+1] <= x_next;
          y_pipe[s+1] <= y_next;
          z_pipe[s+1] <= z_next;
          v_pipe[s+1] <= v_pipe[s];
        end
      end
    end
  endgenerate

  // Outputs
  assign x_out    = x_pipe[NUM_STAGES];
  assign y_out    = y_pipe[NUM_STAGES];
  assign z_out    = z_pipe[NUM_STAGES];
  assign out_valid = v_pipe[NUM_STAGES];

  // Synthesis-time assert: GROUP_SIZE currently supported up to 3
  initial begin
    if (GROUP_SIZE > 3) begin
      $error("GROUP_SIZE > 3 not supported in this implementation");
    end
    if (Z_FRAC != 30) begin
      $warning("Z_FRAC != 30: ATAN_TABLE was generated for Q30; update constants accordingly");
    end
  end

endmodule
