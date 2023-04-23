module SPI_mnrch(clk, rst_n, snd, cmd, done, resp, SS_n, SCLK, MOSI, MISO);
    input clk, rst_n, snd;
    input [15:0] cmd;
    output done;
    output [15:0] resp;
    input MISO;
    output SS_n, SCLK, MOSI;

    ///////////////////////////////
    // Declare internal signals //
    /////////////////////////////
    logic ld_SCLK, shft, full;
    logic [4:0] SCLK_div;
    logic [4:0] bit_cntr;
    logic done16, init;
    logic [15:0] shft_reg;
    logic set_done;
    logic done_ff, SS_n_ff;

    ////////////////////////////////
    // Implement SCLK assignment //
    //////////////////////////////
    always_ff @(posedge clk, negedge rst_n) begin : SCLK_assign
        if(!rst_n)
            SCLK_div <= 0;
        else begin
            if(ld_SCLK)
                SCLK_div <= 5'b10111;
            else
                SCLK_div <= SCLK_div + 1'b1;
        end
    end
    assign SCLK = SCLK_div[4];
    assign shft = (SCLK_div == 5'b10001) ? 1'b1 : 0;
    assign full = (&SCLK_div) ? 1'b1 : 0;

    ////////////////////////////
    // Implement bit-counter //
    //////////////////////////
    always_ff @(posedge clk, negedge rst_n) begin : bit_counter
        if(!rst_n)
            bit_cntr <= 0;
        else begin
            if(init)
                bit_cntr <= 5'b00000;
            else begin
                if(shft)
                    bit_cntr <= bit_cntr + 1'b1;
            end
        end
    end
    assign done16 = (bit_cntr === 5'b10000) ? 1 : 0;
    
    ////////////////////////
    // Implement shifter //
    //////////////////////
    always_ff @(posedge clk, negedge rst_n) begin : shifter
        if(!rst_n)
            shft_reg <= 16'b0;
        else begin
            if(init)
                shft_reg <= cmd;
            else if({init, shft} == 2'b01)
                shft_reg <= {shft_reg[14:0], MISO};
        end
    end
    assign MOSI = shft_reg[15];
    assign resp = shft_reg;

    ///////////////////////////////////////////////////////////////////////////////
    // Implement state machine, including 3 states: IDLE, SHIFTING and TRAILING //
    /////////////////////////////////////////////////////////////////////////////
    typedef enum logic [1:0] {IDLE, SHIFTING, TRAILING} state_t;
    state_t state, nxt_state;
    
    always_ff @(posedge clk, negedge rst_n) begin : state_ff
        if(!rst_n)
            state <= IDLE; ///  reset to HIGH for high impedence, but some ModelSim edition
                           ///  does not compile HIGH, so use IDLE instead
        else
            state <= nxt_state;
    end

    always_comb begin : state_machine
        nxt_state = state;
        ld_SCLK = 1'b0;
        init = 1'b0;
        set_done = 1'b0;

        case(state)
            IDLE: begin
                if(snd) begin
                    init = 1'b1;
                    ld_SCLK = 1'b1;
                    nxt_state = SHIFTING;
                end
            end

            SHIFTING: begin
                if(done16)
                    nxt_state = TRAILING;
            end

            TRAILING: begin
                if(full) begin
                    set_done = 1'b1; 
                    nxt_state = IDLE;
                end
            end

            default: nxt_state = IDLE;
        endcase
    end

    ///////////////////////////////////////////////////
    // Set done and SS_n using two difference flops //
    /////////////////////////////////////////////////
    always_ff @(posedge clk, negedge rst_n) begin : done_assign
        if(!rst_n)
            done_ff <= 1'b0;
        else begin
            if(init)
                done_ff <= 1'b0;
            if(set_done)
                done_ff <= 1'b1;
        end
    end
    assign done = done_ff;
    
    always_ff @(posedge clk, negedge rst_n) begin : SS_n_assign
        if(!rst_n)
            SS_n_ff <= 1'b1;
        else begin
            if(init)
                SS_n_ff <= 1'b0;
            if(set_done)
                SS_n_ff <= 1'b1;
        end
    end
    assign SS_n = SS_n_ff;

endmodule