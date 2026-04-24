`include "FF_D.v"
`include "FACWP.v"
module Counter #(parameter max)(
    input  clk,
    input  rst,
    input  enable,
    output [max:0] q,
    output done
);

wire [max:0]d;
wire [max:0]c;
wire [max:0]p;

genvar i,j,k;
FACWP fa0(.x(q[0]), .y(enable), .carryIn(1'b0), .z(d[0]), .carryOut(c[0]), .p(p[0]));
generate
	for(i = 1;i < max;i = i + 1)
	begin facgen:
		FACWP fac(.x(q[i]), .y(1'b0),   .carryIn(c[i-1]),   .z(d[i]), .carryOut(c[i]), .p(p[i]));
	end
endgenerate

generate
	for(j = 0;j < max;j = j + 1)
	begin ffgen:
		FF_D ff0(.clk(clk), .rst(rst), .d(d[j]), .enable(1'b1), .q(q[j]));
	end
endgenerate

wire [max-1:0]not_q;
generate
	for(k = 0;k < max;k = k + 1)
	begin notgen:
		not(not_q[k], q[k]);
	end
endgenerate

generate
    if (max == 3)
	begin : facgen_3
		wire done_3;
		and(done_3, q[1], q[0]);	
        buf(done, done_3);
	end
    else
	begin : facgen_16
		wire done_16;
		and(done_16, q[3], not_q[2], not_q[1], not_q[0]);
        buf(done, done_16);
	end
endgenerate

endmodule