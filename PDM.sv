/*
Pulse Density Modulation (PDM) module
*/
module PDM
(
	input		clk,			// 50MHz system clk
	input		rst_n,			// Asynch active low
	input [15:0]	duty,			// unsigned 16-bit duty cycle
	output reg	PDM,			// PDM signal
	output reg	PDM_n			// PDM compliment (use preset)
);


/////////////////////////////////////
////  Declare internal signals  ////
///////////////////////////////////

// A1 and A3 are output of FF of duty[15:0]
// f = B - A correspond to B2 = B1 - A1
// f = A + B correspond to B3 = B3 + B2
logic [15:0]	A1, A3, B1, B2, B3;
logic AgteB;					// A3 greater or equal to B3


///////////////////////////////////
////  Dataflow assign block  ////
/////////////////////////////////

// compare A3 and B3
assign AgteB = (A3 >= B3) ? 1'b1 : 1'b0;


//////////////////////////////////////
////  Combinational logic block  ////
////////////////////////////////////

// Mux of B1 and f = B - A  (B2 = B1 - A1)
always_comb begin
   if (AgteB)
      B1 = 16'hFFFF;
   else
      B1 = 16'h0000;
   B2 = B1 - A1;
end


///////////////////////////////////
////  Sequential logic block  ////
/////////////////////////////////

// FF comes after duty signal
always_ff @(posedge clk, negedge rst_n) begin
   if (!rst_n) begin
      A1 <= 1'b0;
      A3 <= 1'b0;
   end
   else begin
      A1 <= duty;
      A3 <= duty;
   end
end

// FF comes after f = A + B  (B3 = B3 + B2)
logic [15:0] B4;
always_ff @(posedge clk, negedge rst_n) begin
   if (!rst_n)
      B3 <= 1'b0;
   else
      B3 <= B4;				// accumulator
end
assign B4 = B3 + B2;

// 2 FFs come after AB comparator
always_ff @(posedge clk, negedge rst_n) begin
   if (!rst_n) begin
      PDM <= 1'b0;				// PDM reset to 0
      PDM_n <= 1'b1;			 	// PDM_n preset to 1
   end
   else begin
      PDM <= AgteB;
      PDM_n <= ~AgteB;				// PDM inverse
   end
end


endmodule
