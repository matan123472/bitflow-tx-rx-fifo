`timescale 1ns/1ps
module tb_serial;
  reg clk=0,clr=0,valid=0,serial_data=0,ready=0;
  always #5 clk=~clk;
  wire rx_ready,rx_finish,tx_data,tx_valid,tx_finish;
  wire [1:0] ra,ta;
  wire [7:0] q0,q1,q2,q3,rom_data,tbuf;
  wire rd_mem,ld,shr,inc;
  block_RX rx(clk,clr,serial_data,valid,rx_ready,rx_finish,ra,q0,q1,q2,q3);
  block_TX tx(clk,clr,ready,tx_data,tx_valid,tx_finish,ta,rom_data,tbuf,rd_mem,ld,shr,inc);
  int checks=0;
  task bit_cycle(input bit v,d);
    begin @(negedge clk);valid=v;serial_data=d;@(posedge clk);#1;end
  endtask
  task send_byte(input byte value);
    begin
      wait(rx_ready);
      for(int i=0;i<8;i++)begin
        bit_cycle(1,value[i]);
        // Receiver must hold partial word over arbitrary valid gaps.
        if(i!=7)repeat((i%3)+1)bit_cycle(0,~value[i]);
      end
      bit_cycle(0,0);
      repeat(3)@(negedge clk);
    end
  endtask
  initial begin
    @(negedge clk);clr=1;@(negedge clk);clr=0;
    repeat(12)begin @(posedge clk);#1;if(tx_valid||tx_finish)$fatal(1,"TX ignored not-ready");checks++;end
    @(negedge clk);ready=1;
    // Disable readiness at first word completion, before next WAIT state.
    wait(inc);@(negedge clk);ready=0;
    repeat(12)begin @(posedge clk);#1;if(tx_valid)$fatal(1,"TX crossed word boundary while not-ready");checks++;end
    @(negedge clk);ready=1;
    send_byte(8'h00);send_byte(8'hff);send_byte(8'h81);send_byte(8'h7e);
    wait(rx_finish&&tx_finish);#1;
    if({q0,q1,q2,q3}!==32'h00ff817e)$fatal(1,"RX lost bits during valid gaps");
    checks++;
    $display("PASS SERIAL: %0d checks; TX readiness and RX valid gaps",checks);$finish;
  end
  initial begin #10000;$fatal(1,"serial test timeout");end
endmodule
