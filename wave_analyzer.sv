module wave_analyzer(clk, rst_n, lft_inverse, rght_inverse, freq, amp);
    input clk, rst_n;
    input [15:0] lft_inverse, rght_inverse;
    output [15:0] freq;
    output [11:0] amp;
    logic [15:0] temp_max;
    logic [15:0] freq_counter;
    logic [1:0] start;
    logic finish;
    
    assign amp = 0;
    always_ff @(posedge clk, negedge rst_n) begin: find_max
        if(!rst_n) begin
            temp_max <= 0;
            start <= 1;
        end
        else if(start == 2) begin
            start = 0;
        end
        else if((temp_max - 16'd576) < 2 )
            start <= start + 1;

        temp_max = lft_inverse;
    end

    always_ff@(posedge clk, negedge rst_n) begin: find_freq
        if(!rst_n) begin
            freq_counter <= 0;
        end
        else if(start == 1)
            freq_counter <= freq_counter + 1;
        else if(start == 2) 
            freq_counter <= 0;   
    end
    assign finish = (start == 2);
    assign freq = (finish) ? $ceil(50000000/freq_counter) : freq;
endmodule