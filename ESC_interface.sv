 module ESC_interface (clk,rst_n, wrt, SPEED, PWM);

input clk,rst_n,wrt;  // 50MHZ clk
input [10:0] SPEED;
output logic PWM;

logic [12:0] speed_mult;  // SPEED times 3
logic [13:0] setting;  // pulse width
logic [13:0] q; //output from first ff
logic reset;

logic wrt_f;

logic [10:0] SPEED_f;

//double ff the wrt
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n) begin
		wrt_f <= 0;
		end else begin
		wrt_f <= wrt ;
		end
 	end

	//double ff the d_diff_sat
	 always @(posedge clk, negedge rst_n ) begin
		if(!rst_n) begin
		SPEED_f <= 0;
		end else begin
		SPEED_f <= SPEED ;
		end
 	end

// calculate the clock cycle
assign speed_mult = SPEED_f * 2'b11; 

// total width of clock cycle
assign setting = speed_mult + 6250;

//count the clock cycle
always_ff @(posedge clk,negedge rst_n) begin
	if(!rst_n)
         q <= 1'b0; 
        else if(wrt_f)
         q <= setting;  // set the output to be setting
        else
         q <= q - 1;  // decrementing the output by 1
end

assign reset = ~|q;  // see if PWM needs reset

// Set the PWM pulse
always_ff @( posedge clk,negedge rst_n) begin
	if(!rst_n)
         PWM <= 1'b0;
        else if(reset)  
         PWM <= 1'b0;  
        else if (wrt_f)  // write to rise PWM pulse
         PWM <= 1'b1;
        else
         PWM <= PWM;
        
end


endmodule

