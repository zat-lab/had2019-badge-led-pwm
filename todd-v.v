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
	// Invert all buttons to make things easier
	wire [7:0] btn = ~nbtn;

	wire [29:0] gpio;

	assign genio = gpio;

	reg [7:0] io_counter = 0;

	parameter max_io_counter = 5;

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

		// Timer counter
		if (clkdiv_pulse) begin
			io_counter <= io_counter + 1;

			// display_value <= display_value_inc;
			if (io_counter > 0) begin
				ledc[io_counter - 1] <= 0;
			end else begin
				ledc[max_io_counter] <= 0;
			end

			if (io_counter > max_io_counter) begin
				io_counter <= 0;
			end

			ledc[io_counter] <= 1;
		end

	end


	/*
	always begin
		gpio[20] <= 1; // "genio[20]" SITE "D11"
		gpio[21] <= 1; // "genio[21]" SITE "C11"
		gpio[22] <= 1; // "genio[22]" SITE "B11"
		gpio[23] <= 1; // "genio[23]" SITE "A11"
	end
	*/



	/*
	wire [29:0] gpio;
	assign genio = gpio;

	always @(*) begin
		gpio[20] = 1; // "genio[20]" SITE "D11"
		gpio[21] = 1; // "genio[21]" SITE "C11"
		gpio[22] = 1; // "genio[22]" SITE "B11"
		gpio[23] = 1; // "genio[23]" SITE "A11"
	end
	*/

	/*
	// enable output
	assign genio_oe[20] = 1; // "genio[20]" SITE "D11"
	assign genio_oe[21] = 1; // "genio[21]" SITE "C11"
	assign genio_oe[22] = 1;	// "genio[22]" SITE "B11"
	assign genio_oe[23] = 1;	// "genio[23]" SITE "A11"

	// set output
	assign genio_out[20] = 0; // "genio[20]" SITE "D11"
	assign genio_out[21] = 0; // "genio[21]" SITE "C11"
	assign genio_out[22] = 0;	// "genio[22]" SITE "B11"
	assign genio_out[23] = 0;	// "genio[23]" SITE "A11"
	// @TODO 5th LED?
	*/

	/*
	assign genio[20] = 1; // "genio[20]" SITE "D11"
	assign genio[21] = 1; // "genio[21]" SITE "C11"
	assign genio[22] = 1;	// "genio[22]" SITE "B11"
	assign genio[23] = 1;	// "genio[23]" SITE "A11"
	*/



	/*

	// Display value register and increment bus
	reg [7:0] display_value = 0;
	wire [7:0] display_value_inc;

	// Lap registers
	reg [7:0] lap_value = 0;
	reg [4:0] lap_timeout = 0;

	// Clock divider and pulse registers
	reg [20:0] clkdiv = 0;
	reg clkdiv_pulse = 0;
	reg running = 0;

	// Combinatorial logic
	assign ledc[0] = !nbtn[0];									// Not operator example
	assign ledc[1] = btn[1] || btn[2];							// Or operator example
	assign ledc[2] = btn[2] ^ btn[3];							// Xor Operator example
	assign ledc[3] = btn[3] && !nbtn[0];						// And operator example
	assign ledc[4] = (btn[1] + btn[2] + btn[3] + 2'b00) >> 1;	// Addition and shift example


	*/


endmodule
