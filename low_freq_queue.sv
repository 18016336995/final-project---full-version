module low_freq_queue(clk, rst_n, wrt_smpl, lft_smpl, rght_smpl, lft_out, rght_out, sequencing);
    input clk, rst_n, wrt_smpl;
    output logic sequencing;
    input [15:0] lft_smpl, rght_smpl;
    output [15:0] lft_out, rght_out;
   logic [9:0]new_ptr, old_ptr, end_ptr, rd_ptr;
   logic start;
    dualPort1024x16 idut_lft(.clk(clk), .we(wrt_smpl),
         .waddr(new_ptr), .raddr(rd_ptr), .wdata(lft_smpl), .rdata(lft_out_temp));
    dualPort1024x16 idut_rght(.clk(clk), .we(wrt_smpl),
         .waddr(new_ptr), .raddr(rd_ptr), .wdata(rght_smpl), .rdata(rght_out_temp));

 
    logic full;
    logic first;
    

    always_ff @(posedge clk, negedge rst_n) begin : queue
        if(!rst_n) begin
            old_ptr <= 0;
            new_ptr <= 0;
        end 
        else if(full && wrt_smpl) begin
            old_ptr <= old_ptr + 1;
            new_ptr <= new_ptr + 1;
        end else if(wrt_smpl)
            new_ptr <= new_ptr + 1;
    end
    assign end_ptr = old_ptr + 10'd1020;



    assign first = (new_ptr == 10'd1021);
    always @(posedge first) begin
        if(first)
            full = 1;
    end



    logic seq, finish;
    logic [9:0] counter;
    always_ff @(posedge clk, negedge rst_n)begin
        if(!rst_n)begin
            rd_ptr <= 0;
            counter<=0;
        end
        else if(wrt_smpl)
            rd_ptr <= old_ptr;
        else begin
            rd_ptr <= rd_ptr + 1;
            counter<=counter+1;
        end
    end
    assign finish = (counter == 10'd1020);


      /// define all state names
    typedef enum logic {IDLE, READ} state_t;
    state_t	state, nxt_state;

    /*
    State machine implementation:

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
        sequencing = 0;
        start = 0;
        nxt_state = state;
        
        case(state)
            IDLE : begin
                if(wrt_smpl && full) begin
                    nxt_state = READ;
                    start = 1;
                end
            end
            READ : begin
                start = 1;
                sequencing = 1;
                if(finish)
                    nxt_state = IDLE; 
            end     
            default :
                nxt_state = IDLE;

        endcase
    end

    assign lft_out = (start) ? lft_out_temp : 0;
    assign rght_out = (start) ? rght_out_temp : 0;

endmodule