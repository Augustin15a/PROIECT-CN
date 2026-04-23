`include "FF_D.v" 
module SimpleRegister #(
	parameter p
)(
	input clk,
	input rst,
	input [p - 1:0]d,
	input load,
	input enable;
	output reg [p - 1:0]q
);
generate
	genvar i;
	for(i = p - 1;i >= 0 ; i = i - 1)
		begin : ff_gen
			wire d_in;
			MUX mux1(
				.x(q[i]),
				.y(d[i]),
				.sel(load),
				.enable(enable),
				.out(d_in)
			);
			FF_D ff_d(
				.rst(rst),
				.clk(clk),
				.d(d_in),
				.q(q[i])
			);
		end
endgenerate
endmodule