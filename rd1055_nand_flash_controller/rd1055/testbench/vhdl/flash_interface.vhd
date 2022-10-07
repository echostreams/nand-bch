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
-- 
-- --------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.STD_LOGIC_TEXTIO.ALL;
USE STD.TEXTIO.ALL;

ENTITY flash_interface IS  PORT(
       DIO : INOUT STD_LOGIC_VECTOR(7 DOWNTO 0);
       CLE : IN STD_LOGIC;
       ALE : IN STD_LOGIC;
       WE_n : IN STD_LOGIC;
       RE_n : IN STD_LOGIC;
       CE_n : IN STD_LOGIC;
       rst  : IN STD_LOGIC;
       R_nB : OUT STD_LOGIC
);
END ENTITY flash_interface;

ARCHITECTURE translated OF flash_interface IS           
  
TYPE memory_2113 IS ARRAY (2112 DOWNTO 0) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL memory : memory_2113;
SIGNAL dat_en : std_logic;
SIGNAL datout : std_logic_vector(7 downto 0);
SIGNAL command: std_logic_vector(7 downto 0);
SIGNAL row1   : std_logic_vector(7 downto 0);
SIGNAL row2   : std_logic_vector(7 downto 0);
SIGNAL col1   : std_logic_vector(7 downto 0);
SIGNAL col2   : std_logic_vector(7 downto 0);
SIGNAL idaddr : std_logic_vector(7 downto 0);

SIGNAL con1   : std_logic_vector(11 downto 0);
SIGNAL con1_835 : std_logic_vector(11 downto 0);

SIGNAL con   : std_logic_vector(1 downto 0);
 
SIGNAL con2  : std_logic_vector(11 downto 0);
SIGNAL con2_835 : std_logic_vector(11 downto 0);

BEGIN

DIO <= datout when (dat_en = '1') else "ZZZZZZZZ";  

PROCESS(WE_n , rst)
VARIABLE L : line;
BEGIN
  IF (rst = '1') THEN
     command <= "11111111";
  ELSIF (WE_n'EVENT AND WE_n = '1') THEN
    IF (CE_n = '0' and CLE = '1') THEN
     command <= DIO;
     CASE command IS
     WHEN x"60" =>
        write(L,now, justified => right, field=>20,unit=>ns);
        write(L, string'(" auto block erase setup command "));
        writeline(output,L);
     WHEN x"d0" =>
        write(L,now, justified => right, field=>20,unit=>ns);
        write(L, string'(" erase address:     "));
        write(L, row1&row2);
        writeline(output,L);
     WHEN X"70" =>
        write(L,now, justified => right, field=>20,unit=>ns);
        write(L, string'(" read status command "));
        writeline(output,L);
     WHEN x"80" =>
        write(L,now, justified => right, field=>20,unit=>ns);
        write(L, string'(" write page setup command "));
        writeline(output,L);
     WHEN x"85" =>
        write(L,now, justified => right, field=>20,unit=>ns);
        write(L, string'(" write page row address:     "));
        write(L, row1&row2);
        writeline(output,L);
        write(L,now, justified => right, field=>20,unit=>ns);
        write(L, string'(" random data write command "));
        writeline(output,L);
     WHEN x"10" =>
        write(L,now, justified => right, field=>20,unit=>ns);
        write(L, string'(" random write page column address: "));
        write(L, col1&col2);
        writeline(output,L);
        write(L,now, justified => right, field=>20,unit=>ns);
        write(L, string'(" write page command "));
        writeline(output,L);
     WHEN x"00" =>
        write(L,now, justified => right, field=>20,unit=>ns);
        write(L, string'(" read page setup command "));
        writeline(output,L);
     WHEN x"30" =>
        write(L,now, justified => right, field=>20,unit=>ns);
        write(L, string'(" read page row address:     "));
        write(L,row1&row2);
        writeline(output,L);
        write(L,now, justified => right, field=>20,unit=>ns);
        write(L, string'(" read page column address: "));
        write(L,col1&col2);
        writeline(output,L);
        write(L,now, justified => right, field=>20,unit=>ns);
        write(L, string'(" read page command "));
        writeline(output,L);
     WHEN x"05" =>
        write(L,now, justified => right, field=>20,unit=>ns);
        write(L, string'(" random read page setup command "));
        writeline(output,L);
     WHEN x"e0" =>
        write(L,now, justified => right, field=>20,unit=>ns);
        write(L, string'(" random read page column address: "));
        write(L,col1&col2);
        writeline(output,L);
        write(L,now, justified => right, field=>20,unit=>ns);
        write(L, string'(" random read page command "));
        writeline(output,L);
     WHEN x"ff" =>
        write(L,now, justified => right, field=>20,unit=>ns);
        write(L, string'(" reset function "));
        writeline(output,L);
     WHEN x"90" =>
        write(L,now, justified => right, field=>20,unit=>ns);
        write(L, string'(" read ID function "));
        writeline(output,L);
    WHEN OTHERS =>
        write(L,now, justified => right, field=>20,unit=>ns);
        write(L, string'(" NOT USEFUL COMMAND "));
        writeline(output,L);
    END CASE;
  END IF;
  END IF;
  END PROCESS;


  PROCESS(WE_n , rst)
  BEGIN
     IF (rst = '1') THEN
       row1 <= "00000000";
       row2 <= "00000000";
       col1 <= "00000000";
       col2 <= "00000000";
       idaddr <= "00000000";
     ELSIF (WE_n'EVENT AND WE_n = '1') THEN 
       IF (CE_n = '0' AND ALE = '1') THEN
       CASE command IS 
       WHEN x"60" =>
            row1 <= DIO;
            row2 <= row1;
       WHEN x"80" =>
            row1 <= DIO;
            row2 <= row1;
            col1 <= row2;
            col2 <= col1;
       WHEN x"85" =>
            col1 <= DIO;
            col2 <= col1;
       WHEN x"00" =>
            row1 <= DIO;
            row2 <= row1;
            col1 <= row2;
            col2 <= col1;
       WHEN x"05" =>
            col1 <= DIO;
            col2 <= col1;
       WHEN x"90" =>
            idaddr <= DIO;
       WHEN OTHERS =>
            row1 <= "00000000";
            row2 <= "00000000";
            col1 <= "00000000";
            col2 <= "00000000";
            idaddr <= "00000000";
       END CASE;
       END IF;
     END IF;
  END PROCESS;


  

PROCESS(WE_n , rst)
variable cnt    : std_logic_vector(11 downto 0);
variable cnt_835: std_logic_vector(11 downto 0);
variable data_temp : std_logic_vector(7 downto 0);
 BEGIN
   IF (rst = '1') THEN
     con1_835 <= x"835";
     con1     <= x"000";
     for i in 0 to 2112 loop
         memory(i) <= "00000000";
     end loop;
   ELSIF (WE_n'EVENT AND WE_n = '1') THEN
     IF (CE_n = '0' AND ALE = '0' and CLE = '0' and command = x"80") THEN
         memory(to_integer(unsigned(con1))) <= DIO;
         con1 <= con1 + '1';
     ELSIF (CE_n = '0' AND ALE = '0' AND CLE = '0' AND command = x"85") THEN
         memory(to_integer(unsigned(con1_835))) <= DIO;
         con1_835 <= con1_835 + '1';
     END IF;
   END IF;
 END PROCESS;


PROCESS(RE_n, rst)
BEGIN
   IF (rst = '1') THEN
      con <= "00";
   ELSIF (RE_n'EVENT AND RE_n = '0') THEN
      IF (CE_n = '0' AND ALE = '0' AND command = x"90") THEN
      con <= con + 1;
      END IF;
   END IF;
END PROCESS;



PROCESS(RE_n , rst)
variable L : line;
BEGIN
  IF (rst = '1') THEN
     con2 <= x"000";
     datout <= x"00";
     con2_835 <= x"835";
  ELSIF (RE_n'EVENT AND RE_n = '0') THEN
     IF (CE_n = '0' AND ALE = '0' AND CLE = '0' AND command = x"30") THEN
        datout <= memory(to_integer(unsigned(con2)));
        con2   <= con2 + 1;
        con2_835 <= x"835";
     ELSIF (CE_n = '0' AND ALE = '0' AND CLE = '0' AND command = x"e0") THEN
        datout <= memory(to_integer(unsigned(con2_835)));
        con2_835 <= con2_835 + 1;
     ELSIF (CE_n = '0' AND ALE = '0' AND CLE = '0' AND command = x"70") THEN
        datout <= "00000000";
        con2   <= x"000";
        con2_835 <= x"000";
     ELSIF (CE_n = '0' AND ALE = '0' AND CLE = '0' AND command = x"90") THEN
        con2 <= x"000";
        con2_835 <= x"000";
        IF (con = "00" ) THEN
        datout <= x"ec";
        write(L,now, justified => right, field=>20,unit=>ns) ;
        write(L, string'(" id code :     "));
        write(L,datout);
        writeline(output,L);
        ELSIF ( con = "01") THEN
        datout <= x"a1";
        write(L,now, justified => right, field=>20,unit=>ns) ;
        write(L, string'(" id code :     "));
        write(L,datout);
        writeline(output,L);
        ELSIF ( con = "10") THEN
        datout <= x"00";
        write(L,now, justified => right, field=>20,unit=>ns) ;
        write(L, string'(" id code :     "));
        write(L,datout);
        writeline(output,L);
        ELSIF (con = "11") THEN
        datout <= x"15";
        write(L,now, justified => right, field=>20,unit=>ns) ;
        write(L, string'(" id code :     "));
        write(L,datout);
        writeline(output,L);
        END IF;
     ELSE 
       con2    <= x"000";
       datout  <= x"00";
       con2_835<= x"835"; 
     END IF;
  END IF;
END PROCESS;

PROCESS(RE_n, rst, con2, con2_835) 
BEGIN
  IF (rst = '1') THEN
     dat_en <= '0';
  ELSIF (RE_n'EVENT AND RE_n = '1') THEN
          IF (CE_n = '0' AND ALE = '0' AND CLE = '0' AND command = x"30") THEN
        IF (con2 /= x"800") THEN
           dat_en <= '1';
        ELSE
           dat_en <= '0' after 50ns;
        END IF;
     ELSIF (CE_n = '0' AND ALE = '0' AND CLE = '0' AND command = x"e0") THEN
        IF (con2_835 /= x"841") THEN
           dat_en <= '1';
        ELSE
           dat_en <= '0' after 50ns;
        END IF;
     ELSIF (CE_n = '0' AND ALE = '0' AND CLE = '0' AND command = x"90") THEN
        dat_en <= '1','0' after 50ns;
     ELSIF (command = x"70") THEN
        dat_en <= '1', '0' after 151ns;
     END IF;

  ELSE
     IF (CE_n = '0' AND ALE = '0' AND CLE = '0' AND command = x"30") THEN
        IF (con2 /= x"800") THEN
           dat_en <= '1';
        ELSE
           dat_en <= '0' after 50ns;
        END IF;
     ELSIF (CE_n = '0' AND ALE = '0' AND CLE = '0' AND command = x"e0") THEN
        IF (con2_835 /= x"841") THEN
           dat_en <= '1';
        ELSE
           dat_en <= '0' after 50ns;
        END IF;
     ELSIF (CE_n = '0' AND ALE = '0' AND CLE = '0' AND command = x"90") THEN
         dat_en <= '1','0' after 50ns;
     ELSIF (command = x"70") THEN
        dat_en <= '1', '0' after 151ns;
     END IF;
  END IF;
END PROCESS;
  

PROCESS(RE_n , rst, CE_n, ALE, CLE, WE_n)
BEGIN
  IF (rst = '1') then
      R_nB <= '1';
  ELSE
     IF (command = x"d0") THEN
        R_nB <= '0' after 60ns, '1' after 200ns;
     ELSIF (command = x"10") THEN
        R_nB <= '0' after 60ns, '1' after 200ns;
     ELSIF (command = x"30") THEN
        R_nB <= '0' after 60ns, '1' after 200ns;
     ELSE
        R_nB <= '1';
     END IF;
  END IF;
END PROCESS;

     
  

END ARCHITECTURE translated;
