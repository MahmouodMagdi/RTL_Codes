`timescale 1ns/1ps

module Serializer_tb ();
  
// parameters
  parameter CLK_PERIOD  = 200;
  
// Testbench Input Signals
  reg  [7:0]   Data_in_tb;
  reg          clock_in_tb;
  reg          clock_out_tb; 
  reg          reset_n_tb;
  

// Testbench Output Signals  
  wire         Data_out_tb;



//////////////////////
// Clock Generation //
//////////////////////
always #(CLK_PERIOD / 2)      clock_in_tb  = ~clock_in_tb;
always #(CLK_PERIOD / 12.5)   clock_out_tb = ~clock_out_tb;


/////////////////////////
// Stimulus Generation //
/////////////////////////
initial
    begin
    
      $dumpfile ("Serializer.vcd");
      $dumpvars;
      
	  
      // Initial Values
      clock_in_tb  = 1'b0;
      clock_out_tb = 1'b0;
	  reset_n_tb   = 1'b1;   	// De_activated reset

    
   
      #10
      reset_n_tb =1'b0;    		// Activated reset
      #20
      reset_n_tb =1'b1;     	// De_activated reset
      
      #30
    
      Data_in_tb = 8'b10110101;		// Input Parallel Data
      
    
      #1000 $finish;
    end
  

////////////////////////  
// Design Istaniation //
////////////////////////
Serializer UUT(

  .Data_in(Data_in_tb),
  .clock_in(clock_in_tb),
  .clock_out(clock_out_tb),
  .reset_n(reset_n_tb),
  .Data_out(Data_out_tb)
  
  ); 
  
endmodule
