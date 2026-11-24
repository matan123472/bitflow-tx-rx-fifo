`timescale 1ns/1ps
// TX FSM and block_TX interface follow the report (Figure 1).
module tx_control(input clk,clr,rx_rdy,
    output reg rd_mem,ld_tbuf,shr_tbuf,tx_vld,inc_adrs,tx_finish);
    localparam WAIT=0,READ=1,LOAD=2,SHIFT=3,DONE=4,FINISH=5;
    reg [2:0] state;
    reg [2:0] bit_count;
    reg [1:0] word_count;
    always @* begin
        rd_mem=0;ld_tbuf=0;shr_tbuf=0;tx_vld=0;inc_adrs=0;tx_finish=0;
        case(state)
            READ:rd_mem=1;
            LOAD:ld_tbuf=1;
            SHIFT:begin shr_tbuf=1;tx_vld=1;end
            DONE:inc_adrs=1;
            FINISH:tx_finish=1;
            default:begin end
        endcase
    end
    always @(posedge clk or posedge clr) begin
        if(clr)begin state<=WAIT;bit_count<=0;word_count<=0;end
        else case(state)
            WAIT:if(rx_rdy)state<=READ;
            READ:state<=LOAD;
            LOAD:begin bit_count<=0;state<=SHIFT;end
            SHIFT:if(bit_count==7)state<=DONE;else bit_count<=bit_count+1'b1;
            DONE:if(word_count==3)state<=FINISH;
                 else begin word_count<=word_count+1'b1;state<=WAIT;end
            FINISH:state<=FINISH;
            default:state<=WAIT;
        endcase
    end
endmodule
module tx_adrs_reg(input clk,clr,inc,output reg [1:0] adrs);
    always @(posedge clk or posedge clr)
        if(clr)adrs<=0;else if(inc)adrs<=adrs+1'b1;
endmodule
module tx_rom #(parameter [7:0] WORD0=8'hb2,WORD1=8'hca,WORD2=8'hf0,WORD3=8'h0f)
    (input [1:0] adrs,output reg [7:0] dout);
    always @* case(adrs)
        0:dout=WORD0;1:dout=WORD1;2:dout=WORD2;3:dout=WORD3;
    endcase
endmodule
module tx_tbuf(input clk,clr,ld,shr,input [7:0] din,output tx_data,output reg [7:0] q);
    assign tx_data=q[0];
    always @(posedge clk or posedge clr)
        if(clr)q<=0;else if(ld)q<=din;else if(shr)q<={1'b0,q[7:1]};
endmodule
module block_TX #(parameter [7:0] WORD0=8'hb2,WORD1=8'hca,WORD2=8'hf0,WORD3=8'h0f)
    (input clk,clr_tx,rx_rdy,output tx_data,tx_vld,tx_finish,
     output [1:0] tx_adrs,output [7:0] rom_dout,tbuf_q,
     output rd_mem,ld_tbuf,shr_tbuf,inc_adrs);
    tx_control control(clk,clr_tx,rx_rdy,rd_mem,ld_tbuf,shr_tbuf,tx_vld,inc_adrs,tx_finish);
    tx_adrs_reg address(clk,clr_tx,inc_adrs,tx_adrs);
    tx_rom #(WORD0,WORD1,WORD2,WORD3) rom(tx_adrs,rom_dout);
    tx_tbuf buffer_reg(clk,clr_tx,ld_tbuf,shr_tbuf,rom_dout,tx_data,tbuf_q);
endmodule
