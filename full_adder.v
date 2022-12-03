module full_adder #(
    parameter DATA_WIDTH = 4
) (
    input  [DATA_WIDTH - 1 : 0] A,
    input  [DATA_WIDTH - 1 : 0] B,
    input                       Carry_in,
    output [DATA_WIDTH - 1: 0] Sum,
    output                     Carry_out
);
    wire [DATA_WIDTH + 1 : 0] temp;
    assign temp = A + B + Carry_in;
    
    assign Sum = temp[DATA_WIDTH - 1 :0];
    assign Carry_out = temp[DATA_WIDTH];
endmodule


