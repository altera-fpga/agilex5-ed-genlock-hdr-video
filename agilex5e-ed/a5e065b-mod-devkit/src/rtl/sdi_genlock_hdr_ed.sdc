# (C) 2001-2026 Altera Corporation. All rights reserved.
# Your use of Altera Corporation's design tools, logic functions and other 
# software and tools, and its AMPP partner logic functions, and any output 
# files from any of the foregoing (including device programming or simulation 
# files), and any associated documentation or information are expressly subject 
# to the terms and conditions of the Altera Program License Subscription 
# Agreement, Altera IP License Agreement, or other applicable 
# license agreement, including, without limitation, that your use is for the 
# sole purpose of programming logic devices manufactured by Altera and sold by 
# Altera or its authorized distributors.  Please refer to the applicable 
# agreement for further details.


#**************************************************************
# Time Information
#**************************************************************
set_time_format -unit ns -decimal_places 3
derive_clock_uncertainty

#**************************************************************
# Tcl Procedure to create Rx clk group
#**************************************************************
proc set_rxclk_grp { sdi_rx_name rxphy_top_name } {

    # List out all the transceiver recovered clocks that are clocking rx_sdi instance registers (register Vsync and Hsync are used as reference)
    # Hsync reg could be recognized as separate clock, due to its function in pfd block in a parallel loopback design.
    # Vsync reg is clocked by rx_clkout2 from Direct PHY IP
    # Rx_ready_sync signal in PHY adapter block is clocked by rx_clkout from Direct PHY IP
    set rx_clkout_H_list [query_collection -all -list_format [get_clocks -nowarn -of_objects [get_keepers "${sdi_rx_name}|u_rx_protocol|sdi_receive_gen[0].u_receive|u_trs|H"]]]
    set rx_clkout_list   [query_collection -all -list_format [get_clocks -nowarn -of_objects [get_keepers "${rxphy_top_name}sdi_phy_adapter_inst|rx_comp_gen.rxdata_3ghd_gen.rx_3ghd_fifo_rdreq"]]]
    set rx_sysclk_list   [query_collection -all -list_format [get_clocks -nowarn -of_objects [get_keepers "${rxphy_top_name}sdi_phy_adapter_inst|rx_comp_gen.gxb_rx_ready_sync_inst|din_s1"]]]

    set i 0
    foreach rx_clkout_H $rx_clkout_H_list {
        set rx${i}_clkout_H $rx_clkout_H
        incr i
    }

    set i 0
    foreach rx_clkout $rx_clkout_list {
        set rx${i}_clkout $rx_clkout
        incr i
    }

    set i 0
    foreach rx_sysclk $rx_sysclk_list {
        set rx${i}_sysclk $rx_sysclk
        incr i
    }

    # Multi rate SDI will have 4 profiles while Triple rate SDI will have 2
    # Compare clkout and Hsync regs' clocks, include Hsync clock into the clock group function if they are different.
    if { [get_collection_size [get_clocks -nowarn -of_objects [get_keepers "${rxphy_top_name}sdi_phy_adapter_inst|rx_comp_gen.rxdata_3ghd_gen.rx_3ghd_fifo_rdreq"]]] == 4 } {
        if { [get_collection_size [get_clocks -nowarn -of_objects [get_keepers "${sdi_rx_name}|u_rx_protocol|sdi_receive_gen[0].u_receive|u_trs|H"]]] == 0 ||
             [string equal $rx0_clkout $rx0_clkout_H] } {
            set_clock_groups -physically_exclusive  -group [get_clocks "$rx0_clkout $rx0_sysclk"] \
                                                    -group [get_clocks "$rx1_clkout $rx1_sysclk"] \
                                                    -group [get_clocks "$rx2_clkout $rx2_sysclk"] \
                                                    -group [get_clocks "$rx3_clkout $rx3_sysclk"] \
        } else {
            set_clock_groups -physically_exclusive  -group [get_clocks "$rx0_clkout $rx0_clkout_H $rx0_sysclk"] \
                                                    -group [get_clocks "$rx1_clkout $rx1_clkout_H $rx1_sysclk"] \
                                                    -group [get_clocks "$rx2_clkout $rx2_clkout_H $rx2_sysclk"] \
                                                    -group [get_clocks "$rx3_clkout $rx3_clkout_H $rx3_sysclk"] \
        }
    } elseif { [get_collection_size [get_clocks -nowarn -of_objects [get_keepers "${rxphy_top_name}sdi_phy_adapter_inst|rx_comp_gen.rxdata_3ghd_gen.rx_3ghd_fifo_rdreq"]]] == 2 } {
        if { [get_collection_size [get_clocks -nowarn -of_objects [get_keepers "${sdi_rx_name}|u_rx_protocol|sdi_receive_gen[0].u_receive|u_trs|H"]]] == 0 ||
             [string equal $rx0_clkout $rx0_clkout_H] } {
            set_clock_groups -physically_exclusive  -group [get_clocks "$rx0_clkout $rx0_sysclk"] \
                                                    -group [get_clocks "$rx1_clkout $rx1_sysclk"]
        } else {
            set_clock_groups -physically_exclusive  -group [get_clocks "$rx0_clkout $rx0_clkout_H $rx0_sysclk"] \
                                                    -group [get_clocks "$rx1_clkout $rx1_clkout_H $rx1_sysclk"]
        }
    }
}

#**************************************************************
# Create Clock
#**************************************************************
create_clock -period "312.5 MHz"    -name {syspll_refclk} {syspll_refclk}
create_clock -period "148.5 MHz"    -name {xcvr_refclk_1485} {xcvr_refclk_1485}
create_clock -period "297 MHz"      -name {txpll_refclk} {txpll_refclk}


#**************************************************************
# Create clock groups by calling proc on top
#**************************************************************
set_rxclk_grp nios_inst|sdi_rx_mr|sdi_rx_mr|sdi_rx_inst|rx_sdi     rx_inst|

# Reset to fpga is asynchronous
set_false_path -from [get_ports fpga_core_resetn]

set_false_path -to   [get_ports fmc_lmh1983_init]
set_false_path -to   [get_ports fmc_fpga_fldn]
set_false_path -to   [get_ports fmc_fpga_vsyncn]
set_false_path -to   [get_ports fmc_fpga_hsyncn]

set_false_path -to   [get_ports i2c_sdi_scl]
set_false_path -from [get_ports i2c_sdi_scl]
set_false_path -to   [get_ports i2c_sdi_sda]
set_false_path -from [get_ports i2c_sdi_sda]

set_false_path -to   [get_ports i2c_clocks_scl]
set_false_path -from [get_ports i2c_clocks_scl]
set_false_path -to   [get_ports i2c_clocks_sda]
set_false_path -from [get_ports i2c_clocks_sda]

set_false_path -to   [get_ports i2c_max10_scl]
set_false_path -from [get_ports i2c_max10_scl]
set_false_path -to   [get_ports i2c_max10_sda]
set_false_path -from [get_ports i2c_max10_sda]

set_output_delay -add_delay -max -clock_fall -clock [get_clocks axi4s_clk_iopll_inst|axi4s_clk_iopll|tennm_ph2_iopll|ref_clk0] -source_latency_included 0 [get_ports {fmc_fpga_fldn}]
set_output_delay -add_delay -min -clock_fall -clock [get_clocks axi4s_clk_iopll_inst|axi4s_clk_iopll|tennm_ph2_iopll|ref_clk0] -source_latency_included 0 [get_ports {fmc_fpga_fldn}]
set_output_delay -add_delay -max -clock_fall -clock [get_clocks axi4s_clk_iopll_inst|axi4s_clk_iopll|tennm_ph2_iopll|ref_clk0] -source_latency_included 0 [get_ports {fmc_fpga_vsyncn}]
set_output_delay -add_delay -min -clock_fall -clock [get_clocks axi4s_clk_iopll_inst|axi4s_clk_iopll|tennm_ph2_iopll|ref_clk0] -source_latency_included 0 [get_ports {fmc_fpga_vsyncn}]
set_output_delay -add_delay -max -clock_fall -clock [get_clocks axi4s_clk_iopll_inst|axi4s_clk_iopll|tennm_ph2_iopll|ref_clk0] -source_latency_included 0 [get_ports {fmc_fpga_hsyncn}]
set_output_delay -add_delay -min -clock_fall -clock [get_clocks axi4s_clk_iopll_inst|axi4s_clk_iopll|tennm_ph2_iopll|ref_clk0] -source_latency_included 0 [get_ports {fmc_fpga_hsyncn}]
set_output_delay -add_delay -max -clock_fall -clock [get_clocks axi4s_clk_iopll_inst|axi4s_clk_iopll|tennm_ph2_iopll|ref_clk0] -source_latency_included 0 [get_ports {fmc_lmh1983_init}]
set_output_delay -add_delay -min -clock_fall -clock [get_clocks axi4s_clk_iopll_inst|axi4s_clk_iopll|tennm_ph2_iopll|ref_clk0] -source_latency_included 0 [get_ports {fmc_lmh1983_init}]

