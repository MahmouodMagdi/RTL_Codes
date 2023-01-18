module De_Serializer #(

	parameter  DATA_WIDTH =  8 , 
	parameter  Counter_Width = 3)
(

// input ports
	input                           clock_in,
	input                           reset_n,
	input                           Data_in,
  
// output ports
	output reg                      clock_out,
	output reg [DATA_WIDTH - 1:0]   Data_out
);

// internal signals and Registers
	reg  [Counter_Width - 1 : 0]    counter;



// Serial to Parallel Shifting 
always @(posedge clock_in or negedge reset_n)
begin

  if(!reset_n)
  begin
    Data_out <= 8'b0;
  end

  else
  begin
    Data_out <={ Data_in,Data_out[(DATA_WIDTH - 1) : 1]};
  end
    
end



/////////////////////////////
// Clock Division Behavior //
/////////////////////////////
always@(posedge clock_in or negedge reset_n)
begin
    if(!reset_n)      
	begin
        counter   <= 3'b0;
        clock_out <= 1'b0;
    end
	
    else if(counter == Counter_Width)
    begin
        counter    <= 3'b0;
        clock_out  <= !clock_out;
    end
    
	else
    begin
        counter  <= counter + 1;
    end
end

endmodule