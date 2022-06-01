
module flght_cntrl(clk,rst_n,vld,inertial_cal,d_ptch,d_roll,d_yaw,ptch,
					roll,yaw,thrst,frnt_spd,bck_spd,lft_spd,rght_spd);
				
input clk,rst_n;
input vld;									// tells when a new valid inertial reading ready
											// only update D_QUEUE on vld readings
input inertial_cal;							// need to run motors at CAL_SPEED during inertial calibration
input signed [15:0] d_ptch,d_roll,d_yaw;	// desired pitch roll and yaw (from cmd_cfg)
input signed [15:0] ptch,roll,yaw;			// actual pitch roll and yaw (from inertial interface)
input [8:0] thrst;							// thrust level from slider
output [10:0] frnt_spd;						// 11-bit unsigned speed at which to run front motor
output [10:0] bck_spd;						// 11-bit unsigned speed at which to back front motor
output [10:0] lft_spd;						// 11-bit unsigned speed at which to left front motor
output [10:0] rght_spd;						// 11-bit unsigned speed at which to right front motor


  //////////////////////////////////////////////////////
  // You will need a bunch of interal wires declared //
  // for intermediate math results...do that here   //
  ///////////////////////////////////////////////////
  wire [9:0] ptch_pterm, roll_pterm, yaw_pterm;
  wire [11:0] ptch_dterm, roll_dterm, yaw_dterm;
  
  wire [12:0] ptch_pterm_ex, roll_pterm_ex, yaw_pterm_ex;
  wire [12:0] ptch_dterm_ex, roll_dterm_ex, yaw_dterm_ex;
  wire [12:0] thrst_ex;

  wire [12:0] init_frnt_spd, frnt_spd_sat;
  wire [12:0] init_bck_spd, bck_spd_sat;
  wire [12:0] init_lft_spd, lft_spd_sat;
  wire [12:0] init_rght_spd, rght_spd_sat;
  ///////////////////////////////////////////////////////////////
  // some Parameters to keep things more generic and flexible //
  /////////////////////////////////////////////////////////////
  localparam CAL_SPEED = 11'h290;		// speed to run motors at during inertial calibration
  localparam MIN_RUN_SPEED = 13'h02C0;	// minimum speed while running  
  localparam D_COEFF = 5'b00111;		// D coefficient in PID control = +7
  
  //////////////////////////////////////
  // Instantiate 3 copies of PD_math //
  ////////////////////////////////////
  PD_math iPTCH(.clk(clk),.rst_n(rst_n),.vld(vld),.desired(d_ptch),.actual(ptch),.pterm(ptch_pterm),.dterm(ptch_dterm));
  PD_math iROLL(.clk(clk),.rst_n(rst_n),.vld(vld),.desired(d_roll),.actual(roll),.pterm(roll_pterm),.dterm(roll_dterm));
  PD_math iYAW(.clk(clk),.rst_n(rst_n),.vld(vld),.desired(d_yaw),.actual(yaw),.pterm(yaw_pterm),.dterm(yaw_dterm));  
  
/// OK...rest is up to you...good luck! ///
  //sign extend dterm
  assign ptch_dterm_ex = {ptch_dterm[11],ptch_dterm};
  assign roll_dterm_ex = {roll_dterm[11],roll_dterm};
  assign yaw_dterm_ex = {yaw_dterm[11],yaw_dterm};

  //sign extend pterm
  assign ptch_pterm_ex = {{3{ptch_pterm[9]}},ptch_pterm};
  assign roll_pterm_ex = {{3{roll_pterm[9]}},roll_pterm};
  assign yaw_pterm_ex = {{3{yaw_pterm[9]}},yaw_pterm};

  //append 0 ahead thrst
  assign thrst_ex = {1'b0,1'b0,1'b0,1'b0, thrst};  // append 

  // front speed
  assign init_frnt_spd = thrst_ex + MIN_RUN_SPEED - ptch_pterm_ex
                    - ptch_dterm_ex - yaw_pterm_ex - yaw_dterm_ex;

  // saturate the front speed
  assign frnt_spd_sat = (|init_frnt_spd[12:11]) ? 11'h7FF :
      init_frnt_spd[10:0];
 
  // if front is performing inertial cal
  assign frnt_spd = inertial_cal? CAL_SPEED:frnt_spd_sat;

  // back speed
  assign init_bck_spd = thrst_ex + MIN_RUN_SPEED + ptch_pterm_ex 
                     + ptch_dterm_ex - yaw_pterm_ex - yaw_dterm_ex;

  // saturate the back speed
  assign bck_spd_sat = (|init_bck_spd[12:11]) ? 11'h7FF :
      init_bck_spd[10:0];

 // if back is performing inertial cal
  assign bck_spd = inertial_cal? CAL_SPEED : bck_spd_sat;

  // left speed
  assign init_lft_spd = thrst_ex + MIN_RUN_SPEED - roll_pterm_ex 
    		      - roll_dterm_ex + yaw_pterm_ex + yaw_dterm_ex;

  //saturate the left speed
  assign lft_spd_sat = (|init_lft_spd[12:11]) ? 11'h7FF :
      init_lft_spd[10:0];

  // if left is performing inertial cal
  assign lft_spd = inertial_cal? CAL_SPEED:lft_spd_sat;
  
  // right speed
  assign  init_rght_spd = thrst_ex + MIN_RUN_SPEED + roll_pterm_ex 
			+ roll_dterm_ex + yaw_pterm_ex + yaw_dterm_ex;

  // saturate right speed
  assign rght_spd_sat = (|init_rght_spd[12:11]) ? 11'b11111111111 :
      init_rght_spd[10:0];

  // if right is performing inertial cal
  assign rght_spd = inertial_cal? CAL_SPEED:rght_spd_sat;


endmodule 
