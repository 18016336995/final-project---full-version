module wave_analyzer_high(clk, rst_n, lft_inverse, rght_inverse, freq, amp);

    input clk, rst_n;
    input signed [15:0] lft_inverse, rght_inverse;
    output logic [31:0] freq;
    output logic [11:0] amp;

 

    logic signed [15:0] prev, curr, max, min, next;
    logic zero_cnt_flag;
    logic [1:0] zero_ord;
    logic [31:0] zero_cnt;

    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            prev <= 0;
            next <= 0;
            curr <= 0;
            max <= 16'd567;
            min <= 16'd567;
            zero_cnt <= 0;
            zero_cnt_flag <= 0;
            zero_ord <= 0;
        end else begin
            prev <= curr;
            curr <= next;
            next <= lft_inverse;
            /// find max
            if (curr > max) begin
                max <= curr;
            end
            /// find min
            if (curr < min && curr > 16'd255) begin
                min <= curr;
            end	
            /// first zero
            if (curr > 16'd567 && next <= 16'd567 && (zero_ord == 0)) begin
                zero_cnt_flag <= 1;
                zero_ord <= 1;
            end
            /// second zero
            if (prev > 16'd567 && curr <= 16'd567 && (zero_ord == 1)  && zero_cnt > 32'd3000) begin
                zero_cnt_flag <= 0;
                zero_ord <= 2;
            end

            if(zero_cnt_flag) 
                zero_cnt <= zero_cnt + 1;
        end

    assign freq = zero_cnt;
    assign amp = max - min;

    end
    

endmodule