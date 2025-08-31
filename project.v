  module project(input clk, left, right, start, rst, output reg [7:0] ROW, COL,
	output reg [7:0] seg7_3, seg7_2, seg7_1, output reg [4:0] state, next_state);
	
	reg [1:0] matrix[7:0][7:0];// X_Y
	//////////////////////////
	reg [9:0] score;
	reg [3:0] BCD_1;
	reg [3:0] BCD_2;
	reg [3:0] BCD_3;
	reg [9:0] temp;
	//////////////////////////////
	reg [2:0] player_X; // X_Y
	reg [2:0] player_Y;
	reg player_clk;
	reg [3:0] jump_count;
	reg jump;
	reg [7:0] player_clk_count;
	reg move_finish;
	/////////////////////////////
	//debug
	//reg [7:0] matrix0, matrix1, matrix2, matrix3, matrix4, matrix5, matrix6, matrix7;
	/////////////////////////////
	//reg [4:0] state, next_state;
	reg [2:0] rand_num_3;//use for generate random stair
	reg [4:0] rand_num_5;//
	reg end_game;
	reg [7:0] ROW_REG;
	reg [2:0] generate_fg; // 4: on the disappear stair, 3: on the solid stair, and move down once,
	//2: on the solid stair and move down one, 
	//1: generate a new stair on the top, zero: finish the generation
	reg [4:0] disappear_probility;//disappear_probility
	reg [2:0] display_count;
	reg display;
	reg [7:0] display_clk;
	parameter S_IDLE = 0, S_INITIAL_GAME = 1, 
	S_GENERATE = 2, S_MOVE = 3, S_MOVE_2 = 4,
	S_NEW_STAIR = 5, S_RST = 6;
	parameter BLANK = 8'b00000000, ZERO = 8'b11000000, ONE = 8'b11111001, TWO = 8'b10100100, THREE = 8'b10110000,
	FOUR = 8'b10011001, FIVE = 8'b10010010, SIX = 8'b10000010, SEVEN = 8'b11111000, EIGHT = 8'b10000000,
	NINE = 8'b10010000;
	parameter PLAYER_MOVE_STOP = 150;
	integer i, j, k, x;
	
	initial begin
		score <= 0;
		for (i = 0; i < 8; i = i + 1) begin
			for (j = 0; j < 8; j = j + 1) begin
				matrix[i][j] <= 2'b00; 
			end
		end
		disappear_probility <= 31;
		end_game <= 0;
		jump <= 1;
		move_finish <= 0;
		rand_num_3 <= 1;
		rand_num_5 <= 1;
		player_X <= 2;
		player_Y <= 2;
	end
	always@(posedge clk) begin
		case(state)
		S_RST: begin
			disappear_probility <= 31;
		end
		default: begin
			if(score < 20) begin
				disappear_probility <= 31;
			end
			else if(score == 20) begin
				disappear_probility <= 28;
			end
			else if(score == 30) begin
				disappear_probility <= 25;
			end
			else if(score == 40) begin
				disappear_probility <= 20;
			end
			else if(score == 50) begin
				disappear_probility <= 15;
			end
			else if(score == 60) begin
				disappear_probility <= 10;
			end
			else if(score > 60)begin
				disappear_probility <= 0;
			end
		end
		endcase
	end
	always@(posedge clk) begin // clk
		case(state) 
			S_RST: begin
				player_clk <= 0;
				player_clk_count <= 0;
			end
			S_MOVE: begin
				if(player_clk_count < PLAYER_MOVE_STOP) begin
					player_clk_count <= player_clk_count + 1;
					player_clk <= 0;
				end
				else begin
					player_clk <= 1;
					player_clk_count <= 0;
				end
			end
		endcase
		if(display_clk > 150) begin
			display = ~display;
			display_clk <= 0;
		end
		else begin
			display_clk <= display_clk + 1;
		end
	end
	always@(posedge clk) begin // main
		if(rst) begin
			state <= S_RST;
		end
		else begin
			state <= next_state;
		end
	end
	//////////////////////////////////////////////////////////////////////////////////
	//
	//			Combinational
	//
	////////////////////////////////////////////////////////////////////////////////
	always@(*) begin
		case(state)
			S_RST: begin
				next_state = S_IDLE;
			end
			S_IDLE: begin
				if(start == 1) begin
					next_state = S_INITIAL_GAME;
				end
				else begin
					next_state = S_IDLE;
				end
			end
			S_INITIAL_GAME: begin //initial matrix data
				next_state = S_MOVE;
			end
			S_GENERATE: begin 
			// if the player is on the new stair will need to generate a new stair
				if(generate_fg != 0) begin
					next_state = S_GENERATE;
				end
				else begin
					next_state = S_MOVE;
				end
			end
			S_MOVE: begin
				next_state = S_MOVE_2;
			end
			S_MOVE_2: begin //wait for move_finish
				if(end_game == 1) begin
					next_state = S_RST;
				end
				else if(move_finish == 1) begin
					next_state = S_NEW_STAIR;
				end
				else begin
					next_state = S_MOVE;
				end
			end
			S_NEW_STAIR: begin	 //compare is it on the removeable stair			
				next_state = S_GENERATE;
			end
		endcase
	end
	
	always@(posedge clk) begin
		case(state)
		S_RST:begin
			end_game = 0;
		end
		default: begin
				if(player_Y == 0) begin
					end_game = 1;
				end
			end
		endcase
	end
	//////////////////////////////////////////////////
	//
	//		Generate new stair
	//
	///////////////////////////////////////////////////
	always@(posedge clk) begin //generate_fg
		case(state)
			S_RST: begin
				generate_fg <= 0;
			end
			S_NEW_STAIR:begin
				if(matrix[player_X][player_Y + 1] == 2) begin 
					// if below the player is the moveable stair
					// if the play_Y == 4
					generate_fg <= 4;
				end
				else if(matrix[player_X][player_Y + 1] == 1) begin
					// if below the player is not moveable stair
					// if the play_Y == 4
					generate_fg <= 3;
				end
			end
			S_GENERATE:
				if(generate_fg > 0) begin
					generate_fg <= generate_fg - 1;
				end
		endcase
	end
	///////////////////////////////////////////////////////////////////////////
	//
	//   	Move
	//
	//////////////////////////////////////////////////////////////////////////
	always @(posedge clk) begin
    case(state)
		S_RST: begin
			move_finish <= 0;
			jump <= 1;
			jump_count <= 0;
			player_X <= 2;
			player_Y <= 2;
		end
        S_MOVE: begin
			if(player_clk == 1) begin
				// jump up four step and goes down four step
				if (jump_count < 2) begin
					jump_count <= jump_count + 1;
					jump <= 1;
				end
				else begin
					jump <= 0;
				end

				// Move left and right
				if (right == 1) begin
					if (player_X > 0) begin
						player_X <= player_X - 1; // Move X
					end
					else begin
						player_X <= player_X; 
					end
				end
				else if (left == 1) begin
					if (player_X < 7) begin
						player_X <= player_X + 1; // Move Y
					end
					else begin
						player_X <= player_X;
					end
				end

				// JUMP move movement
				if (jump == 0) begin
					if (matrix[player_X][player_Y - 1] == 0) begin
						player_Y <= player_Y - 1; // player goes down one stair
					end
					else begin
						player_Y <= player_Y; //player is standing on the stair
						jump <= 1; // reset the movement to jump
						jump_count <= 0;
						if(player_Y == 4) begin
							move_finish <= 1;
							player_Y <= player_Y - 2;
						end
					end
				end
				else if (jump == 1) begin
					player_Y <= player_Y + 1; //player jump up one stair
				end
			end
        end
		S_GENERATE:begin
			move_finish <= 0;
		end
    endcase
	end
	//////////////////////////////////////////////////////////////////////////////
	//
	//			Matrix 
	//
	//////////////////////////////////////////////////////////////////////////////
	always@(negedge clk) begin // matrix
		case(state)
			S_RST: begin
				for (i = 0; i < 8; i = i + 1) begin
					for (j = 0; j < 8; j = j + 1) begin
						matrix[i][j] <= 2'b00; 
					end
				end
			end
			S_INITIAL_GAME: begin // initial stair ///////////
				score <= 0;
				matrix[3][1] <= 2'b01;
				matrix[2][1] <= 2'b01;
				matrix[1][1] <= 2'b01;
				matrix[7][3] <= 2'b01;
				matrix[6][3] <= 2'b01;
				matrix[5][3] <= 2'b01;
				matrix[4][5] <= 2'b01;
				matrix[3][5] <= 2'b01;
				matrix[2][5] <= 2'b01;
				matrix[5][7] <= 2'b01;
				matrix[6][7] <= 2'b01;
				matrix[7][7] <= 2'b01;
			end
			S_GENERATE: begin
				if(generate_fg == 4) begin // the player is standing on the one time stair
					for(i = 0; i < 8; i = i + 1) begin
						matrix[i][3] <= 2'b00;
					end
				end
				else if((generate_fg == 3) || (generate_fg == 2)) begin // move stair down 2 times
					for (i = 0; i < 8; i = i + 1) begin
						matrix[i][0] <= matrix[i][1];  // 
						matrix[i][1] <= matrix[i][2];  // 
						matrix[i][2] <= matrix[i][3];  // 
						matrix[i][3] <= matrix[i][4];  // 
						matrix[i][4] <= matrix[i][5];  // 
						matrix[i][5] <= matrix[i][6];  // 
						matrix[i][6] <= matrix[i][7];  // 
						matrix[i][7] <= 2'b00;
					end
				end
				else if(generate_fg == 1) begin
					score <= score + 1;
					case(rand_num_3) // generate stair
						0:begin
							if(rand_num_5 <= disappear_probility) begin
								matrix[2][7] <= 1;
								matrix[1][7] <= 1;
								matrix[0][7] <= 1;
							end
							else begin
								matrix[2][7] <= 2;
								matrix[1][7] <= 2;
								matrix[0][7] <= 2;
							end
						end
						1:begin
							if(rand_num_5 <= disappear_probility) begin
								matrix[3][7] <= 1;
								matrix[2][7] <= 1;
								matrix[1][7] <= 1;
							end
							else begin
								matrix[3][7] <= 2;
								matrix[2][7] <= 2;
								matrix[1][7] <= 2;
							end
						end
						2:begin
							if(rand_num_5 <= disappear_probility) begin
								matrix[4][7] <= 1;
								matrix[3][7] <= 1;
								matrix[2][7] <= 1;
							end
							else begin
								matrix[4][7] <= 2;
								matrix[3][7] <= 2;
								matrix[2][7] <= 2;
							end
						end
						3:begin
							if(rand_num_5 <= disappear_probility) begin
								matrix[5][7] <= 1;
								matrix[4][7] <= 1;
								matrix[3][7] <= 1;
							end
							else begin
								matrix[5][7] <= 2;
								matrix[4][7] <= 2;
								matrix[3][7] <= 2;
							end
						end
						4:begin
							if(rand_num_5 <= disappear_probility) begin
								matrix[6][7] <= 1;
								matrix[5][7] <= 1;
								matrix[4][7] <= 1;
							end
							else begin
								matrix[6][7] <= 2;
								matrix[5][7] <= 2;
								matrix[4][7] <= 2;
							end
						end
						5:begin
							if(rand_num_5 <= disappear_probility) begin
								matrix[5][7] <= 1;
								matrix[6][7] <= 1;
								matrix[7][7] <= 1;
							end
							else begin
								matrix[5][7] <= 2;
								matrix[6][7] <= 2;
								matrix[7][7] <= 2;
							end
						end
						6:begin
							if(rand_num_5 <= disappear_probility) begin
								matrix[2][7] <= 1;
								matrix[1][7] <= 1;
								matrix[0][7] <= 1;
							end
							else begin
								matrix[3][7] <= 2;
								matrix[2][7] <= 2;
								matrix[1][7] <= 2;
							end
						end
						7:begin
							if(rand_num_5 <= disappear_probility) begin
								matrix[4][7] <= 1;
								matrix[3][7] <= 1;
								matrix[2][7] <= 1;
							end
							else begin
								matrix[5][7] <= 2;
								matrix[4][7] <= 2;
								matrix[3][7] <= 2;
							end
						end
					endcase
				end
			end
		endcase
	end
	//////////////////////////////////////////////////////////////////////////////////////
	//
	//		Seg7 display
	//
	////////////////////////////////////////////////////////////////////////////////////////
	always@(posedge clk) begin
		temp = score;
		BCD_3 = 0;
		BCD_2 = 0;
		BCD_1 = 0;
		for(k = 0; k < 9; k = k + 1)
		begin
			{BCD_3, BCD_2, BCD_1, temp} = {BCD_3, BCD_2, BCD_1, temp} * 2;
			if(BCD_2 >= 5)
			begin
				BCD_2 = BCD_2 + 3;
			end
			if(BCD_1 >= 5)
			begin
				BCD_1 = BCD_1 + 3;
			end
		end
		{BCD_3, BCD_2, BCD_1} = {BCD_3, BCD_2, BCD_1} * 2 + temp[9];
	end
	
	always@(posedge clk) begin
		//seg7_3
		case(BCD_3)
			0: seg7_3 <= ZERO;
			1: seg7_3 <= ONE;
			2: seg7_3 <= TWO;
			3: seg7_3 <= THREE;
			4: seg7_3 <= FOUR;
			5: seg7_3 <= FIVE;
			6: seg7_3 <= SIX;
			7: seg7_3 <= SEVEN;
			8: seg7_3 <= EIGHT;
			9: seg7_3 <= NINE;
			default: seg7_3 <= BLANK;
		endcase
	end
	always@(posedge clk) begin
		//seg7_2
		case(BCD_2)
			0: seg7_2 <= ZERO;
			1: seg7_2 <= ONE;
			2: seg7_2 <= TWO;
			3: seg7_2 <= THREE;
			4: seg7_2 <= FOUR;
			5: seg7_2 <= FIVE;
			6: seg7_2 <= SIX;
			7: seg7_2 <= SEVEN;
			8: seg7_2 <= EIGHT;
			9: seg7_2 <= NINE;
			default: seg7_2 <= BLANK;
		endcase
	end
	always@(posedge clk) begin
		//seg7_2
		case(BCD_1)
			0: seg7_1 <= ZERO;
			1: seg7_1 <= ONE;
			2: seg7_1 <= TWO;
			3: seg7_1 <= THREE;
			4: seg7_1 <= FOUR;
			5: seg7_1 <= FIVE;
			6: seg7_1 <= SIX;
			7: seg7_1 <= SEVEN;
			8: seg7_1 <= EIGHT;
			9: seg7_1 <= NINE;
			default: seg7_1 <= BLANK;
		endcase
	end
	////////////////////////////////////////////////////////////////////////////////////
	//
	//			Matrix display
	//
	/////////////////////////////////////////////////////////////////////////////////////
	always@(posedge clk) begin //display;
		case(state)
			S_IDLE, S_RST:begin
				ROW <= 0;
				COL <= (COL << 1);
			end
			default: begin
				case(display_count)
					0:begin
						ROW_REG = 0;
						for(i = 0; i < 8; i = i + 1) begin
							if(matrix[i][0] == 1 || (player_X == i && player_Y == 0)) begin
								ROW_REG = (ROW_REG << 1) + 1;
							end
							else if(matrix[i][0] == 2 || (player_X == i && player_Y == 0)) begin
								ROW_REG = (ROW_REG << 1) + display;
							end
							else begin
								ROW_REG = (ROW_REG << 1);
							end
						end
						ROW = ROW_REG;
						display_count = display_count + 1;
						COL = 8'b10000000;
					end
					1:begin
						ROW_REG = 0;
						for(i = 0; i < 8; i = i + 1) begin
							if(matrix[i][1] == 1|| (player_X == i && player_Y == 1)) begin
								ROW_REG = (ROW_REG << 1) + 1;
							end
							else if(matrix[i][1] == 2 || (player_X == i && player_Y == 1)) begin
								ROW_REG = (ROW_REG << 1) + display;
							end
							else begin
								ROW_REG = (ROW_REG << 1);
							end
						end
						ROW = ROW_REG;
						display_count = display_count + 1;
						COL = 8'b01000000;
					end
					2:begin
						ROW_REG = 0;
						for(i = 0; i < 8; i = i + 1) begin
							if(matrix[i][2] == 1 || (player_X == i && player_Y == 2)) begin
								ROW_REG = (ROW_REG << 1) + 1;
							end
							else if(matrix[i][2] == 2 || (player_X == i && player_Y == 2)) begin
								ROW_REG = (ROW_REG << 1) + display;
							end
							else begin
								ROW_REG = (ROW_REG << 1);
							end
						end
						ROW = ROW_REG;
						display_count = display_count + 1;
						COL = 8'b00100000;
					end
					3:begin
						ROW_REG = 0;
						for(i = 0; i < 8; i = i + 1) begin
							if(matrix[i][3] == 1 || (player_X == i && player_Y == 3)) begin
								ROW_REG = (ROW_REG << 1) + 1;
							end
							else if(matrix[i][3] == 2 || (player_X == i && player_Y == 3)) begin
								ROW_REG = (ROW_REG << 1) + display;
							end
							else begin
								ROW_REG = (ROW_REG << 1);
							end
						end
						ROW = ROW_REG;
						display_count = display_count + 1;
						COL = 8'b00010000;
					end
					4:begin
						ROW_REG = 0;
						for(i = 0; i < 8; i = i + 1) begin
							if(matrix[i][4] == 1 || (player_X == i && player_Y == 4)) begin
								ROW_REG = (ROW_REG << 1) + 1;
							end
							else if(matrix[i][4] == 2 || (player_X == i && player_Y == 4)) begin
								ROW_REG = (ROW_REG << 1) + display;
							end
							else begin
								ROW_REG = (ROW_REG << 1);
							end
						end
						ROW = ROW_REG;
						display_count = display_count + 1;
						COL = 8'b00001000;
					end
					5:begin
						ROW_REG = 0;
						for(i = 0; i < 8; i = i + 1) begin
							if(matrix[i][5] == 1 || (player_X == i && player_Y == 5)) begin
								ROW_REG = (ROW_REG << 1) + 1;
							end
							else if(matrix[i][5] == 2 || (player_X == i && player_Y == 5)) begin
								ROW_REG = (ROW_REG << 1) + display;
							end
							else begin
								ROW_REG = (ROW_REG << 1);
							end
						end
						ROW = ROW_REG;
						display_count = display_count + 1;
						COL = 8'b00000100;
					end
					6:begin
						ROW_REG = 0;
						for(i = 0; i < 8; i = i + 1) begin
							if(matrix[i][6] == 1 || (player_X == i && player_Y == 6)) begin
								ROW_REG = (ROW_REG << 1) + 1;
							end
							else if(matrix[i][6] == 2 || (player_X == i && player_Y == 6)) begin
								ROW_REG = (ROW_REG << 1) + display;
							end
							else begin
								ROW_REG = (ROW_REG << 1);
							end
						end
						ROW = ROW_REG;
						display_count = display_count + 1;
						COL = 8'b00000010;
					end
					7:begin
						ROW_REG = 0;
						for(i = 0; i < 8; i = i + 1) begin
							if(matrix[i][7] == 1 || (player_X == i && player_Y == 7)) begin
								ROW_REG = (ROW_REG << 1) + 1;
							end
							else if(matrix[i][7] == 2 || (player_X == i && player_Y == 7)) begin
								ROW_REG = (ROW_REG << 1) + display;
							end
							else begin
								ROW_REG = (ROW_REG << 1);
							end
						end
						ROW = ROW_REG;
						COL = 8'b00000001;
						display_count = 0;
					end
					default: begin
						display_count = 0;
					end
				endcase
			end
		endcase
	end
	always@(posedge clk) begin
		case(state) 
			S_RST: begin
				rand_num_5 <= 1;
				rand_num_3 <= 1;
			end
			default: begin
				if(rand_num_5 == 31) begin
					rand_num_5 <= 0;
				end
				else begin
					rand_num_5 <= rand_num_5 + 1;
				end
				if(rand_num_3 == 7) begin
					rand_num_3 <= 0;
				end
				else begin
					rand_num_3 <= rand_num_3 + 1;
				end
			end
		endcase
	end
endmodule 