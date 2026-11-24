`timescale 1ns/1ps
// FIFO wiring follows Figure 19: inc_adrs_tx writes ROM data into word FIFO.
// The serial TX still runs, but the FIFO extension is a byte-wide path.
module system_top_fifo #(parameter [7:0] WORD0=8'hb2,WORD1=8'hca,WORD2=8'hf0,WORD3=8'h0f)
    (input clk,clr,output tx_finish,rx_finish,full,empty,
     output [1:0] tx_adrs,rx_adrs,output [7:0] rom_dout,fifo_dout,
     output [7:0] ram_q0,ram_q1,ram_q2,ram_q3);
    wire tx_data,tx_vld,rd_mem,ld_tbuf,shr_tbuf,inc_adrs_tx;
    wire [7:0] tbuf_q;
    wire fifo_rd_en,wr_mem,inc_adrs_rx;
    block_TX #(WORD0,WORD1,WORD2,WORD3) tx(clk,clr,1'b1,tx_data,tx_vld,
        tx_finish,tx_adrs,rom_dout,tbuf_q,rd_mem,ld_tbuf,shr_tbuf,inc_adrs_tx);
    fifo queue(clk,clr,inc_adrs_tx,rom_dout,fifo_rd_en,fifo_dout,full,empty);
    block_RX_fifo rx(clk,clr,fifo_dout,empty,fifo_rd_en,rx_finish,
                    rx_adrs,ram_q0,ram_q1,ram_q2,ram_q3,wr_mem,inc_adrs_rx);
endmodule
module system_top #(parameter [7:0] WORD0=8'hb2,WORD1=8'hca,WORD2=8'hf0,WORD3=8'h0f)
    (input clk,clr,output tx_finish,rx_finish,
     output [7:0] ram_q0,ram_q1,ram_q2,ram_q3);
    wire tx_data,tx_vld,rx_rdy,rd_mem,ld_tbuf,shr_tbuf,inc_adrs;
    wire [1:0] tx_adrs,rx_adrs;
    wire [7:0] rom_dout,tbuf_q;
    block_TX #(WORD0,WORD1,WORD2,WORD3) tx(clk,clr,rx_rdy,tx_data,tx_vld,
        tx_finish,tx_adrs,rom_dout,tbuf_q,rd_mem,ld_tbuf,shr_tbuf,inc_adrs);
    block_RX rx(clk,clr,tx_data,tx_vld,rx_rdy,rx_finish,rx_adrs,
                ram_q0,ram_q1,ram_q2,ram_q3);
endmodule
