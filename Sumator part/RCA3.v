module RCA3(
    input [2:0] x,
    input [2:0] y,
    input carryIn,
    output carryOut,
    output p,
    output [2:0] z
);
    wire [3:0] carry;
    wire [2:0] propagate;
    genvar i;

    buf(carry[0], carryIn);

    generate
        for(i = 0; i < 3; i = i + 1) begin : facwp_gen
            FACWP fac(
                .x(x[i]),
                .y(y[i]),
                .carryIn(carry[i]),
                .carryOut(carry[i+1]),
                .p(propagate[i]),
                .z(z[i])
            );
        end
    endgenerate

    and(p, propagate[0], propagate[1], propagate[2]);
    buf(carryOut, carry[3]);
endmodule