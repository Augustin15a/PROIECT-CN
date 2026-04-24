module BoothEncoder(
	input [2:0]y,
	output neg,
	output twoM,
	output zero
);
wire [2:0]not_y;
wire [3:0]and_y;
wire y_or_int;

//negare
buf(neg,y[2]);

//2M
not(not_y[0],y[0]);
not(not_y[1],y[1]);

and(and_y[0],not_y[0],not_y[1]);
and(and_y[1],y[0],y[1]);

or(y_or_int,and_y[0],and_y[1]);
buf(twoM,y_or_int);

//zero
not(not_y[2],y[2]);

and(and_y[2],not_y[0],not_y[1],not_y[2]);
and(and_y[3],y[0],y[1],y[2]);

or(zero,and_y[2],and_y[3]);
endmodule