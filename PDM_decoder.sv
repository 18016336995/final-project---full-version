module PDM_decoder(clk, rst_n, lft_PDM, rght_PDM, lft_input, rght_input);
    input clk, rst_n, lft_PDM, rght_PDM;
    output logic [15:0] lft_input, rght_input;

    logic[13:0] timer;
    logic next_accum;
    always_ff @(posedge clk, negedge rst_n) begin: clk_counter
        if(!rst_n)
            timer <= 0;
        else
            timer <= timer + 1;
    end
    assign next_accum = & timer;

    logic[15:0] accum_lft, accum_rght;
    always_ff @(posedge clk, negedge rst_n) begin: accum_l
        if(!rst_n) begin
            accum_lft <= 0;
            lft_input <= 0;
        end
        else if(next_accum) begin
            lft_input <= accum_lft;
            accum_lft <= 0;
        end
        else if(lft_PDM)
            accum_lft <= accum_lft + 1;
    end

     always_ff @(posedge clk, negedge rst_n) begin: accum_r
        if(!rst_n)begin
            rght_input <= 0;
            accum_rght <= 0;
        end
        else if(next_accum) begin
            rght_input <= accum_rght;
            accum_rght <= 0;
        end
        else if(rght_PDM)
            accum_rght<= accum_rght + 1;
    end


endmodule