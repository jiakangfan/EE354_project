module clk_div_25mhz (
    input  wire clk_in,   // 100 MHz
    input  wire reset,
    output wire clk_out   // 25 MHz
);
    reg [1:0] cnt;

    always @(posedge clk_in or posedge reset) begin
        if (reset)
            cnt <= 2'b00;
        else
            cnt <= cnt + 2'b01;
    end
  
    assign clk_out = cnt[1];
endmodule
