module MUX2_1(
	input x,
	input y,
	input sel,
	input enable,
	output out
);
wire not_sel,and_x,and_y,or_xy;

not(not_sel,sel);
and(and_x,x,not_sel);
and(and_y,y,sel);
or(or_xy,and_x,and_y);
and(out,enable,or_xy);

endmodule
