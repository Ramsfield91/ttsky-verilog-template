`default_nettype none

module tt_um_vga_example(
    input wire [7:0] ui_in, // Dedizierte Eingänge
    output wire [7:0] uo_out, // Dedizierte Ausgänge
    input wire [7:0] uio_in, // IOs: Eingangs-Pfad
    output wire [7:0] uio_out, // IOs: Ausgangs-Pfad
    output wire [7:0] uio_oe, // IOs: Enable-Pfad (aktiv High: 0=Eingang, 1=Ausgang)
    input wire ena, // Ignorieren
    input wire clk, // Takt
    input wire rst_n // Reset (aktiv Low)
);

  // VGA-Signale
  wire hsync;
  wire vsync;
  wire [1:0] R;
  wire [1:0] G;
  wire [1:0] B;
  wire video_active;
  wire [9:0] pix_x;
  wire [9:0] pix_y;
  
  // Ausgangssignale für VGA
  assign uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};
  
  // Ungenutzte Ausgänge auf 0 setzen
  assign uio_out = 0;
  assign uio_oe = 0;
  
  // Suppress Unused Signals Warning
  wire _unused_ok = &{ena, uio_in};
  
  // VGA-Signalgenerator instanziieren
  hvsync_generator hvsync_gen(
      .clk(clk),
      .reset(~rst_n),
      .hsync(hsync),
      .vsync(vsync),
      .display_on(video_active),
      .hpos(pix_x),
      .vpos(pix_y)
  );
  
  // Strichmännchenposition
  reg [9:0] jump_offset; // Offset für das Springen

  always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
      jump_offset <= 0; // Reset
    end else begin
      if (ui_in[0]) begin
        jump_offset <= 50; // Springt um 50 Pixel
      end else begin
        jump_offset <= 0; // Zurück auf den Boden
      end
    end
  end

  // Bewegung für das rechteck
  reg [9:0] shift_amount; // Zähler für die Bewegung nach links

  // Rechteckbewegung
  always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
      shift_amount <= 0;
    end else if (ui_in[0]) begin
      shift_amount <= shift_amount + 1; // Bewege nach links
    end
  end

  // Strichmännchen-Zeichenlogik
  wire mann;
  assign mann = (pix_x >= 310 && pix_x <= 330 && pix_y >= (300 - jump_offset) && pix_y <= 320 - jump_offset);

  // Wiederholtes Rechteck alle 50 Pixel, bewegen, wenn aktiv
  wire rechteseite_rechteck;
  assign rechteseite_rechteck = ((pix_x + shift_amount) % 50 >= 40 && (pix_x + shift_amount) % 50 <= 49 && pix_y >= 315 && pix_y <= 330);

  // Bodendarstellung, immer anzeigen
  wire boden;
  assign boden = (pix_y >= 330 && pix_y <= 340);

  // VGA-Farbsignale
  assign R = video_active ? ((boden || mann || rechteseite_rechteck) ? 2'b11 : 2'b00) : 2'b00; // Boden, Männchen und Rechteck weiß, ansonsten schwarz
  assign G = R;
  assign B = R;

endmodule
