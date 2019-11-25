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

	// random - see NEW code at bottom of file
	wire [31:0] rngno;
	rng rng(
		.clk1(clk),
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

	parameter led_mapping_size = 10; // there are 11 LEDs, 0 - 10 // @TODO DEPRICATE!

	parameter max_led_counter = max_side_led_counter; // there are 11 LEDs, 0 - 10
	parameter max_led_array_counter = max_led_counter + 1; // =11 (inclludes an extra for rotation "LED")

	parameter [6*max_led_counter : 0] led_mapping = { // @DEBUG was led_mapping_size-1
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
	reg [7:0] leds [0:max_led_array_counter] [0:2]; // 11 x 3 array of bytes ([7:0])
	reg [7:0] leds_nxt [0:max_led_array_counter] [0:2]; // 11 x 3 array of bytes ([7:0])
	reg [7:0] led_save [0:2];

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

	reg integer r;

	reg ledc_offset, ledc_offset_nxt;



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



	// @TODO - barely started
	function remap_led_color;
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
		for (l = 0; l < (max_led_array_counter + 1); l = l + 1) begin
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

		leds[9][2'b00] = 'h40; // black
		leds[9][2'b01] = 'h80;
		leds[9][2'b10] = 'hc0;

		leds[10][2'b00] = 'hc0; // black
		leds[10][2'b01] = 'h80;
		leds[10][2'b10] = 'h40;
	end



	always @* begin

		// PWM cycle counter- counts down
		if (clkdiv == 0) begin
			clkdiv_nxt = 'h2ff; // aka 3 * d256 - 1, will be count down! was 0
		end else begin
			clkdiv_nxt = clkdiv - 1;
		end


		// Clock divider pulse generator
		if (ctr == 1200000) begin // @DEBUG was originally 800000, whiel 200000 was good for twinkling
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


		/* @NOTE **** working twinkle ****

		// r = rngno[6:0] % 11; // get 0 - 10 // @NOTE too complicated?!?

		// r = (rngno[5:0] + 2) / 6; // @NOTE = 67 / 6 = ~0-11

		r = rngno[10 -:4]; // @NOTE 0 - 16 so sometimes it doesn't do anything (> 10)

		for (l = 0; l < (led_mapping_size + 1); l = l + 1) begin
			// @TODO do color mapping

			if (ctr_pulse && r == l) begin
				// @TODO ???? leds_nxt[l][clkdiv[9:8]] = rngno[7:0];
				leds_nxt[l][2'b00] = rngno[7:0];
				leds_nxt[l][2'b01] = rngno[15 -:8]; // @NOTE ex: [6*led +:6]
				leds_nxt[l][2'b10] = rngno[23 -:8];
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

	*/

	/* @NOTE non-working "cycle"
	if (ctr_pulse) begin
		for (l = led_mapping_size; l >= 0; l = l - 1) begin
		// @TODO do color mapping

				// led_save[2'b00] = leds_nxt[led_mapping_size][2'b00];
				// led_save[2'b01] = leds_nxt[led_mapping_size][2'b01];
				// led_save[2'b10] = leds_nxt[led_mapping_size][2'b10];

				leds_nxt[l][2'b00] = leds[l + 1][2'b00];
				leds_nxt[l][2'b01] = leds[l + 1][2'b01];
				leds_nxt[l][2'b10] = leds[l + 1][2'b10];

		end // for
	end // if (ctr_pulse)
	*/


	/*
	// "cycle"
	if (ctr_pulse) begin
		ledc_offset_nxt = 1;
		leds_nxt[]
	end // if (ctr_pulse)
	*/

	/*
	for (l = 0; l < led_mapping_size; l = l + 1) begin
		// @TODO do color mapping
		if (ctr_pulse) begin

				// led_save[2'b00] = leds_nxt[led_mapping_size][2'b00];
				// led_save[2'b01] = leds_nxt[led_mapping_size][2'b01];
				// led_save[2'b10] = leds_nxt[led_mapping_size][2'b10];

				leds_nxt[l][2'b00] = leds[l + 1][2'b00];
				leds_nxt[l][2'b01] = leds[l + 1][2'b01];
				leds_nxt[l][2'b10] = leds[l + 1][2'b10];

		end // if (ctr_pulse)
	end // for
	*/

		/*
		if (ctr_pulse) begin
			leds_nxt[led_mapping_size][2'b00] = rngno[7:0];
			leds_nxt[led_mapping_size][2'b01] = rngno[15 -:8]; // @NOTE ex: [6*led +:6]
			leds_nxt[led_mapping_size][2'b10] = rngno[23 -:8];
		end
		*/


		// test updating
		for (l = 0; l < (max_led_counter + 1); l = l + 1) begin
				leds_nxt[l][2'b00] = leds[l + ledc_offset][2'b00];
				leds_nxt[l][2'b01] = leds[l + ledc_offset][2'b01];
				leds_nxt[l][2'b10] = leds[l + ledc_offset][2'b10];
		end // for

		// set last "blank" LED
		if (ledc_offset) begin
			leds_nxt[max_led_counter][2'b00] = rngno[7:0];
			leds_nxt[max_led_counter][2'b01] = rngno[15 -:8];
			leds_nxt[max_led_counter][2'b10] = rngno[23 -:8];
		end



		if (ctr_pulse) begin
			ledc_offset_nxt = 1;
		end else begin
			ledc_offset_nxt = 0;
		end

		// this is just the pwm portion
		for (l = 0; l < (max_led_counter + 1); l = l + 1) begin
			if (clkdiv[7:0] < leds[l][clkdiv[9:8]]) begin // just compare the lower 8 bits
				ledc_nxt[l] = 1;
			end else begin
				ledc_nxt[l] = 0;
			end
		end // for


	end // always @*



	// Synchronous logic
	always @(posedge clk) begin

		clkdiv <= clkdiv_nxt;
		ctr <= ctr_nxt;
		ledc_offset <= ledc_offset_nxt;

		// set sink control
		for (s = 0; s < 3; s = s + 1) begin
			ledrgb[s] <= ledrgb_nxt[s];
		end

		// led changes
		for (l = 0; l < (max_led_counter + 1); l = l + 1) begin
			// set LED source control
			ledc[l] <= ledc_nxt[l + ledc_offset_nxt];

			// copy the LED array
			// @TODO only need to do when it changes
			for (s = 0; s < 3; s = s + 1) begin
				leds[l][s] <= leds_nxt[l  + ledc_offset_nxt][s];
			end
		end

		// "init"
		if (!rst_) begin
			clkdiv <= 'h2ff; // aka 3 * d256 - 1, will be count down! was 0
			ctr <= 0;
			ledc_offset <= 0; // @DEBUG the value other than 0
			// color_index <= 0;
		end

	end // always @(posedge clk)


endmodule









// @NOTE see http://rdsl.csit-sun.pub.ro/docs/PROIECTARE%20cu%20FPGA%20CURS/lecture6[1].pdf

module rng (
		input clk1,
		output reg [31:0] rngno
	);

	always @(posedge clk1) begin
		// @TODO

		rngno = rngno * 153 + rngno * 152 + 1;

		// x(n+1) = [ a.x(b) + b ] mod m
		// P(X) = x^153 + x^152 + 1 is a maximum-length feedback polynomial

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
