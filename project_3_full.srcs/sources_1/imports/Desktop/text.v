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
module tb_clk_div(
	input  				clk_pin,
	input 				rst_pin,
	input				mid_pin,
	input				left_pin,
	input				right_pin,
	input				up_pin,
	input				down_pin,
	output reg [7:0]	digit,
	output reg [7:0]	seg
);

	wire				clk_100;
	wire				clk_1k;
	wire				clk_1;

	reg 				reset;
	reg					pause;
	reg					blink;

	reg [3:0] 			semi[7:0];
	reg [3:0] 			bcd;
	reg [7:0]			selected;
	reg [7:0]			able;
	reg [7:0] 			sub;

	wire				clk_i;
	wire				rst_i;
	wire				rst_clk;
	wire				mid_i;
	wire				mid_clk;
	wire				left_i;
	wire				left_clk;
	wire				right_i;
	wire				right_clk;
	wire				up_i;
	wire				up_clk;
	wire				down_i;
	wire				down_clk;
	
	IBUF	IBUF_clk_i0		(.I (clk_pin),		.O (clk_i));
	IBUF	IBUF_rst_i0		(.I (rst_pin),		.O (rst_i));
	IBUF	IBUF_mid_i0		(.I (mid_pin),		.O (mid_i));
	IBUF	IBUF_left_i0	(.I (left_pin),		.O (left_i));
	IBUF	IBUF_right_i0	(.I (right_pin),	.O (right_i));
	IBUF	IBUF_up_i0		(.I (up_pin),		.O (up_i));
	IBUF	IBUF_down_i0	(.I (down_pin),		.O (down_i));

	meta_harden meta_harden_rst_i0 (
		.clk_dst      (clk_i),
		.rst_dst      (1'b1),    // No reset on the hardener for reset!
		.signal_src   (rst_i),
		.signal_dst   (rst_clk)
	);

	// And the button input
	meta_harden meta_harden_mid_i0 (
		.clk_dst      (clk_i),
		.rst_dst      (rst_clk),
		.signal_src   (mid_i),
		.signal_dst   (mid_clk)
	);

	meta_harden meta_harden_left_i0 (
		.clk_dst      (clk_i),
		.rst_dst      (rst_clk),
		.signal_src   (left_i),
		.signal_dst   (left_clk)
	);

	meta_harden meta_harden_right_i0 (
		.clk_dst      (clk_i),
		.rst_dst      (rst_clk),
		.signal_src   (right_i),
		.signal_dst   (right_clk)
	);

	meta_harden meta_harden_up_i0 (
		.clk_dst      (clk_i),
		.rst_dst      (rst_clk),
		.signal_src   (up_i),
		.signal_dst   (up_clk)
	);

	meta_harden meta_harden_down_i0 (
		.clk_dst      (clk_i),
		.rst_dst      (rst_clk),
		.signal_src   (down_i),
		.signal_dst   (downs_clk)
	);

		
	clk_div_100	clk100	(clk_i, reset, clk_100);
	clk_div_1k	clk1k	(clk_i, reset, clk_1k);
	clk_div_1k	clk1	(clk_i, reset, clk_1);

	initial begin
	    digit = 8'b1000_0000;
		selected = 8'b1000_0000;
		able = 8'b1111_1111;
		pause = 1'b0;
		blink = 1'b0;
		semi[0] = 4'd9;
		semi[1] = 4'd9;
		semi[2] = 4'd9;
		semi[3] = 4'd5;
		semi[4] = 4'd9;
		semi[5] = 4'd5;
		semi[6] = 4'd9;
		semi[7] = 4'd9;
		sub = 8'b0;
        #5820000	reset = 0;
		#112		reset = 1;
	end

	always @ (negedge mid_clk) begin
		pause = ~pause;
	end

	always @ (posedge clk_1) begin
		blink = ~blink;
	end

	always @ (posedge clk_100) begin
		if (!rst_clk) begin
			semi[0] = 4'd0;
			semi[1] = 4'd0;
			semi[2] = 4'd1;
			semi[3] = 4'd0;
			semi[4] = 4'd0;
			semi[5] = 4'd0;
			semi[6] = 4'd0;
			semi[7] = 4'd0;
		end

		sub = 8'b0;

		if (semi[7])			able[6] = 1'b1;
		else					able[6] = 1'b0;
		if (able[6] || semi[6])	able[5] = 1'b1;
		else					able[5] = 1'b0;
		if (able[5] || semi[5])	able[4] = 1'b1;
		else					able[4] = 1'b0;
		if (able[4] || semi[4])	able[3] = 1'b1;
		else					able[3] = 1'b0;
		if (able[3] || semi[3])	able[2] = 1'b1;
		else					able[2] = 1'b0;
		if (able[2] || semi[2])	able[1] = 1'b1;
		else					able[1] = 1'b0;
		if (able[1] || semi[1])	able[0] = 1'b1;
		else					able[0] = 1'b0;
		if (able[0] || semi[0]) able[0] = 1'b0;
	
		if (pause == 1'b0) begin
			if ((semi[0] == 4'd0) && able[0]) begin
				if (able[0]) begin
					semi[0] = 4'd9;
					sub[1] = 1'b1;
				end
			end
			else begin 
				semi[0] = semi[0] - 4'b1;
				sub[2] = 1'b0;
			end
			if (sub[1]) begin
				if ((semi[1] == 4'd0) && able[1]) begin
					semi[1] = 4'd9;
					sub[2] = 1'b1;
				end
				else begin 
					semi[1] = semi[1] - 4'b1;
					sub[2] = 1'b0;
				end
			end
			if (sub[2]) begin
				if ((semi[2] == 4'd0) && able[2]) begin
					semi[2] = 4'd9;
					sub[3] = 1'b1;
				end
				else begin 
					semi[2] = semi[2] - 4'b1;
					sub[3] = 1'b0;
				end
			end
			if (sub[3]) begin
				if ((semi[3] == 4'd0) && able[3]) begin
					semi[3] = 4'd5;
					sub[4] = 1'b1;
				end
				else begin 
					semi[3] = semi[3] - 4'b1;
					sub[4] = 1'b0;
				end
			end
			if (sub[4]) begin
				if ((semi[4] == 4'd0) && able[4]) begin
					semi[4] = 4'd9;
					sub[5] = 1'b1;
				end
				else begin 
					semi[4] = semi[4] - 4'b1;
					sub[5] = 1'b0;
				end
			end
			if (sub[5]) begin
				if ((semi[5] == 4'd0) && able[5]) begin
					semi[5] = 4'd5;
					sub[6] = 1'b1;
				end
				else begin 
					semi[5] = semi[5] - 4'b1;
					sub[6] = 1'b0;
				end
			end
			if (sub[6]) begin
				if ((semi[6] == 4'd0) && able[6]) begin
					semi[6] = 4'd9;
					sub[7] = 1'b1;
				end
				else begin 
					semi[6] = semi[6] - 4'b1;
					sub[7] = 1'b0;
				end
			end
			if (sub[7]) begin
				if ((semi[7] == 4'd0) && able[7]) begin
					semi[7] = 4'd9;
				end
				else begin 
					semi[7] = semi[7] - 4'b1;
				end
			end
		end
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
