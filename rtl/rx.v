`timescale 1ns/1ps
// Baseline serial RX and word FIFO RX. Single shared clock.
module rx_ram(input clk,clr,wr,input [1:0] adrs,input [7:0] din,
    output [7:0] q0,q1,q2,q3);
    reg [7:0] mem[0:3];integer i;
    assign q0=mem[0];assign q1=mem[1];assign q2=mem[2];assign q3=mem[3];
    always @(posedge clk or posedge clr)
        if(clr)for(i=0;i<4;i=i+1)mem[i]<=0;
        else if(wr)mem[adrs]<=din;
endmodule
module block_RX(input clk,clr_rx,tx_data,tx_vld,output rx_rdy,rx_finish,
    output reg [1:0] rx_adrs,output [7:0] ram_q0,ram_q1,ram_q2,ram_q3);
    localparam IDLE=0,SHIFT=1,WRITE=2,DONE=3,FINISH=4;
    reg [2:0] state,bit_count;
    reg [7:0] rbuf;
    wire wr_mem=(state==WRITE);
    assign rx_rdy=(state==IDLE);
    assign rx_finish=(state==FINISH);
    rx_ram ram(clk,clr_rx,wr_mem,rx_adrs,rbuf,ram_q0,ram_q1,ram_q2,ram_q3);
    always @(posedge clk or posedge clr_rx) begin
        if(clr_rx)begin state<=IDLE;bit_count<=0;rx_adrs<=0;rbuf<=0;end
        else case(state)
            IDLE:if(tx_vld)begin
                rbuf<={tx_data,7'b0};bit_count<=1;state<=SHIFT;
            end
            SHIFT:if(tx_vld)begin
                rbuf<={tx_data,rbuf[7:1]};
                if(bit_count==7)state<=WRITE;else bit_count<=bit_count+1'b1;
            end
            WRITE:state<=DONE;
            DONE:if(rx_adrs==3)state<=FINISH;
                 else begin rx_adrs<=rx_adrs+1'b1;state<=IDLE;end
            FINISH:state<=FINISH;
            default:state<=IDLE;
        endcase
    end
endmodule
module block_RX_fifo(input clk,clr_rx,input [7:0] fifo_dout,input empty,
    output fifo_rd_en,rx_finish,output reg [1:0] rx_adrs,
    output [7:0] ram_q0,ram_q1,ram_q2,ram_q3,output wr_mem,inc_adrs);
    localparam IDLE=0,READ=1,WRITE=2,DONE=3,FINISH=4;
    reg [2:0] state;
    assign fifo_rd_en=(state==READ)&&!empty;
    assign wr_mem=(state==WRITE);
    assign inc_adrs=(state==DONE);
    assign rx_finish=(state==FINISH);
    rx_ram ram(clk,clr_rx,wr_mem,rx_adrs,fifo_dout,ram_q0,ram_q1,ram_q2,ram_q3);
    always @(posedge clk or posedge clr_rx) begin
        if(clr_rx)begin state<=IDLE;rx_adrs<=0;end
        else case(state)
            IDLE:if(!empty)state<=READ;
            READ:if(!empty)state<=WRITE;else state<=IDLE;
            WRITE:state<=DONE;
            DONE:if(rx_adrs==3)state<=FINISH;
                 else begin rx_adrs<=rx_adrs+1'b1;state<=IDLE;end
            FINISH:state<=FINISH;
            default:state<=IDLE;
        endcase
    end
endmodule
