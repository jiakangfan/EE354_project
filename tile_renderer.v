module tile_renderer(
    input  wire [9:0]  pixel_x,
    input  wire [9:0]  pixel_y,
    input  wire        video_on,
    input  wire [11:0] board [0:15],
    input  wire [1:0]  game_state,
    output reg  [11:0] rgb
);
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
