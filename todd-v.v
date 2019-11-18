// Project entry point
module top (
	input clk,
	// WRONG input clk48m,
	// input clkint, // "unconstrained"
	// input rst, // "unconstrained"
	// input [7:0] nbtn, // @NOTE removed from sample as unconstrained with prod.lpf
	output reg [10:0] ledc,
	output reg [2:0] ledrgb
	// output [3:0] leda,
	// output [7:0] pmod,
);

	// random - see stolen code at bottom of file
	wire [31:0] rngno;
	rng rng(
		.clk1(clk), // was ori .clk1(clk48m),
		.clk2(clkint),
		.rst(rst),
		.rngno(rngno)
	);

	reg rst_ = 1'b0;
	always @(posedge clk) begin
		rst_ <= 1'b1;
	end

/* CORRECT AS OF had19_prod.lpf
	PCB		Schem		Pin/Site	Logical		"A" clr	"B" clr	"C" clr
	D5		LED1		E3				ledc[0]		RED			GREEN		BLUE
	D6		LED2		D3				ledc[1]		BLUE		GREEN		RED
	D7		LED3		C3				ledc[2]		RED			GREEN		BLUE
	D8		LED4		C4				ledc[3]		BLUE		GREEN		RED
	D9		LED5		C2				ledc[4]		RED			GREEN		BLUE
	D10		LED6		B1				ledc[5]		BLUE		GREEN		RED


	D11 	LED10		K20				ledc[6]		BLUE		GREEN		RED
	D12		LED11		K19				ledc[7]		GREEN		RED			BLUE
	D13		LED7		B20				ledc[8]		GREEN		RED			BLUE
	D14		LED8		B19				ledc[9]		RED			GREEN		BLUE
	D15 	LED9		A18				ledc[10]	RED			GREEN		BLUE
*/

	reg [7:0] top_led_counter = 0;
	parameter min_top_led_counter = 0;
	parameter max_top_led_counter = 5;

	reg [7:0] side_led_counter = 6;
	parameter min_side_led_counter = 6;
	parameter max_side_led_counter = 10;

	parameter red = 2'b00;
	parameter green = 2'b01;
	parameter blue = 2'b10;

	parameter led_mapping_size = 10;

	parameter [6*led_mapping_size-1 : 0] led_mapping = {
		{red, green, blue}, // 0, LED1
		{blue, green, red}, // 1, LED2
		{red, green, blue}, // 2, LED3
		{blue, green, red}, // 3, LED4
		{red, green, blue}, // 4, LED5
		{blue, green, red}, // 5, LED6
		{blue, green, red}, // 6, LED10 * sequence is mixed here
		{green, red, blue}, // 7, LED11
		{green, red, blue}, // 8, LED7
		{red, green, blue}, // 9, LED8
		{red, green, blue} // 10, LED9
	};

	// reg [7:0] a [0:3];
	reg [7:0] leds [0:10] [0:2]; // 11 x 3 array of bytes ([7:0])
	reg [7:0] leds_nxt [0:10] [0:2]; // 11 x 3 array of bytes ([7:0])

	// reg [0:2] color_index, color_index_nxt; // @DEBUG was = 0;

	// Clock divider and pulse registers
	reg [20:0] clkdiv, clkdiv_nxt; // @DEBUG was = 0;
	// reg clkdiv_pulse = 0;

	reg [2:0] ledrgb_nxt;

	reg [10:0] ledc_nxt;

	reg [7:0] value; // single-color (of RGB) "PWM" value

	// general counters
	reg integer l;
	reg integer c;
	reg integer s;

	reg [23:0] ctr, ctr_nxt;
	reg ctr_pulse;



	function save_led_color;
		input integer led;
		input [7:0] red, green, blue; // , [7:0] green, [7:0] blue;

		reg [5:0] idx_0, idx_1, idx_2; // @DEBUG was integer
		reg [5:0] led_map;

		begin
			/* @DEBUG below gets error on second line
			led_map = led_mapping[6*led +:6];
			idx_2 = led_map && 'b000011; // 'b11;
			led_map = led_map >> 2; // get rid of the idx_2 val
			idx_1 = led_map && 2'b11;
			led_map = led_map >> 2; // get rid of the idx_1 val
			idx_0 = led_map && 2'b11;
			*/

			led_map = led_mapping[6*led +:6];

			idx_2 = led_map[1:0];
			idx_1 = led_map[3:2];
			idx_1 = led_map[5:4];

			leds[0][idx_0] = red;
			leds[0][idx_1] = green;
			leds[0][idx_2] = blue;
		end

	endfunction


	initial begin
		// clear leds array
		// if (!rst_) begin
			for (l = 0; l < (led_mapping_size + 1); l = l + 1) begin
				for (c = 0; c < 3; c = c + 1) begin
					leds[l][c] = 0;
				end
			end

			// @DEBUG testing LED colors below
			leds[0][2'b00] = 'hff;
			leds[1][2'b01] = 'hff;
			leds[2][2'b10] = 'hff;

			leds[3][2'b00] = 'h80;
			leds[4][2'b01] = 'h80;
			leds[5][2'b10] = 'h80;

			leds[6][2'b00] = 'h40;
			leds[6][2'b01] = 'h40;
			leds[7][2'b01] = 'h40;
			leds[7][2'b10] = 'h40;
			leds[8][2'b10] = 'h40;
			leds[8][2'b00] = 'h40;

			leds[9][2'b00] = 'h00; // black
			leds[9][2'b01] = 'h00;
			leds[9][2'b10] = 'h00;

			// leds[10][2'b00] = 'h00; // black
			// leds[10][2'b01] = 'h00;
			// leds[10][2'b10] = 'h00;

			// @DEBUG error: assign leds[10][2'b00] = rngno[7:0]; // 'hff;
			// leds[10][2'b01] = rngno[7:0]; // 'hff;
			// leds[10][2'b10] = rngno[7:0]; // 'hff;
		// end
	end



	always @* begin

		// PWM cycle counter- counts down
		if (clkdiv == 0) begin
			clkdiv_nxt = 'h2ff; // aka 3 * d256 - 1, will be count down! was 0
		end else begin
			clkdiv_nxt = clkdiv - 1;
		end


		// Clock divider pulse generator
		if (ctr == 800000) begin
			ctr_nxt = 0;
			ctr_pulse = 1;
		end else begin
			ctr_nxt = ctr + 1;
			ctr_pulse = 0;
		end


		// set cycle of color "sinks"
		case (clkdiv[9:8])
			0: begin
					ledrgb_nxt[0] = 1;
					ledrgb_nxt[1] = 0;
					ledrgb_nxt[2] = 0;
				end
			1: begin
					ledrgb_nxt[0] = 0;
					ledrgb_nxt[1] = 1;
					ledrgb_nxt[2] = 0;
				end
			2: begin
					ledrgb_nxt[0] = 0;
					ledrgb_nxt[1] = 0;
					ledrgb_nxt[2] = 1;
				end
			default: begin // @ NOTE this should never be used...
					ledrgb_nxt[0] = 0;
					ledrgb_nxt[1] = 0;
					ledrgb_nxt[2] = 0;
				end
		endcase


		for (l = 0; l < (led_mapping_size + 1); l = l + 1) begin
			// @TODO do color mapping

			if (!ctr_nxt) begin
			// if (1) begin // @DEBUG
			// if (ctr_pulse) begin // @DEBUG it should be this?
				// @TODO ???? leds_nxt[l][clkdiv[9:8]] = rngno[7:0];
				leds_nxt[l][2'b00] = rngno[7:0];
				leds_nxt[l][2'b01] = rngno[15 -:8];  // @NOTE ex: [6*led +:6]
				leds_nxt[l][2'b10] = rngno[23 -:8]; // @DEBUG 'hff;
			end else begin
				leds_nxt[l][2'b00] = leds[l][2'b00];
				leds_nxt[l][2'b01] = leds[l][2'b01];
				leds_nxt[l][2'b10] = leds[l][2'b10];
			end


			if (clkdiv[7:0] < leds[l][clkdiv[9:8]]) begin // just compare the lower 8 bits
				ledc_nxt[l] = 1;
			end else begin
				ledc_nxt[l] = 0;
			end

		end // for

	end // always @*


	// leds[10][2'b00] = rngno[7:0]; // 'hff;


	// Synchronous logic
	always @(posedge clk) begin

		clkdiv <= clkdiv_nxt;
		ctr <= ctr_nxt;

		// set sink control
		for (s = 0; s < 3; s = s + 1) begin
			ledrgb[s] <= ledrgb_nxt[s];
		end

		// led changes
		for (l = 0; l < (led_mapping_size + 1); l = l + 1) begin
			// set LED source control
			ledc[l] <= ledc_nxt[l];

			// copy the LED array
			// @TODO only need to do when it changes
			for (s = 0; s < 3; s = s + 1) begin
				leds[l][s] <= leds_nxt[l][s];
			end
		end

		// "init"
		if (!rst_) begin
			clkdiv <= 'h2ff; // aka 3 * d256 - 1, will be count down! was 0
			ctr <= 0;
			// color_index <= 0;
		end

	end // always @(posedge clk)


endmodule











/*
 * Copyright (C) 2019  Jeroen Domburg <jeroen@spritesmods.com>
 * All rights reserved.
 *
 * BSD 3-clause, see LICENSE.bsd
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of the <organization> nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

//Semi-random trng (ish) generator. It's based on two lfsrs clocked by the main clock and the internal
//clock of the ecp5, respectively. While it should have a somewhat good random output, don't try to
//rely too much on it for crypto stuff... It's mainly chosen above a pure lfsr because it gives a
//different set of random-ish numbers on every bootup.

//Note: You probably don't want to read from this more often than once every 32 clock cycles.

module rng (
		input clk1,
		input clk2, //assumed to be slower than clk - >= 2x slower.
		input rst,
		output reg [31:0] rngno
	);

	wire [31:0] rngnuma;
	wire [31:0] rngnumb;

	lfsr64b #(
		.INITIAL_VAL(64'hAAAAAAAAAAAAAAAA)
	) prnga (
		.clk(clk1),
		.rst(rst),
		.prngout(rngnuma)
	);

	//Reset is synchronous with clk1. Domain-cross-thingy to clk2, so we know for sure it lasts long enough
	//there as well.
	reg [1:0] reset_slow_ct;
	reg [1:0] old_clk2;
	always @(posedge clk1) begin
		if (rst) begin
			reset_slow_ct <= 3;
		end else if (old_clk2[0] == 1 && old_clk2[1] == 0 && reset_slow_ct != 0) begin
			reset_slow_ct <= reset_slow_ct - 1;
		end
		old_clk2[1] <= old_clk2[0];
		old_clk2[0] <= clk2;
	end

	reg reset_clk2;
	always @(posedge clk2) begin
		reset_clk2 <= (reset_slow_ct != 0);
	end

	lfsr64b #(
		.INITIAL_VAL(64'hBBBBBBBBBBBBBBBB)
	) prngb (
		.clk(clk2),
		.rst(reset_clk2),
		.prngout(rngnumb)
	);

	//Do clock domain crossing back and
	reg [31:0] rngnumb_cross[0:1];
	always @(posedge clk1) begin
		rngnumb_cross[1] <= rngnumb_cross[0];
		rngnumb_cross[0] <= rngnumb;
		rngno <= rngnumb_cross[1] ^ rngnuma;
	end

endmodule

module lfsr64b #(
		parameter [63:0] INITIAL_VAL = 64'hFFFFFFFFFFFFFFFF
	) (
		input clk,
		input rst,
		output [31:0] prngout
	);

	reg [63:0] prngdata;
	assign prngout = prngdata[31:0];

	wire feedback;
	assign feedback = ~(prngdata[63] ^ prngdata[62] ^ prngdata[60] ^ prngdata[59]);

	always @(posedge clk) begin
		if (rst) begin
			prngdata <= INITIAL_VAL;
		end else begin
			prngdata <= {prngdata[62:0],feedback};
		end
	end
endmodule
