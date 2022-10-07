/* Verilog netlist generated by SCUBA Diamond (64-bit) 3.3.0.109  Patch Version(s) 122746 */
/* Module Version: 7.4 */
/* C:\lscc\diamond\3.3_x64\ispfpga\bin\nt64\scuba.exe -w -n ebr_buffer -lang verilog -synth synplify -bus_exp 7 -bb -arch mj5g00 -type bram -wp 11 -rp 1010 -data_width 8 -rdata_width 8 -num_rows 2048 -outdataA REGISTERED -outdataB REGISTERED -writemodeA NORMAL -writemodeB NORMAL -resetmode ASYNC -cascade -1  */
/* Mon Nov 10 22:18:45 2014 */


// B goes to the flash
// A comes from the flash
// I think...

`timescale 1 ns / 1 ps
module ebr_buffer (DataInA, DataInB, AddressA, AddressB, ClockA, ClockB, 
    ClockEnA, ClockEnB, WrA, WrB, ResetA, ResetB, QA, QB, ram_a_addr0)/* synthesis NGD_DRC_MASK=1 */;
    input wire [7:0] DataInA;
    input wire [7:0] DataInB;
    input wire [10:0] AddressA;
    input wire [10:0] AddressB;
    input wire ClockA;
    input wire ClockB;
    input wire ClockEnA;
    input wire ClockEnB;
    input wire WrA;
    input wire WrB;
    input wire ResetA;
    input wire ResetB;
    output wire [7:0] QA;
    output wire [7:0] QB;
    output wire [7:0] ram_a_addr0;

    wire [7:0] dummy;
    
    raminfr bram_a(ClockA, ClockEnA, ResetA, WrA, AddressA, DataInA, QA, ram_a_addr0);
    raminfr bram_b(ClockB, ClockEnB, ResetB, WrB, AddressB, DataInB, QB, dummy);

endmodule

module raminfr (clk, en, res, we, a, di, do, addr0); 
input clk; 
input en;
input res;
input we;   
input  [10:0] a;   
input  [7:0] di;   
output [7:0] do;
output [7:0] addr0;
reg    [7:0] ram [0:2047];   
reg    [7:0] read_a, addr_0; 
integer i;
 
  always @(posedge clk) begin 
    if (res)
    begin
        for (i=0; i<2048; i=i+1) ram[i] <= 8'b00000000;
    end
    else
    if (en) 
    begin
      read_a <= a;   
      if (we) begin
        ram[a] <= di;
      end   
    end 
  end   
  assign do = ram[read_a];
  assign addr0 = ram[0];   
endmodule 