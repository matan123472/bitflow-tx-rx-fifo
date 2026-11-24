`timescale 1ns/1ps
module tb_fifo;
    reg clk=0,clr=0,wr_en=0,rd_en=0;reg [7:0] din=0;
    always #5 clk=~clk;
    wire [7:0] dout;wire full,empty;
    fifo dut(clk,clr,wr_en,din,rd_en,dout,full,empty);
    byte model[0:3];int head=0,tail=0,n=0,checks=0,seed=32'hb17f10;
    reg [7:0] expected_dout=0;bit push,pop;
    task cycle(input bit w,r,input byte d);
      begin
        @(negedge clk);wr_en=w;rd_en=r;din=d;
        push=w&&(n<4);pop=r&&(n>0);
        if(pop)begin expected_dout=model[head];head=(head+1)%4;end
        if(push)begin model[tail]=d;tail=(tail+1)%4;end
        if(push&&!pop)n++;if(pop&&!push)n--;
        @(posedge clk);#1;checks++;
        if(dout!==expected_dout||full!==(n==4)||empty!==(n==0))
          $fatal(1,"FIFO scoreboard failure cycle %0d count=%0d dout=%h expected=%h",checks,n,dout,expected_dout);
      end
    endtask
    task clear_queue;
      begin
        @(negedge clk);clr=1;#1;
        head=0;tail=0;n=0;expected_dout=0;
        if(!empty||full||dout!==0)$fatal(1,"FIFO reset failed");
        @(negedge clk);clr=0;wr_en=0;rd_en=0;
      end
    endtask
    initial begin
      $dumpfile("build/fifo.vcd");$dumpvars(0,tb_fifo);
      clear_queue();cycle(0,1,0); // blocked empty read
      for(int i=0;i<4;i++)cycle(1,0,8'(i+20));
      cycle(1,0,99); // blocked full write
      cycle(1,1,88); // full: read only (screenshot's acceptance policy)
      cycle(1,1,77); // interior: both accepted
      repeat(4)cycle(0,1,0);
      cycle(1,1,66); // empty: write only
      cycle(0,1,0);
      repeat(1000)begin
        seed=32'($unsigned(seed)*32'd1664525+32'd1013904223);
        cycle(seed[31],seed[30],seed[15:8]);
      end
      clear_queue();cycle(1,0,55);clear_queue();cycle(0,1,0);
      $display("PASS FIFO: %0d scoreboard cycles",checks);$finish;
    end
    initial begin #100000;$fatal(1,"FIFO timeout");end
endmodule
