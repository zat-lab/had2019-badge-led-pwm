// Project entry point
module top (
	input  clk,
	// input [7:0] nbtn, // @NOTE removed from sample as unconstrained with prod.lpf
	output reg [10:0] ledc,
	output reg [2:0] ledrgb
	// output [3:0] leda,
	// output [7:0] pmod,
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

	reg [0:2] color_index, color_index_nxt; // @DEBUG was = 0;

	// Clock divider and pulse registers
	reg [20:0] clkdiv, clkdiv_nxt; // @DEBUG was = 0;
	// reg clkdiv_pulse = 0;

	reg [2:0] ledrgb_nxt;

	reg [7:0] value; // single-color (of RGB) "PWM" value

	// general counters
	reg integer l;
	reg integer c;
	reg integer s;

	reg [24:0] cntr;


	// ledrgb[0] <= 0; // @DEBUG works (as "normal")
	// ledrgb[1] <= 0; // @DEBUG 0 + 1 yeilds blues into teal?
	// ledrgb[2] <= 1; // @DEBUG 0 + 1 + 2 = all red cause it hogs all the current`



	initial begin
		// clear leds array
		for (l = 0; l < (led_mapping_size + 1); l = l + 1) begin
			for (c = 0; c < 3; c = c + 1) begin
				leds[l][c] = 0;
			end
		end
	end


	always @(posedge clk) begin
		cntr <= cntr + 1;
	end


	always @* begin
		/* @DEBUG this results in
		// ERROR: timing analysis failed due to presence of combinatorial loops, incomplete specification of timing ports, etc.
		if (clkdiv == 255) begin // @DEBUG was 2000000 (for cycle code)
			clkdiv_nxt <= 0;

			// cycle color
			if (color_index == 2) begin
				color_index_nxt <= 0;
			end else begin
				color_index_nxt <= color_index + 1;
			end;
		end else begin
			clkdiv_nxt <= clkdiv + 1;
		end
		*/

		// cycle color
		if (color_index == 2) begin
			color_index_nxt <= 0;
		end else begin
			color_index_nxt <= color_index + 1;
		end;

		// Clock divider pulse generator
		if (clkdiv == 256) begin // @DEBUG was 2000000 (for cycle code)
			clkdiv_nxt <= 0;
			// clkdiv_pulse <= 1;
		end else begin
			clkdiv_nxt <= clkdiv + 1;
			// clkdiv_pulse <= 0;
		end

		// set cycle of color "sinks"
		// @TODO was color_index below
		case (cntr[24:23])
			0: begin
					ledrgb_nxt[0] <= 1;
					ledrgb_nxt[1] <= 0;
					ledrgb_nxt[2] <= 0;
				end
			1: begin
					ledrgb_nxt[0] <= 0;
					ledrgb_nxt[1] <= 1;
					ledrgb_nxt[2] <= 0;
				end
			2: begin
					ledrgb_nxt[0] <= 0;
					ledrgb_nxt[1] <= 0;
					ledrgb_nxt[2] <= 1;
				end
			default: begin
					ledrgb_nxt[0] <= 0;
					ledrgb_nxt[1] <= 0;
					ledrgb_nxt[2] <= 0;
				end
			endcase

	end

	// Synchronous logic
	always @(posedge clk) begin

		// @DEBUG testing LED colors below
		leds[0][2'b00] <= 'hff;
		leds[1][2'b01] <= 'hff;
		leds[2][2'b10] <= 'hff;


		color_index <= color_index_nxt;
		clkdiv <= clkdiv_nxt;


		for (s = 0; s < 3; s = s + 1) begin
			ledrgb[s] <= ledrgb_nxt[s];
		end

		// or (ii=0; ii<6; ii=ii+1)
		for (l = 0; l < (led_mapping_size + 1); l = l + 1) begin
			// @TODO do color mapping
			value = leds[l][color_index]; // @NOTE was <= which was wrong!

			// ledc[i] <= 1; // @DEBUG it does something!
			if (clkdiv_nxt <= value) begin
				ledc[l] <= 1;
			end else begin
				ledc[l] <= 0;
			end

		end // for

		if (!rst_) begin
			clkdiv <= 0;
			color_index <= 0;
		end


		/*
		// cycle through top LED's
		if (clkdiv_pulse) begin
			if (top_led_counter > min_top_led_counter) begin
				ledc[top_led_counter - 1] <= 0;
				ledc[top_led_counter] <= 1;
			end else begin
				ledc[max_top_led_counter] <= 0;
				ledc[top_led_counter] <= 1;
			end

			if (top_led_counter == max_top_led_counter) begin
				top_led_counter <= min_top_led_counter;
			end else begin
				top_led_counter <= top_led_counter + 1;
			end
		end // if (clkdiv_pulse)


		// cycle through side LED's
		if (clkdiv_pulse) begin
			if (side_led_counter > min_side_led_counter) begin
				ledc[side_led_counter - 1] <= 0;
				ledc[side_led_counter] <= 1;
			end else begin
				ledc[max_side_led_counter] <= 0;
				ledc[side_led_counter] <= 1;
			end

			if (side_led_counter == max_side_led_counter) begin
				side_led_counter <= min_side_led_counter;
			end else begin
				side_led_counter <= side_led_counter + 1;
			end
		end // if (clkdiv_pulse)

		*/


	end // always @(posedge clk)



endmodule
