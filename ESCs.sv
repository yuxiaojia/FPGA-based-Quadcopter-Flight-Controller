module ESCs (
input clk, 
input motors_off, 
input wrt, 
input rst_n, 
input [10:0] frnt_spd, 
input [10:0] bck_spd, 
input [10:0] rght_spd, 
input [10:0] lft_spd, 
output frnt, 
output bck, 
output lft, 
output rght);

logic [10:0] frnt_spd1, bck_spd1, rght_spd1, lft_spd1;

// Implements the motor off feature, speed is forced to zero if motor is off
assign frnt_spd1 = motors_off ? 11'h000 : frnt_spd;
assign bck_spd1 = motors_off ? 11'h000 : bck_spd;
assign rght_spd1 = motors_off ? 11'h000 : rght_spd;
assign lft_spd1 = motors_off ? 11'h000 : lft_spd;

// Instantiate 4 copies of ESC interface
ESC_interface iESC1(.clk(clk),.rst_n(rst_n),.wrt(wrt),.SPEED(frnt_spd1),.PWM(frnt));
ESC_interface iESC2(.clk(clk),.rst_n(rst_n),.wrt(wrt),.SPEED(bck_spd1),.PWM(bck));
ESC_interface iESC3(.clk(clk),.rst_n(rst_n),.wrt(wrt),.SPEED(lft_spd1),.PWM(lft));
ESC_interface iESC4(.clk(clk),.rst_n(rst_n),.wrt(wrt),.SPEED(rght_spd1),.PWM(rght));

endmodule