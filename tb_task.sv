/*
Tasks
*/

// Task for sendind cmd and data, wait for response
task send(logic [7:0]cmd2send, [15:0]data2send);
@(posedge clk);
host_cmd = cmd2send;
data = data2send;
send_cmd = 1;
@(posedge clk) send_cmd = 0;

fork
 begin: test
 
 if (cmd2send != CALIBRATE) repeat (150000) @(posedge clk);
 else repeat (3000000) @(posedge clk);  //reduce wait 
 $display("ERROR: timeout error on cmd: %h", cmd2send);
 $stop();
 end

 begin
 @(posedge resp_rdy);  //check if response != A5 then error
if(resp !== ACK) begin
 $display("Response not correct %h",  resp);
 $stop();
end
 disable test;
 end
join

endtask

// Initialization task
task init();
clk = 0;
RST_n = 0;
send_cmd = 0;
error = 0;

// Deassert rest
repeat (2)@(posedge clk);
RST_n = 1;

endtask


// Check whether two values are equal after a period of time
task checkval(logic [15:0]val, [15:0]tar);
/*
if(val < (tar - 16'hA) | val > (tar + 16'hA)) begin      //value in a range 10
    $display("Not equal, val = %h, tar = %h", val, tar);
    $stop();
end
*/
static integer diff = 0;
diff  = val - tar;
if(val < tar) diff = ~diff + 1;

if (diff > 16'hA) begin      //value in a range 10
    $display("Not equal, val = %h, tar = %h", val, tar);
    $stop();
end

endtask