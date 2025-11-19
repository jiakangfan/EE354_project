module lfsr_random(
    input  wire clk,
    input  wire reset,
    output reg [9:0] rnd   // 10-bit random
);
    always @(posedge clk or posedge reset) begin
        if (reset)
            rnd <= 10'b0000_0001;  // seed
        else begin
            // x^10 + x^7 + 1 for example
            rnd <= {rnd[8:0], rnd[9] ^ rnd[6]};
        end
    end
endmodule
