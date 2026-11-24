`timescale 1ns/1ps
module tb_system;
    reg clk=0,clr=0;
    always #5 clk=~clk;
    wire tf0,rf0,tf1,rf1,full,empty;
    wire [7:0] a0,a1,a2,a3,b0,b1,b2,b3;
    wire [1:0] ta,ra;wire [7:0] rom_data,fifo_data;
    system_top baseline(clk,clr,tf0,rf0,a0,a1,a2,a3);
    // Report Figure 23 shows B2, CA, F0, 0F in RAM in this order.
    system_top_fifo buffered(clk,clr,tf1,rf1,
        full,empty,ta,ra,rom_data,fifo_data,b0,b1,b2,b3);
    integer nbits=0,checks=0;reg [7:0] captured=0;
    reg [7:0] expected[0:3];
    // Independent serial monitor: verifies first bit and LSB order, not just RAM.
    always @(posedge clk) begin
      if(clr)begin nbits=0;captured=0;end
      else if(baseline.tx.tx_vld)begin
        captured[nbits%8]=baseline.tx.tx_data;
        if(nbits%8==7)begin
          if(captured!==expected[nbits/8])$fatal(1,"serial TX word/order failure");
          checks++;
        end
        nbits++;
      end
    end
    task run_transfer;
      begin
        @(negedge clk);clr=1;repeat(2)@(negedge clk);clr=0;
        wait(rf0&&rf1&&tf0&&tf1);#1;
        if({a0,a1,a2,a3}!==32'hb2caf00f)$fatal(1,"serial RAM mismatch");
        if({b0,b1,b2,b3}!==32'hb2caf00f)$fatal(1,"FIFO RAM mismatch");
        if(!empty||full||nbits!=32)$fatal(1,"completion/bit count failure");
        checks+=3;
        repeat(8)@(negedge clk);
        if({a0,a1,a2,a3}!==32'hb2caf00f||{b0,b1,b2,b3}!==32'hb2caf00f)
          $fatal(1,"finished RAM not stable");
        checks++;
      end
    endtask
    initial begin
      expected[0]=8'hb2;expected[1]=8'hca;expected[2]=8'hf0;expected[3]=8'h0f;
      $dumpfile("build/system.vcd");$dumpvars(0,tb_system);
      // Reset during active transfer, then restart and complete twice.
      @(negedge clk);clr=1;@(negedge clk);clr=0;
      repeat(13)@(negedge clk);
      run_transfer();run_transfer();
      $display("PASS SYSTEM: %0d checks; serial baseline + word FIFO; restart verified",checks);$finish;
    end
    initial begin #10000;$fatal(1,"system timeout");end
endmodule
