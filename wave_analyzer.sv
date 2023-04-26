module wave_analyzer(clk, rst_n, lft_inverse, rght_inverse, freq, amp);

    input clk, rst_n;
    input signed [15:0] lft_inverse, rght_inverse;
    output logic [15:0] freq, amp;

    // logic [15:0] temp_max;
    // logic [15:0] freq_counter;
    // logic [1:0] start;
    // logic finish;
    
    // assign amp = 0;
    // always_ff @(posedge clk, negedge rst_n) begin: find_max
    //     if(!rst_n) begin
    //         temp_max <= 0;
    //         start <= 1;
    //     end
    //     else if(start == 2) begin
    //         start = 0;
    //     end
    //     else if((temp_max - 16'd576) < 2 )
    //         start <= start + 1;

    //     temp_max = lft_inverse;
    // end

    // always_ff@(posedge clk, negedge rst_n) begin: find_freq
    //     if(!rst_n) begin
    //         freq_counter <= 0;
    //     end
    //     else if(start == 1)
    //         freq_counter <= freq_counter + 1;
    //     else if(start == 2) 
    //         freq_counter <= 0;   
    // end

    // assign finish = (start == 2);
    // assign freq = (finish) ? $ceil(50000000/freq_counter) : freq;

    logic signed [15:0] prev, next, curr, max, min;
    logic zero_cnt_flag;
    logic [1:0] zero_ord;
    logic [15:0] zero_cnt;

    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            prev <= 0;
            next <= 0;
            curr <= 0;
            max <= 0;
            min <= 0;
            zero_cnt <= 0;
            zero_cnt_flag <= 0;
            zero_ord <= 0;
        end else begin
            prev <= curr;
            curr <= next;
            next <= lft_inverse;
            /// find max
            if (curr > prev && curr > next && curr > max) begin
                max <= curr;
            end
            /// find min
            if (curr < prev && curr < next && curr < min) begin
                min <= curr;
            end
            /// first zero
            if (prev > 0 && curr <= 0 && (zero_ord == 0)) begin
                zero_cnt_flag <= 1;
                zero_ord <= 1;
            end
            /// second zero
            if (prev > 0 && curr <= 0 && (zero_ord == 1)) begin
                zero_cnt_flag <= 0;
                zero_ord <= 2;
            end

            if(zero_cnt_flag) 
                zero_cnt <= zero_cnt + 1;
        end

    assign freq = 1/(zero_cnt + zero_cnt);
    assign amp = max - min;

    end
    

endmodule