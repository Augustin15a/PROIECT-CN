module AddSub(
    input op,
    output cska_op,
    output reg_A_load,
    output reg_A_enable,
    output reg_M_load,
    output reg_M_enable,
    output done
);

buf(cska_op, op);
buf(reg_A_load,   1'b1);
buf(reg_A_enable, 1'b1);
buf(reg_M_load,   1'b1);
buf(reg_M_enable, 1'b1);
buf(done, 1'b1);

endmodule
