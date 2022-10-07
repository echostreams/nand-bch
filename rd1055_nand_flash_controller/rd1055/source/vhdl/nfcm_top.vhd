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
--   Ver  :| Author :| Mod. Date :| Changes Made:
--   V01.0:| A.Y    :| 09/30/06  :| Initial ver
--   v01.1:| J.T    :| 06/21/09  :| just use one buffer and change ecc generator
-- --------------------------------------------------------------------
--
-- 
--Description of module:
----------------------------------------------------------------------------------
--  This block is the top level VHDL entity for this
--  reference Design.  It instantiates the following modules:
--    - MFSM.v
--    - TFSM.v
--    - ACounter.v
--    - H_gen.v
--    - ErrLoc.v
--    - ebr_buffer.v
-- --------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity nfcm_top is
  port (
-- Flash mem i/f (Samsung 128Mx8)  
  DIO : inout std_logic_vector(7 downto 0);
  CLE : out std_logic; -- CLE
  ALE : out std_logic; -- ALE
  WE_n : out std_logic; -- ~WE
  RE_n : out std_logic; -- ~RE
  CE_n : out std_logic; -- ~CE
  R_nB : in std_logic; -- R/~B
-- system
  CLK : in std_logic;
  RES : in std_logic;
-- Host I/F
  BF_sel : in std_logic;
  BF_ad  : in std_logic_vector(10 downto 0);
  BF_din : in std_logic_vector(7 downto 0);
  BF_dou : out std_logic_vector(7 downto 0);
  BF_we  : in std_logic;
  RWA    : in std_logic_vector(15 downto 0); -- row addr
-- Status
  PErr : out std_logic;  -- progr err
  EErr : out std_logic;  -- erase err
  RErr : out std_logic; -- selcted buffer isn't ready
-- control & handshake
  nfc_cmd : in std_logic_vector (2 downto 0);  -- command see below
  nfc_strt : in std_logic;  -- pos edge (pulse) to start
  nfc_done : out std_logic   );  -- operation finished if '1'
end nfcm_top;

-- NFC commands (all remaining encodings are ignored = NOP):
-- WPA 001=write page
-- RPA 010=read page
-- EBL 100=erase block
-- RET 011=reset
-- RID 101= read ID
--
architecture RTL of nfcm_top is

component ebr_buffer
port (DataInA: in  std_logic_vector(7 downto 0); 
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
end component;

component ACounter
Port (clk : in std_logic;
      Res : in std_logic;
      Set835 : in std_logic;
      CntEn : in std_logic;
      CntOut : out std_logic_vector(11 downto 0);
      TC2048 : out std_logic;
      TC3  : out std_logic   );
end component;

component TFSM
  port (
  CLE : out std_logic; -- CLE
  ALE : out std_logic; -- ALE
  WE_n : out std_logic; -- ~WE
  RE_n : out std_logic; -- ~RE
  CE_n : out std_logic; -- ~CE
  DOS  : out std_logic; -- data out strobe
  DIS  : out std_logic;  -- data in strobe
  cnt_en : out std_logic; -- ca counter ce
  TC3 : in std_logic; -- term counts
  TC2048 : in std_logic;
  CLK : in std_logic;
  RES : in std_logic;
  start: in std_logic;
  cmd_code: in std_logic_vector(2 downto 0);
  ecc_en:out std_logic;
  Done : out std_logic   );
end component;

component MFSM
  port (
  CLK : in std_logic;
  RES : in std_logic;
  start : in std_logic;
  command : in std_logic_vector(2 downto 0);
  setDone : out std_logic;
  R_nB : in std_logic;  -- R/B_
  BF_sel : in std_logic;
  mBF_sel : out std_logic;  -- BF sel fm the nfc
  BF_we : out std_logic;
  io_0 : in std_logic;  -- LSB fm flash data (status)
  t_start : out std_logic;  -- i/f w TFSM
  t_cmd  : out std_logic_vector(2 downto 0);
  t_done : in std_logic;
  WrECC : out std_logic;
  EnEcc : out std_logic;
  AMX_sel : out std_logic_vector (1 downto 0);  --add mx sel
  cmd_reg : out std_logic_vector (7 downto 0);  -- data to cmd reg
  cmd_reg_we : out std_logic;
  RAR_we : out std_logic;
  set835 : out std_logic;  -- to cnt
  cnt_res : out std_logic;
  tc8, tc4 : in std_logic;  -- term counts fm Wait counter
  wCntRes, wCntCE : out std_logic;  -- wait conter ctrl
  SetPrErr, SetErErr : out std_logic;
  ADC_sel : out std_logic_vector(1 downto 0)   );  -- ad/dat/cmd mux ctrl
end component;

component H_gen
Port (
      clk : in std_logic;
      Res : in std_logic;
      Din : in std_logic_vector(3 downto 0);
      EN : in std_logic;  -- enable ECC

      eccByte : out std_logic_vector(7 downto 0)      
      );
end component;

component ErrLoc
Port (
      clk : in std_logic;
      Res : in std_logic;
      F_ecc_data : in std_logic_vector(6 downto 0); -- ecc byte read fm flash
      WrECC : in std_logic;
 
      ECC_status: out std_logic
      );
end component;

constant HI : std_logic := '1';
constant LO : std_logic := '0';

signal ires, res_t : std_logic;
--
signal FlashDataIn, FlashDataOu, FlashCmd : std_logic_vector (7 downto 0);
signal adc_sel : std_logic_vector (1 downto 0);
signal  QA_1, QB_1 : std_logic_vector (7 downto 0);
signal BF_data2flash, ECC_data : std_logic_vector (7 downto 0);
signal Flash_BF_sel, Flash_BF_we, DIS, F_we : std_logic;

-- ColAd, RowAd
signal rar_we : std_logic;
signal addr_data : std_logic_vector( 7 downto 0);
signal rad_1 : std_logic_vector( 7 downto 0) ;
signal rad_2 : std_logic_vector( 7 downto 0) ;
signal cad_1 : std_logic_vector( 7 downto 0);
signal cad_2 : std_logic_vector( 7 downto 0);
signal amx_sel : std_logic_vector(1 downto 0);
-- counter ctrls
signal CntEn, tc3, tc2048, cnt_res, acnt_res : std_logic;
signal CntOut : std_logic_vector(11 downto 0);
--TFSM
signal DOS : std_logic;  -- data out strobe
signal t_start, t_done : std_logic;
signal t_cmd : std_logic_vector(2 downto 0);

-- wait counter
signal WCountRes, WCountCE : std_logic;
signal TC4, TC8 : std_logic;  -- term counts

--
signal cmd_we : std_logic;
signal cmd_reg : std_logic_vector (7 downto 0);

signal SetPrErr, SetErErr,SetRrErr : std_logic;
--
signal WrECC, WrECC_e, enEcc, Ecc_en,ecc_en_tfsm : std_logic;
signal setDone, set835: std_logic;

-- internal sigs before the out registers
signal ALE_i, CLE_i, WE_ni, CE_ni, RE_ni : std_logic;
signal DOS_i : std_logic;
signal FlashDataOu_i : std_logic_vector(7 downto 0); 

signal WC_tmp : std_logic_vector (3 downto 0):="0000";
begin

a0: BF_dou <= QA_1;
a1: BF_data2flash <=  QB_1;
                  
a5: cad_1 <= CntOut(7 downto 0);
a6: cad_2 <= "0000" & CntOut(11 downto 8);

a7: acnt_res <= (ires or cnt_res);
a8: WrECC_e <= WrEcc and DIS;
a9: Flash_BF_we <= DIS and F_we;


ecc_en4gen: Ecc_en <= enEcc and ecc_en_tfsm;



buff: ebr_buffer
port map (DataInA(7 downto 0)=> BF_din,
          QA(7 downto 0)=> QA_1,
          AddressA(10 downto 0)=> BF_ad,
          ClockA=> CLK,
          ClockEnA=> BF_sel,
          WrA=> BF_we,
          ResetA=> LO,
          DataInB(7 downto 0)=> FlashDataIn,
          QB(7 downto 0)=> QB_1,
          AddressB(10 downto 0)=> CntOut(10 downto 0),
          ClockB=> CLK,
          ClockEnB=> Flash_BF_sel,
          WrB=> Flash_BF_we,
          ResetB=> LO   );

addr_counter: ACounter
port map (clk => CLK,
          Res => acnt_res,
          Set835 => set835,
          CntEn => CntEn,
          CntOut => CntOut,
          TC2048 => tc2048,
          TC3  => tc3  );
          
tim_fsm:  TFSM
port map (
          CLE => CLE_i,
          ALE => ALE_i,
          WE_n => WE_ni,
          RE_n => RE_ni,
          CE_n => CE_ni,
          DOS  => DOS_i,
          DIS  => DIS,
          cnt_en => CntEn,
          TC3  => tc3,
          TC2048 => tc2048,
          CLK => CLK,
          RES => ires,
          start => t_start,
          cmd_code => t_cmd,
          ecc_en=>ecc_en_tfsm,
          Done => t_done     );
          
main_fsm:  MFSM
port map (
  CLK => CLK,
  RES => ires,
  start => nfc_strt,
  command => nfc_cmd,
  setDone => setDone,
  R_nB => R_nB,
  BF_sel => BF_sel,
  mBF_sel => Flash_BF_sel,
  BF_we => F_we,
  io_0 => FlashDataIn(0),
  t_start => t_start,
  t_cmd  => t_cmd,
  t_done => t_done,
  WrECC => WrECC,
  EnEcc => enEcc,
  AMX_sel => amx_sel,
  cmd_reg => cmd_reg,
  cmd_reg_we => cmd_we,
  RAR_we => rar_we,
  set835 => set835,
  cnt_res => cnt_res,
  tc8  => TC8, 
  tc4  => TC4,
  wCntRes => WCountRes, 
  wCntCE =>  WCountCE,
  SetPrErr  => SetPrErr, 
  SetErErr  =>  SetErErr,
  ADC_sel => adc_sel   );
  
ecc_gen:  H_gen
port map(
      clk => CLK,
      Res => acnt_res,
      Din => FlashDataIn(3 downto 0),
      EN => Ecc_en,
  
      eccByte => ECC_data
   );
    
ecc_err_loc:  ErrLoc
Port map (
      clk => CLK,
      Res => acnt_res,
      F_ecc_data => FlashDataIn(6 downto 0),
      WrECC => WrECC_e,
      
      ECC_status => SetRrErr      );        

res_int: process (CLK)
begin
if rising_edge (CLK) then
  res_t <= RES;
  ires <= res_t;
end if;
end process;

rowAdReg: process (CLK)
begin
if rising_edge(CLK) then
  if rar_we = '1' then
    rad_1 <= RWA(7 downto 0 );
    rad_2 <= RWA(15 downto 8 );
  end if;
end if;
end process;

out_regs: process(CLK)
begin
if rising_edge(CLK) then
  FlashDataOu <= FlashDataOu_i;
  DOS <= DOS_i;
  ALE <= ALE_i;
  CLE <= CLE_i;
  WE_n <= WE_ni;
  CE_n <= CE_ni;
  RE_n <= RE_ni;
end if;
end process;
  
ca_ra_mux: process(cad_1, cad_2, rad_1, rad_2, amx_sel)
begin
case amx_sel is
  when "11" => addr_data <= rad_2;
  when "10" => addr_data <= rad_1;
  when "01" => addr_data <= cad_2;
  when others => addr_data <= cad_1;
end case;
end process;

fl_out_mux: process (adc_sel,BF_data2flash,FlashCmd,addr_data,ECC_data)
begin
case adc_sel is
  when "11" => FlashDataOu_i <= FlashCmd;
  when "10" => FlashDataOu_i <= addr_data;
  when "01" => FlashDataOu_i <= ECC_data;
  when others => FlashDataOu_i <= BF_data2flash;
end case;
end process;


wait_counter: process (CLK)
--  variable WC_tmp : std_logic_vector (3 downto 0);
begin
if rising_edge (CLK) then
  if ires = '1' or WCountRes = '1' then
    WC_tmp<= "0000";
  elsif WCountCE = '1' then
    WC_tmp<= WC_tmp + 1;
  end if;
  if WC_tmp = "0100" then
    TC4 <= '1'; TC8 <= '0';
  elsif WC_tmp = "1000" then
    TC8<= '1'; TC4 <= '0';
  else
    TC4 <= '0'; TC8 <= '0';
  end if;

end if;
end process;

command_register: process (CLK)
begin
if rising_edge (CLK) then
  if ires = '1' then
    FlashCmd <= "00000000";
  elsif cmd_we = '1' then
    FlashCmd <= cmd_reg;
  end if;
end if;
end process;

done_ff: process (CLK)
begin
if rising_edge (CLK) then
  if ires = '1' then
    nfc_Done <= '0';
  elsif setDone = '1' then
    nfc_Done <= '1';
  elsif nfc_strt = '1' then
    nfc_done <= '0';
  end if;
end if;
end process;

pr_error_ff: process (CLK)
begin
if rising_edge (CLK) then
  if ires = '1' then
    PErr <= '0';
  elsif setPrErr = '1' then
    PErr <= '1';
  elsif nfc_strt = '1' then
    PErr <= '0';
  end if;
end if;
end process;

e_error_ff: process (CLK)
begin
if rising_edge (CLK) then
  if ires = '1' then
    EErr <= '0';
  elsif setErErr = '1' then
    EErr <= '1';
  elsif nfc_strt = '1' then
    EErr <= '0';
  end if;
end if;
end process;

buff_err_ff: process (CLK)
begin
if rising_edge (CLK) then
  if ires = '1' then
    RErr <= '0';
  elsif SetRrErr = '1' then
    RErr <= '1';
  elsif nfc_strt = '1' then
    RErr <= '0';
  end if;
end if;
end process;


ibuffer: FlashDataIn <= DIO;
obuffer: DIO <= FlashDataOu when DOS = '1' else "ZZZZZZZZ";

--
end RTL;
