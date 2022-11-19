module meta_harden (
	input			clk_dst,      // Destination clock
	input			rst_dst,      // Reset - synchronous to destination clock
	input			signal_src,   // Asynchronous signal to be synchronized
	output reg		signal_dst    // Synchronized signal
);

	reg				signal_meta; 

	always @(posedge clk_dst)
		begin
			if (!rst_dst) begin
				signal_meta <= 1'b0;
				signal_dst  <= 1'b0;
			end
			else begin // if rst_dst
				signal_meta <= signal_src;
				signal_dst  <= signal_meta;
			end
		end // always
endmodule

module clk_div_1 (clk, reset, clk_1);
	input 			clk;
	input 			reset;
	output	reg 	clk_1 = 0;

	reg [25:0]		clk_cnt = 0;

	always @ (posedge clk) begin
		if (!reset) begin 
			clk_1 <= 0;
			clk_cnt <= 0;
		end
		else begin
			if (clk_cnt == 26'd49999999) begin
				clk_1 <= ~clk_1;
				clk_cnt <= 26'd0;
			end
			else begin
				clk_cnt <= clk_cnt + 1;
			end
		end
	end
endmodule

module clk_div_100 (clk, reset, clk_100);
	input 			clk;
	input 			reset;
	output	reg 	clk_100 = 0;

	reg [18:0]		clk_cnt = 0;

	always @ (posedge clk) begin
		if (!reset) begin 
			clk_100 <= 0;
			clk_cnt <= 0;
		end
		else begin
			if (clk_cnt == 19'd499999) begin
				clk_100 <= ~clk_100;
				clk_cnt <= 19'd0;
			end
			else begin
				clk_cnt <= clk_cnt + 1;
			end
		end
	end
endmodule


module clk_div_1k(clk, reset, clk_1k);
	input 			clk;
	input 			reset;
	output	reg 	clk_1k = 0;

	reg [15:0]		clk_cnt = 0;

	always @ (posedge clk) begin
		if (!reset) begin 
			clk_1k <= 0;
			clk_cnt <= 0;
		end
		else begin
			if (clk_cnt == 16'd49999) begin
				clk_1k <= ~clk_1k;
				clk_cnt <= 16'd0;
			end
			else begin
				clk_cnt <= clk_cnt + 1;
			end
		end
	end
	
endmodule


`timescale 1ns/100ps
module tb_clk_div(clk_pin, rst_pin, mid_pin, seg, digit);

	input  				clk_pin;
	input 				rst_pin;
	input				mid_pin;
	output reg [7:0]	digit;
	output reg [7:0]	seg;

	wire				clk_100;
	wire				clk_1k;
	wire				clk_1;

	reg 				reset;
	reg					pause;
	reg					blink;

	reg [3:0] 			semi[7:0];
	reg [3:0] 			bcd;
	reg [7:0]			selected;

	wire				clk_i;
	wire				rst_i;
	wire				rst_clk;
	wire				mid_i;
	wire				mid_clk;
		
	IBUF    IBUF_rst_i0    (.I (rst_pin),   .O (rst_i));
	IBUF    IBUF_btn_i0    (.I (mid_pin),   .O (mid_i));
	IBUF    IBUF_clk_i0    (.I (clk_pin),   .O (clk_i));

	meta_harden meta_harden_rst_i0 (
		.clk_dst      (clk_i),
		.rst_dst      (1'b1),    // No reset on the hardener for reset!
		.signal_src   (rst_i),
		.signal_dst   (rst_clk)
	);

	// And the button input
	meta_harden meta_harden_btn_i0 (
		.clk_dst      (clk_i),
		.rst_dst      (rst_clk),
		.signal_src   (mid_i),
		.signal_dst   (mid_clk)
	);
		
	clk_div_100	clk100	(clk_i, reset, clk_100);
	clk_div_1k	clk1k	(clk_i, reset, clk_1k);
	clk_div_1k	clk1	(clk_i, reset, clk_1);

	initial begin
	    digit = 8'b1000_0000;
		selected = 8'b1000_0000;
		pause = 1'b0;
		blink = 1'b0;
		semi[0] = 4'd0;
		semi[1] = 4'd0;
		semi[2] = 4'd0;
		semi[3] = 4'd0;
		semi[4] = 4'd0;
		semi[5] = 4'd0;
		semi[6] = 4'd0;
		semi[7] = 4'd0;
        #5820000	reset = 0;
		#112		reset = 1;
	end

	always @ (posedge clk_100) begin
		if (!rst_clk) begin
			semi[0] = 4'd0;
			semi[1] = 4'd0;
			semi[2] = 4'd0;
			semi[3] = 4'd0;
			semi[4] = 4'd0;
			semi[5] = 4'd0;
			semi[6] = 4'd0;
			semi[7] = 4'd0;
		end

		if (pause == 1'b0) begin
			semi[0] = semi[0] + 4'd1;
			if (semi[0] == 4'd10) begin
				semi[0] = 4'd0;
				semi[1] = semi[1] + 4'd1;
			end
			if (semi[1] == 4'd10) begin 
				semi[1] = 4'd0;
				semi[2] = semi[2] + 4'd1;
			end 
			if (semi[2] == 4'd10) begin 
				semi[2] = 4'd0;
				semi[3] = semi[3] + 4'd1;
			end 
			if (semi[3] == 4'd6) begin 
				semi[3] = 4'd0;
				semi[4] = semi[4] + 4'd1;
			end 
			if (semi[4] == 4'd10) begin
				semi[4] = 4'd0;
				semi[5] = semi[5] + 4'd1;
			end
			if (semi[5] == 4'd6) begin 
				semi[5] = 4'd0;
				semi[6] = semi[6] + 4'd1;
			end 
			if (semi[6] == 4'd10) begin 
				semi[6] = 4'd0;
				semi[7] = semi[7] + 4'd1;
			end 
			if (semi[7] == 4'd10) begin 
				semi[7] = 4'd0;
			end 
		end
	end 

	always @ (negedge mid_clk) begin
		pause = ~pause;
	end

	always @ (posedge clk_1) begin
		blink = ~blink;
	end
	
	always @ (posedge clk_1k) begin

		if (digit == 8'b0000_0001) digit = 8'b1000_0000;
		else digit = digit >> 1;

		case (digit) 
			8'b1000_0000: bcd = semi[7];
			8'b0100_0000: bcd = semi[6];
			8'b0010_0000: bcd = semi[5];
			8'b0001_0000: bcd = semi[4];
			8'b0000_1000: bcd = semi[3];
			8'b0000_0100: bcd = semi[2];
			8'b0000_0010: bcd = semi[1];
			8'b0000_0001: bcd = semi[0];
			default: bcd = 4'd10;
		endcase
		case (bcd)
			4'd0: seg = 8'b1111_1100;
			4'd1: seg = 8'b0110_0000;
			4'd2: seg = 8'b1101_1010;
			4'd3: seg = 8'b1111_0010;
			4'd4: seg = 8'b0110_0110;
			4'd5: seg = 8'b1011_0110;
			4'd6: seg = 8'b0011_1110;
			4'd7: seg = 8'b1110_0000;
			4'd8: seg = 8'b1111_1110;
			4'd9: seg = 8'b1110_0110;
			default: seg = 8'b0000_0000;
		endcase
		case (digit) 
			8'b0100_0000, 8'b0001_0000, 8'b0000_0100, 8'b0000_0001: seg[0] = 1'b1;
			default: seg[0] = 1'b0;
		endcase
		if ((digit == selected) && (blink == 1'b0)) seg = 8'b0000_0000;
	end

endmodule
