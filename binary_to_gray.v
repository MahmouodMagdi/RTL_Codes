module binary_to_gray #(
    parameter DATA_WIDTH = 16
) (

    input  [DATA_WIDTH - 1 : 0] binary_in_data,
    output [DATA_WIDTH - 1 : 0] gray_out_data
    
);
    
    // MSB of binary value is same as the MSB in gray value 
    assign gray_out_data[DATA_WIDTH - 1] = binary_in_data[DATA_WIDTH - 1];
    

    // Looping on the remaining 15 bits
    genvar i;

    for (i=0; i<15; i = i +1) begin
         assign gray_out_data[i] = binary_in_data[i+1] ^ binary_in_data[i];
    end
endmodule
