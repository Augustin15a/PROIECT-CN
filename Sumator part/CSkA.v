module CSkA(
    input [8:0] x,
    input [8:0] y,
    input sum,
    output [8:0] z,
    output c_out
);
    wire [3:0] carry;
    wire [2:0] carryOut;
    wire [8:0] y_in;
    genvar i, j;

    generate
        for(j = 0; j < 9; j = j + 1) begin : xor_gen
            xor(y_in[j], y[j], sum);
        end
    endgenerate

    buf(carry[0], sum);

    generate
        for(i = 0; i < 3; i = i + 1) begin : rca_gen
            wire carryCalc;//pt calculul lui c[i+1]
            wire propagate;
            RCA3 rca3(
                .x(x[3*i + 2 : 3*i]),
                .y(y_in[3*i + 2 : 3*i]),
                .carryIn(carry[i]),
                .carryOut(carryOut[i]),
                .p(propagate),
                .z(z[3*i + 2 : 3*i])
            );
            and(carryCalc, carry[i], propagate);
            or(carry[i + 1], carryCalc, carryOut[i]);
        end
    endgenerate

    buf(c_out, carry[3]);
endmodule