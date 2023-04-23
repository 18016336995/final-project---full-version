module snd_cmd(cmd_start, send, cmd_len, resp_rcvd, TX, RX, clk, rst_n);

input [4:0]cmd_start;
input [3:0]cmd_len;
input send, clk, rst_n, RX;
output resp_rcvd, TX;

logic inc_addr; //increase signal from SM

logic [4:0]cmd_reg, reg1, reg2;
always @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		cmd_reg <= 0;
	else 
		cmd_reg <= reg2;
end
assign reg1 = (inc_addr)? cmd_reg + 1: cmd_reg; // a counter which controled by inc_addr signal
assign reg2 = (send)? cmd_start : reg1; // if send is asserted, load the new cmdstart value

logic[7:0] tx_data;
cmdROM iDUT0(.clk(clk),.addr(cmd_reg),.dout(tx_data)); // call cmdROM

logic[4:0]add, compare_reg, compare_out;
always @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		compare_out <= 0;
	else 
		compare_out <= compare_reg;
end
assign add = cmd_len + cmd_start; // an always block to help check whether the cmd has be loaded completely
assign compare_reg = (send)? add : compare_out; // if send asserted, start to compare

logic last_byte;
assign last_byte = (cmd_reg == compare_out); // if the counter equals to length of cmd, assert last_byte

logic  clr_rx_rdy, rx_rdy;
assign clr_rx_rdy = rx_rdy;

logic TX, RX, trmt, tx_done;
logic[7:0] rx_data;
UART iUART(.clk(clk), .rst_n(rst_n),.RX(RX),.TX(TX), .rx_rdy(rx_rdy),
	.clr_rx_rdy(clr_rx_rdy),.rx_data(rx_data),.trmt(trmt),.tx_data(tx_data),.tx_done(tx_done)); // call UART


assign resp_rcvd = (rx_rdy && (rx_data == 8'h0A)) ? 1'b1 : 1'b0; // resp_rcv is asserted when rxdata equals to 0A and rx_rdy is 1
	
typedef enum reg [1:0] {IDLE, SENDBYTE, FINAL} state_t;
state_t state, nxt_state;

always_ff @(posedge clk or negedge rst_n) begin
	if (!rst_n)
		state <= IDLE; // reset state to IDLE
	else
		state <= nxt_state; 
end

always_comb begin
		nxt_state = state;
		inc_addr = 0;
		trmt = 0;
		
		case(state)
			IDLE: begin
			if(send)
					nxt_state = SENDBYTE; // if send asserted go to sendBYTE
			
			end
			
			
			SENDBYTE: begin
				trmt = 1;
				inc_addr = 1;
				nxt_state = FINAL; // assert trmt and inc_addr
			end
			
			
			FINAL  : begin 
				if(tx_done) begin //if uart finishes and counter finishes end 
					if(last_byte) begin
						nxt_state = IDLE;
					end
					else begin
						nxt_state = SENDBYTE;// else then keep sending byte
					end
				end
			end
			
			default:
				nxt_state = IDLE;
			
		endcase
	
	
	end


endmodule