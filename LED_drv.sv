module LED_drv(clk, rst_n, vld, lft_chnnl, rght_chnnl, LED);

    input clk, rst_n;
    input vld;			// indicates new chnnl sample is valid
    input signed [15:0] lft_chnnl;
    input signed [15:0] rght_chnnl;
    output logic [7:0] LED;

    logic [15:0] inten, temp; // music intensity, calculated by RMS value of left and right inputs
    logic [31:0] sum;
    logic done;
    sqrt iDUT_sqrt(.mag(sum), .sqrt(temp), .go(vld), .clk, .rst_n, .done);

    //////////////////////////////////////
    // ff to calculate music intensity //
    ////////////////////////////////////
    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            sum <= 0;
	    inten <= 0;
        end
        else begin
            if (vld) begin
                // calculate RMS value
                sum <= (lft_chnnl * lft_chnnl + rght_chnnl * rght_chnnl);
		
            end
	    if(done)
		inten <= temp;
        end
    end

    //////////////////////////////////////////
    // LED effect based on music intensity //
    ////////////////////////////////////////
 

   
    assign LED[0] = (inten > 16'h0000) ? 1 : 0;
    assign LED[1] = (inten > 16'h0400) ? 1 : 0;
    assign LED[2] = (inten > 16'h0600) ? 1 : 0;
    assign LED[3] = (inten > 16'h0800) ? 1 : 0;
    assign LED[4] = (inten > 16'h0a00) ? 1 : 0;
    assign LED[5] = (inten > 16'h0c00) ? 1 : 0;
    assign LED[6] = (inten > 16'h1000) ? 1 : 0;
    assign LED[7] = (inten > 16'h2000) ? 1 : 0;
    


endmodule