                   NAND Flash Controller Reference Design                          
===============================================================================
File List 
 1. rd1055/doc/rd1055.pdf            	        			--> NAND Flash Controller Reference Design document
    rd1055/doc/rd1055_readme.txt                        		--> Read me file (this file)    
    rd1055/doc/revision_history						-->Revision History 

 2. rd1055/project/xo/verilog/xo_verilog.ldf		 	        --> Lattice Diamond project file    
    rd1055/project/xo/verilog/xo_verilog.lpf     		        --> preference file             
    rd1055/project/xo/verilog/xo_verilog1.sty     		        --> strategy file

    rd1055/project/xo/vhdl/xo_vhdl.ldf			 	        --> Lattice Diamond project file    
    rd1055/project/xo/vhdl/xo_vhdl.lpf         	 		        --> preference file             
    rd1055/project/xo/vhdl/xo_vhdl1.sty          		        --> strategy file    
	
    rd1055/project/xo2/verilog/xo2_verilog.ldf		 	        --> Lattice Diamond project file    
    rd1055/project/xo2/verilog/xo2_verilog.lpf     		        --> preference file             
    rd1055/project/xo2/verilog/xo2_verilog1.sty     		        --> strategy file 
		
    rd1055/project/xo2/vhdl/xo2_vhdl.ldf			 	--> Lattice Diamond project file    
    rd1055/project/xo2/vhdl/xo2_vhdl.lpf         	 		--> preference file             
    rd1055/project/xo2/vhdl/xo2_vhdl1.sty          		        --> strategy file    

    rd1055/project/xo3l/verilog/xo3l_verilog.ldf		 	--> Lattice Diamond project file    
    rd1055/project/xo3l/verilog/xo3l_verilog.lpf     		        --> preference file            
    rd1055/project/xo3l/verilog/xo3l_verilog1.sty     		        --> strategy file 

    rd1055/project/xo3l/vhdl/xo3l_vhdl.ldf			 	--> Lattice Diamond project file    
    rd1055/project/xo3l/vhdl/xo3l_vhdl.lpf         	 		--> preference file            
    rd1055/project/xo3l/vhdl/xo3l_vhdl1.sty          		        --> strategy file    
	
    rd1055/project/xp2/verilog/xp2_verilog.ldf		                --> Lattice Diamond project file   
    rd1055/project/xp2/verilog/xp2_verilog.lpf                          --> preference file             
    rd1055/project/xp2/verilog/xp2_verilog1.sty                         --> strategy file 	
	
    rd1055/project/xp2/vhdl/xp2_vhdl.ldf				--> Lattice Diamond project file   
    rd1055/project/xp2/vhdl/xp2_vhdl.lpf         	 		--> preference file           
    rd1055/project/xp2/vhdl/xp2_vhdl1.sty        	 		--> strategy file 
	

 3. rd1055/simulation/xo/verilog/rtl_verilog.do			--> RTL simulation script file for verilog
    rd1055/simulation/xo/verilog/timing_verilog.do		--> Timing simulation script file for verilog 

    rd1055/simulation/xo/vhdl/rtl_vhdl.do			--> RTL simulation script file for vhdl
    rd1055/simulation/xo/vhdl/timing_vhdl.do			--> Timing simulation script file for vhdl 
   

    rd1055/simulation/xo2/verilog/rtl_verilog.do	        --> RTL simulation script file for verilog
    rd1055/simulation/xo2/verilog/timing_verilog.do		--> Timing simulation script file for verilog  

    rd1055/simulation/xo2/vhdl/rtl_vhdl.do			--> RTL simulation script file for vhdl
    rd1055/simulation/xo2/vhdl/timing_vhdl.do			--> Timing simulation script file for vhdl 
    

    rd1055/simulation/xo3l/verilog/rtl_verilog.do		--> RTL simulation script file for verilog
    rd1055/simulation/xo3l/verilog/timing_verilog.do		--> Timing simulation script file for verilog 

    rd1055/simulation/xo3l/vhdl/rtl_vhdl.do			--> RTL simulation script file for vhdl
    rd1055/simulation/xo3l/vhdl/timing_vhdl.do			--> Timing simulation script file for vhdl 
    

    rd1055/simulation/xp2/verilog/rtl_verilog.do 		--> RTL simulation script file for verilog
    rd1055/simulation/xp2/verilog/timing_verilog.do		--> Timing simulation script file for verilog 

    rd1055/simulation/xp2/vhdl/rtl_vhdl.do			--> RTL simulation script file for vhdl
    rd1055/simulation/xp2/vhdl/timing_vhdl.do			--> Timing simulation script file for 



	
 4. rd1055/source/verilog/ACounter.v                     --> source file 
    rd1055/source/verilog/ErrLoc.v                       --> source file  
    rd1055/source/verilog/MFSM.v                         --> source file      
    rd1055/source/verilog/TFSM.v                         --> source file  
    rd1055/source/verilog/H_gen.v                        --> source file
    rd1055/source/verilog/nfcm_top.v                     --> source file - top level  
    rd1055/source/verilog/ipexpress/xo/ebr_buffer.v      --> source file generated from IPexpress for xo device
    rd1055/source/verilog/ipexpress/xo/ebr_buffer.ipx    --> configure file generated from IPexpress for xo device         

    rd1055/source/verilog/ipexpress/xp2/ebr_buffer.v     --> source file generated from IPexpress for xp2 device
    rd1055/source/verilog/ipexpress/xp2/ebr_buffer.ipx   --> configure file generated from IPexpress for xp2 device 
    
    rd1055/source/verilog/ipexpress/xo2/ebr_buffer.v     --> source file generated from IPexpress for xo2 device
    rd1055/source/verilog/ipexpress/xo2/ebr_buffer.ipx   --> configure file generated from IPexpress for xo2 device 
	
    rd1055/source/verilog/ipexpress/xo3l/ebr_buffer.v    --> source file generated from IPexpress for xo3l device
    rd1055/source/verilog/ipexpress/xo3l/ebr_buffer.ipx  --> configure file generated from IPexpress for xo3l device 

    rd1055/source/vhdl/ACounter.vhd                     --> source file 
    rd1055/source/vhdl/ErrLoc.vhd                       --> source file  
    rd1055/source/vhdl/MFSM.vhd                         --> source file      
    rd1055/source/vhdl/TFSM.vhd                         --> source file  
    rd1055/source/vhdl/H_gen.vhd                        --> source file
    rd1055/source/vhdl/nfcm_top.vhd                     --> source file - vhdl top level 
    rd1055/source/vhdl/ipexpress/xo/ebr_buffer.vhd      --> source file generated from IPexpress for xo device
    rd1055/source/vhdl/ipexpress/xo/ebr_buffer.ipx      --> configure file generated from IPexpress for xo device         

    rd1055/source/vhdl/ipexpress/xp2/ebr_buffer.vhd     --> source file generated from IPexpress for xp2 device
    rd1055/source/vhdl/ipexpress/xp2/ebr_buffer.ipx     --> configure file generated from IPexpress for xp2 device
    
    rd1055/source/vhdl/ipexpress/xo2/ebr_buffer.vhd     --> source file generated from IPexpress for xo2 device
    rd1055/source/vhdl/ipexpress/xo2/ebr_buffer.ipx     --> configure file generated from IPexpress for xo2 device

    rd1055/source/vhdl/ipexpress/xo3l/ebr_buffer.vhd     --> source file generated from IPexpress for xo3l device
    rd1055/source/vhdl/ipexpress/xo3l/ebr_buffer.ipx     --> configure file generated from IPexpress for xo3l device	
	
 5. rd1055/testbench/verilog/nfcm_tb.v                  --> top testbench for simulation 
    rd1055/testbench/verilog/flash_interface.v          --> flash interface source file for simulation   

    rd1055/testbench/vhdl/nfcm_tb.vhd                   --> top testbench for simulation 
    rd1055/testbench/vhdl/flash_interface.vhd           --> flash interface source file for simulation   
    
                                                                                                                                                                                                                  
===================================================================================================  
!!IMPORTANT NOTES:!!
1. Unzip the rd1055_revyy.y.zip file using the existing folder names, where yy.y is the current
   version of the zip file
2. If there is lpf file or lci file available for the reference design:
	2.1 copy the content of the provided lpf file to the <project_name>.lpf file under your ispLEVER project, 
	2.2 use Constraint Files >> Add >> Exiting File to import the lpf to Diamond project and set it to be active,
	2.3 copy the content of the provided lct file to the <project_name>.lct under your cpld project.  
4. If there is sty file (strategy file for Diamond) available for the design, go to File List tab on the left 
   side of the GUI. Right click on Strategies >> Add >> Existing File. Then right click on the imported file 
   name and select "Set as Active Strategy".

===================================================================================================  
Using ispLEVER or ispLEVER Classic software
---------------------------------------------------------------------------------------------------
HOW TO CREATE A ISPLEVER OR ISPLEVER CLASSIC PROJECT:
1. Bring up ISPLEVER OR ISPLEVER CLASSIC software, in the GUI, select File >> New Project
2. In the New Project popup, select the Project location, provide a Project name, select Design Entry Type 
   and click Next.
3. Use rd1055.pdf to see which device /speedgrade should be selected to achieve the desired timing result
4. Add the necessary source files from the rd1055\source directory, click Next
5. Click Finish. Now the project is successfully created. 
6. Make sure the provided lpf or lct is used in the current directory. 

---------------------------------------------------------------------------------------------------
HOW TO RUN SIMULATION FROM ISPLEVER OR ISPLEVER CLASSIC PROJECT:
1. Import the top-level testbench into the project as test fixture and associate with the device
	1.1 Import the rest as Testbench Dependency File by highligh and right click on the test bench file
2. In the Project Navigator, highlight the testbench file on the left-side panel, user will see 3 
   simulation options on the right panel.
3. For functional simulation, double click on Verilog (or VHDL) Functional Simulation with Aldec 
   Active-HDL. Aldec simulator will be brought up, click yes to overwrite the existing file. The 
   simulator will initialize and run for 1us.
4. Type "run 370us" for vhdl or "run -all" for verilog in the Console panel. A script similar to this 
   will be in the Console panel:
# KERNEL:                  652ns:  reset function 
# KERNEL:                  696  nfcm_tb.reset_cycle  	 	  << reset function over >>
# KERNEL:                 1052ns : auto block erase setup command
# KERNEL:                 1436ns : erase address:1234
# KERNEL:                 1852ns : read status command
# KERNEL:                 2136  nfcm_tb.erase_cycle  	 	  << erase no error >>
# KERNEL:                 2492ns : write page setup command
# KERNEL:               166924ns : write page row address:1234
# KERNEL:               166924ns : random data write command
# KERNEL:               168252ns : random write page column address:0835
# KERNEL:               168252ns : write page command
# KERNEL:               168668ns : read status command
# KERNEL:               168875  nfcm_tb.write_cycle  	 	  << Writing no error >>
# KERNEL:               169228ns : read page setup command
# KERNEL:               169836ns : read page row address:1234,column address:0000
# KERNEL:               169836ns : read page command
# KERNEL:               334108ns : random read page setup command
# KERNEL:               334492ns : random read page column address:0835
# KERNEL:               334492ns : random read page command
# KERNEL:               368440  nfcm_tb.read_cycle  	 	  << ecc no error >>
# KERNEL:               368796ns:  read ID function 
# KERNEL:               369020ns : id code:69
# KERNEL:               369132ns : id code:ec
# KERNEL:               369244ns : id code:f1
# KERNEL:               369356ns : id code:00
# KERNEL:               369448  nfcm_tb.read_id_cycle  	 	  << read id function over >>

   vhdl user will see a script shown in the Console panel
   like this:
run 370us
# KERNEL:               648 ns reset function 
# KERNEL:               696 ns << reset function over >> 
# KERNEL:              1048 ns reset function 
# KERNEL:              1432 ns auto block erase setup command 
# KERNEL:              1784 ns erase address:     0001001000110100
# KERNEL:              2072 ns << erase no error >> 
# KERNEL:              2424 ns read status command 
# KERNEL:            166856 ns write page setup command 
# KERNEL:            168184 ns write page row address:     0001001000110100
# KERNEL:            168184 ns random data write command 
# KERNEL:            168536 ns random write page column address: 0000100000110101
# KERNEL:            168536 ns write page command 
# KERNEL:            168747 ns << Writing no error >> 
# KERNEL:            169096 ns read status command 
# KERNEL:            169704 ns read page setup command 
# KERNEL:            333912 ns read page row address:     0001001000110100
# KERNEL:            333912 ns read page column address: 0000000000000000
# KERNEL:            333912 ns read page command 
# KERNEL:            334296 ns random read page setup command 
# KERNEL:            368248 ns << ecc no error >> 
# KERNEL:            368600 ns random read page column address: 0000100000110101
# KERNEL:            368600 ns random read page command 
# KERNEL:            368824 ns id code :     00000000
# KERNEL:            368936 ns id code :     11101100
# KERNEL:            369048 ns id code :     11110001
# KERNEL:            369160 ns id code :     00000000
# KERNEL:            369256 ns << read id function over >> 
# KERNEL: stopped at time: 370 us
	

5. For timing simulation, double click on Verilog (or VHDL) Post-Route Timing Simulation with Aldec 
   Active-HDL. Similar message will be shown in the console panel of the Aldec Active-HDL simulator.
   5.1 Run 370us to see the complete simulation
   5.1 In timing simulation you may see some warnings about narrow widths or vital glitches. These 
       warnings can be ignored. 
   5.2 Vital glitches can be removed by added a vsim command in the udo file. Use the udo.example 
       under the \project directory
   
===================================================================================================  
Using Diamond Software
---------------------------------------------------------------------------------------------------  
HOW TO CREATE A PROJECT IN DIAMOND:
1. Launch Diamond software, in the GUI, select File >> New Project, click Next
2. In the New Project popup, select the Project location and provide a Project name and implementation 
   name, click Next.
3. Add the necessary source files from the rd1055\source directory, click Next
4. Select the desired part and speedgrade. You may use rd1055.pdf to see which device and speedgrade 
   can be selected to achieve the published timing result 
5. Click Finish. Now the project is successfully created. 
6. MAKE SURE the provided lpf and/or sty files are used in the current directory. 
      
----------------------------------------------------------------------------------------------------      
HOW TO RUN SIMULATION UNDER DIAMOND:
1. Bring up the Simulation Wizard under the Tools menu 
2. Next provide a name for simulation project, and select RTL or post-route simulation
	2.1 For post-route simulation, must export verilog or vhdl simulation file after Place and Route
3. Next add the test bench files form the rd1055\TestBench directory 
	3.1 For VHDL, make sure the top-level test bench is last to be added
4. Next click Finish, this will bring up the Aldec simulator automatically
5. In Aldec environment, you can manually activate the simulation or you can use a script
	5.1 Use the provided script in the rd1055\Simulation\<language> directory
	  a. For functional simulation, change the library name to the device family
	  	i) MachXO2: ovi_machxo2 for verilog, machxo2 for vhdl
	  	ii) MachXO: ovi_machxo for verilog, machxo for vhdl
	  	iii)XP2: ovi_xp2 for verilog, xp2 for vhdl
		iv)MachXO3L: ovi_machxo3l for verilog, machxo3l for vhdl.
		b. For POST-ROUTE simulation, open the script and change the following:
			i) The sdf file name and the path pointing to your sdf file.
		   The path usually looks like "./<implementation_name>/<sdf_file_name>.sdf"
		  ii) Change the library name using the library name described above
		c. Click Tools > Execute Macro and select the xxx.do file to run the simulation
		d. This will run the simulation until finish
	5.2 Manually activate the simulation
		a. Click Simulation > Initialize Simulation
		b. Click File > New > Waveform, this will bring up the Waveform panel
		c. Click on the top-level testbench, drag all the signals into the Waveform panel
		d. At the Console panel, type "run 1500us" for VHDL simulation, or "run -all" for Verilog 
		   simulation
		e. For timing simulation, you must manually add 
		   -sdfmax nfcm = "../xo3l_verilog_synplify_vo.sdf"
		   into the asim or vsim command. Use the command in timing_xxx.do as an example
6. The simulation result will be similar to the one described in ispLEVER simulation section. 
