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
-- (7,4) hamming code detect
-- --------------------------------------------------------------------

LIBRARY IEEE;
USE ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

ENTITY ErrLoc is 
         port (
            clk        : in std_logic;
            Res        : in std_logic;
            F_ecc_data : in std_logic_vector(6 downto 0);
            WrEcc      : in std_logic;

            ECC_status : out std_logic
          
);
END ENTITY ErrLoc;

ARCHITECTURE translated OF ErrLoc IS 
    signal check1     : std_logic;
    signal check2     : std_logic;
    signal check3     : std_logic;
    signal din        : std_logic_vector(6 downto 0);
BEGIN  

   PROCESS  (clk, Res)
   BEGIN
     IF (Res = '1') THEN
       din <= "0000000";
     ELSIF (clk'event and clk = '1') THEN
       if (WrECC = '1') then
       din <= F_ecc_data;
       end if;
     END IF;
   END PROCESS;
check1 <= din(6) xor din(4) xor din(2) xor din(0);
check2 <= din(5) xor din(4) xor din(1) xor din(0);
check3 <= din(3) xor din(2) xor din(1) xor din(0);   

   PROCESS (clk, Res)
   BEGIN
     IF (Res = '1') THEN
       ECC_status <= '0';
     ELSIF (clk'event and clk = '1') THEN
       ECC_status <= (check1 or check2 or check3);
     END IF;
       END PROCESS;
END ARCHITECTURE translated;


