
module PB_release(clk,rst_n,PB,released);

input clk, rst_n;
input PB;

output released;


logic PB_mid; // flip once
logic PB_ff;  //flip twice
logic PB_fff;  //final ff

  always @(posedge clk) begin
	//preset the ff
	if(!rst_n) begin
	PB_mid <= 1;
	PB_ff <= 1;
	PB_fff <= 1;
	end else begin
   	PB_mid <= PB;
	PB_ff <= PB_mid;
	PB_fff <= PB_ff;
	end
  end

//get released  logic
assign released = ~PB_fff & PB_ff;

endmodule