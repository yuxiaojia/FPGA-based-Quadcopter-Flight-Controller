module UART_comm(clk, rst_n, RX, TX, resp, send_resp, resp_sent, cmd_rdy, cmd, data, clr_cmd_rdy);

 input clk, rst_n;  // clock and active low reset
 input RX;    // serial data input
 input send_resp;  // indicates to transmit 8-bit data (resp)
 input [7:0] resp;  // byte to transmit
 input clr_cmd_rdy;  // host asserts when command digested

 output TX;    // serial data output
 output resp_sent;  // indicates transmission of response complete
 output logic cmd_rdy;  // indicates 24-bit command has been received
 output logic [7:0] cmd;  // 8-bit opcode sent from host via BLE
 output logic [15:0] data; // 16-bit parameter sent LSB first via BLE

 wire [7:0] rx_data;  // 8-bit data received from UART
 wire rx_rdy;   // indicates new 8-bit data ready from UART

 ////////////////////////////////////////////////////
 // declare any needed internal signals/registers //
 // below including any state definitions        //
 /////////////////////////////////////////////////
 
 logic set_cmd_rdy; // SM output when cmd ready
 logic clr_rx_rdy;  // clear the ready state of receiving
 logic clr_cmd_rdy_i;  // clear the cmd ready when insert next data
 logic cmd_set;
 logic data_higher_set;  // signal finishing set the cmd and date higher byte
 logic [7:0]data_higher_byte; // second byte to receive

 // Define state as enum type 
 typedef enum reg [1:0] {IDLE,CMD,DATA} state_t;
 state_t state,nxt_state;


 ///////////////////////////////////////////////
 // Instantiate basic 8-bit UART transceiver //
 /////////////////////////////////////////////
 UART iUART(.clk(clk), .rst_n(rst_n), .RX(RX), .TX(TX), .tx_data(resp), .trmt(send_resp),
      .tx_done(resp_sent), .rx_data(rx_data), .rx_rdy(rx_rdy), .clr_rx_rdy(clr_rx_rdy));
  
 ////////////////////////////////
 // Implement UART_comm below //
 //////////////////////////////

// logic for storing the first byte to cmd
always_ff@(posedge clk, negedge rst_n) begin
 if(!rst_n) cmd <= 8'h0;
 else if(cmd_set)
   cmd <= rx_data;
end

// logic for storing the second byte to higher byte data
always_ff @(posedge clk, negedge rst_n) begin
 if(!rst_n) data_higher_byte <= 8'h0;
 else if(data_higher_set)
   data_higher_byte <= rx_data;
end

// append the data 
assign data = {data_higher_byte, rx_data};

// indicate if command is done
always_ff@(posedge clk, negedge rst_n) begin
 if(!rst_n)
   cmd_rdy <= 1'b0;
 else if(clr_cmd_rdy || clr_cmd_rdy_i)
   cmd_rdy <= 1'b0;
 else if(set_cmd_rdy)
   cmd_rdy <= 1'b1;
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
 clr_rx_rdy = 1'b0;
 clr_cmd_rdy_i = 1'b0;
 cmd_set = 1'b0;
 data_higher_set = 1'b0;
 set_cmd_rdy = 1'b0;
 nxt_state = state;
 
 case(state)
   IDLE: begin
     if(rx_rdy)begin
  cmd_set = 1'b1;
   clr_rx_rdy = 1'b1;
  clr_cmd_rdy_i = 1'b1;
  nxt_state = CMD;
  end
     end
   CMD: begin
       if(rx_rdy)begin
  data_higher_set = 1'b1;
   clr_rx_rdy = 1'b1;
  nxt_state = DATA;
         end
   end
   DATA: begin
       if(rx_rdy)begin
   clr_rx_rdy = 1'b1;
  set_cmd_rdy = 1'b1;
  nxt_state = IDLE;
         end
   end
   default: begin
  nxt_state = IDLE;
   end
 endcase
end
 
 
endmodule