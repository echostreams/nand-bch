/* Verilog netlist generated by SCUBA Diamond (64-bit) 3.3.0.109  Patch Version(s) 122746 */
/* Module Version: 7.4 */
/* C:\lscc\diamond\3.3_x64\ispfpga\bin\nt64\scuba.exe -w -n ebr_buffer -lang verilog -synth synplify -bus_exp 7 -bb -arch mg5a00 -type bram -wp 11 -rp 1010 -data_width 8 -rdata_width 8 -num_rows 2048 -outdataA REGISTERED -outdataB REGISTERED -writemodeA NORMAL -writemodeB NORMAL -resetmode ASYNC -cascade -1  */
/* Mon Nov 10 23:18:21 2014 */


`timescale 1 ns / 1 ps
module ebr_buffer (DataInA, DataInB, AddressA, AddressB, ClockA, ClockB, 
    ClockEnA, ClockEnB, WrA, WrB, ResetA, ResetB, QA, QB)/* synthesis NGD_DRC_MASK=1 */;
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

    wire scuba_vhi;
    wire scuba_vlo;

    VHI scuba_vhi_inst (.Z(scuba_vhi));

    VLO scuba_vlo_inst (.Z(scuba_vlo));

    // synopsys translate_off
    defparam ebr_buffer_0_0_0.CSDECODE_B =  3'b000 ;
    defparam ebr_buffer_0_0_0.CSDECODE_A =  3'b000 ;
    defparam ebr_buffer_0_0_0.WRITEMODE_B = "NORMAL" ;
    defparam ebr_buffer_0_0_0.WRITEMODE_A = "NORMAL" ;
    defparam ebr_buffer_0_0_0.GSR = "DISABLED" ;
    defparam ebr_buffer_0_0_0.RESETMODE = "ASYNC" ;
    defparam ebr_buffer_0_0_0.REGMODE_B = "OUTREG" ;
    defparam ebr_buffer_0_0_0.REGMODE_A = "OUTREG" ;
    defparam ebr_buffer_0_0_0.DATA_WIDTH_B = 9 ;
    defparam ebr_buffer_0_0_0.DATA_WIDTH_A = 9 ;
    // synopsys translate_on
    DP16KB ebr_buffer_0_0_0 (.DIA0(DataInA[0]), .DIA1(DataInA[1]), .DIA2(DataInA[2]), 
        .DIA3(DataInA[3]), .DIA4(DataInA[4]), .DIA5(DataInA[5]), .DIA6(DataInA[6]), 
        .DIA7(DataInA[7]), .DIA8(scuba_vlo), .DIA9(scuba_vlo), .DIA10(scuba_vlo), 
        .DIA11(scuba_vlo), .DIA12(scuba_vlo), .DIA13(scuba_vlo), .DIA14(scuba_vlo), 
        .DIA15(scuba_vlo), .DIA16(scuba_vlo), .DIA17(scuba_vlo), .ADA0(scuba_vlo), 
        .ADA1(scuba_vlo), .ADA2(scuba_vlo), .ADA3(AddressA[0]), .ADA4(AddressA[1]), 
        .ADA5(AddressA[2]), .ADA6(AddressA[3]), .ADA7(AddressA[4]), .ADA8(AddressA[5]), 
        .ADA9(AddressA[6]), .ADA10(AddressA[7]), .ADA11(AddressA[8]), .ADA12(AddressA[9]), 
        .ADA13(AddressA[10]), .CEA(ClockEnA), .CLKA(ClockA), .WEA(WrA), 
        .CSA0(scuba_vlo), .CSA1(scuba_vlo), .CSA2(scuba_vlo), .RSTA(ResetA), 
        .DIB0(DataInB[0]), .DIB1(DataInB[1]), .DIB2(DataInB[2]), .DIB3(DataInB[3]), 
        .DIB4(DataInB[4]), .DIB5(DataInB[5]), .DIB6(DataInB[6]), .DIB7(DataInB[7]), 
        .DIB8(scuba_vlo), .DIB9(scuba_vlo), .DIB10(scuba_vlo), .DIB11(scuba_vlo), 
        .DIB12(scuba_vlo), .DIB13(scuba_vlo), .DIB14(scuba_vlo), .DIB15(scuba_vlo), 
        .DIB16(scuba_vlo), .DIB17(scuba_vlo), .ADB0(scuba_vlo), .ADB1(scuba_vlo), 
        .ADB2(scuba_vlo), .ADB3(AddressB[0]), .ADB4(AddressB[1]), .ADB5(AddressB[2]), 
        .ADB6(AddressB[3]), .ADB7(AddressB[4]), .ADB8(AddressB[5]), .ADB9(AddressB[6]), 
        .ADB10(AddressB[7]), .ADB11(AddressB[8]), .ADB12(AddressB[9]), .ADB13(AddressB[10]), 
        .CEB(ClockEnB), .CLKB(ClockB), .WEB(WrB), .CSB0(scuba_vlo), .CSB1(scuba_vlo), 
        .CSB2(scuba_vlo), .RSTB(ResetB), .DOA0(QA[0]), .DOA1(QA[1]), .DOA2(QA[2]), 
        .DOA3(QA[3]), .DOA4(QA[4]), .DOA5(QA[5]), .DOA6(QA[6]), .DOA7(QA[7]), 
        .DOA8(), .DOA9(), .DOA10(), .DOA11(), .DOA12(), .DOA13(), .DOA14(), 
        .DOA15(), .DOA16(), .DOA17(), .DOB0(QB[0]), .DOB1(QB[1]), .DOB2(QB[2]), 
        .DOB3(QB[3]), .DOB4(QB[4]), .DOB5(QB[5]), .DOB6(QB[6]), .DOB7(QB[7]), 
        .DOB8(), .DOB9(), .DOB10(), .DOB11(), .DOB12(), .DOB13(), .DOB14(), 
        .DOB15(), .DOB16(), .DOB17())
             /* synthesis MEM_LPC_FILE="ebr_buffer.lpc" */
             /* synthesis MEM_INIT_FILE="" */
             /* synthesis CSDECODE_B="0b000" */
             /* synthesis CSDECODE_A="0b000" */
             /* synthesis WRITEMODE_B="NORMAL" */
             /* synthesis WRITEMODE_A="NORMAL" */
             /* synthesis GSR="DISABLED" */
             /* synthesis RESETMODE="ASYNC" */
             /* synthesis REGMODE_B="OUTREG" */
             /* synthesis REGMODE_A="OUTREG" */
             /* synthesis DATA_WIDTH_B="9" */
             /* synthesis DATA_WIDTH_A="9" */;



    // exemplar begin
    // exemplar attribute ebr_buffer_0_0_0 MEM_LPC_FILE ebr_buffer.lpc
    // exemplar attribute ebr_buffer_0_0_0 MEM_INIT_FILE 
    // exemplar attribute ebr_buffer_0_0_0 CSDECODE_B 0b000
    // exemplar attribute ebr_buffer_0_0_0 CSDECODE_A 0b000
    // exemplar attribute ebr_buffer_0_0_0 WRITEMODE_B NORMAL
    // exemplar attribute ebr_buffer_0_0_0 WRITEMODE_A NORMAL
    // exemplar attribute ebr_buffer_0_0_0 GSR DISABLED
    // exemplar attribute ebr_buffer_0_0_0 RESETMODE ASYNC
    // exemplar attribute ebr_buffer_0_0_0 REGMODE_B OUTREG
    // exemplar attribute ebr_buffer_0_0_0 REGMODE_A OUTREG
    // exemplar attribute ebr_buffer_0_0_0 DATA_WIDTH_B 9
    // exemplar attribute ebr_buffer_0_0_0 DATA_WIDTH_A 9
    // exemplar end

endmodule
