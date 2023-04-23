/*
A2D_intf.sv

Use SPI_mnrch.sv to make an interface to A2D converter on DE0-Nano board
*/
module A2D_intf
(
	input			clk,		// system clk
	input			rst_n,		// async active low reset
	input			strt_cnv,	// Asserted for at least one clock cycle to start a conversion
	input [2:0]		chnnl,		// Specifies which A2D channel to convert
	output logic		cnv_cmplt,	// Asserted by A2D_intf to indicate the conversion has completed.
						// Stay asserted till the next strt_cnv
	output [11:0]		res,		// 12-bit result from A2D. (lower 12-bits read from SPI)
	output			SS_n,		// Active low serf select (to A2D)
	output			SCLK,		// Serial clk to A2D
	output			MOSI,		// serial data to A2D
	input			MISO		// serial data from A2D
);

// declare all internal signals
logic		snd, done, done2;	// start transaction enable signal; single transcation completed signal;
					// two transcations completed signal; respectively
logic [15:0]	cmd, resp;		// internal signals from SPI_mnrch

// dataflow assignment
assign cmd = {2'b00, chnnl, 11'h000};
assign res = resp[11:0];

// instantiate SPI_mnrch.sv block
SPI_mnrch	SPI_1(.clk(clk), .rst_n(rst_n), .snd(snd), .cmd(cmd), .MISO(MISO), .SS_n(SS_n),
		.SCLK(SCLK), .MOSI(MOSI), .done(done), .resp(resp));

// define all state names
typedef enum reg [1:0] {IDLE, CONVERT_1, WAIT, CONVERT_2} state_t;
state_t		state, nxt_state;


/*
State machine implementation:
Send command to A2D via SPI to ask for conversion on channel. Once that transaction completes
wait one clk cycle. Then start new transaction to read the result of the A2D conversion back.
*/
// sequential logic of SM
always_ff @(posedge clk, negedge rst_n) begin
   if (!rst_n) begin				// reset cnv_cmplt and bring state to IDLE
      cnv_cmplt <= 1'b0;
      state <= IDLE;
   end
   else begin
      state <= nxt_state;
      if (done2) begin				// if two transc completed, asserted cnv_cmplt
	 cnv_cmplt <= 1'b1;
      end
      else begin				// else cnv_cmplt remain low
	 cnv_cmplt <= 1'b0;
      end
   end
end

// combination logic of SM
always_comb begin
   // default state and output
   nxt_state = state;
   snd = 1'b0;
   done2 = 1'b0;

   case (state)
      // enter CONVERT_1 and start 1st transcation as strt_cnv asserted
      IDLE: begin
	 if (strt_cnv) begin
	    snd = 1'b1;
	    nxt_state = CONVERT_1;
	 end
      end
      // as first transaction complete (done asserted), enter WAIT state
      CONVERT_1: begin
	 if (done) begin
	    nxt_state = WAIT;
	 end
      end
      // wait for 1 clk, assert snd to start 2nd transcation, then enter CONVERT_2
      WAIT: begin
	 snd = 1'b1;
	 nxt_state = CONVERT_2;
      end
      // start 2nd transcation, if 2nd transc done, assert done2 and back to IDLE
      CONVERT_2: begin
	 if (done) begin
	    done2 = 1'b1;
	    nxt_state = IDLE;
	 end
      end
      // default state to IDLE
      default: nxt_state = IDLE;
   endcase
end


endmodule
