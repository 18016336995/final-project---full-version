module LED_drv(clk, rst_n, vld, lft_chnnl, rght_chnnl, LED);

    input clk, rst_n;
    input vld;			// indicates new chnnl sample is valid
    input signed [15:0] lft_chnnl;
    input signed [15:0] rght_chnnl;
    output logic [7:0] LED;

    logic [15:0] inten; // music intensity, calculated by RMS value of left and right inputs

    //////////////////////////////////////
    // ff to calculate music intensity //
    ////////////////////////////////////
    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n) 
            inten <= 0;
        else 
            if (vld) 
                inten <= (lft_chnnl ^ 16'h8000) + (rght_chnnl ^ 16'h8000);
    end

    //////////////////////////////////////////
    // LED effect based on music intensity //
    ////////////////////////////////////////
    assign LED[0] = (inten > 16'h0000) ? 1 : 0;
    assign LED[1] = (inten > 16'h0100) ? 1 : 0;
    assign LED[2] = (inten > 16'h0300) ? 1 : 0;
    assign LED[3] = (inten > 16'h0400) ? 1 : 0;
    assign LED[4] = (inten > 16'h0500) ? 1 : 0;
    assign LED[5] = (inten > 16'h0600) ? 1 : 0;
    assign LED[6] = (inten > 16'h0800) ? 1 : 0;
    assign LED[7] = (inten > 16'h0900) ? 1 : 0;

endmodule