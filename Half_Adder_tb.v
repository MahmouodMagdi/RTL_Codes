// **************************************** Test Bench ************************************* //

module half_adder_tb #( parameter DATA_WIDTH = 4 ) ();

reg  [DATA_WIDTH - 1 : 0] A;
reg  [DATA_WIDTH - 1 : 0] B;
wire [DATA_WIDTH - 1 : 0] Sum;
wire                      Carry;


// Half Adder Instantaition
half_adder UUT(A,B,Sum,Carry);


// Stimulus
initial begin
    A = 4'b0110;
    B = 4'b0001;

    #20

    A = 4'b1000;
    B = 4'b0010;

    #100 $finish; 
end

    
endmodule
