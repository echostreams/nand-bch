--   ==================================================================
--   >>>>>>>>>>>>>>>>>>>>>>> COPYRIGHT NOTICE <<<<<<<<<<<<<<<<<<<<<<<<<
--   ------------------------------------------------------------------
--   Copyright (c) 2013 by Lattice Semiconductor Corporation
--   ALL RIGHTS RESERVED 
--   ------------------------------------------------------------------
--
--   Permission:
--
--      Lattice SG Pte. Ltd. grants permission to use this code
--      pursuant to the terms of the Lattice Reference Design License Agreement. 
--
--
--   Disclaimer:
--
--      This VHDL or Verilog source code is intended as a design reference
--      which illustrates how these types of functions can be implemented.
--      It is the user's responsibility to verify their design for
--      consistency and functionality through the use of formal
--      verification methods.  Lattice provides no warranty
--      regarding the use or functionality of this code.
--
--   --------------------------------------------------------------------
--
--                  Lattice SG Pte. Ltd.
--                  101 Thomson Road, United Square #07-02 
--                  Singapore 307591
--
--
--                  TEL: 1-800-Lattice (USA and Canada)
--                       +65-6631-2000 (Singapore)
--                       +1-503-268-8001 (other locations)
--
--                  web: http:--www.latticesemi.com/
--                  email: techsupport@latticesemi.com
--
--   --------------------------------------------------------------------
--
-- Revision History :
-- --------------------------------------------------------------------
--   Ver  :| Author      :| Mod. Date :| Changes Made:
--   V01.0:| Rainy Zhang :| 01/14/10  :| Initial ver
-- --------------------------------------------------------------------
--
-- 
--Description of module:
----------------------------------------------------------------------------------
--This module interprets commands from the Host, passes control to TFSM to execute 
--repeating regular tasks with strict timing requirements.
-- --------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY MFSM IS PORT (
    CLK   : IN STD_LOGIC;
    RES   : IN STD_LOGIC;
    start : IN STD_LOGIC;
    command : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    R_nB    : IN STD_LOGIC;
    BF_sel  : IN STD_LOGIC;
    io_0    : IN STD_LOGIC;
    t_done  : IN STD_LOGIC;
    tc8     : IN STD_LOGIC;
    tc4     : IN STD_LOGIC;
    setDone : OUT STD_LOGIC;
    mBF_sel : OUT STD_LOGIC;
    BF_we   : OUT STD_LOGIC;
    t_start : OUT STD_LOGIC;
    t_cmd   : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    WrECC   : OUT STD_LOGIC;
    EnEcc   : OUT STD_LOGIC;
    AMX_sel : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    cmd_reg : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    cmd_reg_we : OUT STD_LOGIC;
    RAR_we     : OUT STD_LOGIC;
    set835     : OUT STD_LOGIC;
    cnt_res    : OUT STD_LOGIC;
    wCntRes    : OUT STD_LOGIC;
    wCntCE     : OUT STD_LOGIC;
    SetPrErr   : OUT STD_LOGIC;
    SetErErr   : OUT STD_LOGIC;
--    state      : OUT STD_LOGIC_VECTOR( 7 DOWNTO 0);
    ADC_sel    : OUT STD_LOGIC_VECTOR(1 DOWNTO 0)
);

END ENTITY MFSM;

ARCHITECTURE translated OF MFSM IS 
   CONSTANT  Init :  std_logic_vector(7 downto 0) := x"00";
   CONSTANT  S_ADS:  std_logic_vector(7 downto 0) := x"01";
   CONSTANT  S_RAR:  std_logic_vector(7 downto 0) := x"02";
   CONSTANT  S_CmdL0 : std_logic_vector(7 downto 0) := x"03";
   CONSTANT  S_CmdL1 : std_logic_vector(7 downto 0) := x"04";
   CONSTANT  S_adL0  : std_logic_vector(7 downto 0) := x"05";
   CONSTANT  S_adL1  : std_logic_vector(7 downto 0) := x"06";
   CONSTANT  S_CmdL2 : std_logic_vector(7 downto 0) := x"07";
   CONSTANT  S_CmdL3 : std_logic_vector(7 downto 0) := x"08";
   CONSTANT  S_WC0   : std_logic_vector(7 downto 0) := x"09";
   CONSTANT  S_WC1   : std_logic_vector(7 downto 0) := x"0A";
   CONSTANT  S_wait  : std_logic_vector(7 downto 0) := x"0b";
   CONSTANT  S_CmdL4  : std_logic_vector(7 downto 0) := x"0c";
   CONSTANT  S_CmdL5  : std_logic_vector(7 downto 0) := x"0d";
   CONSTANT  S_WC3    : std_logic_vector(7 downto 0) := x"0E";
   CONSTANT  S_WC4    : std_logic_vector(7 downto 0) := x"0F";
   CONSTANT  S_DR1    : std_logic_vector(7 downto 0) := x"10";
   CONSTANT  S_Done   : std_logic_vector(7 downto 0) := x"11";
   CONSTANT  Sr_RAR   : std_logic_vector(7 downto 0) := x"12";
   CONSTANT  Sr_DnErr : std_logic_vector(7 downto 0) := x"13";
   CONSTANT  Sr_CmdL0 : std_logic_vector(7 downto 0) := x"14";
   CONSTANT  Sr_CmdL1 : std_logic_vector(7 downto 0) := x"15";
   CONSTANT  Sr_AdL0  : std_logic_vector(7 downto 0) := x"16";
   CONSTANT  Sr_AdL1  : std_logic_vector(7 downto 0) := x"17";
   CONSTANT  Sr_AdL2  : std_logic_vector(7 downto 0) := x"18";
   CONSTANT  Sr_AdL3  : std_logic_vector(7 downto 0) := x"19";
   CONSTANT  Sr_CmdL2  : std_logic_vector(7 downto 0) := x"1A";
   CONSTANT  Sr_CmdL3  : std_logic_vector(7 downto 0) := x"1B";
   CONSTANT  Sr_WC0    : std_logic_vector(7 downto 0) := x"1C";
   CONSTANT  Sr_WC1    : std_logic_vector(7 downto 0) := x"1D";
   CONSTANT  Sr_wait   : std_logic_vector(7 downto 0) := x"1E";
   CONSTANT  Sr_RPA0   : std_logic_vector(7 downto 0) := x"1F";
   CONSTANT  Sr_CmdL4   : std_logic_vector(7 downto 0) := x"20";
   CONSTANT  Sr_CmdL5   : std_logic_vector(7 downto 0) := x"21";
   CONSTANT  Sr_AdL4   : std_logic_vector(7 downto 0) := x"22";
   CONSTANT  Sr_AdL5   : std_logic_vector(7 downto 0) := x"23";
   CONSTANT  Sr_CmdL6   : std_logic_vector(7 downto 0) := x"24";
   CONSTANT  Sr_CmdL7   : std_logic_vector(7 downto 0) := x"25";
   CONSTANT  Sr_WC2   : std_logic_vector(7 downto 0) := x"26";
   CONSTANT  Sr_RPA1   : std_logic_vector(7 downto 0) := x"27";
   CONSTANT  Sr_wait1   : std_logic_vector(7 downto 0) := x"28";
   CONSTANT  Sr_wait2   : std_logic_vector(7 downto 0) := x"29";
   CONSTANT  Sr_WC3   : std_logic_vector(7 downto 0) := x"2A";
   CONSTANT  Sr_Done   : std_logic_vector(7 downto 0) := x"2B";
   CONSTANT  Sw_RAR   : std_logic_vector(7 downto 0) := x"2C";
   CONSTANT  Sw_CmdL0   : std_logic_vector(7 downto 0) := x"2D";
   CONSTANT  Sw_CmdL1   : std_logic_vector(7 downto 0) := x"2E";
   CONSTANT  Sw_AdL0   : std_logic_vector(7 downto 0) := x"2F";
   CONSTANT  Sw_AdL1   : std_logic_vector(7 downto 0) := x"30";
   CONSTANT  Sw_AdL2   : std_logic_vector(7 downto 0) := x"31";
   CONSTANT  Sw_AdL3   : std_logic_vector(7 downto 0) := x"32";
   CONSTANT  Sw_WPA0   : std_logic_vector(7 downto 0) := x"33";
   CONSTANT  Sw_CmdL2   : std_logic_vector(7 downto 0) := x"34";
   CONSTANT  Sw_CmdL3   : std_logic_vector(7 downto 0) := x"35";
   CONSTANT  Sw_AdL4   : std_logic_vector(7 downto 0) := x"36";
   CONSTANT  Sw_AdL5   : std_logic_vector(7 downto 0) := x"37";
   CONSTANT  Sw_WPA1   : std_logic_vector(7 downto 0) := x"38";
   CONSTANT  Swait3   : std_logic_vector(7 downto 0) := x"39";
   CONSTANT  Sw_CmdL4   : std_logic_vector(7 downto 0) := x"3A";
   CONSTANT  Sw_CmdL5   : std_logic_vector(7 downto 0) := x"3B";
   CONSTANT  Sw_WC1   : std_logic_vector(7 downto 0) := x"3C";
   CONSTANT  Sw_WC2   : std_logic_vector(7 downto 0) := x"3D";
   CONSTANT  Sw_CmdL6   : std_logic_vector(7 downto 0) := x"3E";
   CONSTANT  Sw_CmdL7   : std_logic_vector(7 downto 0) := x"3F";
   CONSTANT  Sw_DR1   : std_logic_vector(7 downto 0) := x"40";
   CONSTANT  Sw_Wait4   : std_logic_vector(7 downto 0) := x"41";
   CONSTANT  Sw_Wait5   : std_logic_vector(7 downto 0) := x"42";
   CONSTANT  Sw_done   : std_logic_vector(7 downto 0) := x"43";
   CONSTANT  Srst_RAR   : std_logic_vector(7 downto 0) := x"44";
   CONSTANT  Srst_CmdL0   : std_logic_vector(7 downto 0) := x"45";
   CONSTANT  Srst_CmdL1   : std_logic_vector(7 downto 0) := x"46";
   CONSTANT  Srst_done   : std_logic_vector(7 downto 0) := x"47";
   CONSTANT  Srid_RAR   : std_logic_vector(7 downto 0) := x"48";
   CONSTANT  Srid_CmdL0   : std_logic_vector(7 downto 0) := x"49";
   CONSTANT  Srid_CmdL1   : std_logic_vector(7 downto 0) := x"4A";
   CONSTANT  Srid_AdL0   : std_logic_vector(7 downto 0) := x"4B";
   CONSTANT  Srid_Wait   : std_logic_vector(7 downto 0) := x"4C";
   CONSTANT  Srid_DR1   : std_logic_vector(7 downto 0) := x"4E";
   CONSTANT  Srid_DR2   : std_logic_vector(7 downto 0) := x"4F";
   CONSTANT  Srid_DR3   : std_logic_vector(7 downto 0) := x"50";
   CONSTANT  Srid_DR4   : std_logic_vector(7 downto 0) := x"51";
   CONSTANT  Srid_done   : std_logic_vector(7 downto 0) := x"52";
   
   SIGNAL NxST : STD_LOGIC_VECTOR( 7 DOWNTO 0);
   SIGNAL CrST : STD_LOGIC_VECTOR( 7 DOWNTO 0);
   SIGNAL BF_sel_int : STD_LOGIC;

   CONSTANT C0 : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0000";
   CONSTANT C1 : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0001";
   CONSTANT C3 : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0011";
   CONSTANT C5 : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0101";
   CONSTANT C6 : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0110";
   CONSTANT C7 : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0111";
   CONSTANT C8 : STD_LOGIC_VECTOR(3 DOWNTO 0) := "1000";
   CONSTANT CD : STD_LOGIC_VECTOR(3 DOWNTO 0) := "1101";
   CONSTANT CE : STD_LOGIC_VECTOR(3 DOWNTO 0) := "1110";
   CONSTANT CF : STD_LOGIC_VECTOR(3 DOWNTO 0) := "1111";
   CONSTANT C9 : STD_LOGIC_VECTOR(3 DOWNTO 0) := "1001";
   

BEGIN
  --state  <= CrST;
  mBF_sel<=BF_sel_int;
   PROCESS (CLK)
   BEGIN
     IF (CLK'EVENT AND CLK = '1') THEN
       IF (start = '1') THEN
         BF_sel_int<=BF_sel;
       END IF;
     END IF;     
   END PROCESS;



--   PROCESS(CLK, RES)
--   BEGIN
--      IF (RES = '1') THEN
--      SetErErr <= '0';
--      ELSIF (CrST = S_Done) THEN
--         IF (io_0 = '1') then
--           SetErErr <= '1';
--         ELSE
--           SetErErr <= '0';
--         END IF;
--     ELSIF ((CrST = S_ADS) and (command /= "100") and (command /= "010") and
--     (command /= "001") and (command /= "011") and (command /= "101")) THEN
--         SetErErr <= '1';
--      END IF;
--   END PROCESS;


   PROCESS (CLK)
   BEGIN
    IF (CLK'EVENT AND CLK = '1') THEN
      CrST <= NxST;
    END IF;
   END PROCESS;

   PROCESS (RES, command, start, R_nB, t_done, tc4, tc8, io_0, CrST)
    BEGIN
      IF (RES = '1') THEN
       NxST <= Init;
       setDone <= '0';
       BF_we <= '0';
       t_start <= '0';
       t_cmd   <= "011";
       WrECC   <= '0';
       EnEcc   <= '0';
       AMX_sel <= "00";
       cmd_reg <= "00000000";
       cmd_reg_we <= '0';
       set835     <= '0';
       cnt_res    <= '0';
       wCntRes    <= '0';
       wCntCE     <= '0';
       ADC_sel    <= "11";
       SetPrErr   <= '0';
       SetErErr   <= '0';
       RAR_we     <= '0';
    ELSE
       setDone <= '0';
       BF_we   <= '0';
       t_start <= '0';
       t_cmd   <= "011";
       WrEcc   <= '0';
       EnEcc   <= '0';
       AMX_sel <= "00";
       cmd_reg <= "00000000";
       cmd_reg_we <= '0';
       set835  <= '0';
       cnt_res <= '0';
       wCntRes <= '0';
       wCntCE  <= '0';
       ADC_sel <= "11";
       SetPrErr <= '0';
       SetErErr <= '0';
       RAR_we  <= '0';
       case CrST IS 
      when Init => 
                 if (start = '1') then
                   NxST <= S_ADS;
                 else 
                   NxST <= Init;
                 end if;
      when S_ADS =>
                 cnt_res <= '1';
                 if (command = "100") then
                    NxST <= S_RAR;
                 elsif (command = "010") then
                    NxST <= Sr_RAR;
                 elsif (command = "001") then
                    NxST <= Sw_RAR;
                 elsif (command = "011") then
                    NxST <= Srst_RAR;
                 elsif (command = "101") then
                    NxST <= Srid_RAR;
                 else
                    setDone <= '1';
                    NxST    <= Init;
                    SetPrErr <= '1';
                    SetErErr <= '1'; 
                 end if ;
      when S_RAR =>
                 RAR_we <= '1';
                 NxST   <= S_CmdL0;
      when S_CmdL0 =>
                 cmd_reg <= C6&C0;
                 cmd_reg_we <= '1';
                 NxST <= S_CmdL1;
      when S_CmdL1 =>
                 t_start <= '1';
                 t_cmd   <= "000";
                 if (t_done = '1') then
                    NxST <= S_adL0;
                 else
                    NxST <= S_CmdL1;
                 end if;
      when S_adL0 =>
                 t_start <= '1';
                 t_cmd   <= "001";
                 ADC_sel <= "10";
                 AMX_sel <= "10";
                 IF (t_done = '1') then
                    NxST <= S_adL1;
                 else
                    NxST <= S_adL0;
                 end if;
      when S_adL1 =>
                 t_start <= '1';
                 t_cmd   <= "001";
                 ADC_sel <= "10";
                 AMX_sel <= "11";
                 if (t_done = '1') then
                    NxST <= S_CmdL2;
                 else 
                     NxST <= S_adL1;
                 end if;
      when S_CmdL2 =>
                 cmd_reg <= CD&C0;
                 cmd_reg_we <= '1';
                 NxST <= S_CmdL3;
      when S_CmdL3 =>
                 t_start <= '1';
                 t_cmd   <= "000";
                 if (t_done = '1') then
                    NxST <= S_WC0;
                 else 
                    NxST <= S_CmdL3;
                 end if;
      when S_WC0 =>
                 wCntRes <= '1';
                 NxST <= S_WC1;
      when S_WC1 => 
                  wCntCE <='1';
                  if (tc8 = '1') THEN
                     NxST <= S_wait;
                  else
                     NxST <= S_WC1;
                  end IF;
      when S_wait =>
                 if (R_nB = '1') THEN
                    NxST <= S_CmdL4;
                 else
                    NxST <= S_wait;
                 end IF;
      when S_CmdL4 => 
                 cmd_reg <= C7&C0;
                 cmd_reg_we <= '1';
                 NxST <= S_CmdL5;
      when S_CmdL5 => 
                 t_start <= '1';
                 t_cmd   <= "000";
                 if (t_done = '1') then
                    NxST <= S_WC3;
                 else
                    NxST <= S_CmdL5;
                 end if;
      when S_WC3 =>
                 wCntRes <= '1';
                 NxST <= S_WC4;
      when S_WC4 =>
                 wCntCE <= '1';
                 if (tc4 = '1') then
                    NxST <= S_DR1;
                 else
                    NxST <= S_WC4;
                 end if;
      when S_DR1 => 
                 t_start <= '1';
                 t_cmd <= "010";
                 if (t_done = '1') then
                    NxST <= S_Done;
                 else
                    NxST <= S_DR1;      
                 end if;
      when S_Done => 
                 setDone <= '1';
                 NxST <= Init;
                 if (io_0 = '1') then 
                    SetErErr <= '1';
                 else
                    SetErErr <= '0';
                 end if;
     when Sr_RAR => 
                 RAR_we <= '1';
                 NxST <= Sr_CmdL0;
     when Sr_CmdL0 =>
                 cmd_reg <= C0&C0;
                 cmd_reg_we <= '1';
                 NxST <= Sr_CmdL1;
     when Sr_CmdL1 =>
                 t_start <= '1';
                 t_cmd <= "000";
                 if (t_done = '1') then
                    NxST <= Sr_AdL0;
                 else
                    NxST <= Sr_CmdL1;
                 end if;
     when Sr_AdL0 =>
                 t_start <= '1';
                 t_cmd <= "001";
                 ADC_sel <= "10"; 
                 AMX_sel <= "00";
                 if (t_done = '1') then
                 NxST <= Sr_AdL1;
                 else
                 NxST <= Sr_AdL0;
                 end if;
     when Sr_AdL1 =>
                 t_start <= '1';
                 t_cmd <= "001";
                 ADC_sel <= "10"; 
                 AMX_sel <= "01";
                 if (t_done = '1') then
                 NxST <= Sr_AdL2;
                 else
                 NxST <= Sr_AdL1;
                 end if;
     when Sr_AdL2 =>
                 t_start <= '1';
                 t_cmd   <= "001";
                 ADC_sel <= "10";
                 AMX_sel <= "10";
                 if (t_done = '1') then
                 NxST <= Sr_AdL3;
                 else
                 NxST <= Sr_AdL2;
                 end if;
      when Sr_AdL3 =>
                 t_start <= '1';
                 t_cmd   <= "001";
                 ADC_sel <= "10";
                 AMX_sel <= "11";
                 if (t_done = '1') then
                    NxST <= Sr_CmdL2;
                 else
                    NxST <= Sr_AdL3;
                 end if;  
      when Sr_CmdL2 =>
                 cmd_reg <= C3&C0;
                 cmd_reg_we <= '1';
                 NxST <= Sr_CmdL3;
      when Sr_CmdL3 =>
                 t_start <= '1';
                 t_cmd <= "000";
                 if (t_done = '1') then
                    NxST <= Sr_WC0;
                 else
                    NxST <= Sr_CmdL3;
                 end if;
      when Sr_WC0 =>
                 wCntRes <= '1';
                 NxST <= Sr_WC1;
      when Sr_WC1 =>
                 wCntCE <= '1';
                 if (tc8 = '1') then
                 NxST <= Sr_wait;
                 else
                 NxST <= Sr_WC1;
                 end if;
      when Sr_wait =>
                 if (R_nB = '0') then
                     NxST <= Sr_wait;
                 else
                     NxST <= Sr_RPA0;
                 end if;
      when Sr_RPA0 =>
                 t_start <= '1';
                 t_cmd <= "101";
                 BF_we <= '1';
                 if (t_done = '1') then
                    NxST <= Sr_CmdL4;
                    t_cmd <= "000";
                 else
                    NxST <= Sr_RPA0;
                 end if;
      when Sr_CmdL4 =>
                 cmd_reg <= C0&C5;
                 cmd_reg_we <= '1';
                 set835 <= '1';
                 t_cmd <= "000";
                 NxST <= Sr_CmdL5;
      when Sr_CmdL5 => 
                 t_start <= '1';
                 t_cmd   <= "000"; 
                 if (t_done = '1') then
                    NxST <= Sr_AdL4;
                 else
                    NxST <= Sr_CmdL5;
                 end if;
      when Sr_AdL4 =>
                 t_start <= '1';
                 t_cmd   <= "001"; 
                 ADC_sel <= "10";
                 AMX_sel <= "00"; 
                 if (t_done ='1') then
                    NxST <= Sr_AdL5;
                 else
                    NxST <= Sr_AdL4;
                 end if;
      when Sr_AdL5 =>
                 t_start <= '1';
                 t_cmd   <= "001";
                 ADC_sel <= "10"; 
                 AMX_sel <= "01"; 
                 if (t_done = '1') then
                    NxST <= Sr_CmdL6;
                 else
                    NxST <= Sr_AdL5;
                 end if;
      when Sr_CmdL6 =>
                 cmd_reg <= CE&C0;
                 cmd_reg_we <= '1';
                 NxST <= Sr_CmdL7;
      when Sr_CmdL7 =>
                 t_start <= '1';
                 t_cmd <= "000";
                 wCntRes <= '1'; 
                 if (t_done = '1') then
                    NxST <= Sr_RPA1;
                 else
                    NxST <= Sr_CmdL7;
                 end if;
      when Sr_RPA1 =>
                 t_start <= '1';
                 t_cmd <= "100"; 
                 WrECC <= '1';
                 if (t_done = '1') then
                 NxST <= Sr_wait1;
                 t_cmd <= "011";
                 else
                 NxST <= Sr_RPA1;
                 end if;   
      when Sr_wait1 =>
                 WrECC <= '1';
                 NxST <= Sr_wait2;
      when Sr_wait2 =>
                 WrECC <= '1';
                 NxST <= Sr_WC3;
      when Sr_WC3 =>
                 WrECC <= '1';
                 wCntCE <= '1';
                 if (tc4 = '0') then
                     NxST <= Sr_WC3;
                 else
                     NxST <= Sr_Done;
                 end if;
      when Sr_Done =>
                 setDone <= '1';
                 NxST <= Init;
      when Sw_RAR =>
                 RAR_we <= '1';
                 NxST <= Sw_CmdL0;
      when Sw_CmdL0 =>
                 cmd_reg <= C8&C0;
                 cmd_reg_we <= '1';
                 NxST <= Sw_CmdL1;
      when Sw_CmdL1 =>
                 t_start <= '1';
                 t_cmd <=  "000";
                 if (t_done = '1') then
                    NxST <= Sw_AdL0;
                 else
                    NxST <= Sw_CmdL1;
                 end if;
      when Sw_AdL0 =>
                 t_start <= '1';
                 t_cmd   <= "001";
                 ADC_sel <= "10"; 
                 AMX_sel <= "00";
                 if (t_done = '1') then
                     NxST <= Sw_AdL1;
                 else
                     NxST <= Sw_AdL0;
                 end if;
      when Sw_AdL1 =>
                 t_start <= '1';
                 t_cmd   <= "001"; 
                 ADC_sel <= "10";
                 AMX_sel <= "01";
                 if (t_done = '1') then
                    NxST <= Sw_AdL2;
                 else
                    NxST <= Sw_AdL1;
                 end if;
      when Sw_AdL2 =>
                 t_start <= '1';
                 t_cmd   <= "001";
                 ADC_sel <= "10"; 
                 AMX_sel <= "10";
                 if (t_done = '1') then
                    NxST <= Sw_AdL3;
                 else
                    NxST <= Sw_AdL2;
                 end if;
      when Sw_AdL3 =>
                 t_start <= '1';
                 t_cmd   <= "001";
                 ADC_sel <= "10"; 
                 AMX_sel <= "11";
                 if (t_done = '1') then
                    NxST <= Sw_WPA0;
                 else
                    NxST <= Sw_AdL3;
                 end if;
      when Sw_WPA0 =>
                 t_start <= '1';
                 t_cmd   <= "111";
                 ADC_sel <= "00";
                 if (t_done = '1') then
                    NxST <= Sw_CmdL2;
                    t_cmd <= "000";
                  else
                    NxST <= Sw_WPA0;
                  end if;
      when Sw_CmdL2 =>
                 cmd_reg <= C8&C5;
                 cmd_reg_we <= '1';
                 set835     <= '1';
                 t_cmd   <= "000";
                 NxST    <= Sw_CmdL3;
      when Sw_CmdL3 =>
                 t_start <= '1';
                 t_cmd   <= "000";
                 if (t_done = '1') then
                    NxST <= Sw_AdL4;
                 else
                    NxST <= Sw_CmdL3;
                  end if;
      when Sw_AdL4 =>
                 t_start <= '1';
                 t_cmd   <= "001"; 
                 ADC_sel <= "10"; 
                 AMX_sel <= "00";
                 if (t_done = '1') then
                     NxST <= Sw_AdL5;
                 else
                     NxST <= Sw_AdL4;
                 end if;
      when Sw_AdL5 =>
                 t_start <= '1';
                 t_cmd   <= "001"; 
                 ADC_sel <= "10"; 
                 AMX_sel <= "01";
                 if (t_done = '1') then
                    NxST <= Sw_WPA1;
                 else
                    NxST <= Sw_AdL5;
                 end if;
      when Sw_WPA1 =>
                 t_start <= '1';
                 t_cmd   <= "110"; 
                 ADC_sel <= "01";
                 EnEcc   <= '1';  
                 if (t_done = '1') then
                     NxST <= Sw_CmdL4;
                     t_cmd <= "000";
                  else
                     NxST <= Sw_WPA1;
                  end if;
      when Sw_CmdL4 =>
                 cmd_reg <= C1&C0;
                 t_cmd   <= "000";
                 cmd_reg_we <= '1';
                 NxST <= Sw_CmdL5;
      when Sw_CmdL5 =>
                 t_start <= '1';
                 t_cmd   <= "000"; 
                 if (t_done = '1') then
                     NxST <= Sw_WC1;
                 else
                     NxST <= Sw_CmdL5;
                 end if;
      when Sw_WC1 =>
                 wCntRes <= '1';
                 NxST    <= Sw_WC2;
      when Sw_WC2 => 
                 wCntCE <= '1';
                 if (tc8 = '1') then
                    NxST <= Swait3;
                 else
                    NxST <= Sw_WC2;
                 end if;
      when Swait3 =>
                 if (R_nB = '1') then
                     NxST <= Sw_CmdL6;
                 else
                     NxST <= Swait3;
                 end if;
      when Sw_CmdL6 =>
                 cmd_reg <= C7&C0;
                 cmd_reg_we <= '1';
                 NxST <= Sw_CmdL7;
      when Sw_CmdL7 =>
                 t_start <= '1';
                 t_cmd   <= "000"; 
                 if (t_done = '1') then
                     NxST <= Sw_Wait4;
                 else
                     NxST <= Sw_CmdL7;
                 end if;
      when Sw_Wait4 =>
                 NxST <= Sw_Wait5;
      when Sw_Wait5 =>
                 NxST <= Sw_DR1;
      when Sw_DR1 =>
                 t_start <= '1';
                 t_cmd   <= "010";
                 if (t_done = '1') then
                    NxST <= Sw_done;
                 else
                    NxST <= Sw_DR1;
                 end if;
      when Sw_done =>
                 setDone <= '1';
                 NxST    <= Init;
                 if (io_0 = '1') then
                    SetPrErr <= '1';
                 else 
                    SetPrErr <= '0';
                 end if;
      when Srst_RAR =>
                 NxST <= Srst_CmdL0;
      when Srst_CmdL0 =>
                 cmd_reg <= CF&CF;
                 cmd_reg_we <= '1';
                 NxST <= Srst_CmdL1;
      when Srst_CmdL1 =>
                 t_start <= '1';
                 t_cmd   <= "000";
                 if (t_done = '1') then
                    NxST <= Srst_done;
                 else
                    NxST <= Srst_CmdL1;
                 end if;
      when Srst_done =>
                 setDone <= '1';
                 NxST <= Init;
      when Srid_RAR =>
                 RAR_we <= '1'; 
                 NxST <= Srid_CmdL0;
      when Srid_CmdL0 =>
                 cmd_reg <= C9&C0;
                 cmd_reg_we <= '1';
                 NxST <= Srid_CmdL1;
      when Srid_CmdL1 =>
                 t_start <= '1';
                 t_cmd <= "000";
                 if (t_done = '1') then
                    NxST <= Srid_AdL0;
                 else
                    NxST <= Srid_CmdL1;
                 end if;
      when Srid_AdL0 =>
                 t_start <= '1';
                 t_cmd   <= "001";
                 ADC_sel <= "10"; 
                 AMX_sel <= "10";
                 if (t_done = '1') then
                    NxST <= Srid_Wait;
                 else
                    NxST <= Srid_AdL0;
                 end if;
      when Srid_Wait =>
                 wCntRes <= '1';
                 NxST <= Srid_DR1;
      when Srid_DR1 => 
                 t_start <= '1';
                 t_cmd   <= "010";
                 BF_we   <= '1';
                 if (t_done = '1') then
                     NxST <= Srid_DR2;
                 else
                     NxST <= Srid_DR1;
                 end if;
      when Srid_DR2 =>
                 t_start <= '1';
                 t_cmd   <= "010";
                 BF_we   <= '1';
                 if (t_done = '1') then
                     NxST <= Srid_DR3;
                 else
                     NxST <= Srid_DR2;
                 end if;
      when Srid_DR3 =>
                 t_start <= '1';
                 t_cmd   <= "010";
                 BF_we   <= '1';
                 if (t_done =  '1') then
                     NxST <= Srid_DR4;
                 else
                     NxST <= Srid_DR3;
                 end if;
      when Srid_DR4 =>
                 t_start <= '1';
                 t_cmd   <= "010";
                 BF_we   <= '1';
                 if (t_done = '1') then
                     NxST <= Srid_done;
                 else
                     NxST <= Srid_DR4;
                 end if;
      when Srid_done =>
                 setDone <= '1';
                 NxST <= Init;
      when others =>
                 NxST <= Init;
       END CASE;          
       END IF;         
    END PROCESS;

END ARCHITECTURE translated;


   
