module ssd_score(
    input  wire        clk,      // 100 MHz system clock
    input  wire [15:0] score,    // score 0..9999 (we show lowest 4 digits)
    output reg  [3:0]  an,       // active-LOW anodes
    output reg  [6:0]  seg,      // active-LOW segments: {a,b,c,d,e,f,g}
    output reg         dp        // active-LOW decimal point
);

    // -------------------------------
    // 1) Binary score → 4 BCD digits
    // -------------------------------
    reg [3:0] d0, d1, d2, d3;    // units, tens, hundreds, thousands
    integer   temp;

    always @* begin
        temp = score;          // use an integer so / and % are easy

        d0 = temp % 10;
        temp = temp / 10;

        d1 = temp % 10;
        temp = temp / 10;

        d2 = temp % 10;
        temp = temp / 10;

        d3 = temp % 10;
    end

    // -------------------------------
    // 2) Refresh / scan counter
    // -------------------------------
    reg [15:0] refresh_cnt;
    reg [1:0]  digit_sel;
    reg [3:0]  curr_digit;

    always @(posedge clk) begin
        refresh_cnt <= refresh_cnt + 1'b1;
    end

    // use top 2 bits as scan selector (~hundreds of Hz per digit)
    always @* begin
        digit_sel = refresh_cnt[15:14];

        case (digit_sel)
            2'b00: begin
                an         = 4'b1110;  // enable rightmost digit
                curr_digit = d0;
            end
            2'b01: begin
                an         = 4'b1101;  // next digit
                curr_digit = d1;
            end
            2'b10: begin
                an         = 4'b1011;
                curr_digit = d2;
            end
            2'b11: begin
                an         = 4'b0111;  // leftmost digit
                curr_digit = d3;
            end
        endcase
    end

    // -------------------------------
    // 3) Digit → 7-seg pattern
    // -------------------------------
    // seg[6:0] = {a,b,c,d,e,f,g}, active LOW (0 = ON)
    always @* begin
        dp = 1'b1;  // decimal point off (active low)

        case (curr_digit)
            4'd0: seg = 7'b0000001;
            4'd1: seg = 7'b1001111;
            4'd2: seg = 7'b0010010;
            4'd3: seg = 7'b0000110;
            4'd4: seg = 7'b1001100;
            4'd5: seg = 7'b0100100;
            4'd6: seg = 7'b0100000;
            4'd7: seg = 7'b0001111;
            4'd8: seg = 7'b0000000;
            4'd9: seg = 7'b0000100;
            default: seg = 7'b1111111;   // all off for safety
        endcase
    end

endmodule

