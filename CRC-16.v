// ************************************* CRC-16 Module **************************************  
// Author: Mahmoud Magdi 


module CRC_16 #(

	parameter Remainder_Width = 16									// Width of the Remainder Register

)(

// Input Ports
	input 	clk,													// Input Clock Signal with Freq. = 32 MHZ
	input	reset_n,												// Asynchronous Active-Low Reset Signal
	input	Data_in,												// Input Data 
	input	Start,													// Start receiving data
	
// Output Ports 	
	output	reg CRC,												// CRC Result
	output  reg Done												// Indicates that the CRC Calculations are done

);


// Internal Registers and signals 
	reg  [Remainder_Width - 1 :0] R;								// Remainder Register 
	reg  [4:0] 					  counter;							// Counter to count the number of data bits 
	wire       					  Feedback;							// Feedback signal
	
	
	
	
//////////////////////////	
///// Feedback Logic /////
//////////////////////////
	assign Feedback = Data_in ^ R[0];
	
	
	
	
//////////////////////////////////////////	
///// Behaviral Modelling of the CRC /////
//////////////////////////////////////////
	always @(posedge clk or negedge reset_n)
	begin
	
		if (!reset_n)												// Check if the reset signal is active to reset the design
		begin
		
			CRC     <= 1'b0;
			Done    <= 1'b0;
			R       <= 16'b0;
			counter <= 5'b00000;
		end
	
		else 
		begin
		
			if (Start)												// Start Recieve the data and register it inside the remainder register
			begin
			
				R[0]  <= R[1];
				R[1]  <= R[2];
				R[2]  <= R[3];
				R[3]  <= R[4] ^ Feedback;
				R[4]  <= R[5];
				R[5]  <= R[6];
				R[6]  <= R[7];
				R[7]  <= R[8];
				R[8]  <= R[9];
				R[9]  <= R[10];
				R[10] <= R[11] ^ Feedback;
				R[11] <= R[12];
				R[12] <= R[13];
				R[13] <= R[14];
				R[14] <= R[15];
				R[15] <= Feedback;
				
				Done <= 1'b0;
				
			end
		
			else if (counter != 5'b10000)							// Check if all of data is registerd inside the remainder or not 
			begin
				
				counter <= counter + 1'b1;
				
				CRC   <= R[0];
				R[0]  <= R[1];
				R[1]  <= R[2];
				R[2]  <= R[3];
				R[3]  <= R[4];
				R[4]  <= R[5];
				R[5]  <= R[6];
				R[6]  <= R[7];
				R[7]  <= R[8];
				R[8]  <= R[9];
				R[9]  <= R[10];
				R[10] <= R[11];
				R[11] <= R[12];
				R[12] <= R[13];
				R[13] <= R[14];
				R[14] <= R[15];
				R[15] <= 1'b0;
			
				Done <= 1'b1;
			
			end
			
			else
			begin
		
				CRC  <= 1'b0;
				Done <= 1'b0;
				
			end
			
		end
	
	end
	
endmodule 	