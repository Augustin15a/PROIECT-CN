module BoothRadix_4(
    input [7:0] reg_M,
    input neg,
    input twoM,
    input zero,
    output [8:0] operand
);

wire [8:0] M_9biti;
wire [8:0] M2_9biti;

//M_9biti si M_9biti sunt fire care ulterior intra intr un mux care decide daca A = A + M sau 2M
//dublare bit de semn
genvar i;
generate
    for(i = 0; i < 8; i = i + 1) begin : mgen
        buf(M_9biti[i], reg_M[i]);
    end
endgenerate
buf(M_9biti[8], reg_M[7]);

//m shift left
buf(M2_9biti[0], 1'b0);
generate
    for(i = 0; i < 8; i = i + 1) begin : m2gen
        buf(M2_9biti[i+1], reg_M[i]);
    end
endgenerate
//

wire not_zero;
not(not_zero, zero);

genvar k;
generate
    for(k = 0; k < 9; k = k + 1) begin : muxgen
        wire sel_out;
        MUX2_1 m(.x(M_9biti[k]), .y(M2_9biti[k]), .sel(twoM),
                  .out(sel_out), .enable(1'b1));
        and(operand[k], sel_out, not_zero);
    end
endgenerate

endmodule