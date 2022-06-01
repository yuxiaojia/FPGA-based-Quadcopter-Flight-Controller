module reset_synch(clk,rst_n,RST_n);

input clk, RST_n;
output logic rst_n;

logic rst_mid; //mid ff logic
  always @(negedge clk) begin
	if(!RST_n) begin  //reset the ff
 	rst_mid <= 0;
	 rst_n <= 0;
	end else begin  //do the double ff
   	 rst_mid <= 1'b1; 
   	 rst_n <= rst_mid;
	end
  end
endmodule