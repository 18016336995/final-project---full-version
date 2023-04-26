module wave_analyzer_tb();

  logic clk;
  logic rst_n;
  logic signed [15:0] lft_inverse, rght_inverse;
  logic [15:0] freq, amp;
  const real pi = 3.1416;
  

  wave_analyzer iDUT (.*);
  
  // Generate clock signal
  always #5 clk = ~clk;
  
  // Initialize signals
  initial begin
    clk = 0;
    rst_n = 0;
    @(posedge clk);
    @(negedge clk);
    rst_n = 1;
    lft_inverse = 0;
    #100;
    
    // Generate sinusoidal waveform
    for (int i = 0; i < 2000000000; i++) begin
      lft_inverse = $signed(50 * $sin(i * pi / 10));
      #5;
    end
  end
  
endmodule