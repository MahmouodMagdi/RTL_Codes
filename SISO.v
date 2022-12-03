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
    input   load,
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

    else begin
        
        temp = temp >> 1'b1;
        temp[3] <= data_in;

    end

end

    assign data_out = data_out_reg;
endmodule