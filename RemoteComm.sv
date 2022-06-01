module RemoteComm(clk, rst_n, RX, TX, cmd, data, send_cmd, cmd_sent, resp_rdy, resp, clr_resp_rdy);

 input clk, rst_n;  // clock and active low reset
 input RX;    // serial data input
 input send_cmd;   // indicates to tranmit 24-bit command (cmd)
 input [7:0] cmd;  // 8-bit command to send
 input [15:0] data;  // 16-bit data that accompanies command
 input clr_resp_rdy;  // asserted in test bench to knock down resp_rdy
 

 output TX;    // serial data output
 output logic cmd_sent;  // indicates transmission of command complete
 output resp_rdy;  // indicates 8-bit response has been received
 output [7:0] resp;  // 8-bit response from DUT
        
 ////////////////////////////////////////////////////
 // Declare any needed internal signals/registers //
 // below including state definitions            //
 /////////////////////////////////////////////////
 logic [7:0]data_higher; // higher byte of data
 logic [7:0]data_lower; // lower byte of data
 logic [1:0] sel; // sel between data and command
 logic frm_sent;
 logic tx_done;  //indicate transmitting finishes
 logic trmt;  // indicate transmitting starts
 logic [7:0] tx_data;  
 // Define state as enum type 
 typedef enum reg [1:0] {IDLE,HIGH,LOW} state_t;
 state_t state,nxt_state;

 ///////////////////////////////////////////////
 // Instantiate basic 8-bit UART transceiver //
 /////////////////////////////////////////////
 UART iUART(.clk(clk), .rst_n(rst_n), .RX(RX), .TX(TX), .tx_data(tx_data), .trmt(trmt),
      .tx_done(tx_done), .rx_data(resp), .rx_rdy(resp_rdy), .clr_rx_rdy(clr_resp_rdy));
     
 /////////////////////////////////
 // Implement RemoteComm Below //
 ///////////////////////////////
// logic for transmitting higher byte of data
always_ff@(posedge clk, negedge rst_n) begin
 if(!rst_n)
   data_higher <= 8'h00;
 if(send_cmd)
   data_higher <= data[15:8];
end

// logic for transmitting the lower byte of data
always_ff @(posedge clk, negedge rst_n) begin
 if(!rst_n)
   data_lower <= 8'h00;
 else if(send_cmd)
   data_lower <= data[7:0];
end

//select the data to transmit
assign tx_data = sel[1] ?  cmd : (sel[0] ? data_higher : data_lower) ;

// indicate if command is done
always_ff@(posedge clk, negedge rst_n) begin
 if(!rst_n)
   cmd_sent <= 1'b0;
 else if(frm_sent)
   cmd_sent <= 1'b1;
end

//infer state machine flop
always_ff@(posedge clk, negedge rst_n) begin
 if(!rst_n)
   state <= IDLE;
 else
   state <= nxt_state;
end

// state machine logic
always_comb begin
 sel = 2'b00;
 trmt = 1'b0;
 frm_sent = 1'b0;
 nxt_state = IDLE;
 
 case(state)
   IDLE: begin
     if(send_cmd)begin  // transmit the command
  trmt = 1'b1;  // start transmitting after command sent
  sel = 2'b10;
  nxt_state = HIGH;
  end else if (tx_done) begin  // transmitting  all done
  frm_sent = 1'b1;
  end
     end 
   HIGH: begin
       if(tx_done)begin  // start tranmitting the higher byte
  trmt = 1'b1;
  sel = 2'b01;
  nxt_state = LOW;
         end else begin  // stay if trasmitting not done
  trmt = 1'b0;
  nxt_state = HIGH;
  end
   end
   LOW: begin
       if(tx_done)begin  // start tranmitting the lower byte
                trmt = 1'b1;
  sel = 2'b00;
  nxt_state = IDLE;
         end else begin  // stay if trasmitting not done
  trmt = 1'b0;
  nxt_state = LOW;
  end
   end
   default: begin
  nxt_state = IDLE;
   end
 endcase
end

endmodule