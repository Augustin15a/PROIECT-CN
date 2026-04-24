`include "Register.v"
`include "CSkA.v"
`include "ControlUnit.v"
`include "BoothRadix_4.v"
`include "SRT_Radix2.v"
`include "Counter.v"
`include "MUX.v"

module ALU(
    input clk,
    input rst,
    input start,
    input [1:0]op,
    input [7:0]X,
    input [7:0]Y,
    output [7:0]result_lo,
    output [7:0]result_hi,
    output done
);
wire [8:0]reg_A_wire;
wire [8:0]reg_Q_wire;
wire [8:0]reg_M_wire;
wire [8:0]cska_z;
wire cska_cout;
wire cu_reg_A_load,cu_reg_A_enable,cu_reg_A_shift_left;
wire cu_reg_Q_load,cu_reg_Q_enable,cu_reg_Q_shift2_right,cu_reg_Q_shift_left;
wire cu_reg_M_load,cu_reg_M_enable;
wire cu_cska_op;
wire cu_neg,cu_twoM,cu_zero,cu_pos;
wire cu_quot_bit,cu_load_phase,cu_done;
wire cu_cnt_mul_enable,cu_cnt_div_enable;
wire cnt_done_mul,cnt_done_div;
wire [8:0]operand_booth;
wire [8:0]operand_srt;
wire [1:0]not_op;
not(not_op[0],op[0]);
not(not_op[1],op[1]);
wire op_is_as,op_is_mul,op_is_div;
buf(op_is_as,not_op[1]);
and(op_is_mul,op[1],not_op[0]);
and(op_is_div,op[1],op[0]);

ControlUnit cu(
    .clk(clk),
    .rst(rst),
    .start(start),
    .op(op),
    .a_msb(reg_A_wire[8]),
    .reg_Q_low(reg_Q_wire[2:0]),
    .reg_A(reg_A_wire),
    .cnt_done_mul(cnt_done_mul),
    .cnt_done_div(cnt_done_div),
    .reg_A_load(cu_reg_A_load),
    .reg_A_enable(cu_reg_A_enable),
    .reg_A_shift_left(cu_reg_A_shift_left),
    .reg_Q_load(cu_reg_Q_load),
    .reg_Q_enable(cu_reg_Q_enable),
    .reg_Q_shift2_right(cu_reg_Q_shift2_right),
    .reg_Q_shift_left(cu_reg_Q_shift_left),
    .reg_M_load(cu_reg_M_load),
    .reg_M_enable(cu_reg_M_enable),
    .cska_op(cu_cska_op),
    .neg(cu_neg),
    .twoM(cu_twoM),
    .zero(cu_zero),
    .pos(cu_pos),
    .quot_bit(cu_quot_bit),
    .load_phase(cu_load_phase),
    .done(cu_done),
    .cnt_mul_enable(cu_cnt_mul_enable),
    .cnt_div_enable(cu_cnt_div_enable)
);

Counter #(.max(3)) cnt_mul(
    .clk(clk),
    .rst(rst),
    .enable(cu_cnt_mul_enable),
    .q(),
    .done(cnt_done_mul)
);

Counter #(.max(8)) cnt_div(
    .clk(clk),
    .rst(rst),
    .enable(cu_cnt_div_enable),
    .q(),
    .done(cnt_done_div)
);

BoothRadix_4 booth(
    .reg_M(reg_M_wire[7:0]),
    .neg(cu_neg),
    .twoM(cu_twoM),
    .zero(cu_zero),
    .operand(operand_booth),
    .cska_op()
);

SRT_Radix2 srt(
    .reg_M(reg_M_wire[7:0]),
    .pos(cu_pos),
    .neg(cu_neg),
    .operand(operand_srt),
    .cska_op()
);

wire [8:0]cska_y;
wire [8:0]M_zero_ext;
genvar j;
generate
    for(j = 0; j < 8; j = j+1) begin : mzext_gen
        buf(M_zero_ext[j],reg_M_wire[j]);
    end
endgenerate
buf(M_zero_ext[8],1'b0);

genvar k;
generate
    for(k = 0; k < 9; k = k+1) begin : mux_cska_y
        wire from_as,from_mul,from_div;
        and(from_as, M_zero_ext[k], op_is_as);
        and(from_mul,operand_booth[k],op_is_mul);
        and(from_div,operand_srt[k], op_is_div);
        or(cska_y[k],from_as,from_mul,from_div);
    end
endgenerate

CSkA cska(
    .x(reg_A_wire),
    .y(cska_y),
    .sum(cu_cska_op),
    .z(cska_z),
    .c_out(cska_cout)
);

wire [8:0]d_A;
wire [8:0]X_ext;
genvar a;
generate
    for(a = 0; a < 8; a = a+1) begin : xext_gen
        buf(X_ext[a],X[a]);
    end
endgenerate
buf(X_ext[8],1'b0);

wire not_cu_load_phase;
not(not_cu_load_phase, cu_load_phase);
generate
    for(a = 0; a < 9; a = a+1) begin : mux_dA
        wire from_load,from_compute;
        and(from_load, X_ext[a], cu_load_phase);
        and(from_compute,cska_z[a], not_cu_load_phase);
        or(d_A[a],from_load,from_compute);
    end
endgenerate

wire [8:0]d_Q;
wire [8:0]Y_ext;
genvar y;
generate
    for(y = 0; y < 8; y = y+1) begin : yext_gen
        buf(Y_ext[y],Y[y]);
    end
endgenerate
buf(Y_ext[8],Y[7]);

wire d_Q0_base,d_Q0_quot;
MUX2_1 mux_dq0(
    .x(Y_ext[0]),
    .y(X[0]),
    .sel(op_is_div),
    .enable(1'b1),
    .out(d_Q0_base)
);
and(d_Q0_quot,cu_quot_bit,op_is_div);
or(d_Q[0],d_Q0_base,d_Q0_quot);

genvar q;
generate
    for(q = 1; q < 9; q = q+1) begin : mux_dQ
        wire from_mul,from_div,from_as;
        wire mul_bit,div_bit;
        buf(mul_bit,(q <= 7) ? Y[q-1] : Y[7]);
        and(from_mul,mul_bit, op_is_mul);
        buf(div_bit,(q <= 7) ? X[q] : 1'b0);
        and(from_div,div_bit, op_is_div);
        and(from_as, Y_ext[q],op_is_as);
        or(d_Q[q],from_mul,from_div,from_as);
    end
endgenerate

wire [8:0]d_M;
genvar m;
generate
    for(m = 0; m < 9; m = m+1) begin : mux_dM
        buf(d_M[m],Y_ext[m]);
    end
endgenerate

Register #(.p(9)) reg_A(
    .clk(clk),
    .rst(rst),
    .d(d_A),
    .load(cu_reg_A_load),
    .shift_right(1'b0),
    .shift_left(cu_reg_A_shift_left),
    .shift2_right(1'b0),
    .enable(cu_reg_A_enable),
    .q(reg_A_wire)
);

Register #(.p(9)) reg_Q(
    .clk(clk),
    .rst(rst),
    .d(d_Q),
    .load(cu_reg_Q_load),
    .shift_right(1'b0),
    .shift_left(cu_reg_Q_shift_left),
    .shift2_right(cu_reg_Q_shift2_right),
    .enable(cu_reg_Q_enable),
    .q(reg_Q_wire)
);

Register #(.p(9)) reg_M(
    .clk(clk),
    .rst(rst),
    .d(d_M),
    .load(cu_reg_M_load),
    .shift_right(1'b0),
    .shift_left(1'b0),
    .shift2_right(1'b0),
    .enable(cu_reg_M_enable),
    .q(reg_M_wire)
);

genvar o;
generate
    for(o = 0; o < 8; o = o+1) begin : out_gen
        buf(result_lo[o],reg_Q_wire[o]);
        buf(result_hi[o],reg_A_wire[o]);
    end
endgenerate

buf(done,cu_done);
endmodule