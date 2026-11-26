/*
 * Copyright (c) 2024 Uri Shaked
 * SPDX-License-Identifier: Apache-2.0
 */
 
`default_nettype none
 
module tt_um_vga_example(
  input  wire [7:0] ui_in,    // Dedicated inputs
  output wire [7:0] uo_out,   // Dedicated outputs
  input  wire [7:0] uio_in,   // IOs: Input path
  output wire [7:0] uio_out,  // IOs: Output path
  output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
  input  wire       ena,      // always 1 when the design is powered, so you can ignore it
  input  wire       clk,      // clock
  input  wire       rst_n     // reset_n - low to reset
);
 
  // VGA signals
  wire hsync;
  wire vsync;
  wire [1:0] R;
  wire [1:0] G;
  wire [1:0] B;
  wire video_active;
  wire [9:0] pix_x;
  wire [9:0] pix_y;
 
  // TinyVGA PMOD
  assign uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};
 
  // Unused outputs assigned to 0.
  assign uio_out = 0;
  assign uio_oe  = 0;
 
  // Suppress unused signals warning
  wire _unused_ok = &{ena, ui_in, uio_in};
 
 
 
  hvsync_generator hvsync_gen(
    .clk(clk),
    .reset(~rst_n),
    .hsync(hsync),
    .vsync(vsync),
    .display_on(video_active), //!blank
    .hpos(pix_x),
    .vpos(pix_y)
  );
 
  reg [9:0] rect_top;
  reg [9:0] rect_left;
  reg [9:0] enemies_center_x;
  reg [9:0] enemies_center_y;
  reg [9:0] bullet_y;
  reg [9:0] bullet_x;
  reg [1:0] color = 3;
  
  assign R = color;
  assign G = R;
  assign B = G;

  reg [16:0] counter;
  reg [18:0] enemies_movement;
  reg enemies_direction;
  reg [1:0] red_color;
  reg shape1, shape2, shape3, shape4, shape5, shape6, shape7;
  reg [5:0] shapes_vis;
  reg player_vis;
  reg bulletshape;
  reg [2:0] enemies_bullet;
  reg [9:0] enemies_bullet_y;
  reg [9:0] enemies_bullet_x;
  reg [2:0] death;
  reg enemy_firing;
  reg fire_available;
  reg failed;
  reg win;
  reg wincon;
 
  always @(posedge clk) begin
    if (rst_n == 0) begin
      color <= 3;
      red_color <= 2;
      counter <= 0;
      rect_top <= 0;
      rect_left <= 345;
      enemies_center_x <= 320;
      enemies_center_y <= 120;
      enemies_movement <= 0;
      enemies_direction <= 0;
      shape1 <= 0;
      shape2 <= 0;
      shape3 <= 0;
      shape4 <= 0;
      shape5 <= 0;
      shape6 <= 0;
      shape7 <= 0;
      shapes_vis <= 0;
      player_vis <= 1;
      failed <= 0;
      wincon <= 0;
      death <= 0;

      bullet_y <= 0;
      bullet_x <= 0;
      enemy_firing <= 0;
      fire_available <= 1;
      enemies_bullet_x <= 0;
      enemies_bullet_y <= 130;
    end
    else begin 

      if (enemies_bullet_y >= 440) begin
        enemies_bullet_y <= 130;
        enemy_firing <= 0;
      end

      if (!enemy_firing) begin
        enemy_firing <= 1;
        enemies_bullet_x <= enemies_center_x;
      end

      if (!ui_in[2] && fire_available && !failed) begin
        bullet_y <= 400;
      end

      if (ui_in[2] && fire_available && !failed) begin
        bullet_y <= 400;
        fire_available <= 0;
        bullet_x <= rect_left;
      end

      if (bullet_y <= 20 && !fire_available) begin
        fire_available <= 1;
      end

      if (enemies_center_x > 400) begin
        enemies_direction <= 1;
      end else if (enemies_center_x < 240) begin
        enemies_direction <= 0;
      end

      enemies_movement <= enemies_movement + 1;
      if (enemies_movement == 0) begin
        if (enemies_center_x && !enemies_direction) begin
          enemies_center_x <= enemies_center_x + 1;
        end
        if (enemies_center_x && enemies_direction) begin
          enemies_center_x <= enemies_center_x - 1;
        end         
      end

      counter <= counter + 1;
      if(counter == 0)begin
        //red_color <= red_color + 1;
        if(ui_in[0] == 1 && !failed) begin
          rect_left <= rect_left - 1;
        end
        if(ui_in[1] == 1 && !failed) begin
          rect_left <= rect_left + 1;
        end

        bullet_y <= bullet_y - 1;
        enemies_bullet_y <= enemies_bullet_y + 1;
      end
    end
      win <= ((pix_x > 180 && pix_x < 188 && pix_y > 215 && pix_y < 241) || 
        (pix_x > 208 && pix_x < 216 && pix_y > 215 && pix_y < 241) || 
        (pix_x > 180 && pix_x < 216 && pix_y > 237 && pix_y < 245) || 
        (pix_x > 194 && pix_x < 202 && pix_y > 241 && pix_y < 265)) || 
        ((pix_x > 226 && pix_x < 262 && pix_y > 215 && pix_y < 223) || 
        (pix_x > 226 && pix_x < 262 && pix_y > 257 && pix_y < 265) || 
        (pix_x > 226 && pix_x < 234 && pix_y > 215 && pix_y < 265) || 
        (pix_x > 254 && pix_x < 262 && pix_y > 215 && pix_y < 265)) || 
        ((pix_x > 272 && pix_x < 280 && pix_y > 215 && pix_y < 265) || 
        (pix_x > 300 && pix_x < 308 && pix_y > 215 && pix_y < 265) || 
        (pix_x > 272 && pix_x < 308 && pix_y > 257 && pix_y < 265)) || 
        ((pix_x > 340 && pix_x < 348 && pix_y > 215 && pix_y < 265) || 
        (pix_x > 358 && pix_x < 366 && pix_y > 230 && pix_y < 265) || 
        (pix_x > 376 && pix_x < 384 && pix_y > 215 && pix_y < 265) || 
        (pix_x > 340 && pix_x < 384 && pix_y > 257 && pix_y < 265)) || 
        ((pix_x > 394 && pix_x < 414 && pix_y > 215 && pix_y < 223) || 
        (pix_x > 400 && pix_x < 408 && pix_y > 215 && pix_y < 265) || 
        (pix_x > 394 && pix_x < 414 && pix_y > 257 && pix_y < 265)) || 
        ((pix_x > 424 && pix_x < 432 && pix_y > 215 && pix_y < 265) || 
        (pix_x > 452 && pix_x < 460 && pix_y > 215 && pix_y < 265) || 
        (pix_x > 432 && pix_x < 440 && pix_y > 225 && pix_y < 240) || 
        (pix_x > 438 && pix_x < 446 && pix_y > 235 && pix_y < 250) || 
        (pix_x > 444 && pix_x < 452 && pix_y > 245 && pix_y < 260));

      bulletshape <= ((pix_x < bullet_x - 21) && (pix_x > bullet_x - 26) && pix_y < 20 + bullet_y && pix_y > 0 + bullet_y);

      shape1 <= ((pix_x < rect_left) && (pix_x > rect_left - 50) && pix_y < 440 && pix_y > 410) ||
                ((pix_x < rect_left - 20) && (pix_x > rect_left - 30) && pix_y < 415 && pix_y > 400);
      
      shape2 <= ((pix_x - enemies_center_x) * (pix_x - enemies_center_x)
                 + (pix_y - enemies_center_y) * (pix_y - enemies_center_y) < 1000);
      
      shape3 <= ((pix_x - enemies_center_x - 150) * (pix_x - enemies_center_x - 150)
                 + (pix_y - enemies_center_y) * (pix_y - enemies_center_y) < 1000);

      shape4 <= ((pix_x - enemies_center_x + 150) * (pix_x - enemies_center_x + 150)
                 + (pix_y - enemies_center_y) * (pix_y - enemies_center_y) < 1000);

      shape5 <= ((pix_x < 355) && (pix_x > 285) && pix_y < 350 && pix_y > 300);
      shape6 <= ((pix_x < 320 + 35 - 150) && (pix_x > 320 - 35 - 150) && pix_y < 350 && pix_y > 300);
      shape7 <= ((pix_x < 320 + 35 + 150) && (pix_x > 320 - 35 + 150) && pix_y < 350 && pix_y > 300);

      enemies_bullet[0] <= ((pix_x < 5 + enemies_bullet_x) && (pix_x > enemies_bullet_x) && pix_y < 20 + enemies_bullet_y && pix_y > 0 + enemies_bullet_y) && !death[0];
      enemies_bullet[1] <= ((pix_x < 5 + 150 + enemies_bullet_x) && (pix_x > 150 + enemies_bullet_x) && pix_y < 20 + enemies_bullet_y && pix_y > 0 + enemies_bullet_y) && !death[1];
      enemies_bullet[2] <= ((pix_x < 5 - 150 + enemies_bullet_x) && (pix_x > -150 + enemies_bullet_x) && pix_y < 20 + enemies_bullet_y && pix_y > 0 + enemies_bullet_y) && !death[2];

      if (bulletshape && shape2 && !shapes_vis[0]) begin
        bullet_y <= 400;
        fire_available <= 1;
        shapes_vis[0] <= 1;
        death[0] <= 1;
      end
      if (bulletshape && shape3 && !shapes_vis[1]) begin
        bullet_y <= 400;
        fire_available <= 1;
        shapes_vis[1] <= 1;
        death[1] <= 1;
      end
      if (bulletshape && shape4 && !shapes_vis[2]) begin
        bullet_y <= 400;
        fire_available <= 1;
        shapes_vis[2] <= 1;
        death[2] <= 1;
      end
      if (bulletshape && shape5 && !shapes_vis[3]) begin
        bullet_y <= 400;
        fire_available <= 1;
        shapes_vis[3] <= 1;
      end
      if (bulletshape && shape6 && !shapes_vis[4]) begin
        bullet_y <= 400;
        fire_available <= 1;
        shapes_vis[4] <= 1;
      end
      if (bulletshape && shape7 && !shapes_vis[5]) begin
        bullet_y <= 400;
        fire_available <= 1;
        shapes_vis[5] <= 1;
      end

      if ((enemies_bullet[0] || enemies_bullet[1] || enemies_bullet[2]) && shape1) begin
        player_vis <= 0;
        failed <= 1;
      end

      if (shapes_vis[0] && shapes_vis[1] && shapes_vis[2]) begin
        wincon <= 1;
      end
      
      color <= (shape1 && player_vis || 
                shape2 && !shapes_vis[0] || 
                shape3 && !shapes_vis[1] || 
                shape4 && !shapes_vis[2] || 
                shape5 && !shapes_vis[3] || 
                shape6 && !shapes_vis[4] || 
                shape7 && !shapes_vis[5] || 
                (bulletshape & !fire_available) || 
                enemies_bullet[0] && !death[0]||
                enemies_bullet[1] && !death[1]||
                enemies_bullet[2] && !death[2]||
                (win && wincon))? 3:0;
      
  end
 
 
endmodule