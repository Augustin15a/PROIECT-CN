
module SRT_Radix2(
    input [7:0]reg_M,
    input pos,
    input neg,
    output [8:0]operand
);

wire [8:0] M_ext;

genvar i;
generate
    for(i = 0; i < 8; i = i + 1) begin : mgen
        buf(M_ext[i], reg_M[i]);
    end
endgenerate
buf(M_ext[8], 1'b0);

wire q_pos_or_neg;
or(q_pos_or_neg, pos, neg);

genvar k;
generate
    for(k = 0; k < 9; k = k + 1) begin : muxgen
        MUX2_1 m(
            .x(1'b0),
            .y(M_ext[k]),
            .sel(q_pos_or_neg),
            .enable(1'b1),
            .out(operand[k])
        );
    end
endgenerate

endmodule