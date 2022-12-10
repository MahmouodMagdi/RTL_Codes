module DFF_SYNCHRONIZER (

	input 	In,
	input 	CLK_1,
	input	CLK_2,
	output 	out

);

wire q1;
wire q2;

flipflop F1 (In,CLK_1,q1);
flipflop F2 (q1, CLK_2, q2);
flipflop F3 (q2,CLK_2,out);
endmodule 

module flipflop(

	input D,
	input CLK,
	output reg Q

);

	always@(posedge CLK)
	begin
		Q <= D;
	end
	
endmodule

