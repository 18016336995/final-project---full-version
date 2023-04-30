module LED_drv(clk, rst_n, vld, lft_chnnl, rght_chnnl, LED);

    input clk, rst_n;
    input vld;			// indicates new chnnl sample is valid
    input signed [15:0] lft_chnnl;
    input signed [15:0] rght_chnnl;
    output logic [7:0] LED;

    logic [15:0] inten, inten_temp; // music intensity, calculated by RMS value of left and right inputs
    logic [31:0] sum, sum_lft, sum_lft_temp, sum_rght, sum_rght_temp;
    logic done;

    ///////////////////////////////////
    // implement square root module //
    /////////////////////////////////
    sqrt iSQRT(.clk, .rst_n, .go(vld), .mag(sum), .sqrt(inten_temp), .done);

    //////////////////////////////////////
    // ff to calculate music intensity //
    ////////////////////////////////////
    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            sum <= 0;
            inten <= 0;
        end
        else begin 
            sum <= sum_lft + sum_rght;
            if (done)
                inten <= inten_temp;
        end
    end

    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            sum_lft <= 0;
            sum_lft_temp <= 0;
        end
        else if (vld) begin
            sum_lft_temp <= lft_chnnl * lft_chnnl;
            sum_lft <= sum_lft_temp;
        end
    end

    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            sum_rght <= 0;
            sum_rght_temp <= 0;
        end
        else if (vld) begin
            sum_rght_temp <= lft_chnnl * lft_chnnl;
            sum_rght <= sum_rght_temp;
        end
    end    

    //////////////////////////////////////////
    // LED effect based on music intensity //
    ////////////////////////////////////////
    assign LED[0] = (inten > 16'h0000) ? 1 : 0;
    assign LED[1] = (inten > 16'h0800) ? 1 : 0;
    assign LED[2] = (inten > 16'h0b00) ? 1 : 0;
    assign LED[3] = (inten > 16'h0e00) ? 1 : 0;
    assign LED[4] = (inten > 16'h1100) ? 1 : 0;
    assign LED[5] = (inten > 16'h1400) ? 1 : 0;
    assign LED[6] = (inten > 16'h1700) ? 1 : 0;
    assign LED[7] = (inten > 16'h2000) ? 1 : 0;

endmodule