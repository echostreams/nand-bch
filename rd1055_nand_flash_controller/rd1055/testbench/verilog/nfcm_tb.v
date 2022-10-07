//   ==================================================================
//   >>>>>>>>>>>>>>>>>>>>>>> COPYRIGHT NOTICE <<<<<<<<<<<<<<<<<<<<<<<<<
//   ------------------------------------------------------------------
//   Copyright (c) 2013 by Lattice Semiconductor Corporation
//   ALL RIGHTS RESERVED 
//   ------------------------------------------------------------------
//
//   Permission:
//
//      Lattice SG Pte. Ltd. grants permission to use this code
//      pursuant to the terms of the Lattice Reference Design License Agreement. 
//
//
//   Disclaimer:
//
//      This VHDL or Verilog source code is intended as a design reference
//      which illustrates how these types of functions can be implemented.
//      It is the user's responsibility to verify their design for
//      consistency and functionality through the use of formal
//      verification methods.  Lattice provides no warranty
//      regarding the use or functionality of this code.
//
//   --------------------------------------------------------------------
//
//                  Lattice SG Pte. Ltd.
//                  101 Thomson Road, United Square #07-02 
//                  Singapore 307591
//
//
//                  TEL: 1-800-Lattice (USA and Canada)
//                       +65-6631-2000 (Singapore)
//                       +1-503-268-8001 (other locations)
//
//                  web: http://www.latticesemi.com/
//                  email: techsupport@latticesemi.com
//
//   --------------------------------------------------------------------
//
//
// Revision History :
// --------------------------------------------------------------------
//   Ver  :| Author :| Mod. Date :| Changes Made:
//   v01.0:| J.T    :| 06/20/09  :| Initial ver
// --------------------------------------------------------------------
//
// 
//Description of module:
//--------------------------------------------------------------------------------
// 
// --------------------------------------------------------------------
`timescale 1 ns / 1 fs

module nfcm_tb();

 reg clk,rst;
// reg [7:0] DIO_reg;
// reg ena;
 wire [7:0] DIO;
 wire CLE;// -- CLE
 wire ALE;//  -- ALE
 wire WE_n;// -- ~WE
 wire RE_n; //-- ~RE
 wire CE_n; //-- ~CE
 wire R_nB; //-- R/~B

 reg BF_sel;
 reg [10:0] BF_ad;
 reg [7:0] BF_din;
 reg BF_we;
 reg [15:0] RWA; //-- row addr
 wire [7:0] BF_dou;

 wire PErr ; // -- progr err
 wire EErr ; // -- erase err
 wire RErr ;

 reg [2:0] nfc_cmd; // -- command see below
 reg nfc_strt;//  -- pos edge (pulse) to start
 wire nfc_done;//  -- operation finished if '1'

  
reg[7:0] memory[0:2047];

reg [7:0] temp;
  
//GSR GSR_INST(.GSR(1'b1));
//PUR PUR_INST(.PUR(1'b1));  

//pullup (DIO[0]);
//pullup (DIO[1]);
//pullup (DIO[2]);
//pullup (DIO[3]);
//pullup (DIO[4]);
//pullup (DIO[5]);
//pullup (DIO[6]);
//pullup (DIO[7]);

parameter period=16;         // suppose 60MHz

//assign DIO=ena?DIO_reg:8'hzz;
initial begin
  clk <= 1'b0;
	rst  <= 1'b1;
	BF_sel<=1'b0;                   
	BF_ad<=0;            
	BF_din<=0;            
	BF_we<=0;                   
	RWA<=0; 
	nfc_cmd<=3'b111;
	nfc_strt<=1'b0; 
	temp<=8'h24;
//	R_nB<=1'b1;
//	DIO_reg<=0;
//	ena<=0;
	#300;
	rst<=1'b0;

	kill_time; 
	kill_time; 

	reset_cycle;

	kill_time; 
	kill_time; 
	
	erase_cycle(16'h1234);
	
	kill_time; 
	kill_time;
	
	write_cycle(16'h1234);
	
	kill_time; 
	kill_time;
	
	read_cycle(16'h1234);
	
	kill_time; 
	kill_time;

	read_id_cycle(16'h0000);
	
	kill_time; 
	kill_time;
	
        #1000;
	$stop;
	
	end

always
   #(period/2) clk <= ~clk;
   
// Instantiation of the nfcm
nfcm_top nfcm(
 .DIO(DIO),
 .CLE(CLE),
 .ALE(ALE),
 .WE_n(WE_n),
 .RE_n(RE_n),
 .CE_n(CE_n),
 .R_nB(R_nB),

 .CLK(clk),
 .RES(rst),

 .BF_sel(BF_sel),
 .BF_ad (BF_ad ),
 .BF_din(BF_din),
 .BF_we (BF_we ),
 .RWA   (RWA   ), 

 .BF_dou(BF_dou),
 .PErr(PErr), 
 .EErr(EErr), 
 .RErr(RErr),
      
 .nfc_cmd (nfc_cmd ), 
 .nfc_strt(nfc_strt),  
 .nfc_done(nfc_done)
);

// Instantiation of the nand flash interface
flash_interface nand_flash(
    .DIO(DIO),
    .CLE(CLE),// -- CLE
    .ALE(ALE),//  -- ALE
    .WE_n(WE_n),// -- ~WE
    .RE_n(RE_n), //-- ~RE
    .CE_n(CE_n), //-- ~CE
    .R_nB(R_nB), //-- R/~B
    .rst(rst)
);

// --------------------------------------------------------------------
// --------------------------------------------------------------------
// erase block task
// NFC commands (all remaining encodings are ignored = NOP):
//-- WPA 001=write page
//-- RPA 010=read page
//-- EBL 100=erase block
//-- RET 011=reset
//-- RID 101= read ID
task reset_cycle;    
begin
    @(posedge clk) ;
//    RWA=address;
    nfc_cmd=3'b011;
    nfc_strt=1'b1;

    @(posedge clk) ;
    nfc_strt=1'b0;    
   wait(nfc_done);
   @(posedge clk) ;
   nfc_cmd=3'b111;                                           
   $display($time,"  %m  \t \t  << reset function over >>"); 
    
end      
endtask 


task erase_cycle;
    input [15:0]  address; 
begin
//    $display($time,"  %m  \t \t  << erase flash block Address = %h >>",address);
    @(posedge clk) ;
    #3;
    RWA=address;
    nfc_cmd=3'b100;
    nfc_strt=1'b1;

    @(posedge clk) ;
    #3;
    nfc_strt=1'b0; 
    @(posedge clk) ;

   wait(nfc_done);
   @(posedge clk) ;
   nfc_cmd=3'b111;

   if(EErr)                                         
     $display($time,"  %m  \t \t  << erase error >>");    
   else                                             
     $display($time,"  %m  \t \t  << erase no error >>"); 
    
end      
endtask 
// --------------------------------------------------------------------
// --------------------------------------------------------------------
// write page task
// NFC commands (all remaining encodings are ignored = NOP):
//-- WPA 001=write page
//-- RPA 010=read page
//-- EBL 100=erase block

task write_cycle;
    input [15:0]  address; 
    integer i;
begin
//    $display($time,"  %m  \t \t  << Writing flash page Address = %h >>",address);
    @(posedge clk) ;
    #3;
    RWA=address;
    nfc_cmd=3'b001;
    nfc_strt=1'b1;
    BF_sel=1'b1;
    @(posedge clk) ;
    #3;
    nfc_strt=1'b0; 
    BF_ad=0;
    for(i=0;i<2048;i=i+1) begin    
       @(posedge clk) ; 
       #3;      
       BF_we=1'b1;
       memory[i]=$random % 256; 
       BF_din<=memory[i];
       BF_ad<=#3 i; 
    end 
   @(posedge clk) ;
   @(posedge clk) ;
   #3;
   BF_we=1'b0;  
   wait(nfc_done);
   @(posedge clk) ;
   #3;
   nfc_cmd=3'b111;
   BF_sel=1'b0;
   if(PErr)                                         
     $display($time,"  %m  \t \t  << Writing error >>");    
   else                                             
     $display($time,"  %m  \t \t  << Writing no error >>"); 
    
end      
endtask 

// --------------------------------------------------------------------
// --------------------------------------------------------------------
// read page task
// NFC commands (all remaining encodings are ignored = NOP):
//-- WPA 001=write page
//-- RPA 010=read page
//-- EBL 100=erase block
task read_cycle;
    input [15:0]  address; 
    integer i;
    
begin
    @(posedge clk) ;
    #3;
    RWA=address;
    nfc_cmd=3'b010;
    nfc_strt=1'b1;
    BF_sel=1'b1;
    BF_we=1'b0;
    BF_ad=#3 0;
    @(posedge clk) ;
    #3;
    nfc_strt=1'b0;  
    @(posedge clk) ;  
   wait(nfc_done);
   @(posedge clk) ;
   #3;
   nfc_cmd=3'b111;
   BF_ad<=#3 BF_ad+1;
   for(i=0;i<2048;i=i+1) begin       
       @(posedge clk) ;
       temp<=memory[i];    
       BF_ad<=#3 BF_ad+1; 
    end 
   
   if(RErr)                                         
     $display($time,"  %m  \t \t  << ecc error >>");    
   else                                             
     $display($time,"  %m  \t \t  << ecc no error >>"); 
    
end      
endtask 


task read_id_cycle;
    input [15:0]  address; 
    
begin    
    @(posedge clk) ;
    #3;
    RWA=address;
    nfc_cmd=3'b101;
    nfc_strt=1'b1;
    BF_sel=1'b1;
    $monitor("t=%3d R_nB=%x DIO=%x RE_n=%x",$time,R_nB,DIO,RE_n);
    @(posedge clk) ;
    #3;
    nfc_strt=1'b0;    
    @(posedge clk) ;
   wait(nfc_done);
   @(posedge clk) ;
   nfc_cmd=3'b111;
      $display($time,"  %m  \t \t  << read id function over >>"); 
    
end      
endtask 



// -------------------------------------------------------------------- 
// Task for waiting                                                     
                                                                        
task kill_time;                                                         
  begin                                                                 
    @(posedge clk);                                                 
    @(posedge clk);                                                 
    @(posedge clk);                                                 
    @(posedge clk);                                                 
    @(posedge clk);                                                 
  end                                                                   
endtask // of kill_time;                                                
                                                                        
// ---------------------------------------------------------------------   

 
endmodule



