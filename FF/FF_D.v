`include "FF_D.v"
`include "FACWP.v"

module Counter(
    input  clk,
    input  rst,
    input  enable,
    output [1:0] q,
    output done
);

wire [1:0] d;
wire carry0;
wire p0, p1;

FACWP fa0(
    .x       (q[0]),
    .y       (enable),
    .carryIn (1'b0),
    .z       (d[0]),
    .carryOut(carry0),
    .p       (p0)
);

FACWP fa1(
    .x       (q[1]),
    .y       (1'b0),
    .carryIn (carry0),
    .z       (d[1]),
    .carryOut(),
    .p       (p1)
);

FF_D ff0(.clk(clk), .rst(rst), .d(d[0]), .enable(1'b1), .q(q[0]));
FF_D ff1(.clk(clk), .rst(rst), .d(d[1]), .enable(1'b1), .q(q[1]));

and(done, q[1], q[0]);

endmodule