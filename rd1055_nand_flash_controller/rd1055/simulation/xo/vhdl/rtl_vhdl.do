set PROJ_DIR "Enter Simulation Directory Path"

# Example: 
# set PROJ_DIR "C:\rd1055_nand_flash_controller\rd1055\simulation\"

cd $PROJ_DIR/xo/vhdl/

if {![file exists rtl_vhdl]} {
    vlib rtl_vhdl 
}
endif

design create rtl_vhdl .
design open rtl_vhdl
adel -all

cd $PROJ_DIR/xo/vhdl/

acom ../../../source/vhdl/ACounter.vhd
acom ../../../source/vhdl/ErrLoc.vhd
acom ../../../source/vhdl/H_gen.vhd
acom ../../../source/vhdl/MFSM.vhd
acom ../../../source/vhdl/nfcm_top.vhd
acom ../../../source/vhdl/TFSM.vhd
acom ../../../source/vhdl/ipexpress/xo/ebr_buffer.vhd


acom ../../../testbench/vhdl/flash_interface.vhd
acom ../../../testbench/vhdl/nfcm_tb.vhd

asim +access +r nfcm_tb -PL pmi_work -L machxo

 add wave -noreg {/nfcm_tb/nfcm/DIO}
 add wave -noreg {/nfcm_tb/nfcm/CLE}
 add wave -noreg {/nfcm_tb/nfcm/ALE}
 add wave -noreg {/nfcm_tb/nfcm/WE_n}
 add wave -noreg {/nfcm_tb/nfcm/RE_n}
 add wave -noreg {/nfcm_tb/nfcm/CE_n}
 add wave -noreg {/nfcm_tb/nfcm/R_nB}
 add wave -noreg {/nfcm_tb/nfcm/CLK}
 add wave -noreg {/nfcm_tb/nfcm/RES}
 add wave -noreg {/nfcm_tb/nfcm/BF_sel}
 add wave -noreg {/nfcm_tb/nfcm/BF_ad}
 add wave -noreg {/nfcm_tb/nfcm/BF_din}
 add wave -noreg {/nfcm_tb/nfcm/BF_dou}
 add wave -noreg {/nfcm_tb/nfcm/BF_we}
 add wave -noreg {/nfcm_tb/nfcm/RWA}
 add wave -noreg {/nfcm_tb/nfcm/PErr}
 add wave -noreg {/nfcm_tb/nfcm/EErr}
 add wave -noreg {/nfcm_tb/nfcm/RErr}
 add wave -noreg {/nfcm_tb/nfcm/nfc_cmd}
 add wave -noreg {/nfcm_tb/nfcm/nfc_strt}
 add wave -noreg {/nfcm_tb/nfcm/nfc_done}

run -all