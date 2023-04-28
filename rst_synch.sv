/*
 Reset synchronizer that takes in raw push button signal and creates a signal
 that is deasserted at the negative edge of clock.
*/
module rst_synch
(
	input		RST_n,		// raw input from push button
	input		clk,		// clock, use negedge
	output reg	rst_n		// synchronized output to form global reset
);

// Declare internal signals
logic intmd;				// intermediate signal between 2 FFs

always_ff @(negedge clk, negedge RST_n) begin
   if (!RST_n) 
      intmd <= 1'b0;
   else 
      intmd <= 1'b1;
end

buf(rst_n, intmd);

endmodule
