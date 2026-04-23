`include "FF_D.v"
`include "MUX.v" 

module Register #(
    parameter p = 8
)(
    input clk,
    input rst,
    input [p - 1:0] d,
    input load,
    input shift_right,
    input shift_left,
    input shift2_right,
	input enable,
    output reg [p - 1:0] q
);

generate
    genvar i;
    for(i = p - 1; i >= 0; i = i - 1) begin : ff_gen
        wire d_in;
        wire [3:0] mux_out;
        MUX m1(.x(q[i]), .y( (i==0) ? 1'b0 : q[i-1] ), .sel(shift_left), .out(mux_out[0]),.enable(enable));
        MUX m2(.x(mux_out[0]), .y( (i==p-1) ? 1'b0 : q[i+1] ), .sel(shift_right), .out(mux_out[1]),.enable(enable));
        MUX m3(.x(mux_out[1]), .y( (i>=p-2) ? 1'b0 : q[i+2] ), .sel(shift2_right), .out(mux_out[2]),.enable(enable));
        MUX m4(.x(mux_out[2]), .y(d[i]), .sel(load), .out(d_in),.enable(enable));

        FF_D ff_d(
            .rst(rst),
            .clk(clk),
            .d(d_in),
            .enable(1'b1), 
            .q(q[i])
        );
    end
endgenerate
endmodule