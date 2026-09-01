module asy_fifo(
  input rst, clk_wr, clk_rd, wr_en, rd_en,
  input [7:0] din,
  output reg [7:0] dout,
  output empty, full 
  );
  reg [4:0] wr_ptr, rd_ptr, wr_gray_ptr, rd_gray_ptr, wr_gray_ptr_sync1, wr_gray_ptr_sync2, rd_gray_ptr_sync1, rd_gray_ptr_sync2; 
  reg [7:0] fifomem [15:0];
  integer i;

  always@(posedge clk_wr or negedge rst)
  begin
  if (!rst) 
  begin
    wr_ptr <= 5'd0; wr_gray_ptr <= 5'd0;
    for (i = 0; i < 16; i = i + 1)
     fifomem[i] <= 8'd0;
  end
  else if (wr_en == 1 && !full)
  begin
    fifomem[wr_ptr[3:0]] <= din;
    wr_ptr <= wr_ptr + 1;
    wr_gray_ptr <= ((wr_ptr + 1) << 1 ^ (wr_ptr + 1));
  end
  end
 
 
  
 always@(posedge clk_rd or negedge rst)
  begin
  if (!rst) 
  begin
    rd_ptr <= 5'd0;
    rd_gray_ptr <= 3'd0;
  end
  else 
  begin
    if (rd_en == 1 && !empty)
       begin
          rd_ptr <= 5'd0;
          rd_gray_ptr <= 5'd0;
       end
       else
          dout <= fifomem[rd_ptr[3:0]];
          rd_ptr <= rd_ptr + 1;
          rd_gray_ptr <= (( rd_ptr + 1) << 1) ^ ( rd_ptr + 1);
       end
  end
  
  
  
  always@(posedge clk_rd or negedge rst)
  begin
  if (!rst) 
   begin
    wr_gray_ptr_sync1 <= 5'd0;
    wr_gray_ptr_sync2 <= 5'd0;
   end
  else 
   begin
    wr_gray_ptr_sync1 <= wr_gray_ptr;
    wr_gray_ptr_sync2 <= wr_gray_ptr_sync1;
   end
  end
  
  always@(posedge clk_wr or negedge rst)
  begin
  if (!rst) 
   begin
    rd_gray_ptr_sync1 <= 5'd0;
    rd_gray_ptr_sync2 <= 5'd0;
   end
  else 
   begin
    rd_gray_ptr_sync1 <= rd_gray_ptr;
    rd_gray_ptr_sync2 <= rd_gray_ptr_sync1;
   end
  end
   
  assign full = (wr_gray_ptr == {~rd_gray_ptr_sync2[4:3], rd_gray_ptr_sync2[2:0]});
  assign empty = (wr_gray_ptr_sync2 == rd_gray_ptr);
    
endmodule
//testbench
