`timescale 1ns/1ps

module De_Serializer_tb();

// parameters
	parameter CLK_PERIOD = 100;

//////////////////////
// Clock Generation //
//////////////////////
always   #(CLK_PERIOD/2)  clock_in_tb = !clock_in_tb;


// Testbench Input Signals
	reg             clock_in_tb;
	reg             reset_n_tb;
	reg             Data_in_tb;
	
// Testbench Output Signals 	
	wire            clock_out_tb;
	wire  [7:0]     Data_out;


////////////////////////  
// Design Istaniation //
////////////////////////
	De_Serializer UUT(

		.clock_in(clock_in_tb),
		.reset_n(reset_n_tb),
		.Data_in(Data_in_tb),
		.clock_out(clock_out_tb),
		.Data_out(Data_out)
		
	);  




//////////////////////////////////////
// 		Stimulus Generation 	    //
//////////////////////////////////////
initial
 begin
   
   $dumpfile("DE_SERIALIZER.vcd");
   $dumpvars;
   
// Initial Values
   clock_in_tb = 1'b1;
   reset_n_tb  = 1'b1;   
   Data_in_tb  = 1'b1;

   #CLK_PERIOD/10
   reset_n_tb = 1'b0;   
   
   #CLK_PERIOD/10
   reset_n_tb = 1'b1;
   
   #CLK_PERIOD
   Data_in_tb = 1'b1;
   
   #CLK_PERIOD
   Data_in_tb = 1'b0;
   
   #CLK_PERIOD
   Data_in_tb = 1'b1;
   
   
   #CLK_PERIOD
   Data_in_tb = 1'b0;
   
   #CLK_PERIOD
   Data_in_tb = 1'b0;
   
   #CLK_PERIOD
   Data_in_tb = 1'b0;
   
   #CLK_PERIOD
   Data_in_tb = 1'b1;
   
   
   #1000   $finish;
   
 end
  
endmodule
