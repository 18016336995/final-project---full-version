module PDM_decoder(clk, rst_n, lft_PDM, rght_PDM, lft_inverse, rght_inverse);
    input clk, rst_n, lft_PDM, rght_PDM;
    output logic [15:0] lft_inverse, rght_inverse;
   logic[15:0] accum_lft, accum_rght;  

    logic [10:0] timer;

    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            timer <= 0;
        end
        else if(timer == 11'd1152) begin
            timer <= 0;
        end
        else begin
            timer <= timer + 1;
        end
    end


    always_ff @(posedge clk, negedge rst_n) begin: accum_l
        if(!rst_n) begin
            accum_lft <= 0;
            lft_inverse <= 0;
        end
        else if(timer == 11'd1152) begin
            lft_inverse <= accum_lft;
            accum_lft <= 0;
        end
        else if(lft_PDM)
            accum_lft <= accum_lft + 1;
    end

     always_ff @(posedge clk, negedge rst_n) begin: accum_r
        if(!rst_n)begin
            rght_inverse <= 0;
            accum_rght <= 0;
        end
        else if(timer == 11'd1152) begin
            rght_inverse <= accum_rght;
            accum_rght <= 0;
        end
        else if(rght_PDM)
            accum_rght<= accum_rght + 1;

    end


endmodule