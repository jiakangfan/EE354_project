module ssd_score(
    input  wire       clk,
    input  wire [15:0] score,
    output reg  [3:0]  an,
    output reg  [6:0]  seg,
    output reg         dp
);
    // TODO:
    // 1. Convert score to 4 BCD digits
    // 2. Multiplex among digits with a refresh counter
    // 3. Use a case to map 0-9 to seg[6:0]
endmodule
