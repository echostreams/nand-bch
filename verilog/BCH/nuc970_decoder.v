module nuc970_decoder #(
	parameter T = 4,
	parameter DATA_BITS = 4288,
	parameter BITS = 8,
	parameter SYN_REG_RATIO = 1,
	parameter ERR_REG_RATIO = 1,
	parameter SYN_PIPELINE_STAGES = 0,
	parameter ERR_PIPELINE_STAGES = 0,
	parameter ACCUM = 1
) (
	input [BITS-1:0] data_in,
	input clk_in,
	input start_in,
	output [BITS-1:0] err_out,
	output first_out,
	output [7:0] err_cnt,
	output err_last,
	output err_valid
);
	`include "bch_params.vh"
	//localparam BCH_PARAMS = bch_params(DATA_BITS, T);
	localparam BCH_PARAMS = `BCH_PARAMS(15, (1<<15)-1-(T*15), T, DATA_BITS, T);

	wire [`BCH_SYNDROMES_SZ(BCH_PARAMS)-1:0] syndromes;
	wire syn_done;
	wire key_ready;
	wire key_done;
	(* KEEP = "TRUE" *)
	(* S = "TRUE" *)
	wire [`BCH_SIGMA_SZ(BCH_PARAMS)-1:0] sigma;
	wire [`BCH_ERR_SZ(BCH_PARAMS)-1:0] err_count;
	wire err_first;
	
	wire [BITS-1:0] data;
	wire start;
	wire [BITS-1:0] err;

	localparam TCQ = 1;
	reg [32-1:0] err_count_rd_pos = 0;
	reg err_start = 0;

	pipeline #(1) u_pipeline [BITS*2+2-1:0] (
		.clk(clk_in),
		.i({data_in, start_in, err_first, err}),
		.o({data, start, first_out, err_out})
	);
/*
	BUFG u_bufg (
		.I(clk_in),
		.O(clk)
	);
*/
	bch_syndrome #(BCH_PARAMS, BITS, SYN_REG_RATIO, SYN_PIPELINE_STAGES) u_bch_syndrome(
		.clk(clk_in),
		.start(start),
		.ce(1'b1),
		.data_in(data),
		.syndromes(syndromes),
		.done(syn_done)
	);

	bch_sigma_bma_serial #(BCH_PARAMS) u_bma (
		.clk(clk_in),
		.start(syn_done && key_ready),
		.ready(key_ready),
		.syndromes(syndromes),
		.sigma(sigma),
		.done(key_done),
		.ack_done(1'b1),
		.err_count(err_count)
	);

	bch_error_tmec #(BCH_PARAMS, BITS, ERR_REG_RATIO, ERR_PIPELINE_STAGES, ACCUM) u_error_tmec(
		.clk(clk_in),
		.start(key_done),
		.sigma(sigma),
		.first(err_first),
		.err(err)
	);

	bch_chien_counter #(BCH_PARAMS, BITS) u_chien_counter(
		.clk(clk_in),
		.first(err_first),
		.last(err_last),
		.valid(err_valid)
	);

	assign err_cnt = err_count;
	
	always @(posedge clk_in) begin
		if (err_first) begin
			err_start <= 1;
			err_count_rd_pos <= #TCQ (err_count_rd_pos + 1);
			$display(" err_count_rd_pos: %d", err_count_rd_pos);
		end

		if (err_start) begin
			err_count_rd_pos <= #TCQ (err_count_rd_pos + 1);
			//if (err)
			//	$display(" err_count_rd_pos: %d", err_count_rd_pos);
		end
	end

endmodule

