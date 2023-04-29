module sqrt(mag, sqrt, go, clk, rst_n, done);

input go, clk, rst_n; // input signal as enable, clock, and reset
output logic done; // signal which represents that calculating is done
input [31:0]mag; // input value to be evaluated
output [15:0] sqrt; // output value, square root of mag

typedef enum reg[1:0]{IDLE, FIND, FINISH} state_t; // set up enum type for the SM
state_t state, next_state;


logic start_shift, shift_done;// whther the calcultion is done or not
logic [15:0] sqrt_temp,sqrt_reg, MASK;//value to help calculate the square root

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        sqrt_temp <= 16'b1000_0000_0000_0000; // reset to calculate square root from 8'h80
        MASK <= 16'b1000_0000_0000_0000; // reset MASK to keep track of the bits we are operating on
    end
    else if(state==IDLE) begin
        sqrt_temp <=16'b1000_0000_0000_0000; // again reset the two values when in the IDLE state
        MASK <= 16'b1000_0000_0000_0000;
    end 
    else if(start_shift) begin
		sqrt_temp<= sqrt_reg; // when start_shift is asserted pass the value from calculated to the flop
		MASK <= {1'b0, MASK[15:1]}; // shift the MASK to keep track of the calculation
    end
end



assign sqrt_reg = (sqrt_temp*sqrt_temp < mag)? (sqrt_temp|{1'b0, MASK[15:1]}): 
			// when sqrt_temp^2 is less than mag, assert the next bit to one
		  (sqrt_temp*sqrt_temp > mag)? ((sqrt_temp&(~MASK))|{1'b0, MASK[15:1]}):
			// when sqrt_temp^2 is larger than mag, clear the current bit and set next bit to one
		   sqrt_temp; // keep the value when equal
		   

assign shift_done = (MASK == 0)? 1'b1:1'b0; // done when the mask is shifted to 0



always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        state <= IDLE; //default state to idle when reset
    else 
        state <= next_state;
end

always_comb begin
    next_state = state;
    done = 1'b0;// reset done 
    start_shift = 1'b0; // reset start_shift

    case(state)
        IDLE: begin
            if(go == 1'b1) // if go is asserted start to find the sqrt
                next_state = FIND;
        end

        FIND: begin
            if(shift_done) begin
                start_shift = 1'b0; //if done, set shift_done to zero
                next_state = FINISH;// move to the finish state
            end
            else begin
                start_shift = 1'b1;// otherwise, keep shifting the MASK
            end
        end

        FINISH: begin
            done = 1'b1; // assert done
            next_state = IDLE;
        end

        default: begin
            next_state = IDLE;// default to IDLE state
        end
        
    endcase
end

assign sqrt = (done)?sqrt_temp:0; // output the result to sqrt when done

endmodule;