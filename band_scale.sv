module band_scale(POT, audio, scaled);
	
input [11:0]POT;
input signed[15:0]audio;
output signed[15:0]scaled;

logic [23:0]POT_square;
logic signed[12:0]POT_13;
logic signed[28:0]result;

logic sign, smaller, larger, temp, temp1;
logic signed[15:0]result_out_neg, result_out_pos;



assign POT_square = POT * POT; // get the square of POT
assign POT_13 = {1'b0, POT_square[23:12]}; // make POT^2 a 13 bit signed value
assign result = audio * POT_13; 
assign sign = result[28]; // get the sign of result

or or0(temp,~result[27], ~result[26], ~result[25]); // determine when the result is negative, does it need to be satuated
and and0(smaller, temp, sign);

or or1(temp1,  result[27], result[26], result[25]);// determine when the result is positive, does it need to be satuated
and and1(larger, ~sign, temp1);
assign result_out_neg = (sign && smaller) ? 16'h8000 : result[25:10]; // negative result
assign result_out_pos = (~sign && larger) ? 16'h7FFF : result[25:10]; // positive result

assign scaled = (sign)? {result_out_neg} : {result_out_pos};

endmodule