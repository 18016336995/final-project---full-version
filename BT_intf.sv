module BT_intf(next_n, clk, rst_n, prev_n, cmd_n, TX, RX);

input next_n;
input clk;
input rst_n;
input prev_n;
output logic cmd_n;
output logic TX;
input logic RX;

typedef enum logic [2:0] {IDLE,START,SET,  WAIT,SEND} state_t;
state_t state, nxt_state;
logic start_count;
logic [16:0] counter;
logic finish;
always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		counter <= '1;
	else 
		counter <= counter - 1;
end
assign finish = ~(|counter);
	
logic released_n, released_p, send, resp_rcvd;
logic [4:0] cmd_start;
logic [3:0] cmd_len;

PB_release iDUT0(.PB(next_n), .clk(clk), .rst_n(rst_n), .released(released_n));
PB_release iDUT1(.PB(prev_n), .clk(clk), .rst_n(rst_n), .released(released_p));
snd_cmd iDUT2(.cmd_start(cmd_start), .send(send), .cmd_len(cmd_len), 
	.resp_rcvd(resp_rcvd), .TX(TX), .RX(RX), .clk(clk), .rst_n(rst_n));

always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        state <= IDLE;
    end
    else begin
        state <= nxt_state;
    end
end

always_comb begin
	send = 0;
    cmd_start = 5'b00000;
	cmd_len = 4'b0000;
	cmd_n = 0;
    nxt_state = state;

    case(state) 

        IDLE: begin
			
			if(!finish) begin
				cmd_n = 1;
				
			end else begin
				cmd_n = 0;
				nxt_state = START;
			end
		end
		START: begin
			if(resp_rcvd) begin
				send = 1;
				cmd_start = 5'b0;
				cmd_len = 4'd6;
				nxt_state = SET;
			end
		end
		SET: begin	
			if(resp_rcvd) begin
				send = 1;
				cmd_start = 5'b00110;
				cmd_len = 4'd10;
				nxt_state = WAIT;
			end
		end
		WAIT: begin	
			if(resp_rcvd) begin
				nxt_state = SEND;
			end
		end
		SEND: begin
			if(released_n) begin
				cmd_start = 5'b10000;
				cmd_len = 4'd4;
				send = 1;
			end else if(released_p) begin
				cmd_start = 5'b10100;
				cmd_len = 4'd4;
				send = 1;
			end
		end
    endcase

end


endmodule