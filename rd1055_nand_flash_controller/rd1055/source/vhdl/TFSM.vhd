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
-- Timing FSM creating all the necessary control signals for the nand-flash memory.
-- --------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;

ENTITY TFSM IS 
        PORT(
        CLK : IN STD_LOGIC;
        RES : IN STD_LOGIC;
        TC3 : IN STD_LOGIC;
        TC2048 : IN STD_LOGIC;
        start  : IN STD_LOGIC;
        cmd_code : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        CLE : OUT STD_LOGIC;
        ALE : OUT STD_LOGIC;
        WE_n : OUT STD_LOGIC;
        RE_n : OUT STD_LOGIC;
        CE_n : OUT STD_LOGIC;
        DOS  : OUT STD_LOGIC;
        DIS  : OUT STD_LOGIC;
        cnt_en : OUT STD_LOGIC;
        Done : OUT STD_LOGIC;
        ecc_en : OUT STD_LOGIC           
        );
END ENTITY TFSM;
        
ARCHITECTURE translated OF TFSM IS 
constant Init        : std_logic_vector(5 downto 0) := "000000";
constant S_Start     : std_logic_vector(5 downto 0) := "000001";
constant S_CE        : std_logic_vector(5 downto 0) := "000010";
constant S_CLE        : std_logic_vector(5 downto 0):= "000011";
constant S_CmdOut    : std_logic_vector(5 downto 0) := "000100";
constant S_WaitCmd   : std_logic_vector(5 downto 0) := "000101";
constant DoneCmd     : std_logic_vector(5 downto 0) := "000110";
constant Finish      : std_logic_vector(5 downto 0) := "000111";
constant S_ALE       : std_logic_vector(5 downto 0) := "001000";
constant S_ADout     : std_logic_vector(5 downto 0) := "001001";
constant WaitAd      : std_logic_vector(5 downto 0) := "001010";
constant DoneAd      : std_logic_vector(5 downto 0) := "001011";
constant S_RE1       : std_logic_vector(5 downto 0) := "001100";
constant WaitR1      : std_logic_vector(5 downto 0) := "001101";
constant WaitR2      : std_logic_vector(5 downto 0) := "001110";
constant DoneR1      : std_logic_vector(5 downto 0) := "001111";
constant S_RE        : std_logic_vector(5 downto 0) := "010000";
constant WaitR1m     : std_logic_vector(5 downto 0) := "010001";
constant WaitR2m     : std_logic_vector(5 downto 0) := "010010";
constant WaitR3m     : std_logic_vector(5 downto 0) := "010011";
constant S_DIS       : std_logic_vector(5 downto 0) := "010100";
constant FinishR     : std_logic_vector(5 downto 0) := "010101";
constant S_WE        : std_logic_vector(5 downto 0) := "010110";
constant WaitW       : std_logic_vector(5 downto 0) := "010111";
constant WaitW1      : std_logic_vector(5 downto 0) := "011000";
constant WaitW2      : std_logic_vector(5 downto 0) := "011001";
constant S_nWE       : std_logic_vector(5 downto 0) := "011010";
constant FinishW     : std_logic_vector(5 downto 0) := "011011";

signal NxST : STD_LOGIC_VECTOR(5 DOWNTO 0);
signal CrST : STD_LOGIC_VECTOR(5 DOWNTO 0);
signal Done_i : STD_LOGIC;
signal TC   : STD_LOGIC;
signal cmd_code_int : STD_LOGIC_VECTOR(2 DOWNTO 0);

BEGIN

TC <= TC2048 WHEN (cmd_code_int(0) = '1') ELSE TC3;


PROCESS(CLK, RES)
BEGIN
  IF (RES = '1') THEN
     Done <= '0';
  ELSIF (CLK'EVENT AND CLK = '1') THEN
     Done <= Done_i;
  END IF;
END PROCESS;

PROCESS(CLK)
BEGIN
  IF (CLK'EVENT AND CLK = '1') THEN
      cmd_code_int <= cmd_code;
  END IF;
END PROCESS;

PROCESS(CLK)
BEGIN
  IF (CLK'EVENT AND CLK= '1') THEN
     CrST <= NxST;
  END IF;
END PROCESS;


PROCESS(RES, TC, cmd_code_int, start, CrST)
BEGIN
   IF (RES = '1') THEN
       NxST   <= Init;
       DIS    <= '0';
       DOS    <= '0';
       Done_i <= '0';
       ALE    <= '0';
       CLE    <= '0';
       WE_n   <= '1';
       RE_n   <= '1';
       CE_n   <= '1';
       cnt_en <= '0';
       ecc_en <= '0';
  ELSE
       DIS    <= '0';
       DOS    <= '0';
       Done_i <='0';
       ALE    <= '0';
       CLE    <= '0';
       WE_n   <= '1';
       RE_n   <= '1';
       CE_n   <= '1';
       cnt_en <= '0';
       ecc_en <= '0';
   case CrST IS
    WHEN Init => 
      if (start = '1') THEN
        NxST <= S_Start;
      else
        NxST <= Init;
      end IF;
    WHEN S_Start=>
      if (cmd_code_int = "011") THEN
        NxST <= Init;
      else
        NxST <= S_CE;
      end IF;
    WHEN S_CE =>
      if (cmd_code_int = "000") THEN
        NxST <= S_CLE;
        CE_n <= '0';
      elsif (cmd_code_int = "001") THEN
        NxST <= S_ALE;
        CE_n <= '0';        
      elsif (cmd_code_int = "010") THEN
        NxST <= S_RE1;
        CE_n <= '0';        
      elsif (cmd_code_int(2 DOWNTO 1) = "10") THEN
        NxST <= S_RE;
        CE_n <= '0';        
      elsif (cmd_code_int(2 downto 1) = "11") THEN
        NxST <= S_WE;
        CE_n <= '0';        
      else
        NxST <= Init;
      end if; 
    WHEN S_CLE =>
      CE_n <= '0';
      CLE  <= '1';
      WE_n <= '0';
      NxST <= S_CmdOut;
    WHEN S_CmdOut =>
      CE_n <= '0';
      CLE  <= '1';
      WE_n <= '0';
      DOS  <= '1';
      NxST <= S_WaitCmd;
    WHEN S_WaitCmd =>
      CE_n <= '0';
      CLE  <= '1';
      WE_n <= '0';
      DOS  <= '1';
      NxST <= DoneCmd;
    WHEN DoneCmd =>
      Done_i <= '1';      
      CE_n   <= '0';
      CLE    <= '1';
      DOS    <= '1';
      NxST   <= Finish;
    WHEN Finish=>
      DIS <= '1'; 
      if (start = '1') THEN
        NxST <= S_Start;
      else
        NxST <= Init;
      end if;
    WHEN S_ALE =>
      CE_n <= '0';
      ALE  <= '1';
      WE_n <= '0';
      NxST <= S_ADout;
    WHEN S_ADout =>
      CE_n <= '0';
      ALE  <= '1';
      WE_n <= '0';
      DOS  <= '1';
      NxST <= WaitAd;
    WHEN WaitAd =>
      CE_n <= '0';
      ALE  <= '1';
      WE_n <= '0';
      DOS  <= '1';
      NxST <= DoneAd;
    WHEN DoneAd =>
      Done_i <= '1';
      CE_n   <= '0';
      ALE    <= '1';
      DOS    <= '1';
      NxST   <= Finish;
    WHEN S_RE1 =>
      CE_n   <= '0';
      RE_n   <= '0';
      NxST   <= WaitR1;
    WHEN WaitR1 =>
      CE_n <= '0';
      RE_n <= '0';
      NxST <= WaitR2;
    WHEN WaitR2 =>
      CE_n <= '0';
      RE_n <= '0';
      NxST <= DoneR1;
    WHEN DoneR1 =>
      Done_i <= '1'; 
      cnt_en <= '1';   
      NxST   <= Finish; 
   WHEN S_RE =>
      CE_n <= '0';
      RE_n <= '0';
      NxST <= WaitR1m;
   WHEN WaitR1m =>
      CE_n <= '0';
      RE_n <= '0';
      NxST <= WaitR2m;
   WHEN WaitR2m =>
      CE_n <= '0';
      RE_n <= '0';
      NxST <= S_DIS;
   WHEN S_DIS =>
      CE_n <= '0';
      if (TC = '0') then
        NxST <= WaitR3m;
      else
        NxST <= FinishR;
    end if;
    WHEN WaitR3m =>
      CE_n   <= '0';
      cnt_en <= '1';
      DIS    <= '1'; 
      NxST   <= S_RE;
    WHEN FinishR =>
      Done_i <= '1';
      cnt_en <= '1';  
      DIS    <= '1'; 
      if (start = '1') THEN
        NxST <= S_Start;
      else
        NxST <= Init;
      end if; 
    WHEN S_WE =>
      CE_n <= '0';
      WE_n <= '0';
      DOS  <= '1';
      NxST <= WaitW;
    WHEN WaitW =>
      ecc_en <= '1';
      CE_n   <= '0';
      WE_n   <= '0';
      DOS    <= '1';
      NxST   <= WaitW1;
    WHEN WaitW1 =>
      CE_n <= '0';
      WE_n <= '0';
      DOS  <= '1';
      NxST <= S_nWE;
    WHEN S_nWE =>
      CE_n <= '0';
      DOS  <= '1';
      if (TC = '0') THEN
        NxST <= WaitW2;
      else
        NxST <= FinishW;
      end if;
    WHEN WaitW2 =>
      CE_n   <= '0';
      DOS    <= '1';    
      cnt_en <= '1';
      NxST   <= S_WE;
    WHEN FinishW =>
      Done_i <= '1';
      cnt_en <= '1';
      DOS    <= '1';
      if (start = '1') THEN
        NxST <= S_Start;
      else
        NxST <= Init;
    end  if;
    WHEN OTHERS =>
       NxST <= Init;
  end case;
END IF;


END PROCESS;

END ARCHITECTURE translated;
