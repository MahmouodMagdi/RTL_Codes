module CLK_GATING(

	input 		CLK,
	input 		Sel,
	output reg 	q
	
);

wire Gated_CLK;

assign Gated_CLK = CLK & Sel;

always @(posedge Gated_CLK)
begin

	q <= 1'b1;									// Here the input of the FF is not changed, So we gated the clk of the ff 
												// to save more power
end

endmodule 