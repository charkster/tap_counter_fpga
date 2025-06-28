// This file was created manually

module button_press_count_top
( input  logic  clk_100mhz, 
  input  logic  button_0,  
  input  logic  button_1,    
  output logic  led_1,
  output logic  led_2,
  output logic  led_3,
  output logic  led_4,
  output logic  led_5,
  output logic  led_6,
  output logic  led_7,
  output logic  led_8
);

  logic       clk_12mhz;
  logic       rst_n;
  logic [7:0] tap_count;
  logic       done;
  
  logic locked;
  
  // My board has a custom 100MHz oscillator, normal board has 12MHz
  clk_wiz_0 clk_wiz_0 
  ( .clk_in1  (clk_100mhz), // input
    .reset    (button_0),   // input
    .locked   (locked),     // output
    .clk_out1 (clk_12mhz)   // output
  );
 
  // synchronous reset
  synchronizer sync_rst_n
  ( .clk      (clk_12mhz), // input
    .rst_n    (locked),    // input
    .data_in  (1'b1),      // input
    .data_out (rst_n)      // output
  );
  
  // output leds
  always_ff @(posedge clk_12mhz, negedge rst_n)
    if (!rst_n) begin
      led_1 <= 0;
      led_2 <= 0;
      led_3 <= 0;
      led_4 <= 0;
      led_5 <= 0;
      led_6 <= 0;
      led_7 <= 0;
      led_8 <= 0;
    end
    else begin
      if (done && tap_count == 'd1) led_1 <= ~led_1;
      if (done && tap_count == 'd2) led_2 <= ~led_2;
      if (done && tap_count == 'd3) led_3 <= ~led_3;
      if (done && tap_count == 'd4) led_4 <= ~led_4;
      if (done && tap_count == 'd5) led_5 <= ~led_5;
      if (done && tap_count == 'd6) led_6 <= ~led_6;
      if (done && tap_count == 'd7) led_7 <= ~led_7;
      if (done && tap_count == 'd8) led_8 <= ~led_8;
    end

  // This was generated 100% by Copilot (ChatGPT), no changes
  tap_counter_debounced #(.TIMEOUT_CYCLES(12_000_000), .DEBOUNCE_CYCLES(12_000), .COUNT_WIDTH(8))
  u_tap_counter_debounced
  ( .clk        (clk_12mhz), // input
    .rst_n,                  // input, active-low sync reset
    .button_raw (button_1),  // input, async, bouncing input
    .count      (tap_count), // output, total taps counted
    .done                    // output, one-clk pulse on timeout
  );

endmodule
