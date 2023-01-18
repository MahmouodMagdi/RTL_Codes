module Serializer #( 

	parameter DATA_WIDTH = 8							// Width of the parallel data

)(

// input ports
	input   [DATA_WIDTH - 1:0]    Data_in,				// Parallel input data 
	input                         clock_in,				
	input                         clock_out,
	input                         reset_n,				// Asynchronous Active-Low Reset Signal

// output ports
	output   reg                  Data_out 				// Serial output data
);

// internal signals
reg    [DATA_WIDTH - 1: 0]  Data_reg;					// Internal Register to register the input data 


// Registeration of the incoming data 
 always @(posedge clock_in or negedge reset_n)
 begin
 
    if(!reset_n)										// Chck if the design is reseted 
	begin
		Data_reg <= 8'b0;
    end
   
   else 
    begin
       Data_reg <= Data_in ;  							// Register the parallel input data into the internal data register
    end
end
  
  
////////////////////////////////////////////////////////	
///// Behaviral Modelling of the Serializer Output /////
////////////////////////////////////////////////////////
always @(posedge clock_out or negedge reset_n)
    begin

      if(!reset_n)
        begin
          Data_out <= 1'b0;
        end

      else 
        begin
		
			Data_out <= Data_reg[0];
			Data_reg [0] <= Data_reg[1];
			Data_reg [1] <= Data_reg[2];
			Data_reg [2] <= Data_reg[3];
			Data_reg [3] <= Data_reg[4];
			Data_reg [4] <= Data_reg[5];
			Data_reg [5] <= Data_reg[6];
			Data_reg [6] <= Data_reg[7];    
			
        end
    end
  
   
   
endmodule
