// Project entry point
module top (
	input  clk,
	input [7:0] nbtn,
	output [10:0] ledc,
	// output [7:0] pmod,
	output [29:0] genio, // An output reg foo is just shorthand for output foo_wire; reg foo; assign foo_wire = foo.

	/*
	input [29:0] genio_in,
	output reg [29:0] genio_out,
	output reg [29:0] genio_oe,
	*/
);

	// PCB D11 is schem LED10 which is pin K20 which is lpf "ledc[6]" SITE "K20"
	// PCB D12 is schem LED11 which is pin K19 which is lpft "ledc[7]" SITE "K19"    **** (ALSO "VIO" via 1K resistor)
	// PCB D13 is schem LED7 which is pin B20 which is lpf "ledc[8]" SITE "B20";
	// PCB D14 is schem LED8 which is pin B19 which is lpf "ledc[9]" SITE "B19";
	// PCB D15 is schem LED9 which is pin A18 which is lpf *** missing *** try "leda[3]"


	// Invert all buttons to make things easier
	wire [7:0] btn = ~nbtn;

	wire [29:0] gpio;

	assign genio = gpio;

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
		if (clkdiv == 1000000) begin // @DEBUG was 800000
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
			/*
			if (top_led_counter == max_top_led_counter) begin
				ledc[top_led_counter - 1] <= 0;
			*/
		end // if (clkdiv_pulse)



		// ledc[9] <= 1; // @DEBUG
		// ledc[8] <= 1; // @DEBUG

		// cycle through top LED's
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
