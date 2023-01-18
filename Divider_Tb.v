// ************************************* 16-bit Unsigned DIVIDER Test Bench **************************************  
// Author: Mahmoud Magdi 

module Unsigned_Divider_16_bit_TB ();


	parameter DATA_WIDTH = 16;
	parameter CLOCK_PERIOD = 10;

// Input Ports
	reg 				   Clk; 		
	reg 				   reset_n;								
	reg 				   start_division;						
	reg [DATA_WIDTH -1 :0] DIVIDEND;					
	reg [DATA_WIDTH -1 :0] DIVISOR;							
		
		
	// Output Ports	
	wire [DATA_WIDTH - 1:0] quotient;
	wire [DATA_WIDTH -1 :0] remainder;
	wire  					output_ready;
	wire					Error;
	


//////////////////////////
// Module Instantiation //
//////////////////////////
Unsigned_16_bit_DIVIDER UUT(

	// Input Ports
		Clk, 									
		reset_n,							
		start_division,					
		DIVIDEND,							
		DIVISOR, 								
		
		
	// Output Ports	
		quotient, 						
		remainder,							
		output_ready,							
		Error									
		
);



////////////////////////////
///// Clock Generation /////
////////////////////////////
always #(CLOCK_PERIOD/2) Clk = ~Clk; 




/////////////////////////////////
////// Stimulus Generation //////
/////////////////////////////////
initial 
begin

// Initial Value
	Clk 		    = 1'b0;
	reset_n 	    = 1'b1;
	start_division 	= 1'b0;
	
	
// Reset the Design
	#25 reset_n = 1'b0;
	

// Deactivate the reset signal
	#25 reset_n = 1'b1;


// Receive the DIVIDEND and DIVISOR Values	
	#15 DIVIDEND = 16'b0111_1001_1110_0100;
		DIVISOR  = 16'b0;									// Catch Division by Zero Case


// Start Division
	#40 start_division = 1'b1;
	
// Receive a non-zero DIVISOR

	#40 DIVISOR = 16'b1101_1000_0100_1011;

	#3000 $finish;
end

endmodule