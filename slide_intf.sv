module slide_intf(POT_LP, POT_B1, POT_B2, POT_B3, POT_HP, POT_VOL, SS_n, SCLK, MOSI, MISO, clk, rst_n);

    input clk, rst_n, MISO;
    output logic [11:0] POT_LP, POT_B1, POT_B2, POT_B3, POT_HP, POT_VOL;
    output SS_n, SCLK, MOSI;

    logic [11:0] res;
    logic [2:0] chnnl, cmplt_counter;
    logic strt_cnv, cnv_cmplt;
    logic en_LP, en_B1, en_B2, en_B3, en_HP, en_VOL; // enable logic for outputing the POT

    //initiate A2D_intf
    A2D_intf iA2D(.chnnl(chnnl), .strt_cnv(strt_cnv), .clk(clk), .rst_n(rst_n), .MISO(MISO), 
		.cnv_cmplt(cnv_cmplt), .res(res), .SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI));

    //set up 6 flops for POT output
    always_ff @(posedge clk, negedge rst_n) begin: LP
        if(!rst_n)
            POT_LP <= 0;
        else if(en_LP)
            POT_LP <= res;//if enabled, pass res to LP
    end

    always_ff @(posedge clk, negedge rst_n) begin: B1
        if(!rst_n)
            POT_B1 <= 0;
        else if(en_B1)
            POT_B1 <= res;//if enabled, pass res to B1
    end

    always_ff @(posedge clk, negedge rst_n) begin: B2
        if(!rst_n)
            POT_B2 <= 0;
        else if(en_B2)
            POT_B2 <= res;//if enabled, pass res to B2
    end

    always_ff @(posedge clk, negedge rst_n) begin: B3
        if(!rst_n)
            POT_B3 <= 0;
        else if(en_B3)
            POT_B3 <= res;//if enabled, pass res to B3
    end   

    always_ff @(posedge clk, negedge rst_n) begin: HP
        if(!rst_n)
            POT_HP <= 0;
        else if(en_HP)
            POT_HP <= res;//if enabled, pass res to HP
    end  

    always_ff @(posedge clk, negedge rst_n) begin: VOL
        if(!rst_n)
            POT_VOL <= 0;
        else if(en_VOL)
            POT_VOL <= res;//if enabled, pass res to VOL
    end

    
    //initialize an eight state state machine for transmitting
    typedef enum logic[3:0] {IDLE,START, CHANNEL1,CHANNEL2,CHANNEL3,CHANNEL4,CHANNEL5,CHANNEL6} state_t;
    state_t state, nxt_state;
    

    //flop used to run the SM
    always_ff @(posedge clk, negedge rst_n) begin : RRsequencer
        if(!rst_n)
            state <= IDLE; 
        else
            state <= nxt_state;
    end

    // counter to help check which state
    always_ff @(posedge clk, negedge rst_n) begin : cnv_cmplt_counter
        if(!rst_n)
            cmplt_counter <= 3'b0; 
        else if (cmplt_counter == 3'd6)
            cmplt_counter <= 3'b0;
        else if (cnv_cmplt)
            cmplt_counter <= cmplt_counter + 1;
            
    end   

    always_comb begin
        strt_cnv = 1'b0;
        nxt_state = state;
        en_LP = 1'b0;
        en_B1 = 1'b0;
        en_B2 = 1'b0;
        en_B3 = 1'b0;
        en_HP = 1'b0;
        en_VOL = 1'b0;
        chnnl = 0;

        case(state)
            IDLE: begin
                nxt_state = START;
            end

            START: begin
                //start transmitting channel 
                strt_cnv = 1'b1;
                chnnl = 3'b001;
                nxt_state = CHANNEL1;
            end

            CHANNEL1: begin
                //if channel1 completed, we enable LP transmit
                // at the same time, start to transmit the channel2
                if(cmplt_counter == 3'd1) begin
                    en_LP = 1'b1;
                    strt_cnv = 1'b1;
                    chnnl = 3'b000;
                    nxt_state = CHANNEL2;
                end   
            end

			CHANNEL2: begin
                //if channel2 completed, we enable B1 transmit
                // at the same time, start to transmit the channel3
                if(cmplt_counter == 3'd2) begin
                    en_B1 = 1'b1;
                    strt_cnv = 1'b1;
                    chnnl = 3'b100;    
                    nxt_state = CHANNEL3;
                end
            end

            CHANNEL3: begin   
                //if channel3 completed, we enable B2 transmit
                // at the same time, start to transmit the channel4
                if(cmplt_counter == 3'd3) begin
                    en_B2 = 1'b1;
                    strt_cnv = 1'b1;   
                    chnnl = 3'b010; 
                    nxt_state = CHANNEL4;
                end    
            end
				
            CHANNEL4: begin       
                //if channel4 completed, we enable B3 transmit
                // at the same time, start to transmit the channel5
                if(cmplt_counter == 3'd4) begin 
                    en_B3 = 1'b1;
                    strt_cnv = 1'b1;
                    chnnl = 3'b011;     
                    nxt_state = CHANNEL5;
                end 
            end


            CHANNEL5: begin
                //if channel5 completed, we enable B4 transmit
                // at the same time, start to transmit the channel6
                if(cmplt_counter == 3'd5) begin
                    en_HP = 1'b1;
                    strt_cnv = 1'b1;
                    chnnl = 3'b111;                  
                    nxt_state = CHANNEL6;
                end
            end

            CHANNEL6: begin   
                //finish channel 6 
                if(cmplt_counter == 3'd6) begin
                    en_VOL = 1'b1;
                    nxt_state = IDLE;
                end
            end

            default : nxt_state = state;
        endcase
    end









endmodule