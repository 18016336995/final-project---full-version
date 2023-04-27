module PDM(clk, rst_n, duty, PDM, PDM_n);
   input	clk, rst_n;			
	input [15:0] duty;			
	output reg PDM;
	output reg PDM_n;			

   /////////////////////////////////
   /// Declare internal signals ///
   ///////////////////////////////
   logic [15:0]	A, B, f1, f2;
   logic greater;	// flag if A >= B

   /// set greater flag
   assign greater = (A >= f2) ? 1'b1 : 1'b0;

   /// flop that stores duty signal
   always_ff @(posedge clk, negedge rst_n) begin
      if (!rst_n)
         A <= 1'b0;
      else 
         A <= duty;
   end

   /// mux of B and f1 = B - A
   always_comb begin
      if (greater)
         B = 16'hFFFF;
      else
         B = 16'h0000;

         f1 = B - A;
   end

   /// flop after f2 
   always_ff @(posedge clk, negedge rst_n) begin
      if (!rst_n)
         f2 <= 1'b0;
      else
         f2 <= f2 + f1;
   end

   /// output flops
   always_ff @(posedge clk, negedge rst_n) begin
      if (!rst_n) begin
         PDM <= 1'b0;
         PDM_n <= 1'b1;
      end
      else begin
         PDM <= greater;
         PDM_n <= ~greater; /// inverse PDM
      end
   end

endmodule
