/* module tile_renderer(
    input  wire [9:0]  pixel_x,
    input  wire [9:0]  pixel_y,
    input  wire        video_on,
    input  wire [191:0] board_flat,   // <-- flat bus from game_logic
    input  wire [1:0]  game_state,
    output reg  [11:0] rgb
);
    // Internal 4x4 board view (16 tiles of 12 bits each)
    wire [11:0] board [0:15];

    genvar tj;
    generate
        for (tj = 0; tj < 16; tj = tj + 1)
     begin : unpack_board
        // board_flat[11:0]   = board[0]
        // board_flat[23:12]  = board[1]
        // ...
            assign board[tj] = board_flat[12*tj +: 12];
        end
endgenerate

    // grid layout parameters
    localparam X0 = 100;
    localparam Y0 = 60;
    localparam TILE_W = 60;
    localparam TILE_H = 60;

    integer row, col, index;
    reg [11:0] value;

    always @* begin
        if (!video_on) begin
            rgb = 12'h000; // black
        end else begin
            // default background
            rgb = 12'h222;

            // check if inside grid area
            if (pixel_x >= X0 && pixel_x < X0 + 4*TILE_W &&
                pixel_y >= Y0 && pixel_y < Y0 + 4*TILE_H) begin

                row = (pixel_y - Y0) / TILE_H;
                col = (pixel_x - X0) / TILE_W;
                index = row*4 + col;
                value = board[index];

                // borders darker
                if (((pixel_x - X0) % TILE_W == 0) ||
                    ((pixel_y - Y0) % TILE_H == 0)) begin
                    rgb = 12'h111;
                end else begin
                    case (value)
                        0:    rgb = 12'h333;
                        2:    rgb = 12'hEEE;
                        4:    rgb = 12'hDDC;
                        8:    rgb = 12'hF80;
                        16:   rgb = 12'hF60;
                        32:   rgb = 12'hF40;
                        64:   rgb = 12'hF20;
                        default: rgb = 12'hFF0;  // others
                    endcase
                end
            end
            // You can later add "GAME OVER" overlay using game_state.
        end
    end
endmodule
*/


module tile_renderer(
    input  wire [9:0]   pixel_x,
    input  wire [9:0]   pixel_y,
    input  wire         video_on,
    input  wire [191:0] board_flat,   // 16 tiles * 12 bits
    input  wire [1:0]   game_state,
    output reg  [11:0]  rgb
);
    // Grid layout parameters
    localparam X0      = 100;
    localparam Y0      = 60;
    localparam TILE_W  = 60;
    localparam TILE_H  = 60;

    integer row, col, index;
    reg [11:0] value;

    // Local coords inside one tile
    integer lx, ly;

    // For digits
    integer digits;           // number of digits (1..4)
    reg [3:0] d0, d1, d2, d3; // least-significant digit = d0

    integer dx_start;         // left margin for whole number
    integer digit_pos;        // index of which digit (0..3)
    integer dx;               // x within that digit (0..7)
    integer dy;               // y within digit (0..7)

    reg [7:0] row_bits;       // 8-bit row of font
    reg       pixel_on;       // font pixel on/off

    // ====== 8x8 FONT FOR DIGITS 0..9 ======
    function [7:0] font_row;
        input [3:0] digit;
        input [2:0] y; // 0..7
        begin
            case (digit)
                4'd0: case (y)
                    0: font_row = 8'b00111100;
                    1: font_row = 8'b01100110;
                    2: font_row = 8'b01101110;
                    3: font_row = 8'b01110110;
                    4: font_row = 8'b01100110;
                    5: font_row = 8'b01100110;
                    6: font_row = 8'b00111100;
                    default: font_row = 8'b00000000;
                endcase
                4'd1: case (y)
                    0: font_row = 8'b00011000;
                    1: font_row = 8'b00111000;
                    2: font_row = 8'b00011000;
                    3: font_row = 8'b00011000;
                    4: font_row = 8'b00011000;
                    5: font_row = 8'b00011000;
                    6: font_row = 8'b00111100;
                    default: font_row = 8'b00000000;
                endcase
                4'd2: case (y)
                    0: font_row = 8'b00111100;
                    1: font_row = 8'b01100110;
                    2: font_row = 8'b00000110;
                    3: font_row = 8'b00001100;
                    4: font_row = 8'b00110000;
                    5: font_row = 8'b01100000;
                    6: font_row = 8'b01111110;
                    default: font_row = 8'b00000000;
                endcase
                4'd3: case (y)
                    0: font_row = 8'b00111100;
                    1: font_row = 8'b01100110;
                    2: font_row = 8'b00000110;
                    3: font_row = 8'b00011100;
                    4: font_row = 8'b00000110;
                    5: font_row = 8'b01100110;
                    6: font_row = 8'b00111100;
                    default: font_row = 8'b00000000;
                endcase
                4'd4: case (y)
                    0: font_row = 8'b00001100;
                    1: font_row = 8'b00011100;
                    2: font_row = 8'b00101100;
                    3: font_row = 8'b01001100;
                    4: font_row = 8'b01111110;
                    5: font_row = 8'b00001100;
                    6: font_row = 8'b00011110;
                    default: font_row = 8'b00000000;
                endcase
                4'd5: case (y)
                    0: font_row = 8'b01111110;
                    1: font_row = 8'b01100000;
                    2: font_row = 8'b01111100;
                    3: font_row = 8'b00000110;
                    4: font_row = 8'b00000110;
                    5: font_row = 8'b01100110;
                    6: font_row = 8'b00111100;
                    default: font_row = 8'b00000000;
                endcase
                4'd6: case (y)
                    0: font_row = 8'b00111100;
                    1: font_row = 8'b01100110;
                    2: font_row = 8'b01100000;
                    3: font_row = 8'b01111100;
                    4: font_row = 8'b01100110;
                    5: font_row = 8'b01100110;
                    6: font_row = 8'b00111100;
                    default: font_row = 8'b00000000;
                endcase
                4'd7: case (y)
                    0: font_row = 8'b01111110;
                    1: font_row = 8'b00000110;
                    2: font_row = 8'b00001100;
                    3: font_row = 8'b00011000;
                    4: font_row = 8'b00110000;
                    5: font_row = 8'b00110000;
                    6: font_row = 8'b00110000;
                    default: font_row = 8'b00000000;
                endcase
                4'd8: case (y)
                    0: font_row = 8'b00111100;
                    1: font_row = 8'b01100110;
                    2: font_row = 8'b01100110;
                    3: font_row = 8'b00111100;
                    4: font_row = 8'b01100110;
                    5: font_row = 8'b01100110;
                    6: font_row = 8'b00111100;
                    default: font_row = 8'b00000000;
                endcase
                4'd9: case (y)
                    0: font_row = 8'b00111100;
                    1: font_row = 8'b01100110;
                    2: font_row = 8'b01100110;
                    3: font_row = 8'b00111110;
                    4: font_row = 8'b00000110;
                    5: font_row = 8'b01100110;
                    6: font_row = 8'b00111100;
                    default: font_row = 8'b00000000;
                endcase
                default: font_row = 8'b00000000;
            endcase
        end
    endfunction

    // Decode tile value (2,4,8,...,2048) into decimal digits.
    // We only handle the values that can appear in 2048.
    task decode_value_to_digits;
        input  [11:0] v;
        output integer n_digits;
        output [3:0]  t3, t2, t1, t0;
        begin
            case (v)
                12'd2:    begin n_digits = 1; t3=0; t2=0; t1=0; t0=4'd2; end
                12'd4:    begin n_digits = 1; t3=0; t2=0; t1=0; t0=4'd4; end
                12'd8:    begin n_digits = 1; t3=0; t2=0; t1=0; t0=4'd8; end
                12'd16:   begin n_digits = 2; t3=0; t2=0; t1=4'd1; t0=4'd6; end
                12'd32:   begin n_digits = 2; t3=0; t2=0; t1=4'd3; t0=4'd2; end
                12'd64:   begin n_digits = 2; t3=0; t2=0; t1=4'd6; t0=4'd4; end
                12'd128:  begin n_digits = 3; t3=0; t2=4'd1; t1=4'd2; t0=4'd8; end
                12'd256:  begin n_digits = 3; t3=0; t2=4'd2; t1=4'd5; t0=4'd6; end
                12'd512:  begin n_digits = 3; t3=0; t2=4'd5; t1=4'd1; t0=4'd2; end
                12'd1024: begin n_digits = 4; t3=4'd1; t2=4'd0; t1=4'd2; t0=4'd4; end
                12'd2048: begin n_digits = 4; t3=4'd2; t2=4'd0; t1=4'd4; t0=4'd8; end
                default:  begin n_digits = 0; t3=0; t2=0; t1=0; t0=0;   end
            endcase
        end
    endtask

    // ===========================
    // Main pixel logic
    // ===========================
    always @* begin
        if (!video_on) begin
            rgb = 12'h000;
        end else begin
            rgb = 12'h000;  // default background

            for (row = 0; row < 4; row = row + 1) begin
                for (col = 0; col < 4; col = col + 1) begin
                    if ( (pixel_x >= X0 + col*TILE_W) && (pixel_x < X0 + (col+1)*TILE_W) &&
                         (pixel_y >= Y0 + row*TILE_H) && (pixel_y < Y0 + (row+1)*TILE_H) ) begin

                        index = row*4 + col;
                        value = board_flat[12*index +: 12];

                        // ---- base tile color ----
                        if (value == 12'd0) begin
                            rgb = 12'h222; // empty
                        end else begin
                            case (value)
                                12'd2:    rgb = 12'hEEE;
                                12'd4:    rgb = 12'hDDC;
                                12'd8:    rgb = 12'hF80;
                                12'd16:   rgb = 12'hF60;
                                12'd32:   rgb = 12'hF40;
                                12'd64:   rgb = 12'hF20;
                                12'd128:  rgb = 12'hEC8;
                                12'd256:  rgb = 12'hEC6;
                                12'd512:  rgb = 12'hEC4;
                                12'd1024: rgb = 12'hEC2;
                                12'd2048: rgb = 12'hEC0;
                                default:  rgb = 12'hFF0;
                            endcase
                        end

                        // thin border
                        if ( (pixel_x == X0 + col*TILE_W) ||
                             (pixel_y == Y0 + row*TILE_H) ||
                             (pixel_x == X0 + (col+1)*TILE_W - 1) ||
                             (pixel_y == Y0 + (row+1)*TILE_H - 1) ) begin
                            rgb = 12'h111;
                        end

                        // ---- number overlay ----
                        if (value != 12'd0) begin
                            // local tile coords
                            lx = pixel_x - (X0 + col*TILE_W);
                            ly = pixel_y - (Y0 + row*TILE_H);

                            // decode decimal digits
                            decode_value_to_digits(value, digits, d3, d2, d1, d0);

                            if (digits > 0) begin
                                // center horizontally, 8 px per digit
                                dx_start = (TILE_W - digits*8) >> 1;

                                // only draw inside 8-pixel-tall text band
                                if ( (lx >= dx_start) && (lx < dx_start + digits*8) &&
                                     (ly >= (TILE_H/2 - 4)) && (ly < (TILE_H/2 + 4)) ) begin

                                    dy        = ly - (TILE_H/2 - 4);          // 0..7
                                    digit_pos = (lx - dx_start) / 8;          // which digit
                                    dx        = (lx - dx_start) - digit_pos*8;// 0..7

                                    // select which digit to draw (left to right)
                                    case (digits)
                                        1: begin
                                            case (digit_pos)
                                                0: row_bits = font_row(d0, dy);
                                                default: row_bits = 8'h00;
                                            endcase
                                        end
                                        2: begin
                                            case (digit_pos)
                                                0: row_bits = font_row(d1, dy);
                                                1: row_bits = font_row(d0, dy);
                                                default: row_bits = 8'h00;
                                            endcase
                                        end
                                        3: begin
                                            case (digit_pos)
                                                0: row_bits = font_row(d2, dy);
                                                1: row_bits = font_row(d1, dy);
                                                2: row_bits = font_row(d0, dy);
                                                default: row_bits = 8'h00;
                                            endcase
                                        end
                                        4: begin
                                            case (digit_pos)
                                                0: row_bits = font_row(d3, dy);
                                                1: row_bits = font_row(d2, dy);
                                                2: row_bits = font_row(d1, dy);
                                                3: row_bits = font_row(d0, dy);
                                                default: row_bits = 8'h00;
                                            endcase
                                        end
                                        default: row_bits = 8'h00;
                                    endcase

                                    pixel_on = row_bits[7 - dx]; // MSB on left

                                    if (pixel_on) begin
                                        // text color: dark for small tiles, white for big ones
                                        if (value <= 12'd4)
                                            rgb = 12'h000;
                                        else
                                            rgb = 12'hFFF;
                                    end
                                end
                            end
                        end
                    end
                end
            end

            // (optional) You could check game_state here to overlay "WIN"/"LOSE".
        end
    end
endmodule

