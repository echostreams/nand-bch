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
 library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned."-";
use ieee.std_logic_unsigned."+";
use ieee.std_logic_textio.all;         
use std.textio.all;                    
use ieee.numeric_std.all;  

ENTITY nfcm_tb IS 
END nfcm_tb;

ARCHITECTURE behav of nfcm_tb is

COMPONENT nfcm_top is
  port (
  DIO : inout std_logic_vector(7 downto 0);
  CLE : out std_logic; -- CLE
  ALE : out std_logic; -- ALE
  WE_n : out std_logic; -- ~WE
  RE_n : out std_logic; -- ~RE
  CE_n : out std_logic; -- ~CE
  R_nB : in std_logic; -- R/~B
  CLK : in std_logic;
  RES : in std_logic;
  BF_sel : in std_logic;
  BF_ad  : in std_logic_vector(10 downto 0);
  BF_din : in std_logic_vector(7 downto 0);
  BF_dou : out std_logic_vector(7 downto 0);
  BF_we  : in std_logic;
  RWA    : in std_logic_vector(15 downto 0); -- row addr
  PErr : out std_logic;  -- progr err
  EErr : out std_logic;  -- erase err
  RErr : out std_logic; -- selcted buffer isn't ready
  nfc_cmd : in std_logic_vector (2 downto 0);  -- command see below
  nfc_strt : in std_logic;  -- pos edge (pulse) to start
  nfc_done : out std_logic   );  -- operation finished if '1'
end component;

component  flash_interface IS  PORT(
       DIO : INOUT STD_LOGIC_VECTOR(7 DOWNTO 0);
       CLE : IN STD_LOGIC;
       ALE : IN STD_LOGIC;
       WE_n : IN STD_LOGIC;
       RE_n : IN STD_LOGIC;
       CE_n : IN STD_LOGIC;
       rst  : IN STD_LOGIC;
       R_nB : OUT STD_LOGIC
);
end component;
SIGNAL clk, rst : std_logic;
SIGNAL DIO      : std_logic_vector(7 downto 0);
SIGNAL CLE      : std_logic;
SIGNAL ALE      : std_logic;
SIGNAL WE_n     : std_logic;
SIGNAL RE_n     : std_logic;
SIGNAL CE_n     : std_logic;
SIGNAL R_nB     : std_logic;
SIGNAL BF_sel   : std_logic;
SIGNAL BF_ad    : std_logic_vector(10 downto 0);
SIGNAL BF_din   : std_logic_vector(7  downto 0);
SIGNAL BF_we    : std_logic;
SIGNAL RWA      : std_logic_vector(15 downto 0);
SIGNAL BF_dou   : std_logic_vector(7  downto 0);
SIGNAL PErr     : std_logic;
SIGNAL EErr     : std_logic;
SIGNAL RErr     : std_logic;

SIGNAL nfc_cmd  : std_logic_vector(2 downto 0);
SIGNAL nfc_strt : std_logic;
SIGNAL nfc_done : std_logic;
signal temp_data : std_logic_vector(7 downto 0);

TYPE memory_2048 is ARRAY (2047 downto 0) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL memory : memory_2048;
SIGNAL temp   : std_logic_vector(7 downto 0);

CONSTANT period : time := 16 ns; -- suppose 60MHZ

BEGIN




nfcm: nfcm_top port map (
 DIO => DIO,
 CLE => CLE,
 ALE => ALE,
 WE_n => WE_n,
 RE_n => RE_n,
 CE_n => CE_n,
 R_nB => R_nB,

 CLK  => clk,
 RES  => rst,

 BF_sel => BF_sel,
 BF_ad  => BF_ad ,
 BF_din => BF_din,
 BF_we  => BF_we ,
 RWA    => RWA   , 

 BF_dou => BF_dou,
 PErr   => PErr, 
 EErr   => EErr, 
 RErr   => RErr,
     
 nfc_cmd  => nfc_cmd , 
 nfc_strt => nfc_strt,  
 nfc_done => nfc_done
);


nand_flash: flash_interface port map (
    DIO  => DIO,
    CLE  => CLE,
    ALE  => ALE,
    WE_n => WE_n,
    RE_n => RE_n,
    CE_n => CE_n,
    R_nB => R_nB,
    rst  => rst
);




process
begin
 clk <= '0';
 wait for (period/2);
 clk <= '1';
 wait for (period/2);
end process;

process
VARIABLE randNum : real;
VARIABLE s1 : positive :=7;
VARIABLE s2 : positive :=222;

procedure uniform(variable Seed1,Seed2:inout integer;variable X:out real) is

	variable z, k: integer;
	begin
	k := Seed1/53668;
	Seed1 := 40014 * (Seed1 - k * 53668) - k * 12211;
	
	if Seed1 < 0  then
		Seed1 := Seed1 + 2147483563;
	end if;


	k := Seed2/52774;
	Seed2 := 40692 * (Seed2 - k * 52774) - k * 3791;
	
	if Seed2 < 0  then
		Seed2 := Seed2 + 2147483399;
	end if;

	z := Seed1 - Seed2;
	if z < 1 then
		z := z + 2147483562;
	end if;

	X :=  REAL(Z)*4.656613e-10;
 end uniform;


 

procedure reset_cycle is
variable L : line;
begin
   wait until rising_edge(clk);
   nfc_cmd  <= "011";
   nfc_strt <= '1';

   wait until rising_edge(clk);
   nfc_strt <= '0';

   wait until nfc_done = '1';

   wait until rising_edge(clk);
   nfc_cmd  <= "111";
    write(L,now, justified => right, field=>20,unit=>ns);
    write(L, string'(" << reset function over >> "));
    writeline(output,L);  
end reset_cycle;


procedure erase_cycle     
    (address: in std_logic_vector(15 downto 0))  is
    variable L : line;
    begin
    wait until rising_edge(clk);
    wait for 3ns;
    RWA   <= address;
    nfc_cmd <= "100";
    nfc_strt<= '1';

    wait until rising_edge(clk);
    wait for 3 ns;
    nfc_strt <= '0';
    
    wait until rising_edge(clk);
    wait until nfc_done = '1';

    wait until rising_edge(clk);
    nfc_cmd   <= "111";

    if (EErr = '1') then
        write(L,now, justified => right, field=>20,unit=>ns);
        write(L, string'(" << erase error >> "));
        writeline(output,L);
     else
        write(L,now, justified => right, field=>20,unit=>ns);
        write(L, string'(" << erase no error >> "));
        writeline(output,L);
     end if;
    end erase_cycle;




procedure write_cycle (
    address : in std_logic_vector(15 downto 0)) is 
    variable L : line;
begin
    wait until rising_edge(clk);
    wait for 3 ns;
    RWA  <= address;
    nfc_cmd <= "001";
    nfc_strt <= '1';
    BF_sel   <= '1';
    wait until rising_edge(clk);
    wait for 3 ns;
    nfc_strt <= '0'; 
    BF_ad    <= "00000000000";
    for i in 0 to 2047 loop 
    wait until rising_edge(clk); 
       wait for 3ns;      
       BF_we  <=  '1';
       uniform(S1, S2, randNum);
       randNum := randNum * 256.0;
       temp_data  <= CONV_STD_LOGIC_VECTOR(integer(randNum),8 ) ;
       memory(i)   <=  CONV_STD_LOGIC_VECTOR(integer(randNum),8 ) ;
       wait for 3 ns;
       BF_din      <= memory(i);
       BF_ad     <= CONV_STD_LOGIC_VECTOR(integer(i),11 ) after 3 ns;
    end loop;

    wait until rising_edge(clk);
    wait until rising_edge(clk);
    wait for 3 ns;
   BF_we  <=  '0';
    wait until nfc_done = '1';
    wait until rising_edge(clk);
    wait for 3 ns;
    nfc_cmd <= "111";
    BF_sel  <= '0';
    
    if (PErr = '1') then
        write(L,now, justified => right, field=>20,unit=>ns);
        write(L, string'(" << Writing error >> "));
        writeline(output,L);
    else
        write(L,now, justified => right, field=>20,unit=>ns);
        write(L, string'(" << Writing no error >> "));
        writeline(output,L);
    end if;

end  write_cycle;    

procedure read_cycle (
    address : in std_logic_vector(15 downto 0)) is 
      variable L : line;
begin
    wait until rising_edge(clk);
    wait for 3ns;
    RWA     <= address;
    nfc_cmd <= "010";
    nfc_strt <= '1';
    BF_sel   <= '1';
    BF_we    <= '0';
    BF_ad    <= "00000000000" after 3ns;
    wait until rising_edge(clk);
    wait for 3ns;
    nfc_strt <= '0';  
    wait until rising_edge(clk); 
    wait until nfc_done = '1';
    wait until rising_edge(clk);
    wait for 3 ns;
    nfc_cmd <= "111";
    BF_ad   <= BF_ad+1 after 3ns;
   for i in 0 to 2047 loop       
       wait until rising_edge(clk);
       temp  <= memory(i);    
       BF_ad <= BF_ad+1 after 3 ns; 
    end loop;
   
   if (RErr = '1') then
        write(L,now, justified => right, field=>20,unit=>ns);
        write(L, string'(" << ecc error >> "));
        writeline(output,L);
   else 
        write(L,now, justified => right, field=>20,unit=>ns);
        write(L, string'(" << ecc no error >> "));
        writeline(output,L);
   end if;
end  read_cycle;    


procedure read_id_cycle(
    address : in std_logic_vector(15 downto 0)) is 
    variable L : line;  
begin
    wait until rising_edge(clk);
    wait for 3ns;
    RWA     <= address;
    nfc_cmd <= "101";
    nfc_strt<= '1';
    BF_sel  <= '1';
    wait until rising_edge(clk);
    wait for 3ns;
    nfc_strt <= '0';
    wait until rising_edge(clk);
    wait until nfc_done = '1';
    wait until rising_edge(clk);
    nfc_cmd <= "111";
        write(L,now, justified => right, field=>20,unit=>ns);
        write(L, string'(" << read id function over >> "));
        writeline(output,L);
          
end read_id_cycle;     



                                         
                                                                        
procedure kill_time is                                                         
  begin                                                                 
    wait until rising_edge(clk);                                                 
    wait until rising_edge(clk);                                                 
    wait until rising_edge(clk);                                                
    wait until rising_edge(clk);                                                 
    wait until rising_edge(clk);                                                
  end  kill_time;     

                                      
begin

rst  <= '1';
BF_sel <= '0';
BF_ad  <= "00000000000";
BF_din <= x"00";
BF_we  <= '0';
RWA    <= x"0000";
nfc_cmd<= "111";
nfc_strt <= '0';
temp   <= x"24";

wait for 300 ns;
rst   <= '0';

	kill_time; 
	kill_time; 

	reset_cycle;

	kill_time; 
	kill_time; 
	
	erase_cycle(x"1234");
	
	kill_time; 
	kill_time;
	
	write_cycle(x"1234");
	
	kill_time; 
	kill_time;
	
	read_cycle(x"1234");
	
	kill_time; 
	kill_time;

	read_id_cycle(x"0000");
	
	kill_time; 
	kill_time;
	
   wait for 10000 ns;


end process;

 

 
END ARCHITECTURE behav; 


