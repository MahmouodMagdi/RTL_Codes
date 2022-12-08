// ********************************* GARAGE SYSTEM MODULE *********************************
// AUTHOR: MAHMOUD MAGDI

module GARAGE_SYSTEM(	

// Input Ports
	input 		Clk,													// Clock Signal
	input 		Reset_n,												// Asynchronous Active-Low Reset Signal
	input 		Car_entry_request,										// Active when a car requests an entry to the garage
	input 		Car_exit_request,   									// Active when a car requests an exit from garage
	
// Output Ports 	
	output reg  Open_entry_door,										// Open when a car requests an entry and there is a place inside the garage 
	output reg  Open_exit_door,											// open when a car requests an exit from the garage
	output reg  Garage_is_complete										// Indicates that there is no any places for more cars inside the garage 

); 	 



////////////////////////		
/// Internal Signals ///
////////////////////////
	reg [4:0]count;      												// Counts the number of cars inside the garage



////////////////////////////////////////////////////////
////////// BEHAVIORAL MODELLING OF THE SYSTEM //////////
////////////////////////////////////////////////////////

always@(posedge Clk or negedge Reset_n) begin     

	if(!Reset_n) begin       											// Check for a reset state

		Open_entry_door    <= 1'b0;       
		Open_exit_door     <= 1'b0;       
		Garage_is_complete <= 1'b0;       
		count			   <= 5'b0; 
		
	end     
	
	else begin   
    
		if(Car_entry_request) begin         							// Check for a car entry requests
		
			if(count < 10) begin           								// Check the number of cars inside the garage
			
				Open_entry_door <= 1'b1;       		
				Open_exit_door  <= 1'b0;           
			
				if(count == 9)       									// Check if the garage is complete 
					Garage_is_complete <= 1'b1;           
				
				else begin             									// Garage is nit complete
					Garage_is_complete <= 1'b0;           
					count <= count + 1; 
				end
			
			end       
		
		end       
	
		if(Car_exit_request) begin										// Check for any car exit requests
		
			if(count > 0) begin
			
				Open_entry_door    <= 1'b0;
				Open_exit_door     <= 1'b1;             
				Garage_is_complete <= 1'b0;           	
				count <= count - 1;         
			
			end       
		end     
	end   
end 
endmodule
