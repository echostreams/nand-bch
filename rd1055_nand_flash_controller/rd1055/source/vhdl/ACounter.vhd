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
-- Revision History :
-- --------------------------------------------------------------------
--   Ver  :| Author      :| Mod. Date :| Changes Made:
--   V01.0:| Rainy Zhang :| 01/14/10  :| Initial ver
-- --------------------------------------------------------------------
--
-- 
--Description of module:
----------------------------------------------------------------------------------
-- 
-- --------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY ACounter IS 
        PORT(
        clk: in std_logic;
        Res: in std_logic;
        Set835: in std_logic;
        CntEn: in std_logic;
        CntOut: out std_logic_vector(11 downto 0);
        TC2048: out std_logic;
        TC3: out std_logic
        );
end entity ACounter;

ARCHITECTURE translated OF ACounter IS 

signal cnt_state : std_logic_vector(11 downto 0);

BEGIN
PROCESS(clk, Res)
BEGIN
  IF (Res = '1') then
     cnt_state <= x"000";
  ELSIF (CLK'EVENT AND CLK = '1') THEN
     if (Set835 = '1') then
     cnt_state <= x"835";
     elsif (CntEn = '1') then
     cnt_state <= cnt_state + 1;
     end if;
  END IF;
END PROCESS;

process(cnt_state)
begin
  if (cnt_state = x"7ff") then
     TC2048 <= '1';
     TC3    <= '0';
  ELSIF (CNT_STATE(7 DOWNTO 0) = X"40") THEN
     TC3    <= '1';
     TC2048 <= '0';
  ELSE
     TC3    <= '0';
     TC2048 <= '0';
  END IF;
end process;


CntOut <= cnt_state;

   

END ARCHITECTURE translated;
