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
  
    logic [31:0] freq_h, freq_l;
	logic [11:0] amp_h, amp_l;
	wave_analyzer_low iWAVE_l(.clk(clk), .rst_n(RST_n), .lft_inverse, .rght_inverse, .freq(freq_l), .amp(amp_l));
	wave_analyzer_high iWAVE_h(.clk(clk), .rst_n(RST_n), .lft_inverse, .rght_inverse, .freq(freq_h), .amp(amp_h));
	initial begin
		clk = 0;
		RST_n = 0;
		next_n = 1;
		prev_n = 1;
		Flt_n = 1;

		@(posedge clk);
        @(negedge clk); /// wait one clock cycle
        RST_n = 1;

		// test low pass band, after sequencing started, a low freq wave will be produced
		LP = 12'd0;
		B1 = 12'd2048;
		B2 = 12'd0;
		B3 = 12'd0;
		HP = 12'd0;
		VOL = 12'd4095;
		repeat (7000000) @(posedge clk);
		
		$stop();
	end

	always
		#5 clk = ~ clk;
  
endmodule	  