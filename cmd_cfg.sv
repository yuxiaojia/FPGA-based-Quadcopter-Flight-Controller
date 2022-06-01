module cmd_cfg(clk, rst_n, cmd_rdy, cmd, data, cal_done, clr_cmd_rdy, resp, send_resp,
d_ptch, d_roll, d_yaw, thrst,strt_cal, inertial_cal, motors_off);

    parameter FAST_SIM = 1;
    input clk, rst_n;  // clock and active low reset
    input cmd_rdy;  // indicates 24-bit command has been received
    input [7:0] cmd;  // 8-bit opcode sent from host via BLE
    input [15:0] data; // 16-bit parameter sent LSB first via BLE
    input cal_done;  
 
    output logic send_resp;  // indicate response sent
    output logic clr_cmd_rdy;  // host asserts when command digested
    output logic [7:0] resp;   // repsonse to send back
    output logic signed [15:0] d_ptch,d_roll,d_yaw; // desired pitch roll and yaw (from cmd_cfg)
    output logic [8:0] thrst;   //
    output logic strt_cal, inertial_cal,motors_off;  // start calibration and turn off the motor

    // set state mechine state
    localparam SET_PTCH 	= 8'h02;
    localparam SET_ROLL 	= 8'h03;
    localparam SET_YAW  	= 8'h04;
    localparam SET_THRST 	= 8'h05;
    localparam EMER_LAND 	= 8'h07;
    localparam MTRS_OFF 	= 8'h08;
    localparam CALIBRATE 	= 8'h06;

    localparam ACK = 8'hA5;

    //internal logic
    reg wptch,wroll,wyaw,wthrst; //output from statemachine
    logic clr_tmr;  // clear the timer
    logic tmr_full;  //indicate timer is full
    logic mtrs_off;  // indicate motors off
    logic [((8*FAST_SIM) + (25*!FAST_SIM)):0] tmr;  // timer to count the seconds before calibration
    logic emer_land;  // emergence landing, turn off all motor


    typedef enum reg [2:0] {IDLE, CMD, FINISH} state_t;
    state_t state, nxt_state;

    //timer to count the time
      always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) tmr <= 0;
        else if (clr_tmr) tmr <= 0;
        else tmr <= tmr + 1;
      end

    assign tmr_full = &tmr ? 1:0;  //assign when timer full

    // register to store the ptch
    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n) d_ptch <= 16'h0000;
        else if(emer_land) d_ptch <= 16'h0000;
        else if (wptch) d_ptch <= $signed(data);
    end

    //register to store the roll
    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n) d_roll <= 16'h0000;
        else if (emer_land) d_roll <= 16'h0000; 
        else if (wroll) d_roll <= $signed(data);
    end

    //register to store the yaw
    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n) d_yaw <= 16'h0000;
        else if(emer_land) d_yaw <= 16'h0000;
        else if (wyaw) d_yaw <= $signed(data);
    end

    //register to store the thrst
    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n) thrst <= 9'h000;
        else if(emer_land) thrst <= 9'h000;
        else if (wthrst) thrst <= data[8:0];  
    end

    //register to assert motorsoff
    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n) motors_off <= 1'b1;  //preset the motors_off
        else if(mtrs_off) motors_off <= 1'b1;
        else if(inertial_cal)  motors_off <= 1'b0;
    end

    // infer statemachine flop 
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) state <= IDLE;
        else state <= nxt_state;
    end

    // state machine logic
    always_comb begin
        //default all signals
        inertial_cal = 0;
        strt_cal = 0;
        clr_tmr = 0;
        mtrs_off = 0;
        wptch = 0;
        wroll = 0;
        wyaw = 0;
        wthrst = 0;
        send_resp = 0;
        clr_cmd_rdy = 0;
        resp = 0;
        emer_land = 0;
        nxt_state = state;

        case(state)
         IDLE: begin
                if(cmd_rdy)  // wait for cmd_rdy
                 nxt_state = CMD;
                 else nxt_state = IDLE;   
            end

            CMD: begin
                case(cmd)
                SET_PTCH: begin
                    wptch = 1'b1;
                    resp = ACK;
                    send_resp = 1'b1;
                    clr_cmd_rdy = 1;
                    nxt_state = IDLE;
                end
                SET_ROLL: begin
                    wroll = 1'b1;
                    resp = ACK;
                    send_resp = 1'b1;
                    clr_cmd_rdy = 1;
                    nxt_state = IDLE;
                end
                SET_YAW: begin
                    wyaw = 1'b1;
                    resp = ACK;
                    send_resp = 1'b1;
                    clr_cmd_rdy = 1;
                    nxt_state = IDLE;
                end
                SET_THRST: begin
                    wthrst = 1'b1;
                    resp = ACK;
                    send_resp = 1'b1;
                    clr_cmd_rdy = 1;
                    nxt_state = IDLE;
                end
                CALIBRATE: begin
                    
                   inertial_cal = 1'b1;
                   clr_cmd_rdy = 1;
                    if(tmr_full) begin  //wait for timer is full
                        clr_tmr = 1'b1; // clear the timer
                        strt_cal = 1'b1;
                        nxt_state = FINISH;
                    end
                end
                EMER_LAND: begin
                    emer_land = 1'b1;  
                    resp = ACK;
                    send_resp = 1'b1;
                    clr_cmd_rdy = 1;
                    nxt_state = IDLE;
                end
                MTRS_OFF: begin
                    mtrs_off= 1'b1;  // indicate turn of motors
                    resp = ACK;
                    send_resp = 1'b1;
                    clr_cmd_rdy = 1;
                    nxt_state = IDLE;
                end
                default:
                    nxt_state = CMD;  
                endcase
            end
                
            FINISH: begin
                inertial_cal = 1'b1;  // keep high during calibration
                if(cal_done) begin  // wait for calibration done
                    resp = ACK; 
                    send_resp = 1'b1;
                    nxt_state = IDLE;
                end
            end

            default: begin
                nxt_state = IDLE;
            end
        endcase
    end
                
    endmodule