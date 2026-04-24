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
    output [p - 1:0] q
);

genvar i;
generate
    for(i = p - 1; i >= 0; i = i - 1) begin : ff_gen
        wire d_in;
        wire [3:0] mux_out;
        
        MUX2_1 m1(.x(q[i]), .y( (i==0) ? 1'b0 : q[i-1] ), .sel(shift_left), .out(mux_out[0]), .enable(enable));
        MUX2_1 m2(.x(mux_out[0]), .y( (i==p-1) ? q[p-1] : q[i+1] ), .sel(shift_right), .out(mux_out[1]), .enable(enable));
        MUX2_1 m3(.x(mux_out[1]), .y( (i>=p-2) ? q[p-1] : q[i+2] ), .sel(shift2_right), .out(mux_out[2]), .enable(enable));
        MUX2_1 m4(.x(mux_out[2]), .y(d[i]), .sel(load), .out(d_in), .enable(enable));

        FF_D ff_d(
            .rst(rst),
            .clk(clk),
            .d(d_in),
            .enable(enable), 
            .q(q[i])
        );
    end
endgenerate
endmodule