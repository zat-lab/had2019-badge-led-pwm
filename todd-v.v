// Project entry point
module top (
	input  clk,
	// input [7:0] nbtn, // @NOTE removed from sample as unconstrained with prod.lpf
	output [10:0] ledc,
	// output [3:0] leda,
	// output [7:0] pmod,
);

/* CORRECT AS OF had19_prod.lpf
	PCB		Schem		Pin/Site	Logical		color
	D5		LED1		E3				ledc[0]		RED
	D6		LED2		D3				ledc[1]		BLUE
	D7		LED3		C3				ledc[2]		RED
	D8		LED4		C4				ledc[3]		BLUE
	D9		LED5		C2				ledc[4]		RED
	D10		LED6		B1				ledc[5]		BLUE


	D11 	LED10		K20				ledc[6]
	D12		LED11		K19				ledc[7]		GREEN
	D13		LED7		B20				ledc[8]		GREEN
	D14		LED8		B19				ledc[9]		RED
	D15 	LED9		A18				ledc[10]	RED
*/

	// ******* BELOW ARE NOT CORRECT *******

	// PCB D12 is schem LED11 which is pin K19 which is lpft "ledc[7]" SITE "K19"  **** ALSO PULLED UP via 1K resistor to "VIO" (3.3V)
	// PCB D13 is schem LED7 which is pin B20 which is lpf "ledc[8]" SITE "B20";
	// PCB D14 is schem LED8 which is pin B19 which is lpf "ledc[9]" SITE "B19";
	// PCB D15 is schem LED9 which is pin A18 which is lpf *** missing *** try "leda[3]"


	reg [7:0] top_led_counter = 0;
	parameter max_top_led_counter = 5;

	reg [7:0] side_led_counter = 0;
	parameter max_side_led_counter = 4;

	// Clock divider and pulse registers
	reg [20:0] clkdiv = 0;
	reg clkdiv_pulse = 0;
	reg running = 0;

	// Synchronous logic
	always @(posedge clk) begin
		// Clock divider pulse generator
		if (clkdiv == 2000000) begin // @DEBUG was 800000
			clkdiv <= 0;
			clkdiv_pulse <= 1;
		end else begin
			clkdiv <= clkdiv + 1;
			clkdiv_pulse <= 0;
		end

		// cycle through top LED's

		if (clkdiv_pulse) begin
			if (top_led_counter > 0) begin
				ledc[top_led_counter - 1] <= 0;
				ledc[top_led_counter] <= 1;
			end else begin
				ledc[max_top_led_counter] <= 0;
				ledc[top_led_counter] <= 1;
			end

			if (top_led_counter == max_top_led_counter) begin
				top_led_counter <= 0;
			end else begin
				top_led_counter <= top_led_counter + 1;
			end
		end // if (clkdiv_pulse)



		// @NOTE new correct code
		// ledc[6] <= 1; // @DEBUG does nothing?! needs pads jumped!
		// ledc[7] <= 1; // @DEBUG OK D12 GREEN
		// ledc[8] <= 1; // @DEBUG OK D13 GREEN
		// ledc[9] <= 1; // @DEBUG OK D14 GREEN
		// ledc[10] <= 1; // @DEBUG OK D15 RED

		// cycle through top LED's - @TODO needs to be changed to reflect reality
		/*
		if (clkdiv_pulse) begin
			case (side_led_counter)
				0: begin
						leda[3] <= 0;
						ledc[6] <= 1;
					end
				1: begin
						ledc[6] <= 0;
						ledc[7] <= 1;
					end
				2: begin
						ledc[7] <= 0;
						ledc[8] <= 1;
					end
				3: begin
						ledc[8] <= 0;
						ledc[9] <= 1;
					end
				4: begin
						ledc[9] <= 0;
						leda[3] <= 1;
					end
			endcase

			side_led_counter <= side_led_counter + 1;

			if (side_led_counter > max_side_led_counter) begin
				side_led_counter <= 0;
			end

		end // if (clkdiv_pulse)
		*/

	end // always @(posedge clk)



endmodule
