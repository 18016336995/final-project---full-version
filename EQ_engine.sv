module EQ_engine(clk, rst_n, aud_in_lft, aud_in_rhgt, vld, POT_LP, POT_B1, 
    POT_B2, POT_B3, POT_HP, VOLUME, aud_out_lft, aud_out_rght);

input rst_n, clk, vld;
input [15:0] aud_in_lft, aud_in_rhgt;
input [11:0] POT_LP, POT_B1, POT_B2, POT_B3, POT_HP, VOLUME;
output [15:0] aud_out_lft, aud_out_rght;

logic [12:0] VOL;
assign VOl = {1'b0, VOLUME};

logic wrt_smpl_low, wrt_smpl_high;
assign wrt_smpl_high = vld;
assign wrt_smpl_low = ???  ///TODO;

// initiate low and high queue
logic [15:0] low_out_lft, low_out_rght, high_out_lft, high_out_rght;
low_freq_queue iDUT_l(.clk(clk), .rst_n(rst_n), .wrt_smpl(wrt_smpl_low), .lft_smpl(aud_in_lft),
      .rght_smpl(aud_in_rhgt), .lft_out(low_out_lft), .rght_out(low_out_rght), .sequencing(sequencing));

high_freq_queue iDUT_h(.clk(clk), .rst_n(rst_n), .wrt_smpl(wrt_smpl_high), .lft_smpl(aud_in_lft),
      .rght_smpl(aud_in_rhgt), .lft_out(high_out_lft), .rght_out(high_out_rght), .sequencing(sequencing))

// initiate 5 FIR ports
logic [15:0] LP_lft, LP_rght, B1_lft, B1_rght, B2_lft, B2_rght,
        B3_lft, B3_rght, HP_lft, HP_rght;
FIR_LP FIR_LP(.clk(clk), .rst_n(rst_n), .lft_in(low_out_lft),  
        .rght_in(low_out_rght), .lft_out(LP_lft), .rght_out(LP_rght), .sequencing(sequencing));
FIR_B1 FIR_B1(.clk(clk), .rst_n(rst_n), .lft_in(low_out_lft),  
        .rght_in(low_out_rght), .lft_out(B1_lft), .rght_out(B1_rght), .sequencing(sequencing));
FIR_B2 FIR_B2(.clk(clk), .rst_n(rst_n), .lft_in(low_out_lft),  
        .rght_in(low_out_rght), .lft_out(B2_lft), .rght_out(B2_rght), .sequencing(sequencing));
FIR_B3 FIR_B3(.clk(clk), .rst_n(rst_n), .lft_in(low_out_lft),  
        .rght_in(low_out_rght), .lft_out(B3_lft), .rght_out(B3_rght), .sequencing(sequencing));
FIR_HP FIR_HP(.clk(clk), .rst_n(rst_n), .lft_in(low_out_lft),  
        .rght_in(low_out_rght), .lft_out(HP_lft), .rght_out(HP_rght), .sequencing(sequencing));

// initiate 10 band scale ports for each FIR output
logic [15:0] band_LP_lft, band_LP_rght, band_B1_lft, band_B1_rght, band_B2_lft, band_B2_rght, 
        band_B3_lft, band_B3_rght, band_HP_lft, band_HP_rght;
band_scale iDUT_LP_lft(.POT(POT_LP), .audio(LP_lft), scaled(band_LP_lft));
band_scale iDUT_LP_rght(.POT(POT_LP), .audio(LP_rght), scaled(band_LP_rght));
band_scale iDUT_B1_lft(.POT(POT_LP), .audio(B1_lft), scaled(band_B1_lft));
band_scale iDUT_B1_rght(.POT(POT_LP), .audio(B1_rght), scaled(band_B1_rght));
band_scale iDUT_B2_lft(.POT(POT_LP), .audio(B2_lft), scaled(band_B2_lft));
band_scale iDUT_B2_rght(.POT(POT_LP), .audio(B2_rght), scaled(band_B2_rght));
band_scale iDUT_B3_lft(.POT(POT_LP), .audio(B3_lft), scaled(band_B3_lft));
band_scale iDUT_B3_rght(.POT(POT_LP), .audio(B3_rght), scaled(band_B3_rght));
band_scale iDUT_HP_lft(.POT(POT_LP), .audio(HP_lft), scaled(band_HP_lft));
band_scale iDUT_HP_rght(.POT(POT_LP), .audio(HP_rght), scaled(band_HP_rght));

logic [15:0] band_LP_lft_f, band_LP_rght_f, band_B1_lft_f, band_B1_rght_f, band_B2_lft_f, band_B2_rght_f, 
        band_B3_lft_f, band_B3_rght_f, band_HP_lft_f, band_HP_rght_f;

//a flop that help ease the timing constraint
always_ff @(posedge clk, negedge rst_n) begin: band_LP_lft
    if(!rst_n) begin
        band_LP_lft_f <= 0;
        band_LP_rght_f <= 0;
        band_B1_lft_f <= 0;
        band_B1_rght_f <= 0;
        band_B2_lft_f <= 0;
        band_B2_rght_f <= 0;
        band_B3_lft_f <= 0;
        band_B3_rght_f <= 0;
        band_HP_lft_f <= 0;
        band_HP_rght_f <=0;
    end
    else begin
        band_LP_lft_f <= band_LP_lft;
        band_LP_rght_f <= band_LP_rght;
        band_B1_lft_f <= band_B1_lft;
        band_B1_rght_f <= band_B1_rght;
        band_B2_lft_f <= band_B2_lft;
        band_B2_rght_f <= band_B2_rght;
        band_B3_lft_f <= band_B3_lft;
        band_B3_rght_f <= band_B3_rght;
        band_HP_lft_f <= band_HP_lft;
        band_HP_rght_f <= band_HP_rght;
    end
end

//sum the left and right scaled signals
logic [15:0] sum_lft, sum_rght;
always_ff @(posedge clk, negedge rst_n) begin: sum
    if(!rst_n) begin
        sum_lft <= 0;
        sum_rght <= 0;
    end
    else begin
        sum_lft <= band_B1_lft_f + band_B2_lft_f + band_B3_lft_f
                        + band_LP_lft_f + band_HP_lft_f;
        sum_rght <= band_B1_rght_f + band_B2_rght_f + band_B3_rght_f
                        + band_LP_rght_f + band_HP_rght_f;
    end
end

assign aud_out_lft = VOL * sum_lft;
assign aud_out_rght = VOL * sum_rght;

endmodule