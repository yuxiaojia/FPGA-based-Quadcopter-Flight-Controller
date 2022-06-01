module PD_math(clk,rst_n,vld,desired,actual,pterm,dterm);

 
	input clk,rst_n;
	input vld;
	input [15:0] desired, actual;	
	output signed[11:0] dterm;
	output logic signed[9:0] pterm;

    //error signal
    logic signed[16:0] err;
	logic signed[9:0] err_sat;

	logic signed[9:0] err_sat_f;


	//difference signal
	logic signed[9:0] D_diff;
	logic signed[6:0] D_diff_sat;

	//pipeline signal
	logic signed[9:0] pterm_f;

	logic signed[6:0] D_diff_sat_f;
	
	localparam DTERM = 5'b00111;

	localparam D_QUEUE_DEPTH = 12;
	logic signed [9:0] prev_err [0:D_QUEUE_DEPTH - 1];
	genvar i;

	// get the error
	assign err = {actual[15],actual} - {desired[15],desired}; //error - desired


	// get the error saturated
	assign err_sat_f = 
   (err[16] == 0) ? (|err[15:9] ? 10'b0111111111 : err[9:0]): 
   (&err[15:9] ? err[9:0] : 10'b1000000000 );

   //ff the err_sat
	 always @(posedge clk, negedge rst_n ) begin
		if(!rst_n)begin
			err_sat <= 0;
		end else begin
			err_sat <= err_sat_f;
		end
	
 	end

	//get the pterm_f
 	assign pterm_f = {err_sat[9],err_sat[9:1]} + {err_sat[9],err_sat[9],err_sat[9],err_sat[9:3]};

	 /////////////////////////////////////////
  	// For now just flop to form prev_err //
  	///////////////////////////////////////
	generate
	for(i = 0; i < D_QUEUE_DEPTH; i = i+1)  begin: queue
	always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n)
	  prev_err[i] <= 10'h000;
	else if (vld && i == 0)
	  prev_err[i] <= err_sat;
	else if(vld)
	prev_err[i] <= prev_err[i-1] ;
	end
	end
	endgenerate

	// get the difference from error and previous error
 	assign D_diff = err_sat - prev_err[D_QUEUE_DEPTH-1];


		//get the difference saturated
        assign D_diff_sat_f = 
   (D_diff[9] == 0) ? ( |D_diff[8:6] ? 7'b0111111 : D_diff[6:0]): 
   (&D_diff[8:6] ? D_diff[6:0] : 7'b1000000);

		//get the dterm
        assign dterm = D_diff_sat * $signed(DTERM);

	//ff the pterm
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n)begin
		pterm <= 0;
		end else begin
		pterm <= pterm_f;
		end
	
 	end

	//double ff the d_diff_sat
	 always @(posedge clk, negedge rst_n ) begin
		if(!rst_n)begin
			D_diff_sat <= 0;
		end else begin
			D_diff_sat <= D_diff_sat_f;
		end
	
 	end

endmodule
