
module FF_D(
	input  rst,clk,
	input d,
	input enable,
	output q
);

wire result_mux,result_rst,not_clk;
not(not_clk,clk);

MUX2_1 reset_gate(
        .x(d),
        .y(1'b0),
        .sel(rst),
        .out(result_rst),
        .enable(1'b1)
    );
MUX2_1 mux(
	.x(result_mux),
	.y(result_rst),
	.sel(not_clk),
	.out(result_mux),
	.enable(enable)
);
MUX2_1 mux1(
	.x(q),
	.y(result_mux),
	.sel(clk),
	.out(q),
	.enable(enable)
);
endmodule