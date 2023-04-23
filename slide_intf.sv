module slide_intf(POT_LP, POT_B1, POT_B2, POT_B3, POT_HP, POT_VOL, SS_n, SCLK, MOSI, MISO, clk, rst_n);

    input clk, rst_n, MISO;
    output logic [11:0] POT_LP, POT_B1, POT_B2, POT_B3, POT_HP, POT_VOL;
    output SS_n, SCLK, MOSI;

    logic [11:0] res;
    logic [2:0] chnnl, cmplt_counter;
    logic strt_cnv, cnv_cmplt;
    logic en_LP, en_B1, en_B2, en_B3, en_HP, en_VOL;

    ///////////////////////////
    // Instantiate A2D_intf //
    /////////////////////////
    A2D_intf iA2D(.chnnl(chnnl), .strt_cnv(strt_cnv), .clk(clk), .rst_n(rst_n), .MISO(MISO), 
		.cnv_cmplt(cnv_cmplt), .res(res), .SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI));

    ////////////////////
    // Slide Pot FFs //
    //////////////////
    always_ff @(posedge clk, negedge rst_n) begin: LP
        if(!rst_n)
            POT_LP <= 0;
        else if(en_LP)
            POT_LP <= res;
    end

    always_ff @(posedge clk, negedge rst_n) begin: B1
        if(!rst_n)
            POT_LP <= 0;
        else if(en_B1)
            POT_B1 <= res;
    end

    always_ff @(posedge clk, negedge rst_n) begin: B2
        if(!rst_n)
            POT_LP <= 0;
        else if(en_B2)
            POT_B2 <= res;
    end

    always_ff @(posedge clk, negedge rst_n) begin: B3
        if(!rst_n)
            POT_LP <= 0;
        else if(en_B3)
            POT_B3 <= res;
    end   

    always_ff @(posedge clk, negedge rst_n) begin: HP
        if(!rst_n)
            POT_LP <= 0;
        else if(en_HP)
            POT_HP <= res;
    end  

    always_ff @(posedge clk, negedge rst_n) begin: VOL
        if(!rst_n)
            POT_LP <= 0;
        else if(en_VOL)
            POT_VOL <= res;
    end

    ///////////////////////////////////////////////////////////////////
    // Implement RRsequencer, including 7 states: IDLE and TRANSMIT //
    /////////////////////////////////////////////////////////////////
    typedef enum logic {IDLE, CHANNEL} state_t;
    state_t state, nxt_state;
    
    always_ff @(posedge clk, negedge rst_n) begin : RRsequencer
        if(!rst_n)
            state <= IDLE; ///  reset to HIGH for high impedence, but some ModelSim edition
                           ///  does not compile HIGH, so use IDLE instead
        else
            state <= nxt_state;
    end

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
        chnnl = 3'b0;
        nxt_state = state;
        en_LP = 1'b0;
        en_B1 = 1'b0;
        en_B2 = 1'b0;
        en_B3 = 1'b0;
        en_HP = 1'b0;
        en_VOL = 1'b0;

        case(state)
            IDLE: begin
               
                nxt_state = CHANNEL;
            end

            CHANNEL: begin
                chnnl = 3'b001;
                if(cmplt_counter == 3'd1) begin
                    en_LP = 1'b1;
                    chnnl = 3'b000;
                    strt_cnv = 1'b1;   
                end
				strt_cnv = 0; 
                if(cmplt_counter == 3'd2) begin
                    en_B1 = 1'b1;
                    chnnl = 3'b100;
                    strt_cnv = 1'b1;
                end
				strt_cnv = 0; 
                if(cmplt_counter == 3'd3) begin
                    en_B2 = 1'b1;
                    chnnl = 3'b010;
                    strt_cnv = 1'b1;
                end    
				strt_cnv = 0; 
                if(cmplt_counter == 3'd4) begin 
                    en_B3 = 1'b1;
                    chnnl = 3'b011;
                    strt_cnv = 1'b1; 
                end 
				strt_cnv = 0; 
                if(cmplt_counter == 3'd5) begin
                    en_HP = 1'b1;
                    chnnl = 3'b111;
                    strt_cnv = 1'b1;   
                end
				strt_cnv = 0; 
                if(cmplt_counter == 3'd6) 
                    en_VOL = 1'b1;
                    strt_cnv = 1'b1;
                    
            end

            default : nxt_state = state;
        endcase
    end









endmodule