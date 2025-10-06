// SPDX-License-Identifier: MIT
`timescale 1ns/1ps

module cordic_angles_tb;
  localparam int XYW        = 24;
  localparam int ZW         = 32;
  localparam int XY_FRAC    = 16;
  localparam int Z_FRAC     = 28; // use Q28 angles to keep pi in 32-bit signed
  localparam int ITER_MAX   = 24;
  localparam int GROUP_SIZE = 3;

  logic clk, rst_n;
  logic in_valid, out_valid;
  logic signed [XYW-1:0] x_in, y_in;
  logic signed [ZW-1:0]  z_in;
  logic signed [XYW-1:0] x_out, y_out;

  cordic_rot_wrap #(
    .XYW(XYW), .ZW(ZW), .XY_FRAC(XY_FRAC), .Z_FRAC(Z_FRAC),
    .ITER_MAX(ITER_MAX), .GROUP_SIZE(GROUP_SIZE), .PRE_SCALE(1'b1)
  ) dut (
    .clk, .rst_n,
    .in_valid,
    .x_in, .y_in, .z_in,
    .out_valid,
    .x_out, .y_out
  );

  // Clock
  initial clk = 0;
  always #5 clk = ~clk;

  // Angles: 0, 45, 30, 60, 90, 180, 270 degrees (Q28 radians)
  localparam int N = 7;
  reg   signed [ZW-1:0]  ANGLES [0:N-1];
  reg   signed [XYW-1:0] COS_REF[0:N-1];
  reg   signed [XYW-1:0] SIN_REF[0:N-1];
  initial begin
    // Values generated offline in Q28/Q16
    ANGLES[0] = 32'sd0;           COS_REF[0] = 24'sd65536;  SIN_REF[0] = 24'sd0;      // 0°
    ANGLES[1] = 32'sd210828714;   COS_REF[1] = 24'sd46341;  SIN_REF[1] = 24'sd46341; // 45°
    ANGLES[2] = 32'sd140552476;   COS_REF[2] = 24'sd56756;  SIN_REF[2] = 24'sd32768; // 30°
    ANGLES[3] = 32'sd281104952;   COS_REF[3] = 24'sd32768;  SIN_REF[3] = 24'sd56756; // 60°
    ANGLES[4] = 32'sd421657428;   COS_REF[4] = 24'sd0;      SIN_REF[4] = 24'sd65536; // 90°
    ANGLES[5] = 32'sd843314857;   COS_REF[5] = -24'sd65536; SIN_REF[5] = 24'sd0;     // 180°
    ANGLES[6] = 32'sd1264972285;  COS_REF[6] = 24'sd0;      SIN_REF[6] = -24'sd65536; // 270°
  end

  // Drive
  int i;
  initial begin
    rst_n = 0; in_valid = 0; x_in = '0; y_in = '0; z_in = '0;
    repeat (5) @(posedge clk);
    rst_n = 1;

    for (i = 0; i < N; i++) begin
      @(posedge clk);
      in_valid <= 1'b1;
      x_in <= 24'sd65536; // 1.0 in Q16
      y_in <= 24'sd0;
      z_in <= ANGLES[i];
    end
    @(posedge clk);
    in_valid <= 1'b0;

    repeat (60) @(posedge clk);
    $finish;
  end

  // Checker
  int idx;
  initial begin
    idx = 0;
    wait(rst_n);
    @(posedge clk);
    while (1) begin
      @(posedge clk);
      if (out_valid) begin
        int err_x = $signed(x_out) - COS_REF[idx];
        int err_y = $signed(y_out) - SIN_REF[idx];
        int abs_ex = (err_x < 0) ? -err_x : err_x;
        int abs_ey = (err_y < 0) ? -err_y : err_y;
        if (abs_ex > 3 || abs_ey > 3)
          $display("FAIL idx %0d angle=%0d x=%0d y=%0d ex=%0d ey=%0d", idx, ANGLES[idx], x_out, y_out, err_x, err_y);
        else
          $display("PASS idx %0d angle=%0d x=%0d y=%0d", idx, ANGLES[idx], x_out, y_out);
        idx++;
        if (idx == N) idx = 0;
      end
    end
  end

endmodule
