

// ************************************** Test Bench ************************************

module SISO_tb #( parameter DATA_WIDTH  = 4 ) ();


reg                      clk;
reg                      rst;
reg                      data_in;
reg  [DATA_WIDTH - 1 :0] temp;
wire                     data_out;


// Unit Under Test Instantiation

serial_in_serial_out_register UUT(clk,rst,data_in,data_out);


// Clock Generation
always begin
    #5 clk = ~clk;
end


// Stimulus
initial begin
    clk = 1'b0;
    rst = 1'b0;

    #10
    rst = 1'b1;

    #5 
    rst = 1'b0;

    #10 
    data_in = 1'b0;

    #5
    data_in = 1'b1;

    #5 data_in = 1'b0;


    #200 $finish;
end

endmodule
