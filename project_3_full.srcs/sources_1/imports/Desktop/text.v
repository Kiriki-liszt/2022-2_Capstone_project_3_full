// 스위치 입력을 시스템 내부 클럭에 맞추어 준다. 
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

// 1Hz 클럭
module clk_div_1 (
	input 			clk,
	input 			reset,
	output	reg 	clk_1 = 0
);

	reg [25:0]		clk_cnt = 0;

	always @ (posedge clk) begin
		if (!reset) begin 
			clk_1 <= 0;
			clk_cnt <= 0;
		end
		else begin
			if (clk_cnt == 26'd49999999) begin // 반주기 : 50000000 -> 한주기 : 100,000,000 -> 100MHz to 1Hz
				clk_1 <= ~clk_1;
				clk_cnt <= 26'd0;
			end
			else begin
				clk_cnt <= clk_cnt + 1;
			end
		end
	end
endmodule

// 100Hz 클럭
module clk_div_100 (
	input 			clk,
	input 			reset,
	output	reg 	clk_100 = 0
);

	reg [18:0]		clk_cnt = 0;

	always @ (posedge clk) begin
		if (!reset) begin 
			clk_100 <= 0;
			clk_cnt <= 0;
		end
		else begin
			if (clk_cnt == 19'd499999) begin // 반주기 : 500000 -> 한주기 : 1,000,000 -> 100MHz to 100Hz
				clk_100 <= ~clk_100;
				clk_cnt <= 19'd0;
			end
			else begin
				clk_cnt <= clk_cnt + 1;
			end
		end
	end
endmodule


module clk_div_1k(
	input 			clk,
	input 			reset,
	output	reg 	clk_1k = 0
);

	reg [15:0]		clk_cnt = 0;

	always @ (posedge clk) begin
		if (!reset) begin 
			clk_1k <= 0;
			clk_cnt <= 0;
		end
		else begin
			if (clk_cnt == 16'd49999) begin // 반주기 : 50000 -> 한주기 : 100,000 -> 100MHz to 1,000Hz
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
	input  				clk_pin,		// 입력 핀
	input 				rst_pin,		// 리셋 핀
	input				mid_pin,		// 가운데 버튼
	input				left_pin,		// 왼쪽 버튼
	input				right_pin,		// 오른쪽 버튼
	input				up_pin,			// 위쪽 버튼
	input				down_pin,		// 아래쪽 버튼
	output reg [7:0]	digit,			// 출력한 숫자의 7-seg 위치
	output reg [7:0]	seg				// 출력할 숫자의 내용
);

	wire				clk_1;			// 1Hz 클럭
	wire				clk_100;		// 100Hz 클럭
	wire				clk_1k;			// 1000Hz 클럭

	reg 				reset;			// 다양한 클럭 만드는 용의 리셋
	reg					pause;			// 카운트 다운 중 일시정지
	reg					blink;			// 초기화 상태 시 깜박임
	reg					init;			// 초기화 상태
	reg					rst_before;		// 버튼을 뗄 데 쓰기 위해 저장하는 용
	reg					mid_before;
	reg					left_before;
	reg					right_before;
	reg					up_before;
	reg					down_before;
	reg					up, down;		// 숫자를 올리거나 내리기 위해 사용

	reg [3:0] 			semi[7:0];		// 각 자리의 숫자를 저장
	reg [3:0] 			bcd;			// 출력할 위치의 숫자 임시 저장
	reg [7:0]			selected;		// 초기화시 조작하는 숫자 겸 깜빡임
	reg [7:0]			able;			// 해당 자릿수 위로 0이 아닌 수가 하나라도 있다면 자리내림 가능
	reg [7:0] 			sub;			// 아래에서 하나 빼서 해당 자리수에 대해 업데이트가 필요한가?

	wire				clk_i;					// 입력 버퍼를 통과한 시스템 클럭
	wire				rst_i,		rst_clk;	// 상기한 클럭에 동기화 된 버튼 입력들
	wire				mid_i,		mid_clk;
	wire				left_i, 	left_clk;
	wire				right_i,	right_clk;
	wire				up_i,		up_clk;
	wire				down_i,		down_clk;
	
	// 입력 버퍼
	IBUF	IBUF_clk_i0		(.I (clk_pin),		.O (clk_i));
	IBUF	IBUF_rst_i0		(.I (rst_pin),		.O (rst_i));
	IBUF	IBUF_mid_i0		(.I (mid_pin),		.O (mid_i));
	IBUF	IBUF_left_i0	(.I (left_pin),		.O (left_i));
	IBUF	IBUF_right_i0	(.I (right_pin),	.O (right_i));
	IBUF	IBUF_up_i0		(.I (up_pin),		.O (up_i));
	IBUF	IBUF_down_i0	(.I (down_pin),		.O (down_i));

	// 입력 버튼을 클럭에 동기화 
	meta_harden	meta_harden_rst_i0		(	.clk_dst(clk_i),	.rst_dst(1'b1),		.signal_src(rst_i),		.signal_dst(rst_clk));
	meta_harden	meta_harden_mid_i0		(	.clk_dst(clk_i),	.rst_dst(rst_clk),	.signal_src(mid_i),		.signal_dst(mid_clk));
	meta_harden	meta_harden_left_i0		(	.clk_dst(clk_i),	.rst_dst(rst_clk),	.signal_src(left_i),	.signal_dst(left_clk));
	meta_harden meta_harden_right_i0	(	.clk_dst(clk_i),	.rst_dst(rst_clk),	.signal_src(right_i),	.signal_dst(right_clk));
	meta_harden meta_harden_up_i0		(	.clk_dst(clk_i),	.rst_dst(rst_clk),	.signal_src(up_i),		.signal_dst(up_clk));
	meta_harden meta_harden_down_i0		(	.clk_dst(clk_i),	.rst_dst(rst_clk),	.signal_src(down_i),	.signal_dst(down_clk));

	// 다양한 주파수의 클럭 생성
	clk_div_100	clk100	(clk_i, reset, clk_100);
	clk_div_1k	clk1k	(clk_i, reset, clk_1k);
	clk_div_1	clk1	(clk_i, reset, clk_1);

	// 초기화 
	initial begin
	    digit			= 8'b1000_0000;		// 가장 첫 번째 자리
		selected		= 8'b1000_0000;		// 시작 위치
		rst_before		= rst_clk;			// 각 입력 버튼의 이전 상태 저장
		mid_before		= mid_clk;
		left_before 	= left_clk;
		right_before	= right_clk;
		up_before 		= up_clk;
		down_before		= down_clk;
		able			= 8'b1111_1111;		// 자리 내림 가능? -> 처기 상태를 Max로 두었기 때문에 모두 가능
		sub 			= 8'b0000_0000;		// 아직 빼기 시작 안함
		pause			= 1'b1;				// 일시정지 상태로 시작
		blink			= 1'b1;				// 초기 상태이므로 깜빡이 한다. 
		init			= 1'b1;				// 초기 상태로 지정
		up				= 1'b0;				// 숫자를 하나 올려야 하나?
		down			= 1'b0;				// 숫자를 하나 내려야 하나?
		semi[0]			= 4'd9;				// 초기 표시값
		semi[1]			= 4'd9;
		semi[2]			= 4'd9;
		semi[3]			= 4'd5;
		semi[4]			= 4'd9;
		semi[5]			= 4'd5;
		semi[6]			= 4'd9;
		semi[7]			= 4'd9;
        #5820000	reset = 0;
		#112		reset = 1;
	end

	always @ (posedge clk_100) begin

		// 일시정지 버튼을 누른 상태에서 떼었다면
		if (mid_before && ~mid_clk) begin
			pause = ~pause;						// 일시정지 상태 반전
		end

		// 리셋 버튼을 떼었다면 -> 리셋
		if (rst_before && ~rst_clk) begin
			rst_before		= rst_clk;			// 상기한 초기 상태 지정
			left_before 	= left_clk;
			right_before	= right_clk;
			up_before 		= up_clk;
			down_before		= down_clk;
			able			= 8'b1111_1111;
			selected		= 8'b1000_0000;
			sub 			= 8'b0;
			pause			= 1'b1;
			blink			= 1'b1;
			init			= 1'b1;
			up				= 1'b0;
			down			= 1'b0;
			semi[0]			= 4'd9;
			semi[1]			= 4'd9;
			semi[2]			= 4'd9;
			semi[3]			= 4'd5;
			semi[4]			= 4'd9;
			semi[5]			= 4'd5;
			semi[6]			= 4'd9;
			semi[7]			= 4'd9;
		end
		
		if (init) begin
			// 왼쪽 버튼을 떼었다면
			if (left_before && ~left_clk) begin
				if (selected == 8'b1000_0000) selected = 8'b0000_0001;	// 현재 선택된 위치가 가장 왼쪽이라면 그 다음 위치는 가장 오른쪽이다. 
				else selected = selected << 1;							// 아니라면 하나 왼쪽으로
			end
			if (right_before && ~right_clk) begin
				if (selected == 8'b0000_0001) selected = 8'b1000_0000;	// 현재 선택된 위치가 가장 오른쪽이라면 그 다음 위치는 가장 왼쪽이다. 
				else selected = selected >> 1;							// 아니라면 하나 오른쪽으로
			end
			if (up_before && ~up_clk) begin								// 위로 버튼을 눌렀다가 떼었다면 
				up = 1'b1;												// 숫자 하나 올리기
			end
			if (down_before && ~down_clk) begin							// 아래로 버튼을 눌렀다가 떼었다면
				down = 1'b1;											// 숫자 하나 내리기
			end

			case (selected) 											// 현재 선택된 자리에 대해
				8'b1000_0000: begin
					if (up) begin										// 숫자를 올려야 한다면
						if (semi[7] == 4'd9) semi[7] = 4'd0;			// 그리거 그게 만약 해당 자리의 최대 숫자라면 0으로 내려라
						else semi[7] = semi[7] + 4'd1;					// 아니라면 하나 올려라
					end
					else if (down) begin								// 숫자를 내려야 한다면
						if (semi[7] == 4'd0) semi[7] = 4'd9;			// 그리거 그게 만약 0이면 해당 자리위 최대 숫자로 올려라
						else semi[7] = semi[7] - 4'd1;;					// 아니라면 하나 내려라
					end
				end
				8'b0100_0000: begin
					if (up) begin
						if (semi[6] == 4'd9) semi[6] = 4'd0;
						else semi[6] = semi[6] + 4'd1;
					end
					else if (down) begin
						if (semi[6] == 4'd0) semi[6] = 4'd9;
						else semi[6] = semi[6] - 4'd1;
					end
				end
				8'b0010_0000: begin
					if (up) begin
						if (semi[5] == 4'd5) semi[5] = 4'd0;
						else semi[5] = semi[5] + 4'd1;
					end
					else if (down) begin
						if (semi[5] == 4'd0) semi[5] = 4'd5;
						else semi[5] = semi[5] - 4'd1;
					end
				end
				8'b0001_0000: begin
					if (up) begin
						if (semi[4] == 4'd9) semi[4] = 4'd0;
						else semi[4] = semi[4] + 4'd1;
					end
					else if (down) begin
						if (semi[4] == 4'd0) semi[4] = 4'd9;
						else semi[4] = semi[4] - 4'd1;
					end
				end
				8'b0000_1000: begin
					if (up) begin
						if (semi[3] == 4'd5) semi[3] = 4'd0;
						else semi[3] = semi[3] + 4'd1;
					end
					else if (down) begin
						if (semi[3] == 4'd0) semi[3] = 4'd5;
						else semi[3] = semi[3] - 4'd1;
					end
				end
				8'b0000_0100: begin
					if (up) begin
						if (semi[2] == 4'd9) semi[2] = 4'd0;
						else semi[2] = semi[2] + 4'd1;
					end
					else if (down) begin
						if (semi[2] == 4'd0) semi[2] = 4'd9;
						else semi[2] = semi[2] - 4'd1;
					end
				end
				8'b0000_0010: begin
					if (up) begin
						if (semi[1] == 4'd9) semi[1] = 4'd0;
						else semi[1] = semi[1] + 4'd1;
					end
					else if (down) begin
						if (semi[1] == 4'd0) semi[1] = 4'd9;
						else semi[1] = semi[1] - 4'd1;
					end
				end
				8'b0000_0001: begin
					if (up) begin
						if (semi[0] == 4'd9) semi[0] = 4'd0;
						else semi[0] = semi[0] + 4'd1;
					end
					else if (down) begin
						if (semi[0] == 4'd0) semi[0] = 4'd9;
						else semi[0] = semi[0] - 4'd1;
					end
				end
			endcase

			if(~pause) begin 						// 초기화가 끝나고 일시정지를 푼다면
				init = 1'b0;						// 초기화 상태 해제
				blink = 1'b0;						// 깜빡임도 꺼라
			end 

			rst_before		= rst_clk;
			left_before 	= left_clk;
			right_before	= right_clk;
			up_before 		= up_clk;
			down_before		= down_clk;
			up				= 1'b0;
			down			= 1'b0;
		end

		sub = 8'b0;									// 일단 모든 자리에 내래 자리내림 없다고 초기화

		// 각 자리에 대해 해당 자리보다 위에 0이 아닌 숫자가 있다면 아직 자리내림이 가능하다는 뜻이다. 
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
	
		// 일시정지 상태가 아닐 때
		if (pause == 1'b0) begin

			// 각 자리에 대해 반복한다. 
			if ((semi[0] == 4'd0)) begin					// 만약 가장 오른쪽 자리 수가 0이라면 
				if (able[0]) begin							// 그리고 자리내림이 가능하다면
					semi[0] = 4'd9;							// 0을 9로 바꾸고
					sub[1] = 1'b1;							// 하나 위 자리수에다가 자리내림 요청을 한다. 
				end
				else begin									// 자리내림이 불가능하다면
					sub[1] = 1'b0;							// 그대로 둔다. 
				end
			end
			else begin 										// 가장 오른쪽 자리 수가 0이 아니라면 
				semi[0] = semi[0] - 4'b1;					// 하나 내리고 
				sub[1] = 1'b0;								// 자리내림 요청을 하지 않는다. 
			end

			if (sub[1]) begin								// 만약 자리내림 요청이 있다면
				if ((semi[1] == 4'd0) && able[1]) begin		// 그리고 해당 자리가 0이고 그 위로 자리 내림이 가능하다면 
					semi[1] = 4'd9;							// 0을 9로 올리고
					sub[2] = 1'b1;							// 자리내림 신청
				end
				else begin 									// 해당 자리가 0이 아니라면
					semi[1] = semi[1] - 4'b1;				// 숫자 하나 빼고
					sub[2] = 1'b0;							// 자리내림 요청을 하지 않는다. 
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
				if ((semi[7] != 4'd0)) begin
					semi[7] = semi[7] - 4'b1;
				end
			end
		end

		mid_before		= mid_clk;								// 현재 버튼의 상태를 다음 클럭을 위해 저장한다. 
	end 
	
	always @ (posedge clk_1k) begin

		if (digit == 8'b0000_0001) digit = 8'b1000_0000;		// 1/1000초마다 출력하는 자리응 하나씩 오른족으로 옮길 것이다. 
		else digit = digit >> 1;

		case (digit) 											// 현재 출력하는 자리에 따라 
			8'b1000_0000: bcd = semi[7];						// seg 계산을 위해 bcd 값을 해당 자리의 숫자로 업데이트 한다. 
			8'b0100_0000: bcd = semi[6];
			8'b0010_0000: bcd = semi[5];
			8'b0001_0000: bcd = semi[4];
			8'b0000_1000: bcd = semi[3];
			8'b0000_0100: bcd = semi[2];
			8'b0000_0010: bcd = semi[1];
			8'b0000_0001: bcd = semi[0];
			default: bcd = 4'd10;
		endcase
		case (bcd)												// bcd 값에 따라 논리적 수를 물리적 segment 값으로 매칭한다. 
			4'd0:		seg = 8'b1111_1100;
			4'd1:		seg = 8'b0110_0000;
			4'd2:		seg = 8'b1101_1010;
			4'd3:		seg = 8'b1111_0010;
			4'd4:		seg = 8'b0110_0110;
			4'd5:		seg = 8'b1011_0110;
			4'd6:		seg = 8'b0011_1110;
			4'd7:		seg = 8'b1110_0000;
			4'd8:		seg = 8'b1111_1110;
			4'd9:		seg = 8'b1110_0110;
			4'd15:		seg = 8'b0000_0010;
			default:	seg = 8'b0000_0000;
		endcase
		case (digit) 											// 시, 분, 초, 세미초 구분자
			8'b0100_0000, 8'b0001_0000, 8'b0000_0100, 8'b0000_0001: seg[0] = 1'b1;
			default: seg[0] = 1'b0;
		endcase

		if ((digit == selected) && blink && clk_1) begin		// 깜빡임이 켜져 있다면 1초 단위로 깜빡여라
			seg = 8'b0000_0000;
		end
	end

endmodule
