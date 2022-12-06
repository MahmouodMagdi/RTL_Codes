// ********************************* PARAMETRIZED UNSIGNED BINARY DIVIDER MODULE *********************************
// AUTHOR: MAHMOUD MAGDI

module Unsigned_16_bit_DIVIDER #(

		parameter DATA_WIDTH = 16									
		
)(

	// Input Ports
		input  reg 					  Clk, 									// Clock signal of the Design
		input  reg 					  reset_n,								// Asynchronous Active-Low Reset signal
		input  reg 					  start_division,						// Indicates to start the division operation
		input  reg [DATA_WIDTH -1 :0] DIVIDEND,								// Number to be Divided
		input  reg [DATA_WIDTH -1 :0] DIVISOR, 								// Number to be divided by
		
		
	// Output Ports	
		output reg [DATA_WIDTH - 1:0] quotient, 							// Result of the division operation
		output     [DATA_WIDTH -1 :0] remainder,							// Remainder of the division operation
		output  					  output_ready,							// High when the division operation is finished and the data is ready at the quotient
		output reg 					  Error									// Active when there is a division by ZERO
		
);



////////////////////////		
// Internal Registers //
////////////////////////
		
	reg [4:0] counter;														// Counter which counts the number of cycles for each division iteration
	reg [(DATA_WIDTH * 2) - 1 :0] dividend_copy; 							// Register used to store a copy of the DIVIDEND
	reg [(DATA_WIDTH * 2) - 1 :0] DIVISOR_copy; 							// Register used to store a copy of the DIVISOR
	reg [(DATA_WIDTH * 2) - 1 :0] diff;										// Register used to store the result of "DIVIDEND - DIVISOR"
			
			
	assign remainder = dividend_copy[DATA_WIDTH - 1 :0];
	initial counter = 4'b0;		
	assign output_ready = !counter;
		
	
	
/////////////////////////////////////////////////////////
////////// BEHAVIORAL MODELLING OF THE DIVIDER //////////
/////////////////////////////////////////////////////////	
			
always @(posedge Clk or negedge reset_n) begin
				
				
		if (!reset_n) begin													// Check if the reset is active 
				
			quotient 	  <= 16'b0;
			counter       <= 5'b0;
			dividend_copy <= 32'b0;
			DIVISOR_copy  <= 32'b0;
			
		end
				
				
		else if (output_ready && start_division) begin						// Check for a division request
				
			if (DIVISOR == 16'b0) begin										// Catch the Division by ZERO
	
				Error <= 1'b1;												// Error flag is active for Division by zero 
			
			end
			
			else begin														// If ni division by ZERO --> be ready for a division iteration	
			
				counter  <= 16;												// Each iteration needs about 16 cycles to complete the division operation
				Error    <= 1'b0;											// No Division by Zero found
				quotient <= 16'b0;											
				dividend_copy = {16'b0, DIVIDEND};							// Store the DIVIDEND value in the internal dividend register
				DIVISOR_copy = {1'b0, DIVISOR, 15'b0};						// Store the DIVISOR value in the internal divisor register
				
			end
		end
			
		
		else if (!output_ready) begin										// Diviosion has not finished yet
			
			diff = dividend_copy - DIVISOR_copy;							// Subtract the DIVISOR for the DIVIDEND
			quotient = quotient << 1;										// Shift left the quotient by 1'b1
			
			if (!diff[31]) begin											
				
				dividend_copy = diff;
				quotient[0] = 1'b1;
				
			end
			
			DIVISOR_copy = DIVISOR_copy >> 1;
			counter = counter - 1;
			
		end
	end
endmodule