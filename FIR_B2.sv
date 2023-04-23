module FIR_B2(clk, rst_n, lft_in, sequencing, rght_in, lft_out, rght_out);
    input signed [15:0] lft_in, rght_in;
    input sequencing, clk, rst_n;
    output signed [15:0] lft_out, rght_out;

    logic [9:0] addr, addr_temp1, addr_temp2;
    logic signed [15:0] dout;
    logic incr_addr, clr_addr, accum, clr_accum;
    logic signed [31:0] lft_temp1, rght_temp1, lft_temp2, rght_temp2, accum_temp1_l, accum_temp1_l_2, accum_temp1_r, accum_temp1_r_2;


    //////////////////////
    // Instantiate ROM //
    ////////////////////
    ROM_B2 iROM(.*);

    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n)
            addr <= 0;
        else 
            addr <= addr_temp2;
    end
    assign addr_temp1 = (incr_addr) ? addr + 1 : addr;
    assign addr_temp2 = (clr_addr) ? 10'h000 : addr_temp1;

    
    /// Instantiate two accumulator flops
    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            lft_temp2 <= 0;
            rght_temp2 <= 0;
        end
        else if (sequencing)begin
            lft_temp2 <= accum_temp1_l_2;
            rght_temp2 <= accum_temp1_r_2;
        end
    end

    assign accum_temp1_l = (accum) ? lft_temp2 + lft_temp1 : lft_temp2;
    assign accum_temp1_l_2 = (clr_accum) ? 32'h0000 : accum_temp1_l;
    assign accum_temp1_r = (accum) ? rght_temp2 + rght_temp1 : rght_temp2;
    assign accum_temp1_r_2 = (clr_accum) ? 32'h0000 : accum_temp1_r;


    /// Combinational logics
    assign lft_temp1 = lft_in * dout;
    assign rght_temp1 = rght_in * dout;
    assign lft_out = lft_temp2[30:15];
    assign rght_out = rght_temp2[30:15];

    /// define all state names
    typedef enum logic {IDLE, CONVOLUTION} state_t;
    state_t	state, nxt_state;


    /*
    State machine implementation:
    Once sequencing signal is high, leave IDLE state to begin convolution, and set
    accum signal to high. When signal goes low, end the convolution
    */
    /// sequential logic of SM
    always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin				// reset cnv_cmplt and bring state to IDLE
        state <= IDLE;
    end
    else begin
        state <= nxt_state;
    end
    end

    /// combination logic of SM
    always_comb begin
        /// default state and output
        nxt_state = state;
        accum = 0;
        clr_accum = 0;
        clr_addr = 0;
        incr_addr = 0;


        case(state)
            IDLE : begin
                clr_addr = 1;
                clr_accum = 1;
                if(sequencing) begin
                    incr_addr = 1;
                    clr_addr = 0;
                    nxt_state = CONVOLUTION;
                end
            end

            CONVOLUTION : begin  
                
                accum = 1;
                incr_addr = 1;
                if(!sequencing) begin
                    nxt_state = IDLE;
                end  
            end
        endcase


    end

endmodule