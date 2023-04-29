module high_freq_queue(clk, rst_n, wrt_smpl, lft_smpl, rght_smpl, lft_out, rght_out, sequencing);

    input clk, rst_n, wrt_smpl;
    output logic sequencing;
    input [15:0] lft_smpl, rght_smpl;
    output [15:0] lft_out, rght_out;

    /// define pointers to access data
    logic unsigned [10:0] new_ptr, old_ptr, end_ptr, rd_ptr;
    /// define internal logics
    logic full, first, finish, set_end;
    

    //////////////////////////////////////
    // Instantiate dualPort1024x16 Ram //
    ////////////////////////////////////
    dualPort1536x16 idut_lft_h(.clk(clk), .we(wrt_smpl), .waddr(new_ptr), .raddr(rd_ptr),
                            .wdata(lft_smpl), .rdata(lft_out));
    dualPort1536x16 idut_rght_h(.clk(clk), .we(wrt_smpl), .waddr(new_ptr), .raddr(rd_ptr),
                            .wdata(rght_smpl), .rdata(rght_out));

    /// a ff to increament new pointer and old pointer
    always_ff @(posedge clk, negedge rst_n) begin : queue
        if(!rst_n) begin
            old_ptr <= 0;
            new_ptr <= 0;
        end 
        else if(full && wrt_smpl) begin
			if(old_ptr == 11'd1535) begin
				old_ptr <= 0;
				new_ptr <= new_ptr + 1;
            end
			else if(new_ptr == 11'd1535) begin
				new_ptr <= 0;
                old_ptr <= old_ptr + 1;
            end
			else begin
                old_ptr <= old_ptr + 1;
                new_ptr <= new_ptr + 1;
            end
        end else if(wrt_smpl) begin
            if(new_ptr == 11'd1535)
				new_ptr <= 0;
            else new_ptr <= new_ptr + 1;
        end
    end

    always_ff @(posedge clk, negedge rst_n) begin : queue_full
        if(!rst_n)
            full <= 0;
        else if(first)
            full <= 1;
    end

    /// a ff to set read pointer
    always_ff @(posedge clk, negedge rst_n) begin : read_pointer
        if(!rst_n)begin
            rd_ptr <= 0;
            finish <= 0;
        end
        else if(set_end) begin
            rd_ptr <= old_ptr; /// initialize to the old pointer
            finish <= 0;
        end
        else if(rd_ptr == end_ptr)
            finish <= 1;
        else if(sequencing)begin
            if(rd_ptr == 11'd1535)
                rd_ptr <= 0;
            else 
                rd_ptr <= rd_ptr + 1;
        end
    end

    always_ff @(posedge clk, negedge rst_n) begin
	    if(!rst_n)
		    end_ptr<=0;
	    else if(set_end) begin
            if(old_ptr > 11'd515)
		        end_ptr <= old_ptr - 11'd516;
            else    
                end_ptr <= old_ptr + 11'd1020;
        end
    end

    /// Combinational logics
 
    assign first = (new_ptr == 11'd1531);
   

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
		nxt_state = READ;
		
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