
module ALU(
    input clk,
    input rst,
    input start,
    input [1:0]op,
    input [7:0]X,
    input [7:0]Y,
    output [7:0]result_lo,
    output [7:0]result_hi,
    output [8:0]out_A,
    output done
);

wire [7:0] not_X, not_Y;
genvar nx;
generate
    for(nx = 0; nx < 8; nx = nx + 1) begin : det_not
        not(not_X[nx], X[nx]);
        not(not_Y[nx], Y[nx]);
    end
endgenerate

wire x_is_zero, y_is_zero, y_is_one;
and(x_is_zero, not_X[0], not_X[1], not_X[2], not_X[3], not_X[4], not_X[5], not_X[6], not_X[7]);
and(y_is_zero, not_Y[0], not_Y[1], not_Y[2], not_Y[3], not_Y[4], not_Y[5], not_Y[6], not_Y[7]);
and(y_is_one, Y[0], not_Y[1], not_Y[2], not_Y[3], not_Y[4], not_Y[5], not_Y[6], not_Y[7]);

wire [8:0]reg_A_wire;
wire [8:0]reg_Q_wire;
wire [8:0]reg_Qneg_wire;
wire [8:0]reg_M_wire;
wire [8:0]cska_z;
wire cska_cout;
wire cu_reg_A_load,cu_reg_A_enable,cu_reg_A_shift_left;
wire cu_reg_Q_load,cu_reg_Q_enable,cu_reg_Q_shift2_right,cu_reg_Q_shift_left;
wire cu_reg_Qneg_load,cu_reg_Qneg_enable,cu_reg_Qneg_shift_left;
wire cu_reg_M_load,cu_reg_M_enable;
wire cu_cska_op;
wire cu_neg,cu_twoM,cu_zero,cu_pos;
wire cu_quot_pos_bit,cu_quot_neg_bit;
wire cu_load_phase,cu_done;
wire cu_cnt_mul_enable,cu_cnt_div_enable;
wire cnt_done_mul,cnt_done_div;
wire [8:0]operand_booth;
wire [8:0]operand_srt;

wire [1:0] not_op;
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
    .x_is_zero(x_is_zero),
    .y_is_zero(y_is_zero),
    .y_is_one(y_is_one),
    .reg_A_load(cu_reg_A_load),
    .reg_A_enable(cu_reg_A_enable),
    .reg_A_shift_left(cu_reg_A_shift_left),
    .reg_Q_load(cu_reg_Q_load),
    .reg_Q_enable(cu_reg_Q_enable),
    .reg_Q_shift2_right(cu_reg_Q_shift2_right),
    .reg_Q_shift_left(cu_reg_Q_shift_left),
    .reg_Qneg_load(cu_reg_Qneg_load),
    .reg_Qneg_enable(cu_reg_Qneg_enable),
    .reg_Qneg_shift_left(cu_reg_Qneg_shift_left),
    .reg_M_load(cu_reg_M_load),
    .reg_M_enable(cu_reg_M_enable),
    .cska_op(cu_cska_op),
    .neg(cu_neg),
    .twoM(cu_twoM),
    .zero(cu_zero),
    .pos(cu_pos),
    .quot_pos_bit(cu_quot_pos_bit),
    .quot_neg_bit(cu_quot_neg_bit),
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
    .operand(operand_booth)
);

SRT_Radix2 srt(
    .reg_M(reg_M_wire[7:0]),
    .pos(cu_pos),
    .neg(cu_neg),
    .operand(operand_srt)
);

wire [8:0] mux_cska_x;
wire [8:0] mux_cska_y;
wire mux_cska_op;

genvar i;
generate
    for(i = 0; i < 9; i = i+1) begin : mux_cska_x_gen
        wire part_normal, part_final;
        and(part_normal, reg_A_wire[i], ~cu_done);
        and(part_final, reg_Q_wire[i], cu_done);
        or(mux_cska_x[i], part_normal, part_final);
    end
endgenerate

wire [8:0]cska_y_normal;
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
    for(k = 0; k < 9; k = k+1) begin : mux_cska_y_logic
        wire from_as,from_mul,from_div;
        and(from_as, M_zero_ext[k], op_is_as);
        and(from_mul,operand_booth[k],op_is_mul);
        and(from_div,operand_srt[k], op_is_div);
        or(cska_y_normal[k],from_as,from_mul,from_div);
        
        wire part_normal_y, part_final_y;
        and(part_normal_y, cska_y_normal[k], ~cu_done);
        and(part_final_y, reg_Qneg_wire[k], cu_done);
        or(mux_cska_y[k], part_normal_y, part_final_y);
    end
endgenerate

wire part_normal_op, part_final_op;
and(part_normal_op, cu_cska_op, ~cu_done);
and(part_final_op, 1'b1, cu_done);
or(mux_cska_op, part_normal_op, part_final_op);

CSkA cska(
    .x(mux_cska_x),
    .y(mux_cska_y),
    .sum(mux_cska_op),
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
wire [8:0]d_Qneg;
wire [8:0]Y_ext;
genvar y;
generate
    for(y = 0; y < 8; y = y+1) begin : yext_gen
        buf(Y_ext[y],Y[y]);
    end
endgenerate
buf(Y_ext[8],Y[7]);

wire d_Q0_base,d_Q0_quot;
wire d_Qneg0_base,d_Qneg0_quot;

MUX2_1 mux_dq0(
    .x(Y_ext[0]),
    .y(X[0]),
    .sel(op_is_div),
    .enable(1'b1),
    .out(d_Q0_base)
);
and(d_Q0_quot,cu_quot_pos_bit,op_is_div);
or(d_Q[0],d_Q0_base,d_Q0_quot);

MUX2_1 mux_dqneg0(
    .x(Y_ext[0]),
    .y(X[0]),
    .sel(op_is_div),
    .enable(1'b1),
    .out(d_Qneg0_base)
);
and(d_Qneg0_quot,cu_quot_neg_bit,op_is_div);
or(d_Qneg[0],d_Qneg0_base,d_Qneg0_quot);

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
        or(d_Qneg[q],from_mul,from_div,from_as);
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

Register #(.p(9)) reg_Qneg(
    .clk(clk),
    .rst(rst),
    .d(d_Qneg),
    .load(cu_reg_Qneg_load),
    .shift_right(1'b0),
    .shift_left(cu_reg_Qneg_shift_left),
    .shift2_right(1'b0),
    .enable(cu_reg_Qneg_enable),
    .q(reg_Qneg_wire)
);

Register #(.p(9)) reg_M(
    .clk(clk),
    .rst(rst),
    .d(Y_ext),
    .load(cu_reg_M_load),
    .shift_right(1'b0),
    .shift_left(1'b0),
    .shift2_right(1'b0),
    .enable(cu_reg_M_enable),
    .q(reg_M_wire)
);

wire force_zero, force_X;
wire mul_any_zero, div_zero_top;
or(mul_any_zero, x_is_zero, y_is_zero);
and(force_zero, op_is_mul, mul_any_zero);
and(div_zero_top, op_is_div, x_is_zero);
and(force_X, op_is_div, y_is_one);

genvar o;
generate
    for(o = 0; o < 8; o = o+1) begin : out_gen
        wire out_lo_calc, out_lo_with_X;
        wire out_lo_normal, out_lo_div_final;
        
        and(out_lo_normal, reg_Q_wire[o], ~cu_done);
        and(out_lo_div_final, cska_z[o], op_is_div, cu_done);
        or(out_lo_calc, out_lo_normal, out_lo_div_final);

        wire p_calc, p_X;
        and(p_calc, out_lo_calc, ~force_X);
        and(p_X, X[o], force_X);
        or(out_lo_with_X, p_calc, p_X);

        wire is_zero_case;
        or(is_zero_case, force_zero, div_zero_top);
        and(result_lo[o], out_lo_with_X, ~is_zero_case);

        and(result_hi[o], reg_A_wire[o], ~is_zero_case);
        buf(out_A[o], reg_A_wire[o]);
    end
endgenerate
buf(out_A[8], reg_A_wire[8]);

buf(done,cu_done);

endmodule