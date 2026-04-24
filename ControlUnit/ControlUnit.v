`include "FF_D.v"
`include "BoothEncoder.v"

module ControlUnit(
    input clk,
    input rst,
    input start,
    input [1:0]op,
    input a_msb,
    input [2:0]reg_Q_low,
    input [8:0]reg_A,
    input cnt_done_mul,
    input cnt_done_div,

    output reg_A_load,
    output reg_A_enable,
    output reg_A_shift_left,
	
    output reg_Q_load,
    output reg_Q_enable,
    output reg_Q_shift2_right,
    output reg_Q_shift_left,
	
    output reg_M_load,
    output reg_M_enable,

    output cska_op,

    output neg,
    output twoM,
    output zero,
    output pos,

    output quot_bit,
    output load_phase,
    output done,

    output cnt_mul_enable,
    output cnt_div_enable
);
wire [1:0] not_op;
not(not_op[0],op[0]);
not(not_op[1],op[1]);

wire op_is_as,op_is_mul,op_is_div;
buf(op_is_as,not_op[1]);
and(op_is_mul,op[1],not_op[0]);
and(op_is_div,op[1],op[0]);

//fsm pe 3 biti
wire [2:0] stare;
wire [2:0] next_stare;
wire [2:0] not_stare;

not(not_stare[0], stare[0]);
not(not_stare[1], stare[1]);
not(not_stare[2], stare[2]);

wire stare_idle, stare_load, stare_as, stare_mul;
wire stare_div_shift, stare_div_comp, stare_div_restore, stare_done;

and(stare_idle,not_stare[2],not_stare[1],not_stare[0]);
and(stare_load,not_stare[2],not_stare[1],stare[0]);
and(stare_as,not_stare[2],stare[1],not_stare[0]);
and(stare_mul,not_stare[2],stare[1],stare[0]);
and(stare_div_shift,stare[2],not_stare[1],not_stare[0]);
and(stare_div_comp,stare[2],not_stare[1],stare[0]);
and(stare_div_restore,stare[2],stare[1],not_stare[0]);
and(stare_done,stare[2],stare[1],stare[0]);

wire not_cnt_done_mul,not_cnt_done_div;
not(not_cnt_done_mul,cnt_done_mul);
not(not_cnt_done_div,cnt_done_div);

wire not_a_msb;
not(not_a_msb,a_msb);

//alege operatia booth
BoothEncoder enc(
    .y    (reg_Q_low),
    .neg  (neg),
    .twoM (twoM),
    .zero (zero)
);

wire q_pos, q_zero, q_neg;
wire [2:0] not_reg_A_msb;
wire a7_or_a6;

not(not_reg_A_msb[0], reg_A[6]);
not(not_reg_A_msb[1], reg_A[7]);
not(not_reg_A_msb[2], reg_A[8]);

buf(q_pos,not_reg_A_msb[2]);
and(q_zero,a_msb,not_reg_A_msb[1],not_reg_A_msb[0]);
or(a7_or_a6,reg_A[7], reg_A[6]);
and(q_neg,a_msb, a7_or_a6);

buf(pos, q_pos);

// next_stare[0]
wire tranz_idle, tranz_load_mul, tranz_mul_done;
wire tranz_div_shift_comp,tranz_div_restore_done, tranz_as_done;
and(tranz_idle,stare_idle,start);
and(tranz_load_mul,stare_load,op_is_mul);
and(tranz_mul_done,stare_mul,cnt_done_mul);
buf(tranz_div_shift_comp,stare_div_shift);
and(tranz_div_restore_done,stare_div_restore,cnt_done_div);
buf(tranz_as_done, stare_as);
or(next_stare[0],tranz_idle,tranz_load_mul,tranz_mul_done,tranz_div_shift_comp,tranz_div_restore_done,tranz_as_done);

// next_stare[1]
wire tranz_load_as, tranz_load_mul_ns1, tranz_mul_stay;
wire tranz_mul_done_ns1, tranz_as_ns1, tranz_comp_restore, tranz_restore_done_ns1;
and(tranz_load_as,stare_load,op_is_as);
and(tranz_load_mul_ns1,stare_load,op_is_mul);
and(tranz_mul_stay,stare_mul,not_cnt_done_mul);
and(tranz_mul_done_ns1,stare_mul,cnt_done_mul);
buf(tranz_as_ns1,stare_as);
buf(tranz_comp_restore,stare_div_comp);
and(tranz_restore_done_ns1,stare_div_restore,cnt_done_div);
or(next_stare[1],tranz_load_as,tranz_load_mul_ns1,tranz_mul_stay,tranz_mul_done_ns1,tranz_as_ns1,tranz_comp_restore,tranz_restore_done_ns1);

// next_stare[2]
wire tranz_load_div, tranz_div_shift_ns2, tranz_div_comp_ns2;
wire tranz_div_restore_shift, tranz_div_restore_done_ns2;
wire tranz_mul_done_ns2, tranz_as_ns2;
and(tranz_load_div,stare_load,op_is_div);
buf(tranz_div_shift_ns2,stare_div_shift);
buf(tranz_div_comp_ns2,stare_div_comp);
and(tranz_div_restore_shift,stare_div_restore,not_cnt_done_div);
and(tranz_div_restore_done_ns2,stare_div_restore,cnt_done_div);
and(tranz_mul_done_ns2,stare_mul,cnt_done_mul);
buf(tranz_as_ns2,stare_as);
or(next_stare[2],tranz_load_div,tranz_div_shift_ns2,tranz_div_comp_ns2,tranz_div_restore_shift,tranz_div_restore_done_ns2,tranz_mul_done_ns2,tranz_as_ns2);

FF_D ff_s0(.clk(clk), .rst(rst), .d(next_stare[0]), .enable(1'b1), .q(stare[0]));
FF_D ff_s1(.clk(clk), .rst(rst), .d(next_stare[1]), .enable(1'b1), .q(stare[1]));
FF_D ff_s2(.clk(clk), .rst(rst), .d(next_stare[2]), .enable(1'b1), .q(stare[2]));

buf(cnt_mul_enable, stare_mul);
buf(cnt_div_enable, stare_div_shift);

buf(load_phase, stare_load);
buf(done,       stare_done);

// cska_op
wire cska_as,cska_mul, cska_div;
and(cska_as,stare_as,op[0]);
and(cska_mul,stare_mul,neg);
and(cska_div,stare_div_comp,q_pos);
or(cska_op,cska_as,cska_mul,cska_div);

// quot_bit
wire quot_pos_or_zero;
or(quot_pos_or_zero,q_pos, q_zero);
and(quot_bit,quot_pos_or_zero,stare_div_restore);

//reg_M
buf(reg_M_load,stare_load);
buf(reg_M_enable,stare_load);

//reg_A
wire reg_A_en_int,reg_A_load_int;
or(reg_A_en_int,stare_load,stare_as,stare_mul,
   stare_div_shift,stare_div_comp,stare_div_restore);
buf(reg_A_enable,reg_A_en_int);
buf(reg_A_shift_left,stare_div_shift);

or(reg_A_load_int,stare_load, stare_as, stare_mul,
   stare_div_comp,stare_div_restore);
buf(reg_A_load,reg_A_load_int);

//reg_Q
wire reg_Q_en_int,reg_Q_load_int;
or(reg_Q_en_int,stare_load,stare_mul,stare_div_shift,stare_div_comp,stare_div_restore);
buf(reg_Q_enable,reg_Q_en_int);

buf(reg_Q_shift2_right,stare_mul);
buf(reg_Q_shift_left,stare_div_shift);

or(reg_Q_load_int,stare_load,stare_mul,stare_div_restore);
buf(reg_Q_load,reg_Q_load_int);

endmodule