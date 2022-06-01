module SPI_mnrch(clk,rst_n,SS_n,SCLK,MOSI,MISO,wrt,wt_data,done,rd_data);

input clk,rst_n;  
input MISO;	
input wrt;
input [15:0] wt_data;

output logic SS_n;
output SCLK, MOSI;
output done;
output [15:0] rd_data;

logic [4:0]bit_cntr;  // count the times shift register shifted
logic[3:0] SCLK_div;  // count the clk to match the SLCK
logic ld_SCLK;  //  inform start of the SLCK

logic[15:0] shft_reg;  // value in shift register
logic init, shift;  // start machine output
logic set_done, done;  // inform transition is done
logic done_counter;  // inform shift is done

typedef enum reg [1:0] {IDLE, SHIFT, FINISH } state_t;
state_t state, nxt_state;

//bit counter to count the shift register shifted
always_ff @(posedge clk or negedge rst_n) begin
 
  if (!rst_n)
    bit_cntr <= 0;			
  else if (init)
    bit_cntr <= 5'b00000; // init the bit counter		
  else begin
	if (shift) 
    bit_cntr <= bit_cntr + 1; // count shift times
  end
end

assign done_counter = bit_cntr[4]; //done if 16 bits have been shifted

// SLCK counter to count SCLK
always_ff @(posedge clk or negedge rst_n) begin
  if (!rst_n)
    SCLK_div <= 0;			
  else if (ld_SCLK)  // init the SLCK starts
    SCLK_div <= 4'b1011;			
  else 
    SCLK_div <= SCLK_div + 1; // count clk
 end

assign shift = (SCLK_div == 4'b1001) ? 1'b1: 1'b0; // inform to shift two clk after rise

assign SCLK = SCLK_div[3];  // get SCLK 


// shift register to shift MOSI and MISO
always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n)
    shft_reg <= 0;			
  else if (init)
    shft_reg <= wt_data;  // initiailize the write data		
  else if(shift)
    shft_reg <= {shft_reg[14:0],MISO};  // shift in MISO
end

assign MOSI = shft_reg[15];  // the MSB is the MOSI shift out

assign rd_data = shft_reg;  // read data from shift register


// indicate if transaction is done
always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n)
   done <= 1'b0;			
  else if (init)
    done <= 1'b0;			
  else if(set_done) 
    done <= 1'b1;
end

// show SS_n line
always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n)
   SS_n <= 1'b1;			
  else if (init)  // set SS_n to low when init
    SS_n <= 1'b0;			
  else if(set_done)  //set SS_n to high after done
    SS_n <= 1'b1;
end


// Infer state flop next 
always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n)
    state <= IDLE;
  else
    state <= nxt_state;
end

// state machine logic
always_comb begin
 init = 1'b0;
 ld_SCLK = 1'b0;
 set_done = 1'b0;
 nxt_state = state;
	case (state)
	IDLE: begin
		ld_SCLK = 1'b1;
		if (wrt) begin
		init = 1'b1;
                nxt_state = SHIFT;
            end
        end

	SHIFT: begin  //stay in counting until shift is done
		if(done_counter)
		nxt_state = FINISH;
	end
	FINISH: begin
		if(SCLK_div == 4'b1111) begin  
                    set_done = 1'b1;
		    ld_SCLK = 1'b1;
                    nxt_state = IDLE;
            end
        end     

        default: begin
	nxt_state = state;
	end
   endcase
end

endmodule





