module GARAGE_SYSTEM_TB;   

// Inputs 
	reg Clk;
	reg Reset_n;
	reg Car_entry_request;
	reg Car_exit_request;

// Outputs   
	wire Open_entry_door;
	wire Open_exit_door;
	wire Garage_is_complete;      


	parameter CLK_PERIOD = 10;


// Module Instantiation
GARAGE_SYSTEM UUT(
	Clk,
	Reset_n,
	Car_entry_request,
	Car_exit_request,
	Open_entry_door,
	Open_exit_door,
	Garage_is_complete
	);      


//////////////////////////////
////// CLOCK GENERATION //////
//////////////////////////////
	
always #(CLK_PERIOD/2) Clk = ~Clk;	


/////////////////////////////
//// STIMULUS GENERATION ////
/////////////////////////////
initial 
begin     

	Clk = 1'b0;     
	Reset_n = 1'b0;
    
	#25 Reset_n= 1'b1;    
	
	#20 Car_entry_request = 1'b1;     
		Car_exit_request  = 1'b0;   
	
	#220 Car_entry_request = 1'b0;     
		 Car_exit_request  = 1'b1;        
end     
      
 initial 
 begin   	
 
	$dumpfile("dump.vcd");   		
	$dumpvars;   	

	#400   $finish; 

end   
 
endmodule