module edge_detector_tb ();

    reg  d;
    reg  clk;
    reg  rst;
    wire out_posedge;
    wire out_negedge;



// Unit Under Test Instantiation
edge_detector UUT( d, clk, rst, out_posedge, out_negedge );

// Clock Generation
always
begin
    #5 clk = ~clk;
end


// Stimulus Generation
initial begin
    clk = 1'b0;
    rst = 1'b0;
    d   = 1'b1;

    genvar i;
    @(posedge clk);
    for (i = 0; i<32; i = i + 1) begin
        d = $random%2;
    @(posedge clk);
    end

    $finish();

    end
endmodule
