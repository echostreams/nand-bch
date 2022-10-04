`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 06.07.2020 21:41:38
// Design Name:
// Module Name: encoder_tb
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module encoder_tb;

    reg clk;
    reg [191:0] data;
    reg start;
    reg ce;

    wire ready;
    wire [7:0] data_out;
    wire first;
    wire last;
    wire data_bits;
    wire ecc_bits;
    wire enc_start;
    wire [7:0] enc_in;

    initial begin
        clk = 0;
        ce = 1;
        start = 0;
        data = 192'h123456789ABCDEF0123456789ABCDEF0123456789ABCDEF1;
        #7 start = 1;
        #10 start = 0;
    end

    buff #(192,8) buff_dec_in (
        .clk(clk),
        .start_in(start),
        .b_in(data),
        .b_out(enc_in),
        .start_out(enc_start)
    );

    xilinx_encode #(.T(8),.DATA_BITS(192),.BITS(8),.PIPELINE_STAGES(0)) encoder(
        .clk_in(clk),
        .data_in(enc_in),
        .start(enc_start),
        .ce(ce),
        .ready(ready),
        .data_out(data_out),
        .first(first),
        .last(last),
        .data_bits(data_bits),
        .ecc_bits(ecc_bits)
    );
    `include "bch_params.vh"
    //localparam [`BCH_PARAM_SZ-1:0] P = bch_params(192, 8);
    localparam [`BCH_PARAM_SZ-1:0] P = bch_params(4288, 24);

    always #5 clk = !clk;
    initial begin
	$display("bch_params: %x", P);
	$display("m: %d,\n n: %d,\n k: %d,\n t: %d,\n data_bits: %d,\n syndromes: %d\n",
		`BCH_M(P), `BCH_N(P), `BCH_K(P), `BCH_T(P), `BCH_DATA_BITS(P), `BCH_SYNDROMES_SZ(P)
	);
    end
    always @(posedge clk)
	begin
		if (data_bits)
			$display("data: %02x", data_out);
		if (ecc_bits)
			$display("ecc:  %02x", data_out);
		if (last)
			$finish();
	end
endmodule
