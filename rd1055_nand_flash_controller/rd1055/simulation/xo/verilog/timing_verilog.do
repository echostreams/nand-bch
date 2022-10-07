set PROJ_DIR "Enter Simulation Directory Path"

# Example: 
# set PROJ_DIR "C:\rd1055_nand_flash_controller\rd1055\simulation\"

cd $PROJ_DIR/xo/verilog/

if {![file exists timing_verilog]} {
    vlib timing_verilog 
}
endif

design create timing_verilog .
design open timing_verilog
adel -all

cd $PROJ_DIR/xo/verilog/

vlog -dbg ../../../project/xo/verilog/xo_verilog/xo_verilog_xo_verilog_vo.vo

vlog ../../../testbench/verilog/flash_interface.v
vlog ../../../testbench/verilog/nfcm_tb.v

vsim +access +r nfcm_tb -PL pmi_work -L ovi_machxo -noglitch +no_tchk_msg -sdfmax nfcm = "../../../project/xo/verilog/xo_verilog/xo_verilog_xo_verilog_vo.sdf"

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

run 
