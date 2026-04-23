`include "FACWP.v"
`include "RCA3.v"
module CSkA(
	input [8:0]x,
	input [8:0]y,
	input sum,// 0 = adunare, 1 = scadere
	output [8:0]z,
	output c_out
);

wire [3:0]carry;
wire [2:0]carryOut;

buf(carry[0],sum);

generate
	genvar i;
	for(i = 0;i < 3; i = i + 1) 
		begin : rca_gen
			wire carryCalc;//folosit pentru calculul lui c[i+1]
			wire propagate;
			RCA3 rca3(
				.x(x[3*i + 2 : 3*i]),
				.y(y[3*i + 2 : 3*i]),
				.carryIn(carry[i]),
				.carryOut(carryOut[i]),
				.p(propagate),
				.z(z[3*i + 2 : 3*i])
				);
				and(carryCalc,carry[i],propagate);
				or(carry[i + 1],carryCalc,carryOut[i]);
		end
endgenerate

buf (c_out, carry[3]);

endmodule