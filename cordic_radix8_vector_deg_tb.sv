`timescale 1ns/1ps
`default_nettype none

module cordic_radix8_vector_deg_tb;
  // Parameters
  localparam int XY_WIDTH   = 18;
  localparam int ANG_WIDTH  = 16;
  localparam int ANG_FRAC   = 7;
  localparam int GUARD_BITS = 3;
  localparam int ITER       = XY_WIDTH;
  localparam int STAGES     = (ITER + 2) / 3;

  // Clock/Reset
  logic clk; initial clk = 0; always #5 clk = ~clk; // 100MHz
  logic rst_n;

  // DUT I/O
  logic in_valid;
  logic signed [XY_WIDTH-1:0] x_in, y_in;
  logic out_valid;
  logic signed [ANG_WIDTH-1:0] angle_deg;

  // Instantiate DUT
  cordic_radix8_vector_deg #(
    .XY_WIDTH(XY_WIDTH),
    .GUARD_BITS(GUARD_BITS),
    .ANG_WIDTH(ANG_WIDTH),
    .ANG_FRAC(ANG_FRAC),
    .ITER(ITER)
  ) dut (
    .clk(clk), .rst_n(rst_n),
    .in_valid(in_valid), .x_in(x_in), .y_in(y_in),
    .out_valid(out_valid), .angle_deg(angle_deg)
  );

  // Helpers
  localparam signed [ANG_WIDTH-1:0] DEG180 = signed'(180 << ANG_FRAC);

  function automatic int fixdeg(input real deg);
    fixdeg = $rtoi(deg * (1<<ANG_FRAC));
  endfunction

  function automatic real rad2deg(input real r);
    return r * 180.0 / 3.14159265358979323846;
  endfunction

  // Randomized stimulus and scoreboard
  localparam int TOTAL_TESTS = 304; // 4 directed + 300 random
  localparam int DEG_TOL = 3;       // tolerance in fixed-point units
  int drive_idx;
  int outputs_seen;
  // Check index for expected computation on-the-fly
  int rd_idx;
  // Pre-generated inputs
  logic signed [XY_WIDTH-1:0] xi_mem [0:TOTAL_TESTS-1];
  logic signed [XY_WIDTH-1:0] yi_mem [0:TOTAL_TESTS-1];

  // Drive inputs, randomize
  initial begin
    rst_n = 0; in_valid = 0; x_in = 0; y_in = 0;
    drive_idx = 0; outputs_seen = 0; rd_idx = 0;
    // Prepare vectors
    xi_mem[0] = 18'sd10000; yi_mem[0] = 18'sd0;      // 0 deg
    xi_mem[1] = -18'sd10000; yi_mem[1] = 18'sd0;     // 180 deg
    xi_mem[2] = 18'sd0; yi_mem[2] = 18'sd10000;      // +90 deg
    xi_mem[3] = 18'sd0; yi_mem[3] = -18'sd10000;     // -90 deg
    for (int i = 4; i < TOTAL_TESTS; i++) begin
      int xi = $urandom_range(-(1<<(XY_WIDTH-1))+1, (1<<(XY_WIDTH-1))-1);
      int yi = $urandom_range(-(1<<(XY_WIDTH-1))+1, (1<<(XY_WIDTH-1))-1);
      if (xi == 0 && yi == 0) yi = 1;
      xi_mem[i] = xi;
      yi_mem[i] = yi;
    end
    repeat (5) @(posedge clk);
    rst_n = 1;
  end

  // Generate and queue expected values on posedge; drive DUT simultaneously
  always @(posedge clk) begin
    if (!rst_n) begin
      in_valid <= 1'b0;
      x_in <= '0; y_in <= '0;
    end else begin
      if (drive_idx < TOTAL_TESTS) begin
        in_valid <= 1'b1;
        x_in <= xi_mem[drive_idx];
        y_in <= yi_mem[drive_idx];
        drive_idx++;
      end else begin
        in_valid <= 1'b0;
      end
    end
  end

  // Remove unused queue-based driver (replaced by direct generator above)

  // Capture outputs after latency and compare
  int pass_count = 0, fail_count = 0, total_count = 0;
  int latency = STAGES + 1; // conservative

  // Compare on posedge aligned with DUT output
  always @(posedge clk) begin
    if (!rst_n) begin
      // no-op
    end else begin
      // compare when out_valid
      if (out_valid) begin
        int signed exp;
        int signed got;
        int signed err;
        int signed abs_err;
        // Compute expected from the corresponding input index
        exp = fixdeg(rad2deg($atan2(real'(yi_mem[rd_idx]), real'(xi_mem[rd_idx]))));
        rd_idx++;
        got = angle_deg;
        err = got - exp;
        abs_err = (err < 0) ? -err : err;
        total_count++;
        if (abs_err <= DEG_TOL) begin
          pass_count++;
        end else begin
          fail_count++;
          $display("[FAIL] idx=%0d got=%0d exp=%0d err=%0d (fx), deg got=%0.3f exp=%0.3f x=%0d y=%0d",
            rd_idx-1, got, exp, err, real'(got)/(1<<ANG_FRAC), real'(exp)/(1<<ANG_FRAC), xi_mem[rd_idx-1], yi_mem[rd_idx-1]);
        end
        outputs_seen++;
      end
    end
  end

  // Finish when done
  initial begin
    // Wait until all outputs observed or timeout
    int cycles = 0;
    while (outputs_seen < TOTAL_TESTS && cycles < 5000) begin
      @(posedge clk);
      cycles++;
    end
    $display("[RESULT] total=%0d pass=%0d fail=%0d", total_count, pass_count, fail_count);
    if (fail_count == 0 && total_count > 0) begin
      $display("[TB] PASS");
    end else begin
      $display("[TB] FAIL");
    end
    $finish;
  end

endmodule

`default_nettype wire
