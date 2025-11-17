// project_top_A7.v
module project_top_A7 (
    input  wire        CLK100MHZ,
    input  wire        btnU, btnD, btnL, btnR, btnC,
    input  wire [15:0] sw,
    output wire [15:0] led,
    output wire [3:0]  an,
    output wire [6:0]  seg,
    output wire        dp,
    output wire        vga_hs,
    output wire        vga_vs,
    output wire [3:0]  vga_r,
    output wire [3:0]  vga_g,
    output wire [3:0]  vga_b
);

    // ==== 1. Clock division for VGA (from demo) ====
    wire clk_25mhz;
    //instantiate clock divider from VGA demo
    clk_div_25mhz clk_div_inst (
        .clk_in (CLK100MHZ),
        .reset  (btnC),      // use center button as reset
        .clk_out(clk_25mhz)
    );

    // ==== 2. VGA sync module (from demo) ====
    wire [9:0] pixel_x, pixel_y;
    wire       video_on;
    // instantiate vga_sync / vga_controller 
    // It should drive vga_hs, vga_vs, pixel_x, pixel_y, video_on
    vga_sync vga_unit (
        .clk      (clk_25mhz),
        .reset    (btnC),
        .hsync    (vga_hs),
        .vsync    (vga_vs),
        .video_on (video_on),
        .pixel_x  (pixel_x),
        .pixel_y  (pixel_y)
    );

    // ==== 3. Debounced button pulses ====
    wire up_pulse, down_pulse, left_pulse, right_pulse;
    // instantiate debounce_onepulse for each button
    btn_onepulse up_btn (
        .clk   (CLK100MHZ),
        .reset (btnC),
        .btn_in(btnU),
        .pulse (up_pulse)
    );

    btn_onepulse down_btn (
        .clk   (CLK100MHZ),
        .reset (btnC),
        .btn_in(btnD),
        .pulse (down_pulse)
    );

    btn_onepulse left_btn (
        .clk   (CLK100MHZ),
        .reset (btnC),
        .btn_in(btnL),
        .pulse (left_pulse)
    );

    btn_onepulse right_btn (
        .clk   (CLK100MHZ),
        .reset (btnC),
        .btn_in(btnR),
        .pulse (right_pulse)
    );


    // ==== 4. Game logic (2048 core) ====
    // We keep board as 16 tiles of up to, say, 12 bits (4096 max).
    wire [11:0] board [0:15];
    wire [15:0] score;
    wire [1:0]  game_state;

    game_logic core (
        .clk(CLK100MHZ),           // maybe use a slower divided clock later
        .reset(btnC),
        .move_up(up_pulse),
        .move_down(down_pulse),
        .move_left(left_pulse),
        .move_right(right_pulse),
        .board(board),
        .score(score),
        .game_state(game_state)
    );

    // ==== 5. Tile renderer (VGA pixels) ====
    wire [11:0] rgb; // 4-4-4

    tile_renderer draw (
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .video_on(video_on),
        .board(board),
        .game_state(game_state),
        .rgb(rgb)
    );

    // ==== 6. Map RGB bus to VGA pins ====
    assign vga_r = rgb[11:8];
    assign vga_g = rgb[7:4];
    assign vga_b = rgb[3:0];

    // ==== 7. SSD score display ====
    ssd_score ssd_unit (
        .clk(CLK100MHZ),
        .score(score),
        .an(an),
        .seg(seg),
        .dp(dp)
    );

    // ==== 8. LEDs for debug (optional) ====
    assign led[1:0] = game_state;

endmodule
