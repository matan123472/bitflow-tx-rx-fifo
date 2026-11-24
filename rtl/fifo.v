`timescale 1ns/1ps
// Four-byte synchronous FIFO, following report Figure 18.
// Same pre-edge full/empty acceptance policy as screenshot, registered dout.
module fifo(input clk,clr,wr_en,input [7:0] din,input rd_en,
    output reg [7:0] dout,output full,empty);
    reg [7:0] mem[0:3];
    reg [1:0] wr_ptr,rd_ptr;
    reg [2:0] count;
    assign full=(count==3'd4);
    assign empty=(count==3'd0);
    always @(posedge clk or posedge clr) begin
        if(clr) begin wr_ptr<=0;rd_ptr<=0;count<=0;dout<=0;end
        else case ({(wr_en&&!full),(rd_en&&!empty)})
            2'b10: begin mem[wr_ptr]<=din;wr_ptr<=wr_ptr+1'b1;count<=count+1'b1;end
            2'b01: begin dout<=mem[rd_ptr];rd_ptr<=rd_ptr+1'b1;count<=count-1'b1;end
            2'b11: begin
                mem[wr_ptr]<=din;wr_ptr<=wr_ptr+1'b1;
                dout<=mem[rd_ptr];rd_ptr<=rd_ptr+1'b1;
            end
            default: begin end
        endcase
    end
endmodule
