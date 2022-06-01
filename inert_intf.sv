module inert_intf(clk,rst_n,ptch,roll,yaw,strt_cal,cal_done,vld,SS_n,SCLK,
                  MOSI,MISO,INT);
      
  parameter FAST_SIM = 1;  // used to accelerate simulation
 
  input clk, rst_n;
  input MISO;     // SPI input from inertial sensor
  input INT;     // goes high when measurement ready
  input strt_cal;    // from comand config.  Indicates we should start calibration
  
  output signed [15:0] ptch,roll,yaw; // fusion corrected angles
  output cal_done;      // indicates calibration is done
  output reg vld;      // goes high for 1 clock when new outputs available
  output SS_n,SCLK,MOSI;    // SPI outputs


  ////////////////////////////////////////////
  // Declare any needed internal registers //
  //////////////////////////////////////////
  reg INT_1, INT_2;
  logic [15:0] timer;
  reg signed [7:0] PH, PL, RH, RL, YH, YL, AXH, AXL, AYH, AYL;
  
  //////////////////////////////////////
  // Outputs of SM are of type logic //
  ////////////////////////////////////
  logic [15:0] cmd;
  logic wrt, done;
  logic CPH, CPL, CRH, CRL, CYH, CYL, CAXH, CAXL, CAYH, CAYL;
  logic tstart, tend;


  //////////////////////////////////////////////////////////////
  // Declare any needed internal signals that connect blocks //
  ////////////////////////////////////////////////////////////
  wire signed [15:0] ptch_rt,roll_rt,yaw_rt; // feeds inertial_integrator
  wire signed [15:0] ax,ay;      // accel data to inertial_integrator
  wire signed [15:0] inert_data;  //should be 16
  
  
  ///////////////////////////////////////
  // Create enumerated type for state //
  /////////////////////////////////////
  typedef enum reg [3:0] {INIT1, INIT2, INIT3, INIT4, IDLE, RPH, RPL, RRH, RRL, RYH, RYL, RAXH, RAXL, RAYH, RAYL, END} state_t;
  state_t state, nxt_state;
  
  
  ////////////////////////////////////////////////////////////
  // Instantiate SPI monarch for Inertial Sensor interface //
  //////////////////////////////////////////////////////////
  SPI_mnrch iSPI(.clk(clk),.rst_n(rst_n),.SS_n(SS_n),.SCLK(SCLK),.MISO(MISO),.MOSI(MOSI),
                 .wrt(wrt),.done(done),.rd_data(inert_data),.wt_data(cmd));
      
  ////////////////////////////////////////////////////////////////////
  // Instantiate Angle Engine that takes in angular rate readings  //
  // and acceleration info and produces ptch,roll, & yaw readings //
  /////////////////////////////////////////////////////////////////
  inertial_integrator #(FAST_SIM) iINT(.clk(clk), .rst_n(rst_n), .strt_cal(strt_cal), .cal_done(cal_done),
                                       .vld(vld), .ptch_rt(ptch_rt), .roll_rt(roll_rt), .yaw_rt(yaw_rt), .ax(ax),
                     .ay(ay), .ptch(ptch), .roll(roll), .yaw(yaw));
 
  // infer state machine flop
  always @(posedge clk, negedge rst_n)
    if (!rst_n) state <= INIT1;
    else state <= nxt_state;

 //double ff the INT
  always @(posedge clk) begin
    INT_1 <= INT;
    INT_2 <= INT_1;
  end

 //timer counter
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n) timer <= 16'h0000;
    else if (tend) timer <= 16'h0000;
    else if (tstart) timer <= timer + 1;

  //assign PH
  always @(posedge clk)
    if(CPH) PH <= inert_data[7:0];

  //assign PL
  always @(posedge clk)
    if(CPL) PL <= inert_data[7:0];

  //assign RH
  always @(posedge clk)
    if(CRH) RH <= inert_data[7:0];
  
  //assign RL
  always @(posedge clk)
    if(CRL) RL <= inert_data[7:0];

  //assign YH
  always @(posedge clk)
    if(CYH) YH <= inert_data[7:0];

  //assign YL
  always @(posedge clk)
    if(CYL) YL <= inert_data[7:0];

  //assign AXH
  always @(posedge clk)
    if(CAXH) AXH <= inert_data[7:0];

  //assign AXL
  always @(posedge clk)
    if(CAXL) AXL <= inert_data[7:0];

  //assign AYH
  always @(posedge clk)
    if(CAYH) AYH <= inert_data[7:0];

  //assign AYL
  always @(posedge clk)
    if(CAYL) AYL <= inert_data[7:0];

  
  always_comb begin
   //default all signals
    wrt = 0;
    tstart = 0;
    tend = 0;
    cmd = 16'h0000;
    vld = 0;
    nxt_state = INIT1;

    CPH = 0;
    CPL = 0;
    CRH = 0;
    CRL = 0;
    CYH = 0;
    CYL = 0;
    CAXH = 0;
    CAXL = 0;
    CAYH = 0;
    CAYL = 0;
    
     case(state)
     // start transmitting
        INIT1: begin
  tstart = 1;
  //wait for timer full
  if (&timer) begin
   tstart = 0;
   tend = 1;
   wrt = 1;
   cmd  = 16'h0D02;
   nxt_state = INIT2;
  end
  else nxt_state = INIT1;
  end

// keep transmitting
 INIT2: if (done) begin
   wrt = 1;
   cmd  = 16'h1062;
   nxt_state = INIT3;
  end
  else nxt_state = INIT2;

// keep transmitting
 INIT3: if (done) begin
   wrt = 1;
   cmd  = 16'h1162;
   nxt_state = INIT4;
  end
  else nxt_state = INIT3;

// keep transmitting
 INIT4: if (done) begin
   wrt = 1;
   cmd  = 16'h1460;
   nxt_state = IDLE;
  end
  else nxt_state = INIT4;

//idle state indicate starting transmitting 
 IDLE: if (INT_2 == 1) begin
   wrt = 1;
   cmd  = 16'hA200;
   nxt_state = RPL;
  end
  else nxt_state = IDLE;

//RPL starts
 RPL: if (done) begin
   CPL = 1;
   wrt = 1;
   cmd  = 16'hA300;
   nxt_state = RPH;
  end
  else nxt_state = RPL;

//RPH starts
 RPH: if (done) begin
   CPH = 1;
   wrt = 1;
   cmd  = 16'hA400;
   nxt_state = RRL;
  end
  else nxt_state = RPH;

//RRL starts
 RRL: if (done) begin
   CRL = 1;
   wrt = 1;
   cmd  = 16'hA500;
   nxt_state = RRH;
  end
  else nxt_state = RRL;

//RRH starts
 RRH: if (done) begin
   CRH = 1;
   wrt = 1;
   cmd  = 16'hA600;
   nxt_state = RYL;
  end
  else nxt_state = RRH;

//RYL starts
 RYL: if (done) begin
   CYL = 1;
   wrt = 1;
   cmd  = 16'hA700;
   nxt_state = RYH;
  end
  else nxt_state = RYL;

//RYH starts
 RYH: if (done) begin
   CYH = 1;
   wrt = 1;
   cmd  = 16'hA800;
   nxt_state = RAXL;
  end
  else nxt_state = RYH;

//RAXL starts
 RAXL: if (done) begin
   CAXL = 1;
   wrt = 1;
   cmd  = 16'hA900;
   nxt_state = RAXH;
  end
  else nxt_state = RAXL;

//RAXH STARTS
 RAXH: if (done) begin
   CAXH = 1;
   wrt = 1;
   cmd  = 16'hAA00;
   nxt_state = RAYL;
  end
  else nxt_state = RAXH;

//RAYL starts
 RAYL: if (done) begin
   CAYL = 1;
   wrt = 1;
   cmd  = 16'hAB00;
   nxt_state = RAYH;
  end
  else nxt_state = RAYL;

//RAYH starts
 RAYH: if (done) begin
   CAYH = 1;
   nxt_state = END;
  end
  else nxt_state = RAYH;

//transmitting ends
 END: if(done) begin
   vld = 1;
   nxt_state = IDLE;
  end
  else nxt_state = END;

    endcase
  end

// assign the signals based on state machine output
assign ptch_rt  = {PH, PL};
assign roll_rt  = {RH, RL};
assign yaw_rt  = {YH, YL};
assign ax  = {AXH, AXL};
assign ay  = {AYH, AYL};


  
endmodule