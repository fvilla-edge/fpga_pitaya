`timescale 1ns / 1ps
// Testbench de dio_lectura (al final de rtl/rtl/rp_gpio/rp_gpio.sv):
// DIO2_P siempre entrada aunque el software escriba 0 en dir_p, y lectura
// de los pines con 2 flops de sincronizacion. Ver etapa_dio_sim.sh.
module tb_dio_lectura;

logic        clk = 0;
logic [ 7:0] dir_p_sw = '0;
logic [ 7:0] pin_p = '0;
logic [ 7:0] pin_n = '0;
logic [ 7:0] dir_p_efectiva;
logic [15:0] pines;
logic [31:0] id;

int ok = 0, fallas = 0;

always #4 clk = ~clk;  // 125 MHz

dio_lectura dut (.*);

task automatic chequear(string que, logic [31:0] leido, logic [31:0] esperado);
  if (leido === esperado) begin ok++; $display("OK   %s: 0x%0h", que, leido); end
  else begin fallas++; $display("FAIL %s: leido 0x%0h, esperado 0x%0h", que, leido, esperado); end
endtask

initial begin
  // direccion efectiva: DIO2_P siempre entrada
  dir_p_sw = 8'h00; #1; chequear("dir 0x00 -> DIO2_P entrada", dir_p_efectiva, 8'h04);
  dir_p_sw = 8'h02; #1; chequear("dir 0x02 -> 0x06",           dir_p_efectiva, 8'h06);
  dir_p_sw = 8'hFF; #1; chequear("dir 0xFF sin cambios",       dir_p_efectiva, 8'hFF);
  dir_p_sw = 8'hFB; #1; chequear("dir 0xFB (bit2 en 0) -> 0xFF", dir_p_efectiva, 8'hFF);
  dir_p_sw = 8'h00;

  chequear("id (0x7C) = SM v1", id, 32'h534D_0001);

  // arranque: registro en 0
  @(negedge clk); chequear("pines al arranque", pines, 16'h0000);

  // rele "off": NPN cortado -> pull-up -> DIO2_P = 1; latencia de 2 flancos
  pin_p = 8'h04;
  @(posedge clk); #1; chequear("DIO2_P=1 tras 1 flanco (todavia no)", pines, 16'h0000);
  @(posedge clk); #1; chequear("DIO2_P=1 tras 2 flancos", pines, 16'h0004);
  chequear("mascara 0x4 de control_starlink -> off", |(pines & 16'h4), 1'b1);

  // rele "on": NPN saturado -> DIO2_P = 0
  pin_p = 8'h00;
  repeat (2) @(posedge clk); #1; chequear("DIO2_P=0 (on)", pines, 16'h0000);

  // posiciones P y N
  pin_p = 8'hA5; pin_n = 8'h3C;
  repeat (2) @(posedge clk); #1; chequear("{N,P} = {0x3C,0xA5}", pines, 16'h3CA5);

  // cambio de pin a mitad de ciclo (asincronico) -> se toma en el flanco siguiente
  pin_p = 8'h00; pin_n = 8'h00;
  repeat (2) @(posedge clk);
  #2 pin_p = 8'h04;
  repeat (2) @(posedge clk); #1; chequear("cambio asincronico", pines, 16'h0004);

  $display("RESULTADO: %s (%0d/%0d)", fallas == 0 ? "TODOS LOS CHECKS PASARON" : "CHECKS FALLARON", ok, ok + fallas);
  $finish;
end

initial begin #10000; $display("TIMEOUT"); $finish; end

endmodule
