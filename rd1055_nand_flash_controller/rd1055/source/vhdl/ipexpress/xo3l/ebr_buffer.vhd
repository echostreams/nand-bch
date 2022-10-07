-- VHDL netlist generated by SCUBA Diamond (64-bit) 3.3.0.109  Patch Version(s) 122746
-- Module  Version: 7.4
--C:\lscc\diamond\3.3_x64\ispfpga\bin\nt64\scuba.exe -w -n ebr_buffer -lang vhdl -synth synplify -bus_exp 7 -bb -arch xo3c00a -type bram -wp 11 -rp 1010 -data_width 8 -rdata_width 8 -num_rows 2048 -outdataA REGISTERED -outdataB REGISTERED -cascade -1 -resetmode ASYNC -reset_rel SYNC -mem_init0 -writemodeA NORMAL -writemodeB NORMAL 

-- Mon Nov 10 22:58:42 2014

library IEEE;
use IEEE.std_logic_1164.all;
-- synopsys translate_off
library MACHXO3L;
use MACHXO3L.components.all;
-- synopsys translate_on

entity ebr_buffer is
    port (
        DataInA: in  std_logic_vector(7 downto 0); 
        DataInB: in  std_logic_vector(7 downto 0); 
        AddressA: in  std_logic_vector(10 downto 0); 
        AddressB: in  std_logic_vector(10 downto 0); 
        ClockA: in  std_logic; 
        ClockB: in  std_logic; 
        ClockEnA: in  std_logic; 
        ClockEnB: in  std_logic; 
        WrA: in  std_logic; 
        WrB: in  std_logic; 
        ResetA: in  std_logic; 
        ResetB: in  std_logic; 
        QA: out  std_logic_vector(7 downto 0); 
        QB: out  std_logic_vector(7 downto 0));
end ebr_buffer;

architecture Structure of ebr_buffer is

    -- internal signal declarations
    signal scuba_vhi: std_logic;
    signal scuba_vlo: std_logic;

    -- local component declarations
    component VHI
        port (Z: out  std_logic);
    end component;
    component VLO
        port (Z: out  std_logic);
    end component;
    component DP8KC
        generic (INIT_DATA : in String; INITVAL_1F : in String; 
                INITVAL_1E : in String; INITVAL_1D : in String; 
                INITVAL_1C : in String; INITVAL_1B : in String; 
                INITVAL_1A : in String; INITVAL_19 : in String; 
                INITVAL_18 : in String; INITVAL_17 : in String; 
                INITVAL_16 : in String; INITVAL_15 : in String; 
                INITVAL_14 : in String; INITVAL_13 : in String; 
                INITVAL_12 : in String; INITVAL_11 : in String; 
                INITVAL_10 : in String; INITVAL_0F : in String; 
                INITVAL_0E : in String; INITVAL_0D : in String; 
                INITVAL_0C : in String; INITVAL_0B : in String; 
                INITVAL_0A : in String; INITVAL_09 : in String; 
                INITVAL_08 : in String; INITVAL_07 : in String; 
                INITVAL_06 : in String; INITVAL_05 : in String; 
                INITVAL_04 : in String; INITVAL_03 : in String; 
                INITVAL_02 : in String; INITVAL_01 : in String; 
                INITVAL_00 : in String; ASYNC_RESET_RELEASE : in String; 
                RESETMODE : in String; GSR : in String; 
                WRITEMODE_B : in String; WRITEMODE_A : in String; 
                CSDECODE_B : in String; CSDECODE_A : in String; 
                REGMODE_B : in String; REGMODE_A : in String; 
                DATA_WIDTH_B : in Integer; DATA_WIDTH_A : in Integer);
        port (DIA8: in  std_logic; DIA7: in  std_logic; 
            DIA6: in  std_logic; DIA5: in  std_logic; 
            DIA4: in  std_logic; DIA3: in  std_logic; 
            DIA2: in  std_logic; DIA1: in  std_logic; 
            DIA0: in  std_logic; ADA12: in  std_logic; 
            ADA11: in  std_logic; ADA10: in  std_logic; 
            ADA9: in  std_logic; ADA8: in  std_logic; 
            ADA7: in  std_logic; ADA6: in  std_logic; 
            ADA5: in  std_logic; ADA4: in  std_logic; 
            ADA3: in  std_logic; ADA2: in  std_logic; 
            ADA1: in  std_logic; ADA0: in  std_logic; CEA: in  std_logic; 
            OCEA: in  std_logic; CLKA: in  std_logic; WEA: in  std_logic; 
            CSA2: in  std_logic; CSA1: in  std_logic; 
            CSA0: in  std_logic; RSTA: in  std_logic; 
            DIB8: in  std_logic; DIB7: in  std_logic; 
            DIB6: in  std_logic; DIB5: in  std_logic; 
            DIB4: in  std_logic; DIB3: in  std_logic; 
            DIB2: in  std_logic; DIB1: in  std_logic; 
            DIB0: in  std_logic; ADB12: in  std_logic; 
            ADB11: in  std_logic; ADB10: in  std_logic; 
            ADB9: in  std_logic; ADB8: in  std_logic; 
            ADB7: in  std_logic; ADB6: in  std_logic; 
            ADB5: in  std_logic; ADB4: in  std_logic; 
            ADB3: in  std_logic; ADB2: in  std_logic; 
            ADB1: in  std_logic; ADB0: in  std_logic; CEB: in  std_logic; 
            OCEB: in  std_logic; CLKB: in  std_logic; WEB: in  std_logic; 
            CSB2: in  std_logic; CSB1: in  std_logic; 
            CSB0: in  std_logic; RSTB: in  std_logic; 
            DOA8: out  std_logic; DOA7: out  std_logic; 
            DOA6: out  std_logic; DOA5: out  std_logic; 
            DOA4: out  std_logic; DOA3: out  std_logic; 
            DOA2: out  std_logic; DOA1: out  std_logic; 
            DOA0: out  std_logic; DOB8: out  std_logic; 
            DOB7: out  std_logic; DOB6: out  std_logic; 
            DOB5: out  std_logic; DOB4: out  std_logic; 
            DOB3: out  std_logic; DOB2: out  std_logic; 
            DOB1: out  std_logic; DOB0: out  std_logic);
    end component;
    attribute MEM_LPC_FILE : string; 
    attribute MEM_INIT_FILE : string; 
    attribute MEM_LPC_FILE of ebr_buffer_0_0_1 : label is "ebr_buffer.lpc";
    attribute MEM_INIT_FILE of ebr_buffer_0_0_1 : label is "INIT_ALL_0s";
    attribute MEM_LPC_FILE of ebr_buffer_0_1_0 : label is "ebr_buffer.lpc";
    attribute MEM_INIT_FILE of ebr_buffer_0_1_0 : label is "INIT_ALL_0s";
    attribute NGD_DRC_MASK : integer;
    attribute NGD_DRC_MASK of Structure : architecture is 1;

begin
    -- component instantiation statements
    scuba_vhi_inst: VHI
        port map (Z=>scuba_vhi);

    ebr_buffer_0_0_1: DP8KC
        generic map (INIT_DATA=> "STATIC", ASYNC_RESET_RELEASE=> "SYNC", 
        INITVAL_1F=> "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000", 
        INITVAL_1E=> "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000", 
        INITVAL_1D=> "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000", 
        INITVAL_1C=> "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000", 
        INITVAL_1B=> "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000", 
        INITVAL_1A=> "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000", 
        INITVAL_19=> "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000", 
        INITVAL_18=> "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000", 
        INITVAL_17=> "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000", 
        INITVAL_16=> "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000", 
        INITVAL_15=> "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000", 
        INITVAL_14=> "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000", 
        INITVAL_13=> "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000", 
        INITVAL_12=> "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000", 
        INITVAL_11=> "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000", 
        INITVAL_10=> "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000", 
        INITVAL_0F=> "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000", 
        INITVAL_0E=> "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000", 
        INITVAL_0D=> "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000", 
        INITVAL_0C=> "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000", 
        INITVAL_0B=> "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000", 
        INITVAL_0A=> "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000", 
        INITVAL_09=> "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000", 
        INITVAL_08=> "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000", 
        INITVAL_07=> "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000", 
        INITVAL_06=> "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000", 
        INITVAL_05=> "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000", 
        INITVAL_04=> "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000", 
        INITVAL_03=> "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000", 
        INITVAL_02=> "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000", 
        INITVAL_01=> "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000", 
        INITVAL_00=> "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000", 
        CSDECODE_B=> "0b000", CSDECODE_A=> "0b000", WRITEMODE_B=> "NORMAL", 
        WRITEMODE_A=> "NORMAL", GSR=> "ENABLED", RESETMODE=> "ASYNC", 
        REGMODE_B=> "OUTREG", REGMODE_A=> "OUTREG", DATA_WIDTH_B=>  4, 
        DATA_WIDTH_A=>  4)
        port map (DIA8=>scuba_vlo, DIA7=>scuba_vlo, DIA6=>scuba_vlo, 
            DIA5=>scuba_vlo, DIA4=>scuba_vlo, DIA3=>DataInA(3), 
            DIA2=>DataInA(2), DIA1=>DataInA(1), DIA0=>DataInA(0), 
            ADA12=>AddressA(10), ADA11=>AddressA(9), ADA10=>AddressA(8), 
            ADA9=>AddressA(7), ADA8=>AddressA(6), ADA7=>AddressA(5), 
            ADA6=>AddressA(4), ADA5=>AddressA(3), ADA4=>AddressA(2), 
            ADA3=>AddressA(1), ADA2=>AddressA(0), ADA1=>scuba_vlo, 
            ADA0=>scuba_vlo, CEA=>ClockEnA, OCEA=>ClockEnA, CLKA=>ClockA, 
            WEA=>WrA, CSA2=>scuba_vlo, CSA1=>scuba_vlo, CSA0=>scuba_vlo, 
            RSTA=>ResetA, DIB8=>scuba_vlo, DIB7=>scuba_vlo, 
            DIB6=>scuba_vlo, DIB5=>scuba_vlo, DIB4=>scuba_vlo, 
            DIB3=>DataInB(3), DIB2=>DataInB(2), DIB1=>DataInB(1), 
            DIB0=>DataInB(0), ADB12=>AddressB(10), ADB11=>AddressB(9), 
            ADB10=>AddressB(8), ADB9=>AddressB(7), ADB8=>AddressB(6), 
            ADB7=>AddressB(5), ADB6=>AddressB(4), ADB5=>AddressB(3), 
            ADB4=>AddressB(2), ADB3=>AddressB(1), ADB2=>AddressB(0), 
            ADB1=>scuba_vlo, ADB0=>scuba_vlo, CEB=>ClockEnB, 
            OCEB=>ClockEnB, CLKB=>ClockB, WEB=>WrB, CSB2=>scuba_vlo, 
            CSB1=>scuba_vlo, CSB0=>scuba_vlo, RSTB=>ResetB, DOA8=>open, 
            DOA7=>open, DOA6=>open, DOA5=>open, DOA4=>open, DOA3=>QA(3), 
            DOA2=>QA(2), DOA1=>QA(1), DOA0=>QA(0), DOB8=>open, 
            DOB7=>open, DOB6=>open, DOB5=>open, DOB4=>open, DOB3=>QB(3), 
            DOB2=>QB(2), DOB1=>QB(1), DOB0=>QB(0));

    scuba_vlo_inst: VLO
        port map (Z=>scuba_vlo);

    ebr_buffer_0_1_0: DP8KC
        generic map (INIT_DATA=> "STATIC", ASYNC_RESET_RELEASE=> "SYNC", 
        INITVAL_1F=> "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000", 
        INITVAL_1E=> "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000", 
        INITVAL_1D=> "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000", 
        INITVAL_1C=> "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000", 
        INITVAL_1B=> "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000", 
        INITVAL_1A=> "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000", 
        INITVAL_19=> "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000", 
        INITVAL_18=> "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000", 
        INITVAL_17=> "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000", 
        INITVAL_16=> "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000", 
        INITVAL_15=> "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000", 
        INITVAL_14=> "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000", 
        INITVAL_13=> "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000", 
        INITVAL_12=> "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000", 
        INITVAL_11=> "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000", 
        INITVAL_10=> "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000", 
        INITVAL_0F=> "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000", 
        INITVAL_0E=> "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000", 
        INITVAL_0D=> "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000", 
        INITVAL_0C=> "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000", 
        INITVAL_0B=> "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000", 
        INITVAL_0A=> "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000", 
        INITVAL_09=> "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000", 
        INITVAL_08=> "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000", 
        INITVAL_07=> "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000", 
        INITVAL_06=> "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000", 
        INITVAL_05=> "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000", 
        INITVAL_04=> "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000", 
        INITVAL_03=> "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000", 
        INITVAL_02=> "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000", 
        INITVAL_01=> "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000", 
        INITVAL_00=> "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000", 
        CSDECODE_B=> "0b000", CSDECODE_A=> "0b000", WRITEMODE_B=> "NORMAL", 
        WRITEMODE_A=> "NORMAL", GSR=> "ENABLED", RESETMODE=> "ASYNC", 
        REGMODE_B=> "OUTREG", REGMODE_A=> "OUTREG", DATA_WIDTH_B=>  4, 
        DATA_WIDTH_A=>  4)
        port map (DIA8=>scuba_vlo, DIA7=>scuba_vlo, DIA6=>scuba_vlo, 
            DIA5=>scuba_vlo, DIA4=>scuba_vlo, DIA3=>DataInA(7), 
            DIA2=>DataInA(6), DIA1=>DataInA(5), DIA0=>DataInA(4), 
            ADA12=>AddressA(10), ADA11=>AddressA(9), ADA10=>AddressA(8), 
            ADA9=>AddressA(7), ADA8=>AddressA(6), ADA7=>AddressA(5), 
            ADA6=>AddressA(4), ADA5=>AddressA(3), ADA4=>AddressA(2), 
            ADA3=>AddressA(1), ADA2=>AddressA(0), ADA1=>scuba_vlo, 
            ADA0=>scuba_vlo, CEA=>ClockEnA, OCEA=>ClockEnA, CLKA=>ClockA, 
            WEA=>WrA, CSA2=>scuba_vlo, CSA1=>scuba_vlo, CSA0=>scuba_vlo, 
            RSTA=>ResetA, DIB8=>scuba_vlo, DIB7=>scuba_vlo, 
            DIB6=>scuba_vlo, DIB5=>scuba_vlo, DIB4=>scuba_vlo, 
            DIB3=>DataInB(7), DIB2=>DataInB(6), DIB1=>DataInB(5), 
            DIB0=>DataInB(4), ADB12=>AddressB(10), ADB11=>AddressB(9), 
            ADB10=>AddressB(8), ADB9=>AddressB(7), ADB8=>AddressB(6), 
            ADB7=>AddressB(5), ADB6=>AddressB(4), ADB5=>AddressB(3), 
            ADB4=>AddressB(2), ADB3=>AddressB(1), ADB2=>AddressB(0), 
            ADB1=>scuba_vlo, ADB0=>scuba_vlo, CEB=>ClockEnB, 
            OCEB=>ClockEnB, CLKB=>ClockB, WEB=>WrB, CSB2=>scuba_vlo, 
            CSB1=>scuba_vlo, CSB0=>scuba_vlo, RSTB=>ResetB, DOA8=>open, 
            DOA7=>open, DOA6=>open, DOA5=>open, DOA4=>open, DOA3=>QA(7), 
            DOA2=>QA(6), DOA1=>QA(5), DOA0=>QA(4), DOB8=>open, 
            DOB7=>open, DOB6=>open, DOB5=>open, DOB4=>open, DOB3=>QB(7), 
            DOB2=>QB(6), DOB1=>QB(5), DOB0=>QB(4));

end Structure;

-- synopsys translate_off
library MACHXO3L;
configuration Structure_CON of ebr_buffer is
    for Structure
        for all:VHI use entity MACHXO3L.VHI(V); end for;
        for all:VLO use entity MACHXO3L.VLO(V); end for;
        for all:DP8KC use entity MACHXO3L.DP8KC(V); end for;
    end for;
end Structure_CON;

-- synopsys translate_on
