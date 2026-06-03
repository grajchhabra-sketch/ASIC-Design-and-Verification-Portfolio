 // ROUND ROBIN ARBITER 
 module rr_arbiter #(parameter N=3)
(
  input clk,
  input reset,
  input [N-1:0] req,

  input tx_done,

  output reg [N-1:0] grant
);

reg [$clog2(N)-1:0] last_grant;
reg busy;

integer i;
integer idx;

always @(posedge clk or posedge reset)
begin

  if(reset)
  begin
    grant <= 0;
    last_grant <= 0;
    busy <= 0;
  end

  else
  begin

    if(busy)
    begin

      if(tx_done)
      begin
        busy <= 0;
        grant <= 0;
      end

    end

    else
    begin

      for(i=1;i<=N;i=i+1)
      begin

        idx = (last_grant+i)%N;

        if(req[idx])
        begin

          grant <= (1'b1<<idx);
          last_grant <= idx;
          busy <= 1;

          

        end
      end

    end

  end

end

endmodule
    

