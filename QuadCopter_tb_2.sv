module QuadCopter_tb_2();
   
//// Interconnects to DUT/support defined as type wire /////
wire SS_n,SCLK,MOSI,MISO,INT;
wire RX,TX;
wire [7:0] resp;    // response from DUT
wire cmd_sent,resp_rdy;
wire frnt_ESC, back_ESC, left_ESC, rght_ESC;

////// Stimulus is declared as type reg ///////
reg clk, RST_n;
reg [7:0] host_cmd;    // command host is sending to DUT
reg [15:0] data;    // data associated with command
reg send_cmd;     // asserted to initiate sending of command
reg clr_resp_rdy;    // asserted to knock down resp_rdy

wire [7:0] LED;

logic error;

//// Maybe define some localparams for command encoding ///
localparam SET_PTCH  = 8'h02;
localparam SET_ROLL  = 8'h03;
localparam SET_YAW   = 8'h04;
localparam SET_THRST  = 8'h05;
localparam EMER_LAND  = 8'h07;
localparam MTRS_OFF  = 8'h08;
localparam CALIBRATE  = 8'h06;

localparam ACK = 8'hA5;

////////////////////////////////////////////////////////////////
// Instantiate Physical Model of Copter with Inertial sensor //
////////////////////////////////////////////////////////////// 
CycloneIV iQuad(.clk(clk),.RST_n(RST_n),.SS_n(SS_n),.SCLK(SCLK),.MISO(MISO),
                .MOSI(MOSI),.INT(INT),.frnt_ESC(frnt_ESC),.back_ESC(back_ESC),
    .left_ESC(left_ESC),.rght_ESC(rght_ESC));         
  
  
////// Instantiate DUT ////////
QuadCopter iDUT(.clk(clk),.RST_n(RST_n),.SS_n(SS_n),.SCLK(SCLK),.MOSI(MOSI),.MISO(MISO),
                .INT(INT),.RX(RX),.TX(TX),.FRNT(frnt_ESC),.BCK(back_ESC),
    .LFT(left_ESC),.RGHT(rght_ESC));


//// Instantiate Master UART (mimics host commands) //////
RemoteComm iREMOTE(.clk(clk), .rst_n(RST_n), .RX(TX), .TX(RX),
                     .cmd(host_cmd), .data(data), .send_cmd(send_cmd),
      .cmd_sent(cmd_sent), .resp_rdy(resp_rdy),
      .resp(resp), .clr_resp_rdy(clr_resp_rdy));

initial begin

init();

// Turn on motor 
send(CALIBRATE, 16'h0000);

$display("First cal done");

// Set desire thrust
send(SET_THRST, 16'h00ff);

if(iDUT.thrst !== data[8:0]) begin
 $display("thrst not match");
 error = 1;
end

// Test whether thrust is reached
repeat (6000000) @(posedge clk);
checkval(iDUT.thrst, data[8:0]);

$display("First thrust done");

// Set desire pitch
send(SET_PTCH, 16'h0100);

if(iDUT.d_ptch !== data) begin
 $display("d_ptch not match");
 error = 1;
end


repeat (500000) @(posedge clk);

// Set desire pitch
send(SET_PTCH, 16'h0050);

repeat (2000000) @(posedge clk);

$display("Pitch done");

// Set desire roll
send(SET_ROLL, 16'hff80);

if(iDUT.d_roll !== data) begin
 $display("d_roll not match");
 error = 1;
end

// Test whether roll is reached
repeat (6000000) @(posedge clk);
checkval(iDUT.roll, data);

$display("Roll done");

// Set desire yaw
send(SET_YAW, 16'h0080);

if(iDUT.d_yaw !== data) begin
 $display("d_yaw not match");
 error = 1;
end

// Test whether yaw is reached
repeat (6000000) @(posedge clk);
checkval(iDUT.yaw, data);

$display("Yaw done");
  

$display("Yahoo all test");

$stop();

end



always
  #10 clk = ~clk;

`include "tb_task.sv";
endmodule