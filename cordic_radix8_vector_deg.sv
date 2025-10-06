// Radix-8 (3 micro-iterations per pipeline stage) CORDIC - Vectoring mode
// Outputs angle in degrees (fixed-point Q(ANG_WIDTH-ANG_FRAC).ANG_FRAC)
// Synthesizable, pipelined, streaming (ready/valid always-ready input)

`timescale 1ns/1ps
`default_nettype none

module cordic_radix8_vector_deg #(
  parameter int XY_WIDTH   = 18,   // signed input width for x,y
  parameter int GUARD_BITS = 3,    // extra integer guard bits for internal growth
  parameter int ANG_WIDTH  = 16,   // signed angle width
  parameter int ANG_FRAC   = 7,    // fractional bits in angle (degrees * 2^ANG_FRAC)
  parameter int ITER       = XY_WIDTH  // number of base-2 micro-iterations
) (
  input  logic                      clk,
  input  logic                      rst_n,

  input  logic                      in_valid,
  input  logic signed [XY_WIDTH-1:0] x_in,
  input  logic signed [XY_WIDTH-1:0] y_in,

  output logic                      out_valid,
  output logic signed [ANG_WIDTH-1:0] angle_deg
);
  // ---------------------------------------------------------------------------
  // Parameters and local types
  // ---------------------------------------------------------------------------
  localparam int STAGES = (ITER + 2) / 3; // ceil(ITER/3)
  localparam int IW     = XY_WIDTH + GUARD_BITS; // internal width for x/y pipeline

  // Sanity: ensure ITER <= XY_WIDTH to avoid overshifts beyond width
  initial begin
    if (ITER > XY_WIDTH) begin
      $error("ITER (%0d) must be <= XY_WIDTH (%0d) for safe shifting", ITER, XY_WIDTH);
    end
  end

  // Angle lookup function for atan(2^-k) in degrees scaled by 2^ANG_FRAC
  // Generated for ANG_FRAC=7 up to k=17.
  function automatic logic signed [ANG_WIDTH-1:0] atan_table(input int k);
    case (k)
      0:  atan_table = 16'sd5760;
      1:  atan_table = 16'sd3400;
      2:  atan_table = 16'sd1797;
      3:  atan_table = 16'sd912;
      4:  atan_table = 16'sd458;
      5:  atan_table = 16'sd229;
      6:  atan_table = 16'sd115;
      7:  atan_table = 16'sd57;
      8:  atan_table = 16'sd29;
      9:  atan_table = 16'sd14;
      10: atan_table = 16'sd7;
      11: atan_table = 16'sd4;
      12: atan_table = 16'sd2;
      13: atan_table = 16'sd1;
      default: atan_table = 16'sd0;
    endcase
  endfunction

  localparam signed [ANG_WIDTH-1:0] DEG180 = signed'(180 << ANG_FRAC);

  // ---------------------------------------------------------------------------
  // Pipeline state
  // ---------------------------------------------------------------------------
  logic signed [IW-1:0] x_pipe   [0:STAGES];
  logic signed [IW-1:0] y_pipe   [0:STAGES];
  logic signed [ANG_WIDTH-1:0] z_pipe [0:STAGES];
  logic                    v_pipe  [0:STAGES];

  // Stage 0: pre-normalize to handle full arctan2 range
  // If x < 0, flip vector and add/sub 180 deg to z0.
  wire x_neg = x_in[XY_WIDTH-1];
  wire y_neg = y_in[XY_WIDTH-1];

  wire signed [IW-1:0] x0_w = x_neg ? -{{GUARD_BITS{x_in[XY_WIDTH-1]}}, x_in} : {{GUARD_BITS{x_in[XY_WIDTH-1]}}, x_in};
  wire signed [IW-1:0] y0_w = x_neg ? -{{GUARD_BITS{y_in[XY_WIDTH-1]}}, y_in} : {{GUARD_BITS{y_in[XY_WIDTH-1]}}, y_in};

  wire signed [ANG_WIDTH-1:0] z0_w = x_neg ? (y_neg ? -DEG180 : DEG180) : '0;

  // Register stage 0
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      x_pipe[0] <= '0;
      y_pipe[0] <= '0;
      z_pipe[0] <= '0;
      v_pipe[0] <= 1'b0;
    end else begin
      if (in_valid) begin
        x_pipe[0] <= x0_w;
        y_pipe[0] <= y0_w;
        z_pipe[0] <= z0_w;
      end
      v_pipe[0] <= in_valid;
    end
  end

  // ---------------------------------------------------------------------------
  // Generate stages: each stage performs up to 3 dependent micro-iterations
  // ---------------------------------------------------------------------------
  genvar s;
  generate
    for (s = 0; s < STAGES; s++) begin : gen_stage
      localparam int K0 = 3*s + 0;
      localparam int K1 = 3*s + 1;
      localparam int K2 = 3*s + 2;
      localparam bit DO0 = (K0 < ITER);
      localparam bit DO1 = (K1 < ITER);
      localparam bit DO2 = (K2 < ITER);

      // Combinational micro-iterations within the stage
      // Step 0
      wire signed [IW-1:0] xt0 = x_pipe[s];
      wire signed [IW-1:0] yt0 = y_pipe[s];
      wire signed [ANG_WIDTH-1:0] zt0 = z_pipe[s];

      wire d0_pos = ~yt0[IW-1];
      wire signed [IW-1:0] xt1 = DO0 ? (d0_pos ? (xt0 + (yt0 >>> K0)) : (xt0 - (yt0 >>> K0))) : xt0;
      wire signed [IW-1:0] yt1 = DO0 ? (d0_pos ? (yt0 - (xt0 >>> K0)) : (yt0 + (xt0 >>> K0))) : yt0;
      wire signed [ANG_WIDTH-1:0] zt1 = DO0 ? (d0_pos ? (zt0 + atan_table(K0)) : (zt0 - atan_table(K0))) : zt0;

      // Step 1
      wire d1_pos = ~yt1[IW-1];
      wire signed [IW-1:0] xt2 = DO1 ? (d1_pos ? (xt1 + (yt1 >>> K1)) : (xt1 - (yt1 >>> K1))) : xt1;
      wire signed [IW-1:0] yt2 = DO1 ? (d1_pos ? (yt1 - (xt1 >>> K1)) : (yt1 + (xt1 >>> K1))) : yt1;
      wire signed [ANG_WIDTH-1:0] zt2 = DO1 ? (d1_pos ? (zt1 + atan_table(K1)) : (zt1 - atan_table(K1))) : zt1;

      // Step 2
      wire d2_pos = ~yt2[IW-1];
      wire signed [IW-1:0] xt3 = DO2 ? (d2_pos ? (xt2 + (yt2 >>> K2)) : (xt2 - (yt2 >>> K2))) : xt2;
      wire signed [IW-1:0] yt3 = DO2 ? (d2_pos ? (yt2 - (xt2 >>> K2)) : (yt2 + (xt2 >>> K2))) : yt2;
      wire signed [ANG_WIDTH-1:0] zt3 = DO2 ? (d2_pos ? (zt2 + atan_table(K2)) : (zt2 - atan_table(K2))) : zt2;

      // Register this stage outputs into next pipeline stage
      always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
          x_pipe[s+1] <= '0;
          y_pipe[s+1] <= '0;
          z_pipe[s+1] <= '0;
          v_pipe[s+1] <= 1'b0;
        end else begin
          x_pipe[s+1] <= xt3;
          y_pipe[s+1] <= yt3;
          z_pipe[s+1] <= zt3;
          v_pipe[s+1] <= v_pipe[s];
        end
      end
    end
  endgenerate

  assign out_valid = v_pipe[STAGES];
  assign angle_deg = z_pipe[STAGES];

endmodule

`default_nettype wire
