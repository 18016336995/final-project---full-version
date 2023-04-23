module I2S_Serf(clk, rst_n, I2S_sclk, I2S_ws, I2S_data, lft_chnnl, rght_chnnl, vld);
input clk, rst_n, I2S_data, I2S_sclk, I2S_ws;
output logic [23:0] lft_chnnl, rght_chnnl;
output logic vld;


logic sclk_rise, sclk_fall, rise_det, fall_det;
logic temp1, temp2;
// rise edge detector, use two flops to keep track of the edge
always_ff @(posedge clk, negedge rst_n)begin
    if(!rst_n) begin
        rise_det <= 1'b0; //reset
	temp1 <= 1'b0;
    end
    else begin
	temp1 <= I2S_sclk; 
        rise_det <= temp1;
    end
end
assign sclk_rise = (~rise_det) && temp1; //detect whether the previous is neg and next is pos

// fall edge detector
always_ff @(posedge clk, negedge rst_n)begin
    if(!rst_n) begin
        fall_det <= 1'b0; //reset
	temp2 <= 1'b0;
    end
    else begin
	temp2 <= I2S_ws;
        fall_det <= temp2;
    end
end
assign sclk_fall = (~temp2) && fall_det; //detect whether previous is pos and next is neg




reg [47:0]shft_reg, shft_temp;
always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        shft_reg <= 48'b0; // reset the shift register
    else
        shft_reg <= shft_temp;
end
assign shft_temp = (sclk_rise)? {shft_reg[46:0], I2S_data} : shft_reg; // if sclk is rise edge, shift 1 bit to the left by adding I2S_data
assign lft_chnnl = shft_reg[47:24]; // [47:24] is the signal for left channel
assign rght_chnnl = shft_reg[23:0]; // the rest is assigned to the right channel



logic [4:0]bit_cntr, cntr_temp1, cntr_temp2;
logic eq22, eq23, eq24;
logic clr_cnt;
always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n)
        bit_cntr <= 0; // reset the counter
    else
        bit_cntr <= cntr_temp2;
end
assign cntr_temp1 = (sclk_rise)? bit_cntr+1: bit_cntr; //if sclk_rise is asserted, start to count
assign cntr_temp2 = (clr_cnt)? 5'b0 : cntr_temp1; //if clr_cnt asserted, clear and reset
assign eq22 = (bit_cntr == 5'd22)? 1:0; // determine whether counts to 22
assign eq23 = (bit_cntr == 5'd23)? 1:0;// determine whether counts to 23
assign eq24 = (bit_cntr == 5'd24)? 1:0;// determine whether counts to 24


logic check22, check23;
and check0(check22, eq22, ~I2S_ws, sclk_rise);// determine the negedge while reading data
and check1(check23, eq23, I2S_ws, sclk_rise);



typedef enum logic[1:0] {IDLE, WAIT, LEFT, RIGHT} state_t; // initialize states
state_t state, nxt_state;




always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n)
	state <= IDLE; //reset state to IDLE
    else
	state <= nxt_state;
end
	
	
	
always_comb begin
	nxt_state = state;
	clr_cnt = 0;
	vld = 0;
	
	case(state) 
	IDLE: 
	    if(sclk_fall == 1'b1)
		nxt_state = WAIT; //go to WAIT if a fall is detected
			
	WAIT:
	    if(sclk_rise == 1'b1)begin
		clr_cnt = 1;
		nxt_state = LEFT;// go to left is rise is detected
	    end
	LEFT:
	    if(eq24 == 1'b1)begin
		clr_cnt = 1;
		nxt_state = RIGHT; //go to read right
	    end
	RIGHT:
	    if(check22||check23)
		nxt_state = IDLE; // if not sync, go back to idle
	    else if(eq24)begin
		clr_cnt = 1;
		vld = 1;
		nxt_state = LEFT; // end 1 cycle of read, go to the next cycle
	    end
	endcase
	
	end
	
endmodule


