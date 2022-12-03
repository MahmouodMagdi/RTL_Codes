module half_adder #(
    parameter DATA_WIDTH = 4
) (
    input  [DATA_WIDTH - 1 : 0] A,
    input  [DATA_WIDTH - 1 : 0] B,
    output [DATA_WIDTH - 1 : 0] Sum,
    output                      Carry
);

assign Sum = A ^ B;
assign Carry = A & B;
    
endmodule
