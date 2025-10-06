// SPDX-License-Identifier: MIT
`timescale 1ns/1ps

module cordic_radix8_tb;
  // Parameters matching DUT
  localparam int XYW        = 24;
  localparam int ZW         = 32;
  localparam int XY_FRAC    = 16;
  localparam int Z_FRAC     = 30;
  localparam int ITER_MAX   = 24;
  localparam int GROUP_SIZE = 3;

  logic clk, rst_n;
  logic in_valid, out_valid;
  logic signed [XYW-1:0] x_in, y_in;
  logic signed [ZW-1:0]  z_in;
  logic signed [XYW-1:0] x_out, y_out;
  logic signed [ZW-1:0]  z_out;

  cordic_radix8_core #(
    .XYW(XYW),
    .ZW(ZW),
    .XY_FRAC(XY_FRAC),
    .Z_FRAC(Z_FRAC),
    .ITER_MAX(ITER_MAX),
    .GROUP_SIZE(GROUP_SIZE),
    .PRE_SCALE(1'b1)
  ) dut (
    .clk,
    .rst_n,
    .in_valid,
    .x_in,
    .y_in,
    .z_in,
    .out_valid,
    .x_out,
    .y_out,
    .z_out
  );

  // Clock
  initial clk = 0;
  always #5 clk = ~clk;

  // Stimulus vectors
  localparam int N = 11;
  reg   signed [ZW-1:0]  ANGLES [0:N-1];
  reg   signed [XYW-1:0] COS_REF [0:N-1];
  reg   signed [XYW-1:0] SIN_REF [0:N-1];
  initial begin
    ANGLES[0]  = -32'sd1686629713;
    ANGLES[1]  = -32'sd1124419809;
    ANGLES[2]  = -32'sd843314857;
    ANGLES[3]  = -32'sd562209904;
    ANGLES[4]  = -32'sd281104952;
    ANGLES[5]  = 32'sd0;
    ANGLES[6]  = 32'sd281104952;
    ANGLES[7]  = 32'sd562209904;
    ANGLES[8]  = 32'sd843314857;
    ANGLES[9]  = 32'sd1124419809;
    ANGLES[10] = 32'sd1686629713;

    COS_REF[0]  = 24'sd0;
    COS_REF[1]  = 24'sd32768;
    COS_REF[2]  = 24'sd46341;
    COS_REF[3]  = 24'sd56756;
    COS_REF[4]  = 24'sd63303;
    COS_REF[5]  = 24'sd65536;
    COS_REF[6]  = 24'sd63303;
    COS_REF[7]  = 24'sd56756;
    COS_REF[8]  = 24'sd46341;
    COS_REF[9]  = 24'sd32768;
    COS_REF[10] = 24'sd0;

    SIN_REF[0]  = -24'sd65536;
    SIN_REF[1]  = -24'sd56756;
    SIN_REF[2]  = -24'sd46341;
    SIN_REF[3]  = -24'sd32768;
    SIN_REF[4]  = -24'sd16962;
    SIN_REF[5]  = 24'sd0;
    SIN_REF[6]  = 24'sd16962;
    SIN_REF[7]  = 24'sd32768;
    SIN_REF[8]  = 24'sd46341;
    SIN_REF[9]  = 24'sd56756;
    SIN_REF[10] = 24'sd65536;
  end

  // Drive
  int i;
  initial begin
    rst_n = 0; in_valid = 0; x_in = '0; y_in = '0; z_in = '0;
    repeat (5) @(posedge clk);
    rst_n = 1;

    // feed all angles, unit vector x=1.0 (Q16), y=0
    for (i = 0; i < N; i++) begin
      @(posedge clk);
      in_valid <= 1'b1;
      x_in <= 24'sd65536; // 1.0 in Q16
      y_in <= 24'sd0;
      z_in <= ANGLES[i];
    end
    @(posedge clk);
    in_valid <= 1'b0;

    // wait for pipeline to drain
    repeat (50) @(posedge clk);
    $finish;
  end

  // Checker: compare with tolerance when valid
  int idx;
  int latency;
  initial begin
    idx = 0; latency = 0;
    wait(rst_n);
    @(posedge clk);
    while (1) begin
      @(posedge clk);
      if (out_valid) begin
        int err_x = $signed(x_out) - COS_REF[idx];
        int err_y = $signed(y_out) - SIN_REF[idx];
        int abs_ex = (err_x < 0) ? -err_x : err_x;
        int abs_ey = (err_y < 0) ? -err_y : err_y;
        if (abs_ex > 3 || abs_ey > 3) begin
          $display("FAIL at idx %0d angle=%0d x_out=%0d y_out=%0d ex=%0d ey=%0d", idx, ANGLES[idx], x_out, y_out, err_x, err_y);
        end else begin
          $display("PASS idx %0d angle=%0d x=%0d y=%0d", idx, ANGLES[idx], x_out, y_out);
        end
        idx++;
        if (idx == N) idx = 0; // continue printing
      end
      if (in_valid) latency++;
    end
  end

endmodule
