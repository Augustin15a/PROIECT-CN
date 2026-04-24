`include "BoothEncoder.v"
`include "Counter.v"
`include "MUX.v"
`include "FF_D.v"

module BoothRadix_4(
    input clk,
    input rst,
    input start,
    input [7:0]reg_M,
    input [8:0]reg_Q,
    output [8:0]operand,
    output cska_op,
    output reg_A_load,
    output reg_A_enable,
    output reg_Q_load,
    output reg_Q_shift2_right,
    output reg_Q_enable,
    output load_phase,
    output done
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
        buf(M2_9biti[i+1],reg_M[i]);
    end
endgenerate
//

wire [1:0]stare;
wire [1:0]next_stare;
wire [1:0]not_stare;
not(not_stare[0], stare[0]);
not(not_stare[1], stare[1]);

wire stare_idle,stare_load,stare_execute,stare_done;
and(stare_idle,not_stare[1], not_stare[0]);//00
and(stare_load,not_stare[1], stare[0]);//01
and(stare_execute,stare[1],not_stare[0]);//10
and(stare_done,stare[1],stare[0]);//11

wire cnt_done;

wire tranz_stare_idle,tranz_stare_done;
and(tranz_stare_idle, stare_idle,start);
and(tranz_stare_done, stare_execute,cnt_done);
or(next_stare[0], tranz_stare_idle,tranz_stare_done);

wire tranz_stare_load, tranz_stare_execute, cnt_done_n;
buf(tranz_stare_load, stare_load);
not(cnt_done_n, cnt_done);
and(tranz_stare_execute, stare_execute, cnt_done_n);
or(next_stare[1], tranz_stare_load, tranz_stare_execute);

FF_D ff_s0(.clk(clk), .rst(rst), .d(next_stare[0]), .enable(1'b1), .q(stare[0]));
FF_D ff_s1(.clk(clk), .rst(rst), .d(next_stare[1]), .enable(1'b1), .q(stare[1]));

Counter #(.MAX(3)) cnt(
    .clk(clk),
    .rst(rst),
    .enable(stare_execute),
    .q(),
    .done(cnt_done)
);

wire neg,twoM,zero;

BoothEncoder enc(
    .y(reg_Q[2:0]),
    .neg(neg),
    .twoM(twoM),
    .zero(zero)
);

wire not_zero;
not(not_zero,zero);

genvar k;
generate
    for(k = 0; k < 9; k = k + 1) begin : muxgen
        wire sel_out;
        MUX m_sel(.x(M_9biti[k]), .y(M2_9biti[k]), .sel(twoM),
                  .out(sel_out), .enable(1'b1));
        and(operand[k], sel_out, not_zero);
    end
endgenerate

buf(cska_op, neg);
buf(load_phase, stare_load);
//terminarea operatiei de inmultire
buf(done, stare_done);
wire reg_A_act;
or(reg_A_act, stare_load, stare_execute);
//pt reg A
buf(reg_A_load,   reg_A_act);
buf(reg_A_enable, reg_A_act);
//pt reg Q
buf(reg_Q_enable,        reg_A_act);
buf(reg_Q_load,          stare_load);
buf(reg_Q_shift2_right,  stare_execute);

endmodule