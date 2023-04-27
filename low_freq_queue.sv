module low_freq_queue(clk, rst_n, wrt_smpl, lft_smpl, rght_smpl, lft_out, rght_out, sequencing);

    input clk, rst_n, wrt_smpl;
    output logic sequencing;
    input [15:0] lft_smpl, rght_smpl;
    output [15:0] lft_out, rght_out;

    /// define pointers to access data
    logic unsigned [9:0] new_ptr, old_ptr, end_ptr, rd_ptr;
    /// define internal logics
    logic full, first, finish, set_end;
 

    //////////////////////////////////////
    // Instantiate dualPort1024x16 Ram //
    ////////////////////////////////////
    dualPort1024x16 idut_lft(.clk(clk), .we(wrt_smpl), .waddr(new_ptr), .raddr(rd_ptr),
                            .wdata(lft_smpl), .rdata(lft_out));
    dualPort1024x16 idut_rght(.clk(clk), .we(wrt_smpl), .waddr(new_ptr), .raddr(rd_ptr),
                            .wdata(rght_smpl), .rdata(rght_out));

    /// a ff to increament new pointer and old pointer
    always_ff @(posedge clk, negedge rst_n) begin : queue
        if(!rst_n) begin
            old_ptr <= 0;
            new_ptr <= 0;
        end 
        else if(full && wrt_smpl) begin //if full, and wrt asserted, increment both pointer
            old_ptr <= old_ptr + 1;
            new_ptr <= new_ptr + 1;
        end else if(wrt_smpl)
            new_ptr <= new_ptr + 1; //if not full, increment new
    end

    // once the queue is full, assert full forever
    always_ff @(posedge clk) begin : queue_full
        if(first)
            full = 1;
    end
    assign first = (new_ptr == 10'd1021);
    

    /// a ff to set read pointer
    always_ff @(posedge clk, negedge rst_n) begin : read_pointer
        if(!rst_n)begin
            rd_ptr <= 0;
        end
	    else if(set_end)begin
            finish = 0;
            rd_ptr <= old_ptr; /// initialize to the old pointer
	    end else if(rd_ptr == end_ptr)
	            finish = 1;
            else if(sequencing)begin //increase rd when sequencing
                rd_ptr <= rd_ptr + 1;
        end
    end

    always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		end_ptr<=0;
	else if(set_end)
		end_ptr <= old_ptr + 10'd1020; // find end ptr

    end

 
    
 

    /// define all state names
    typedef enum logic [1:0]{IDLE, WAIT, READ} state_t;
    state_t	state, nxt_state;

    /*
    State machine implementation: after writing all 1021 locations, begin to read and sequence. After it's
    done, go back to IDLE state.
    */
    /// sequential logic of SM
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin // reset cnv_cmplt and bring state to IDLE
            state <= IDLE;
        end
        else begin
            state <= nxt_state;
        end
    end

    /// combination logic of SM
    always_comb begin
        sequencing = 0;
        nxt_state = state;
        set_end = 0;
        case(state)
            IDLE : begin
                if(wrt_smpl && full) begin
                    nxt_state = WAIT;
                    set_end = 1;
                end
            end

	    WAIT : begin
		nxt_state = READ; // wait 1 cycle to read
		
	    end

            READ : begin
                sequencing = 1;
                if(finish)
                    nxt_state = IDLE; 
            end  
               
            default : nxt_state = IDLE;
        endcase
    end

endmodule   