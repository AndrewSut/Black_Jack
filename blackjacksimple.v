module alu_with_reg (


	//////////// ADC //////////
	//output		          		ADC_CONVST,
	//output		          		ADC_DIN,
	//input 		          		ADC_DOUT,
	//output		          		ADC_SCLK,

	//////////// Audio //////////
	//input 		          		AUD_ADCDAT,
	//inout 		          		AUD_ADCLRCK,
	//inout 		          		AUD_BCLK,
	//output		          		AUD_DACDAT,
	//inout 		          		AUD_DACLRCK,
	//output		          		AUD_XCK,

	//////////// CLOCK //////////
	//input 		          		CLOCK2_50,
	//input 		          		CLOCK3_50,
	//input 		          		CLOCK4_50,
	input 		          		CLOCK_50,

	//////////// SDRAM //////////
	//output		    [12:0]		DRAM_ADDR,
	//output		     [1:0]		DRAM_BA,
	//output		          		DRAM_CAS_N,
	//output		          		DRAM_CKE,
	//output		          		DRAM_CLK,
	//output		          		DRAM_CS_N,
	//inout 		    [15:0]		DRAM_DQ,
	//output		          		DRAM_LDQM,
	//output		          		DRAM_RAS_N,
	//output		          		DRAM_UDQM,
	//output		          		DRAM_WE_N,

	//////////// I2C for Audio and Video-In //////////
	//output		          		FPGA_I2C_SCLK,
	//inout 		          		FPGA_I2C_SDAT,

	//////////// SEG7 //////////
	output		     [6:0]		HEX0,
	output		     [6:0]		HEX1,
	output		     [6:0]		HEX2,
	output		     [6:0]		HEX3,
	output		     [6:0]		HEX4,
	output		     [6:0]		HEX5,

	//////////// IR //////////
	//input 		          		IRDA_RXD,
	//output		          		IRDA_TXD,

	//////////// KEY //////////
	input 		     [3:0]		KEY,

	//////////// LED //////////
	output		     [9:0]		LEDR,

	//////////// PS2 //////////
	//inout 		          		PS2_CLK,
	//inout 		          		PS2_CLK2,
	//inout 		          		PS2_DAT,
	//inout 		          		PS2_DAT2,

	//////////// SW //////////
	input 		     [9:0]		SW

	//////////// Video-In //////////
	//input 		          		TD_CLK27,
	//input 		     [7:0]		TD_DATA,
	//input 		          		TD_HS,
	//output		          		TD_RESET_N,
	//input 		          		TD_VS,

	//////////// VGA //////////
	//output		          		VGA_BLANK_N,
	//output		     [7:0]		VGA_B,
	//output		          		VGA_CLK,
	//output		     [7:0]		VGA_G,
	//output		          		VGA_HS,
	//output		     [7:0]		VGA_R,
	//output		          		VGA_SYNC_N,
	//output		          		VGA_VS,

	//////////// GPIO_0, GPIO_0 connect to GPIO Default //////////
	//inout 		    [35:0]		GPIO_0,

	//////////// GPIO_1, GPIO_1 connect to GPIO Default //////////
	//inout 		    [35:0]		GPIO_1
);

wire clk;
assign clk = CLOCK_50;
wire rst;
assign rst = ~SW[3];

reg [3:0] deck [11:0];  // 12 items, each 4 bits wide
reg deck_aces [11:0];  // 12 items, each 4 bits wide

reg [3:0] player_hand [5:0];  // 12 items, each 4 bits wide
reg [3:0] player_aces;
reg [9:0] player_points;
reg [3:0] dealer_hand [5:0];  // 12 items, each 4 bits wide
reg [3:0] dealer_aces;

reg gen_seed;
reg gen_card;
reg start_lsfr;
wire rand_out;
wire ace_pres,      
reg start_delay;
reg create_deck_done;
reg delay_done;
reg serve_two_done;

reg [3:0] seed;

reg [1:0] timer, new_timer;
reg [25:0] timer_2, new_timer_2;

reg [5:0] curr_card_deck;
reg [5:0] curr_card_player;

//instantiate an lsfr here

lfsr_seed lfsr_inst (
    .clk(clk),            // Connect the clock
    .reset(rst),        // Connect the reset
    .enable(gen_seed),      // Connect the enable signal
    .out(seed)        // Connect the LFSR output to the top module's output
);

// Instantiate the lfsr_cards module
lfsr_cards lfsr_inst_cards (
    .clk(clk),             // Connect clock signal
    .reset(rst),         // Connect reset signal
    .enable(gen_card),       // Connect enable signal
    .seed(seed),           // Connect seed input
    .ace_pres(ace_pres),   // Connect ace_pres output
    .out(rand_out)         // Connect LFSR output to the top-level module
);

always @(posedge clk or negedge rst) begin
    if(rst == 1'b0)begin
        S <= START;
    end else begin
        S <= NS;
    end
end

always @(*) begin
    
    case(S)

    START: begin
        if(input_start == 1'b1) begin
            NS = START_LSFR;
        end else begin
            NS = START;
        end
    end

    START_LSFR: begin
        if(start_lsfr == 1'b1) begin
            NS = CREATE_DECK;
        end else begin
            NS = START_LSFR;
        end
    end

    CREATE_DECK: begin
        if(start_delay == 1'b1) begin
            NS = DELAY;
        end else if (create_deck_done == 1'b1)begin
            NS = SERVE_TWO;
        end else begin
            NS = CREATE_DECK;
        end
    end

    DELAY: begin
        if(delay_done == 1'b1) begin
            NS = CREATE_DECK;
        end else begin
            NS = DELAY;
        end
    end

    SERVE_TWO: begin
        if(serve_two_done == 1'b1) begin
            NS = PLAYER_TURN;
        end else begin
            NS = SERVE_TWO;
        end
    end

    PLAYER_TURN: begin
        if(input_draw == 1'b1) begin
            NS = PLAYER_DRAW;
        end else if(input_fold)begin
            NS = DEALER_TURN;
        end else begin
            NS = PLAYER_TURN;
        end
    end

    PLAYER_DRAW: begin
        if(player_draw_done == 1'b1) begin
            if(player_busted == 1'b1) begin
                NS = PLAYER_BUST;
            end else begin
                NS = DELAY_HUMAN_SPEED;
            end
        end else begin
            NS = PLAYER_DRAW;
        end
    end

    DELAY_HUMAN_SPEED: begin
        if(delay_done_2 == 1'b1) begin
            NS = PLAYER_TURN;
        end else begin
            NS = DELAY_HUMAN_SPEED;
        end
    end

    //PLAYER_BUST:

    DEALER_TURN: begin
        if(dealer_turn_done == 1'b1) begin
            if(dealer_draws == 1'b1) begin
                NS = DEALER_DRAW;
            end else begin
                NS = LOSS;
            end
        end else begin
            NS = DEALER_TURN;
        end
    end

    DEALER_DRAW:begin
        if(dealer_draw_done == 1'b1) begin
            if(dealer_busted == 1'b1) begin
                NS = DEALER_BUST;
            end else begin
                NS = DEALER_TURN;
            end
        end else begin
            NS = DEALER_DRAW;
        end
    end

    //DEALER_BUST:

    //LOSS:

    endcase
end


always @(posedge clk or negedge rst) begin
    
    case(S)

    START: begin gen_seed <= 1'b1; curr_card_deck <= 6'd4; curr_card_player <= 6'd2 end

    START_LSFR: begin
        gen_seed <= 1'b0;
        start_lsfr <= 1'b1;
    end

    CREATE_DECK: begin

        delay_done <= 1'b0;

        if(deck[0] == 1'b0) begin deck[0] <= rand_out; start_delay <= 1'b1; end
        else if(deck[0] == 1'b0) begin deck[0] <= rand_out; deck_aces[0] <= ace_pres; start_delay <= 1'b1; end
        else if(deck[1] == 1'b0) begin deck[1] <= rand_out; deck_aces[1] <= ace_pres;  start_delay <= 1'b1; end
        else if(deck[2] == 1'b0) begin deck[2] <= rand_out; deck_aces[2] <= ace_pres;  start_delay <= 1'b1; end
        else if(deck[3] == 1'b0) begin deck[3] <= rand_out; deck_aces[3] <= ace_pres;  start_delay <= 1'b1; end
        else if(deck[4] == 1'b0) begin deck[4] <= rand_out; deck_aces[4] <= ace_pres;  start_delay <= 1'b1; end
        else if(deck[5] == 1'b0) begin deck[5] <= rand_out; deck_aces[5] <= ace_pres;  start_delay <= 1'b1; end
        else if(deck[6] == 1'b0) begin deck[6] <= rand_out; deck_aces[6] <= ace_pres;  start_delay <= 1'b1; end
        else if(deck[7] == 1'b0) begin deck[7] <= rand_out; deck_aces[7] <= ace_pres;  start_delay <= 1'b1; end
        else if(deck[8] == 1'b0) begin deck[8] <= rand_out; deck_aces[8] <= ace_pres;  start_delay <= 1'b1; end
        else if(deck[9] == 1'b0) begin deck[9] <= rand_out; deck_aces[9] <= ace_pres;  start_delay <= 1'b1; end
        else if(deck[10] == 1'b0) begin deck[10] <= rand_out; deck_aces[10] <= ace_pres;  start_delay <= 1'b1; end
        else if(deck[11] == 1'b0) begin deck[11] <= rand_out; deck_aces[11] <= ace_pres;  start_delay <= 1'b1; end
        else begin create_deck_done <= 1'b1; end
    end

    DELAY: begin
        start_delay <= 1'b0;
        if(timer < 2'd2) begin new_timer <= timer + 1'b1; timer <= new_timer; end
        else begin timer <= 1'b0; new_timer <= 1'b0; delay_done <= 1'b1; end
    end

    SERVE_TWO: begin
        player_hand[0] <= deck[0];
        player_hand[1] <= deck[1];
        dealer_hand[0] <= deck[2];
        dealer_hand[1] <= deck[3];

        player_aces <= deck_aces[0] + deck_aces[1];
        dealer_aces <= deck_aces[2] + deck_aces[3];

        serve_two_done <= 1'b1;
    end

    //PLAYER_TURN:

    PLAYER_DRAW: begin 
        player_hand[curr_card_player] <= deck[curr_card_deck];
        new_player_aces <= player_aces + deck_aces[curr_card_deck];
        player_aces <= new_player_aces;

        new_curr_card_player <= curr_card_player + 1'b1;
        curr_card_player <= new_curr_card_player;

        new_curr_card_deck <= curr_card_deck + 1'b1;
        curr_card_deck <= new_curr_card_deck;

        player_points <= player_hand[0] + player_hand[1] + player_hand[2] + player_hand[3] + player_hand[4] + player_hand[5];

        if((player_points) > 5'd21) begin
            player_busted <= 1'b1;
        end else player_busted <= 1'b0;

        player_draw_done <= 1'b1;
    end

    DELAY_HUMAN_SPEED: begin
        player_draw_done <= 1'b0;
        if(timer_2 < 26'd50000000) begin new_timer_2 <= timer_2 + 1'b1; timer_2 <= new_timer_2; end
        else begin timer_2 <= 1'b0; new_timer_2 <= 1'b0; delay_2_done = 1'b1; end
    end

    PLAYER_BUST:

    DEALER_TURN:begin

        dealer_points <= dealer_hand[0] + dealer_hand[1] + dealer_hand[2] + dealer_hand[3] + dealer_hand[4] + dealer_hand[5];

        if(player_points >= dealer_points) dealer_draws = 1'b1;
        
        dealer_turn_done <= 1'b1;
    end

    DEALER_DRAW: begin 
        dealer_hand[curr_card_dealer] <= deck[curr_card_deck];
        new_dealer_aces <= dealer_aces + deck_aces[curr_card_deck];
        dealer_aces <= new_dealer_aces;

        new_curr_card_dealer <= curr_card_dealer + 1'b1;
        curr_card_dealer <= new_curr_card_dealer;

        new_curr_card_deck <= curr_card_deck + 1'b1;
        curr_card_deck <= new_curr_card_deck;

        dealer_points <= dealer_hand[0] + dealer_hand[1] + dealer_hand[2] + dealer_hand[3] + dealer_hand[4] + dealer_hand[5];

        if((dealer_points) > 5'd21) begin
            dealer_busted <= 1'b1;
        end else dealer_busted <= 1'b0;

        dealer_draw_done <= 1'b1;
    end

    DEALER_BUST:

    endcase
end
endmodule