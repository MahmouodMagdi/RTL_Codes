module CLK_GATING(

	input 		CLK,
	input 		Sel,
	output reg 	q
	
);

wire Gated_CLK;

assign Gated_CLK = CLK & Sel;

always @(posedge Gated_CLK)
begin

	q <= 1'b1;									// As you can see, input of the flop is tied to a constant. Naturally, output will
											// remain at this constant value at all the time irrespective of the clock applied at its input.
											// Since, the clock input of the flop will not be switching now, it will save switching power.
end

endmodule 
