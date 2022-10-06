`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 06.07.2020 21:41:38
// Design Name:
// Module Name: nuc970_decoder_tb
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


module nuc970_decoder_tb;

    reg clk;
    reg [4348-1:0] data;   // 512 + 24 bytes + 60 bits
    reg start;
    reg ce;

    wire ready;
    wire [7:0] data_out;
    wire first;
    wire last;
    wire data_bits;
    wire ecc_bits;
    wire dec_start;
    wire [7:0] dec_in;
    integer i;

    wire [7:0] err_out;
	wire first_out;
    wire [7:0] err_cnt;
    wire err_last;

    wire [7:0] corrected;
    wire [7:0] ecc_out;
    reg [7:0] err_out2;
    reg [7:0] err_out3;
    reg ecc_start;
    assign corrected = ecc_out ^ err_out2;

    initial begin
        clk = 0;
        ce = 1;
        start = 0;
        // [4347:252][251:60][59:0]

        for (i = 252; i < 4348; i = i + 1)
            data[i] = 1'b1;
        data[251:60] = 192'h000000000000000000000000000000000000000000000000;
        data[59:0] = 60'b110100110010101110011111100111110010010001110011010101001100;

        // error
        data[310] = 1'b0;   // 4347 - 310 = 4037 / 8 = 504 (1 << (7-5))
        data[312] = 1'b0;   // 4347 - 312 = 4035 / 8 = 504 (1 << (7-3))

        data[2000] = 1'b0;  // 4347 - 2000 = 2347 / 8 = 293 (1 << (7-3))
        data[3000] = 1'b0;  // 4347 - 3000 = 1347 / 8 = 168 (1 << (7-3))

        #7 start = 1;
        #10 start = 0;
    end

    buff #(4348,8) buff_dec_in (
        .clk(clk),
        .start_in(start),
        .b_in(data),
        .b_out(dec_in),
        .start_out(dec_start)
    );

    nuc970_decoder #(
        .T(4),
	    .DATA_BITS(4348),
	    .BITS(8),
	    .SYN_REG_RATIO(1),
	    .ERR_REG_RATIO(1),
	    .SYN_PIPELINE_STAGES(0),
	    .ERR_PIPELINE_STAGES(0),
	    .ACCUM(1)
    ) decoder (
        .data_in(dec_in),
        .clk_in(clk),
        .start_in(dec_start),
        .err_out(err_out),
        .first_out(first_out),
        .err_cnt(err_cnt),
        .err_last(err_last)
    );

    buff #(4348,8) buff_correction (
        .clk(clk),
        .start_in(first_out),
        .b_in(data),
        .b_out(ecc_out),
        .start_out()
    );

    always #5 clk = !clk;

    initial begin
	    $dumpfile("test2.vcd");
	    $dumpvars(0);
    end

    always @(posedge clk) begin
        if (err_last) begin
			#50;
            $finish();
        end
    end

    always @(posedge clk)
	begin
        err_out2 <= err_out;
        err_out3 <= err_out2;

		if (ecc_bits)
			$display("ecc:  %02x", data_out);
		
        if (first_out) begin
            ecc_start <= 1;
        end

        if (ecc_start)
            $write("%02x", corrected);
	end
endmodule
