module FACWP(
	input x,
	input y,
	input carryIn,
	output p,
	output z,
	output carryOut
);

wire [2:0]rez_carryOut;

xor(z,x,y,carryIn);

and(rez_carryOut[0],x,y);
and(rez_carryOut[1],x,carryIn);
and(rez_carryOut[2],carryIn,y);
or(carryOut,rez_carryOut[0],rez_carryOut[1],rez_carryOut[2]);
or(p,x,y);

endmodule