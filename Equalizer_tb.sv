module Equalizer_tb();

	reg clk,RST_n;
	reg next_n,prev_n,Flt_n;
	reg [11:0] LP,B1,B2,B3,HP,VOL;

	wire [7:0] LED;
	wire ADC_SS_n,ADC_MOSI,ADC_MISO,ADC_SCLK;
	wire I2S_data,I2S_ws,I2S_sclk;
	wire cmd_n,RX_TX,TX_RX;
	wire lft_PDM,rght_PDM;
	wire lft_PDM_n,rght_PDM_n;

	//////////////////////
	// Instantiate DUT //
	////////////////////
	Equalizer iDUT(.clk(clk),.RST_n(RST_n),.LED(LED),.ADC_SS_n(ADC_SS_n),
					.ADC_MOSI(ADC_MOSI),.ADC_SCLK(ADC_SCLK),.ADC_MISO(ADC_MISO),
					.I2S_data(I2S_data),.I2S_ws(I2S_ws),.I2S_sclk(I2S_sclk),.cmd_n(cmd_n),
					.sht_dwn(sht_dwn),.lft_PDM(lft_PDM),.rght_PDM(rght_PDM),
					.lft_PDM_n(lft_PDM_n),.rght_PDM_n(rght_PDM_n),.Flt_n(Flt_n),
					.next_n(next_n),.prev_n(prev_n),.RX(RX_TX),.TX(TX_RX));
		
		
	//////////////////////////////////////////
	// Instantiate model of RN52 BT Module //
	////////////////////////////////////////	
	RN52 iRN52(.clk(clk),.RST_n(RST_n),.cmd_n(cmd_n),.RX(TX_RX),.TX(RX_TX),.I2S_sclk(I2S_sclk),
			.I2S_data(I2S_data),.I2S_ws(I2S_ws));

	//////////////////////////////////////////////
	// Instantiate model of A2D and Slide Pots //
	////////////////////////////////////////////		   
	A2D_with_Pots iPOTs(.clk(clk),.rst_n(RST_n),.SS_n(ADC_SS_n),.SCLK(ADC_SCLK),.MISO(ADC_MISO),
						.MOSI(ADC_MOSI),.LP(LP),.B1(B1),.B2(B2),.B3(B3),.HP(HP),.VOL(VOL));

	logic [15:0] rght_inverse, lft_inverse;
	PDM_decoder iPDM(.clk(clk), .rst_n(RST_n), .lft_PDM(lft_PDM), .lft_inverse(lft_inverse), .rght_PDM(rght_PDM), 
					.rght_inverse(rght_inverse));	
  
    logic [21:0] freq_h, freq_l;
	logic [11:0] amp_h, amp_l;
	logic reset;
	wave_analyzer_low iWAVE_l(.clk(clk), .rst_n(RST_n), .lft_inverse, .rght_inverse, .freq(freq_l), .amp(amp_l), .reset);
	wave_analyzer_high iWAVE_h(.clk(clk), .rst_n(RST_n), .lft_inverse, .rght_inverse, .freq(freq_h), .amp(amp_h), .reset);
	logic [21:0] seq_LP, seq_B1, seq_B2, seq_B3, seq_HP;
	logic [11:0] amp_LP, amp_B1, amp_B2, amp_B3, amp_HP;

	always_ff @(posedge clk, negedge RST_n) begin
		if(!RST_n) begin
			seq_LP <= 0;
			seq_B1 <= 0;
			seq_B2 <= 0;
			seq_B3 <= 0;
			seq_HP <= 0;
			amp_LP <= 0;
			amp_B1 <= 0;
			amp_B2 <= 0;
			amp_B3 <= 0;
			amp_HP <= 0;
		end else if(LP !== 0) begin
			seq_LP <= freq_l;
			amp_LP <= amp_l;
		end else if(B1 !== 0) begin
			seq_B1 <= freq_l;
			amp_B1 <= amp_l;
		end else if(B2 !== 0) begin
			seq_B2 <= freq_h;
			amp_B2 <= amp_h;
		end else if(B3 !== 0) begin
			seq_B3 <= freq_h;
			amp_B3 <= amp_h;
		end else if(HP !== 0) begin
			seq_HP <= freq_h;
			amp_HP <= amp_h;
		end
	end


		
	initial begin 
		reset = 0;
		RST_n = 0;
		clk = 0;
		next_n = 1;
		prev_n = 1;
		Flt_n = 1;
		@(posedge clk);
        @(negedge clk); /// wait one clock cycle
		RST_n = 1;


		LP = 12'd2048;
		B1 = 12'd0;
		B2 = 12'd0;
		B3 = 12'd0;
		HP = 12'd0;
		VOL = 12'd2048;
		repeat (4200000) @(posedge clk);
		reset = 1;
		@(posedge clk);
        @(negedge clk);
		if(LED[7] | LED[6] | LED[5]) begin
			$display("LED shouldnt be this bright when wave intensity is low");
			$stop();
		end


		reset = 0;
		LP = 12'd0;
		B1 = 12'd2048;
		B2 = 12'd0;
		B3 = 12'd0;
		HP = 12'd0;
		VOL = 12'd3072;
		repeat (400000) @(posedge clk);
		reset = 1;
		@(posedge clk);
        @(negedge clk);
		if(LED[7]) begin
			$display("LED shouldnt be this bright when wave intensity is low");
			$stop();
		end

		reset = 0;
		LP = 12'd0;
		B1 = 12'd0;
		B2 = 12'd2048;
		B3 = 12'd0;
		HP = 12'd0;
		VOL = 12'd4095;
		repeat (300000) @(posedge clk);
		reset = 1;
		@(posedge clk);
        @(negedge clk);
		

		reset = 0;
		LP = 12'd0;
		B1 = 12'd0;
		B2 = 12'd0;
		B3 = 12'd2048;
		HP = 12'd0;
		VOL = 12'd4095;
		repeat (150000) @(posedge clk);		
		reset = 1;
		@(posedge clk);
        @(negedge clk);
		

		reset = 0;
		LP = 12'd0;
		B1 = 12'd0;
		B2 = 12'd0;
		B3 = 12'd0;
		HP = 12'd2048;
		VOL = 12'd4095;
		repeat (100000) @(posedge clk);		
		@(posedge clk);
        @(negedge clk);
		reset = 1;
		

		// In our project, we use two wave analyzer to detect the freq and amplitude
		// freq is detected by detecting the clk cycles between a zero crossing 
		// and the zero crossing after its next zero crossing
		// Thus, if we devided 50M by the cycles we get, we can get the frequency
		// ex. in LP, the min cycles should be 50M/80
		if(seq_LP < 20'd625000) begin
			$display("FIR_LP failed to filter a wave with frequency lower than 80hz!");
			$stop();
		end
		if(seq_B1 > 20'd625000 | seq_B1 < 20'd178572) begin
			$display("FIR_B1 failed to filter a wave with frequency higher than 80hz, while lower than 280hz!");
			$stop();
		end
		if(seq_B2 > 20'd178571 | seq_B2 < 20'd50000) begin
			$display("FIR_B2 failed to filter a wave with frequency higher than 280hz, whiler lower than 1khz!");
			$stop();
		end
		if(seq_B3 > 20'd50000 | seq_B3 < 20'd13889) begin
			$display("FIR_B3 failed to filter a wave with frequency higher than 1khz, while lower than 3.6khz");
			$stop();
		end
		if(seq_HP > 20'd13889) begin
			$display("FIR_HP failed to filter a wave with frequency higher than 3.6hz!");
			$stop();
		end

		if(amp_LP > amp_B1 | amp_B1 > amp_B2) begin
			$display("The amplitude does not increase when vol is increased %d %d %d", amp_LP, amp_B1, amp_B2);
			$stop();
		end
		$display("yahoo!");
		$stop();
	end
		

	always
		#5 clk = ~ clk;
  
endmodule	  