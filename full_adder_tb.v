module full_adder_tb #( parameter DATA_WIDTH = 4 )();

reg  [DATA_WIDTH - 1 : 0] A;
reg  [DATA_WIDTH - 1 : 0] B;
reg                       Carry_in;
wire [DATA_WIDTH - 1 : 0] Sum;
wire                      Carry_out;



// Half Adder Instantaition
full_adder uut(A, B, Carry_in, Sum, Carry_out);


// Stimulus
initial 
begin

    A = 4'b0110;
    B = 4'b0001;
    Carry_in = 1'b1;

    #20

    A = 4'b1000;
    B = 4'b0010;
    Carry_in = 0;
    
    #100 $finish; 
end

endmodule