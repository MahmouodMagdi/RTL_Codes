// **************************************** TEST BENCH *******************************************

module bin_to_gry_tb #( parameter DATA_WIDTH = 16)();

reg  [DATA_WIDTH - 1 : 0] binary_in_data;
wire [DATA_WIDTH - 1 : 0] gray_out_data;


// Unit Under Test Instantiation
binary_to_gray (

 binary_in_data,
 gray_out_data
    
);


// Stimulus Generation
initial begin
    binary_in_data = 16'b0010_1110_1001_0110;

    #50
    binary_in_data = 16'b1101_0010_1111_0011;

    #50
    binary_in_data = 16'b1101_0001_0110_1001;

end
    
    
endmodule
