 `timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// 
// Engineer: Mahmoud Magdi
// 
// Design Name: Serial In Serial Out Shift Register 
// Module Name: SISO
// 
//////////////////////////////////////////////////////////////////////////////////


 `timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// 
// Engineer: Mahmoud Magdi
// 
// Create Date: 12/03/2022 03:14:16 PM
// Design Name: Serial In Serial Out Shift Register 
// Module Name: SISO
// 
//////////////////////////////////////////////////////////////////////////////////


module serial_in_serial_out_register #(

    parameter DATA_WIDTH = 4

)(

    input   clk,
    input   rst,
    input   data_in,
    output  data_out
);

reg [DATA_WIDTH - 1 : 0] temp;    
    

always @(posedge clk) begin

    if (rst) begin

        temp <= 4'b0;
    
    end 
    else begin
        
        temp = temp >> 1'b1;
        temp[3] <= data_in;

    end

end

    assign data_out = temp[0];
endmodule




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
