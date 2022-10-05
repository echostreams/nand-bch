module nuc970_encode #(
	parameter T = 4,
	parameter DATA_BITS = 4288,
	parameter BITS = 8,
	parameter PIPELINE_STAGES = 0
) (
	input [BITS-1:0] data_in,
	input clk_in,
	input start,
	input ce,
	output ready,
	output [BITS-1:0] data_out,
	output first,
	output last,
	output data_bits,
	output ecc_bits
);
	`include "bch_params.vh"
	//localparam BCH_PARAMS = bch_params(DATA_BITS, T);
/*
	nuc970 BCH_PARAMS
	m: 15
	n: 32767	(1 << 15)
	k: 32707,
	t: 4,
	data_bits: 16384	(2048 * 8)
	syndromes: 60	(4 * 15)
*/
	localparam BCH_PARAMS = `BCH_PARAMS(15, (1<<15)-1-(T*15), T, DATA_BITS, T);

	wire [BITS-1:0] data_in0;
	wire start0;
	wire ce0;
	wire ready0;
	wire [BITS-1:0] data_out0;
	wire first0;
	wire last0;
	wire data_bits0;
	wire ecc_bits0;
/*
	BUFG u_bufg (
		.I(clk_in),
		.O(clk)
	);
*/
	pipeline #(2) u_input [BITS+2-1:0] (
		.clk(clk_in),
		.i({data_in, start, ce}),
		.o({data_in0, start0, ce0})
	);

	pipeline #(2) u_output [BITS+5-1:0] (
		.clk(clk_in),
		.i({ready0, data_out0, first0, last0, data_bits0, ecc_bits0}),
		.o({ready, data_out, first, last, data_bits, ecc_bits})
	);


	bch_encode #(BCH_PARAMS, BITS, PIPELINE_STAGES) u_encode(
		.clk(clk_in),
		.start(start0),
		.ready(ready0),
		.ce(ce0),
		.data_in(data_in0),
		.data_out(data_out0),
		.data_bits(data_bits0),
		.ecc_bits(ecc_bits0),
		.first(first0),
		.last(last0)
	);

	initial begin
		$display(" NUC970 BCH PARAMS: %x", BCH_PARAMS);
	end

endmodule

