# Project setup with sdi_genlock_hdr_ed.qsf 
set prj_top [file join .. .. sdi_genlock_hdr_ed.qsf]
project_open $prj_top

post_message [pwd]
puts [pwd]

# Project setup with qsys system
set prj_vds [file join src vds nios nios.vds]

post_message [pwd]
puts [pwd]

load_package vds
# project_new sdi_genlock_hdr_ed
# 
# Info: Current script was exported with Quartus Prime Pro Release 26.1.1 Build 130
# 
regexp {[\.0-9]+} $quartus(version) import_release
if {$import_release != "26.1.1"} {
	post_message -type error "Cannot import script exported from Quartus Prime Pro version \"26.1.1 Build 130\" into current release \"$import_release\".\n\tOpen, upgrade, and validate the original system in VDS to ensure design correctness."
	return
}
proc get_current_hier {} {
set current_hier [vds::get_current_hier]
if {$current_hier == "|"} {
	set current_hier ""
}
return $current_hier
}

vds::create_system nios
vds::create_cell -vlnv altera.com:ip:altera_clock_bridge:19.2.0 axi4s_clock_bridge
vds::create_cell -vlnv altera.com:ip:altera_reset_bridge:19.2.0 axi4s_reset_bridge
vds::create_cell -properties { parameters:enableDebugReset {true} parameters:resetSlave {onchip_mem.s1}  } -vlnv altera.com:ip:intel_niosv_m:26.0.0 cpu
vds::create_cell -properties { parameters:EXPLICIT_CLOCK_RATE {100000000}  } -vlnv altera.com:ip:altera_clock_bridge:19.2.0 cpu_clock_bridge
vds::create_cell -properties { parameters:readBufferDepth {1024} parameters:readIRQThreshold {1} parameters:writeBufferDepth {1024} parameters:writeIRQThreshold {1}  } -vlnv altera.com:ip:altera_avalon_jtag_uart:19.3.2 cpu_jtag_debug
vds::create_cell -vlnv altera.com:ip:altera_reset_bridge:19.2.0 cpu_reset_bridge
vds::create_cell -properties { parameters:FIFO_DEPTH {32}  } -vlnv altera.com:ip:altera_avalon_i2c:19.2.6 i2c_0
vds::create_cell -properties { parameters:FIFO_DEPTH {32}  } -vlnv altera.com:ip:altera_avalon_i2c:19.2.6 i2c_clocks
vds::create_cell -properties { parameters:FIFO_DEPTH {32}  } -vlnv altera.com:ip:altera_avalon_i2c:19.2.6 i2c_max10
vds::create_cell -vlnv altera.com:ip:altera_avalon_timer:19.3.5 nios_timer
vds::create_cell -properties { parameters:memorySize {262144}  } -vlnv altera.com:ip:intel_onchip_memory:2.0.0 onchip_mem
vds::create_cell -properties { parameters:direction {InOut} parameters:width {1}  } -vlnv altera.com:ip:altera_avalon_pio:19.2.4 pio_systempll
vds::create_cell -properties { parameters:AXIS_VIDEOIF_EN {1} parameters:BPS {10} parameters:DIRECTION {rx} parameters:ED_TXPLL_TYPE {fPLL} parameters:RX_CORECLK_FREQ {100.0} parameters:RX_EN_VPID_EXTRACT {1} parameters:TEST_RECONFIG_SEQ {half} parameters:TEST_SYNC_OUTPUT {0} parameters:VIDEO_STANDARD {mr} parameters:WRAPPER_OPT {0}  } -vlnv altera.com:ip:altera_sdi_ii_gts:2.5.0 sdi_rx_mr
vds::create_cell -properties { parameters:AXIS_VIDEOIF_EN {1} parameters:BPS {10} parameters:ED_TXPLL_TYPE {fPLL} parameters:TEST_RECONFIG_SEQ {half} parameters:TEST_SYNC_OUTPUT {0} parameters:TX_EN_VPID_INSERT {1} parameters:VIDEO_STANDARD {mr} parameters:WRAPPER_OPT {0}  } -vlnv altera.com:ip:altera_sdi_ii_gts:2.5.0 sdi_tx_mr
vds::create_cell -properties { parameters:BPS_IN {10} parameters:BPS_OUT {10} parameters:LUT_INIT_0 {1} parameters:LUT_INIT_1 {1} parameters:LUT_INIT_FILENAME_0 {pq_bt709} parameters:LUT_INIT_FILENAME_1 {hlg_bt709} parameters:PIXELS_IN_PARALLEL {2} parameters:SEPARATE_SLAVE_CLOCK {1}  } -vlnv altera.com:ip:intel_vvp_3d_lut:24.7.0 vvp_3d_lut_10
vds::create_cell -properties { parameters:BPS_IN {10} parameters:BPS_OUT {10} parameters:LUT_INIT_0 {1} parameters:LUT_INIT_1 {1} parameters:LUT_INIT_FILENAME_0 {slog3_bt709} parameters:LUT_INIT_FILENAME_1 {slog3_bt709_opt2} parameters:PIXELS_IN_PARALLEL {2} parameters:SEPARATE_SLAVE_CLOCK {1}  } -vlnv altera.com:ip:intel_vvp_3d_lut:24.7.0 vvp_3d_lut_20
vds::create_cell -properties { parameters:BPS {10} parameters:NUMBER_OF_COLOR_PLANES {3} parameters:OUTPUTS {3} parameters:OUT_0_FIFO {1} parameters:OUT_0_FIFO_DEPTH {4096} parameters:OUT_1_FIFO {1} parameters:OUT_1_FIFO_DEPTH {4096} parameters:OUT_2_FIFO {1} parameters:OUT_2_FIFO_DEPTH {4096} parameters:PIXELS_IN_PARALLEL {2} parameters:VVP_INTF_TYPE {Lite}  } -vlnv altera.com:ip:intel_vvp_axi4s_broadcaster:24.5.0 vvp_axi4s_broadcaster_0
vds::create_cell -properties { parameters:BPS {10} parameters:CLIPPING_METHOD {RECTANGLE} parameters:ENABLE_DEBUG {1} parameters:EXTERNAL_MODE {1} parameters:NUMBER_OF_COLOR_PLANES {3} parameters:PIXELS_IN_PARALLEL {2} parameters:RUNTIME_CONTROL {1} parameters:SEPARATE_SLAVE_CLOCK {1}  } -vlnv altera.com:ip:intel_vvp_clipper:24.8.0 vvp_clipper_0
vds::create_cell -properties { parameters:BPS {10} parameters:CLIPPING_METHOD {RECTANGLE} parameters:ENABLE_DEBUG {1} parameters:EXTERNAL_MODE {1} parameters:NUMBER_OF_COLOR_PLANES {3} parameters:PIXELS_IN_PARALLEL {2} parameters:RUNTIME_CONTROL {1} parameters:SEPARATE_SLAVE_CLOCK {1}  } -vlnv altera.com:ip:intel_vvp_clipper:24.8.0 vvp_clipper_1
vds::create_cell -properties { parameters:BPS {10} parameters:CLIPPING_METHOD {RECTANGLE} parameters:ENABLE_DEBUG {1} parameters:EXTERNAL_MODE {1} parameters:NUMBER_OF_COLOR_PLANES {3} parameters:PIXELS_IN_PARALLEL {2} parameters:RUNTIME_CONTROL {1} parameters:SEPARATE_SLAVE_CLOCK {1}  } -vlnv altera.com:ip:intel_vvp_clipper:24.8.0 vvp_clipper_2
vds::create_cell -properties { parameters:BPS {10} parameters:HORIZ_ALGORITHM {FILTERED} parameters:MAX_WIDTH {4096} parameters:PIPELINE_READY {1} parameters:PIXELS_IN_PARALLEL_IN {2} parameters:PIXELS_IN_PARALLEL_OUT {2} parameters:SUPPORT_420_TO_444 {1} parameters:SUPPORT_444_PASS {1} parameters:VERT_ALGORITHM {FILTERED}  } -vlnv altera.com:ip:intel_vvp_crs:24.8.0 vvp_crs_rx
vds::create_cell -properties { parameters:BPS {10} parameters:ENABLE_DEBUG {1} parameters:HORIZ_ALGORITHM {FILTERED} parameters:MAX_WIDTH {4096} parameters:PIPELINE_READY {1} parameters:PIXELS_IN_PARALLEL_IN {2} parameters:PIXELS_IN_PARALLEL_OUT {2} parameters:RUNTIME_CONTROL {1} parameters:SEPARATE_SLAVE_CLOCK {1} parameters:SUPPORT_422_TO_444 {0} parameters:SUPPORT_444_PASS {1} parameters:SUPPORT_444_TO_420 {1} parameters:SUPPORT_444_TO_422 {1} parameters:VERT_ALGORITHM {FILTERED}  } -vlnv altera.com:ip:intel_vvp_crs:24.8.0 vvp_crs_tx
vds::create_cell -properties { parameters:BPS_IN {10} parameters:BPS_OUT {10} parameters:COEFFICIENT_INT_BITS {2} parameters:ENABLE_DEBUG {1} parameters:PIPELINE_READY {1} parameters:PIXELS_IN_PARALLEL {2} parameters:RUNTIME_CONTROL {1} parameters:SEPARATE_SLAVE_CLOCK {1} parameters:SUMMAND_INT_BITS {11} parameters:SUMMAND_SIGNED {1}  } -vlnv altera.com:ip:intel_vvp_csc:24.8.0 vvp_csc_rx
vds::create_cell -properties { parameters:BPS_IN {10} parameters:BPS_OUT {10} parameters:COEFFICIENT_INT_BITS {2} parameters:ENABLE_DEBUG {1} parameters:PIPELINE_READY {1} parameters:PIXELS_IN_PARALLEL {2} parameters:RUNTIME_CONTROL {1} parameters:SEPARATE_SLAVE_CLOCK {1} parameters:SUMMAND_INT_BITS {11} parameters:SUMMAND_SIGNED {1}  } -vlnv altera.com:ip:intel_vvp_csc:24.8.0 vvp_csc_tx
vds::create_cell -properties { parameters:BPS {10} parameters:FIFO_DEPTH {8192} parameters:NUMBER_OF_COLOR_PLANES {3} parameters:PIPELINE_READY {1} parameters:PIXELS_IN_PARALLEL {2}  } -vlnv altera.com:ip:intel_vvp_fifo:24.5.0 vvp_fifo_rx
vds::create_cell -properties { parameters:BPS {10} parameters:FIFO_DEPTH {8192} parameters:NUMBER_OF_COLOR_PLANES {3} parameters:PIPELINE_READY {1} parameters:PIXELS_IN_PARALLEL {2}  } -vlnv altera.com:ip:intel_vvp_fifo:24.5.0 vvp_fifo_tx
vds::create_cell -properties { parameters:BPS {10} parameters:NUMBER_OF_COLOR_PLANES {3} parameters:OUTPUT_GUARD_BAND_LOWER_0 {4} parameters:OUTPUT_GUARD_BAND_LOWER_1 {4} parameters:OUTPUT_GUARD_BAND_LOWER_2 {4} parameters:OUTPUT_GUARD_BAND_UPPER_0 {1019} parameters:OUTPUT_GUARD_BAND_UPPER_1 {1019} parameters:OUTPUT_GUARD_BAND_UPPER_2 {1019} parameters:PIXELS_IN_PARALLEL {2}  } -vlnv altera.com:ip:intel_vvp_guard_bands:24.8.0 vvp_guard_bands_tx
vds::create_cell -properties { parameters:BLENDING_MODE_1 {1} parameters:BLENDING_MODE_2 {1} parameters:BLENDING_MODE_3 {1} parameters:BLENDING_MODE_4 {1} parameters:BLENDING_MODE_5 {1} parameters:BPS {10} parameters:ENABLE_DEBUG {1} parameters:EXTERNAL_MODE {1} parameters:NUMBER_OF_COLOR_PLANES {3} parameters:NUM_LAYERS {4} parameters:PIPELINE_LEVEL {2} parameters:PIXELS_IN_PARALLEL {2} parameters:SEPARATE_SLAVE_CLOCK {1}  } -vlnv altera.com:ip:intel_vvp_mixer:24.8.0 vvp_mixer_hdr
vds::create_cell -properties { parameters:BPS {10} parameters:INPUT_MODE {INTERNAL} parameters:NUMBER_OF_COLOR_PLANES {3} parameters:PIPELINE_READY {1} parameters:PIXELS_IN_PARALLEL {2}  } -vlnv altera.com:ip:intel_vvp_protocol_conv:24.9.0 vvp_protocol_conv_rx
vds::create_cell -properties { parameters:BPS {10} parameters:ENABLE_DEBUG {1} parameters:INPUT_MODE {EXTERNAL} parameters:NUMBER_OF_COLOR_PLANES {3} parameters:OUTPUT_MODE {INTERNAL} parameters:PIPELINE_READY {1} parameters:PIXELS_IN_PARALLEL {2} parameters:SEPARATE_SLAVE_CLOCK {1}  } -vlnv altera.com:ip:intel_vvp_protocol_conv:24.9.0 vvp_protocol_conv_tx
vds::create_cell -properties { parameters:BPS {10} parameters:CORE_PATTERN_0 {1} parameters:ENABLE_DEBUG {1} parameters:EXTERNAL_MODE {1} parameters:PIPELINE_READY {1} parameters:PIXELS_IN_PARALLEL {2} parameters:RUNTIME_CONTROL {1} parameters:SEPARATE_SLAVE_CLOCK {1}  } -vlnv altera.com:ip:intel_vvp_tpg:24.8.0 vvp_tpg_mixer
vds::connect_interface_net -dest cpu|dm_agent -src cpu|data_manager
vds::assign_base_address -connection cpu.data_manager/cpu.dm_agent 0x00040000
vds::connect_interface_net -dest cpu|dm_agent -src cpu|instruction_manager
vds::assign_base_address -connection cpu.instruction_manager/cpu.dm_agent 0x00040000
vds::connect_interface_net -dest cpu|timer_sw_agent -src cpu|data_manager
vds::assign_base_address -connection cpu.data_manager/cpu.timer_sw_agent 0x00052800
vds::connect_interface_net -dest vvp_csc_rx|av_mm_control_agent -src cpu|data_manager
vds::assign_base_address -connection cpu.data_manager/vvp_csc_rx.av_mm_control_agent 0x00052600
vds::connect_interface_net -dest vvp_tpg_mixer|av_mm_control_agent -src cpu|data_manager
vds::assign_base_address -connection cpu.data_manager/vvp_tpg_mixer.av_mm_control_agent 0x00052400
vds::connect_interface_net -dest vvp_mixer_hdr|av_mm_control_agent -src cpu|data_manager
vds::assign_base_address -connection cpu.data_manager/vvp_mixer_hdr.av_mm_control_agent 0x00050c00
vds::connect_interface_net -dest vvp_protocol_conv_tx|av_mm_control_agent -src cpu|data_manager
vds::assign_base_address -connection cpu.data_manager/vvp_protocol_conv_tx.av_mm_control_agent 0x00052200
vds::connect_interface_net -dest vvp_csc_tx|av_mm_control_agent -src cpu|data_manager
vds::assign_base_address -connection cpu.data_manager/vvp_csc_tx.av_mm_control_agent 0x00052000
vds::connect_interface_net -dest vvp_crs_tx|av_mm_control_agent -src cpu|data_manager
vds::assign_base_address -connection cpu.data_manager/vvp_crs_tx.av_mm_control_agent 0x00051e00
vds::connect_interface_net -dest vvp_clipper_1|av_mm_control_agent -src cpu|data_manager
vds::assign_base_address -connection cpu.data_manager/vvp_clipper_1.av_mm_control_agent 0x00051c00
vds::connect_interface_net -dest vvp_clipper_2|av_mm_control_agent -src cpu|data_manager
vds::assign_base_address -connection cpu.data_manager/vvp_clipper_2.av_mm_control_agent 0x00051a00
vds::connect_interface_net -dest vvp_clipper_0|av_mm_control_agent -src cpu|data_manager
vds::assign_base_address -connection cpu.data_manager/vvp_clipper_0.av_mm_control_agent 0x00051000
vds::connect_interface_net -dest vvp_3d_lut_20|av_mm_cpu_agent -src cpu|data_manager
vds::assign_base_address -connection cpu.data_manager/vvp_3d_lut_20.av_mm_cpu_agent 0x00051600
vds::connect_interface_net -dest vvp_3d_lut_10|av_mm_cpu_agent -src cpu|data_manager
vds::assign_base_address -connection cpu.data_manager/vvp_3d_lut_10.av_mm_cpu_agent 0x00051200
vds::connect_interface_net -dest cpu_jtag_debug|avalon_jtag_slave -src cpu|data_manager
vds::assign_base_address -connection cpu.data_manager/cpu_jtag_debug.avalon_jtag_slave 0x000528f0
vds::connect_interface_net -dest i2c_0|csr -src cpu|data_manager
vds::assign_base_address -connection cpu.data_manager/i2c_0.csr 0x00052880
vds::connect_interface_net -dest i2c_clocks|csr -src cpu|data_manager
vds::assign_base_address -connection cpu.data_manager/i2c_clocks.csr 0x00052840
vds::connect_interface_net -dest i2c_max10|csr -src cpu|data_manager
vds::assign_base_address -connection cpu.data_manager/i2c_max10.csr 0x00052900
vds::connect_interface_net -dest sdi_rx_mr|rx_av_mm_control -src cpu|data_manager
vds::assign_base_address -connection cpu.data_manager/sdi_rx_mr.rx_av_mm_control 0x00050800
vds::connect_interface_net -dest nios_timer|s1 -src cpu|data_manager
vds::assign_base_address -connection cpu.data_manager/nios_timer.s1 0x000528c0
vds::connect_interface_net -dest onchip_mem|s1 -src cpu|data_manager
vds::assign_base_address -connection cpu.data_manager/onchip_mem.s1 0x0000
vds::connect_interface_net -dest pio_systempll|s1 -src cpu|data_manager
vds::assign_base_address -connection cpu.data_manager/pio_systempll.s1 0x000528e0
vds::connect_interface_net -dest sdi_tx_mr|tx_av_mm_control -src cpu|data_manager
vds::assign_base_address -connection cpu.data_manager/sdi_tx_mr.tx_av_mm_control 0x00050000
vds::connect_interface_net -dest onchip_mem|s1 -src cpu|instruction_manager
vds::assign_base_address -connection cpu.instruction_manager/onchip_mem.s1 0x0000
vds::connect_interface_net -dest i2c_0|interrupt_sender -src cpu|platform_irq_rx
vds::set_interrupt_irq -connection cpu.platform_irq_rx/i2c_0.interrupt_sender 0
vds::connect_interface_net -dest i2c_clocks|interrupt_sender -src cpu|platform_irq_rx
vds::set_interrupt_irq -connection cpu.platform_irq_rx/i2c_clocks.interrupt_sender 3
vds::connect_interface_net -dest i2c_max10|interrupt_sender -src cpu|platform_irq_rx
vds::set_interrupt_irq -connection cpu.platform_irq_rx/i2c_max10.interrupt_sender 4
vds::connect_interface_net -dest cpu_jtag_debug|irq -src cpu|platform_irq_rx
vds::set_interrupt_irq -connection cpu.platform_irq_rx/cpu_jtag_debug.irq 1
vds::connect_interface_net -dest nios_timer|irq -src cpu|platform_irq_rx
vds::set_interrupt_irq -connection cpu.platform_irq_rx/nios_timer.irq 2
vds::connect_interface_net -dest vvp_fifo_rx|axi4s_vid_in -src sdi_rx_mr|rx_axi4s_vid_out
vds::connect_interface_net -dest sdi_tx_mr|tx_axi4s_vid_in -src vvp_fifo_tx|axi4s_vid_out
vds::connect_interface_net -dest vvp_clipper_1|axi4s_vid_in -src vvp_3d_lut_10|axi4s_vid_out
vds::connect_interface_net -dest vvp_3d_lut_10|axi4s_vid_in -src vvp_axi4s_broadcaster_0|axi4s_vid_out_1
vds::connect_interface_net -dest vvp_clipper_2|axi4s_vid_in -src vvp_3d_lut_20|axi4s_vid_out
vds::connect_interface_net -dest vvp_3d_lut_20|axi4s_vid_in -src vvp_axi4s_broadcaster_0|axi4s_vid_out_2
vds::connect_interface_net -dest vvp_clipper_0|axi4s_vid_in -src vvp_axi4s_broadcaster_0|axi4s_vid_out_0
vds::connect_interface_net -dest vvp_axi4s_broadcaster_0|axi4s_vid_in -src vvp_protocol_conv_rx|axi4s_vid_out
vds::connect_interface_net -dest vvp_mixer_hdr|axi4s_vid_1_in -src vvp_clipper_0|axi4s_vid_out
vds::connect_interface_net -dest vvp_mixer_hdr|axi4s_vid_2_in -src vvp_clipper_1|axi4s_vid_out
vds::connect_interface_net -dest vvp_mixer_hdr|axi4s_vid_3_in -src vvp_clipper_2|axi4s_vid_out
vds::connect_interface_net -dest vvp_csc_rx|axi4s_vid_in -src vvp_crs_rx|axi4s_vid_out
vds::connect_interface_net -dest vvp_crs_rx|axi4s_vid_in -src vvp_fifo_rx|axi4s_vid_out
vds::connect_interface_net -dest vvp_guard_bands_tx|axi4s_vid_in -src vvp_crs_tx|axi4s_vid_out
vds::connect_interface_net -dest vvp_crs_tx|axi4s_vid_in -src vvp_csc_tx|axi4s_vid_out
vds::connect_interface_net -dest vvp_protocol_conv_rx|axi4s_vid_in -src vvp_csc_rx|axi4s_vid_out
vds::connect_interface_net -dest vvp_csc_tx|axi4s_vid_in -src vvp_protocol_conv_tx|axi4s_vid_out
vds::connect_interface_net -dest vvp_fifo_tx|axi4s_vid_in -src vvp_guard_bands_tx|axi4s_vid_out
vds::connect_interface_net -dest vvp_protocol_conv_tx|axi4s_vid_in -src vvp_mixer_hdr|axi4s_vid_out
vds::connect_interface_net -dest vvp_mixer_hdr|axi4s_vid_0_in -src vvp_tpg_mixer|axi4s_vid_out
vds::export_interface_pin pio_systempll|external_connection pio_systempll_external_connection
vds::export_interface_pin i2c_max10|i2c_serial i2c_serial
vds::export_interface_pin i2c_clocks|i2c_serial i2c_clocks_i2c_serial
vds::export_interface_pin i2c_0|i2c_serial i2c_0_i2c_serial
vds::connect_net -src axi4s_clock_bridge|out_clk -dest axi4s_reset_bridge|clk
vds::connect_net -src axi4s_clock_bridge|out_clk -dest vvp_fifo_rx|main_clock
vds::connect_net -src axi4s_clock_bridge|out_clk -dest vvp_crs_rx|main_clock
vds::connect_net -src axi4s_clock_bridge|out_clk -dest vvp_csc_rx|main_clock
vds::connect_net -src axi4s_clock_bridge|out_clk -dest vvp_fifo_tx|main_clock
vds::connect_net -src axi4s_clock_bridge|out_clk -dest vvp_guard_bands_tx|main_clock
vds::connect_net -src axi4s_clock_bridge|out_clk -dest vvp_crs_tx|main_clock
vds::connect_net -src axi4s_clock_bridge|out_clk -dest vvp_csc_tx|main_clock
vds::connect_net -src axi4s_clock_bridge|out_clk -dest vvp_protocol_conv_tx|main_clock
vds::connect_net -src axi4s_clock_bridge|out_clk -dest vvp_mixer_hdr|main_clock
vds::connect_net -src axi4s_clock_bridge|out_clk -dest vvp_tpg_mixer|main_clock
vds::connect_net -src axi4s_clock_bridge|out_clk -dest vvp_protocol_conv_rx|main_clock
vds::connect_net -src axi4s_clock_bridge|out_clk -dest vvp_clipper_1|main_clock
vds::connect_net -src axi4s_clock_bridge|out_clk -dest vvp_clipper_2|main_clock
vds::connect_net -src axi4s_clock_bridge|out_clk -dest vvp_clipper_0|main_clock
vds::connect_net -src axi4s_clock_bridge|out_clk -dest sdi_rx_mr|rx_axi4s_clk
vds::connect_net -src axi4s_clock_bridge|out_clk -dest sdi_tx_mr|tx_axi4s_clk
vds::connect_net -src axi4s_clock_bridge|out_clk -dest vvp_3d_lut_20|vid_clock
vds::connect_net -src axi4s_clock_bridge|out_clk -dest vvp_3d_lut_10|vid_clock
vds::connect_net -src axi4s_clock_bridge|out_clk -dest vvp_axi4s_broadcaster_0|vid_clock
vds::export_pin axi4s_clock_bridge|in_clk axi4s_clock_bridge_in_clk
vds::connect_net -src axi4s_reset_bridge|out_reset -dest vvp_fifo_rx|main_reset
vds::connect_net -src axi4s_reset_bridge|out_reset -dest vvp_crs_rx|main_reset
vds::connect_net -src axi4s_reset_bridge|out_reset -dest vvp_csc_rx|main_reset
vds::connect_net -src axi4s_reset_bridge|out_reset -dest vvp_fifo_tx|main_reset
vds::connect_net -src axi4s_reset_bridge|out_reset -dest vvp_guard_bands_tx|main_reset
vds::connect_net -src axi4s_reset_bridge|out_reset -dest vvp_crs_tx|main_reset
vds::connect_net -src axi4s_reset_bridge|out_reset -dest vvp_csc_tx|main_reset
vds::connect_net -src axi4s_reset_bridge|out_reset -dest vvp_protocol_conv_tx|main_reset
vds::connect_net -src axi4s_reset_bridge|out_reset -dest vvp_mixer_hdr|main_reset
vds::connect_net -src axi4s_reset_bridge|out_reset -dest vvp_tpg_mixer|main_reset
vds::connect_net -src axi4s_reset_bridge|out_reset -dest vvp_protocol_conv_rx|main_reset
vds::connect_net -src axi4s_reset_bridge|out_reset -dest vvp_clipper_1|main_reset
vds::connect_net -src axi4s_reset_bridge|out_reset -dest vvp_clipper_2|main_reset
vds::connect_net -src axi4s_reset_bridge|out_reset -dest vvp_clipper_0|main_reset
vds::connect_net -src axi4s_reset_bridge|out_reset -dest sdi_rx_mr|rx_axi4s_reset
vds::connect_net -src axi4s_reset_bridge|out_reset -dest sdi_tx_mr|tx_axi4s_reset
vds::connect_net -src axi4s_reset_bridge|out_reset -dest vvp_3d_lut_20|vid_reset
vds::connect_net -src axi4s_reset_bridge|out_reset -dest vvp_3d_lut_10|vid_reset
vds::connect_net -src axi4s_reset_bridge|out_reset -dest vvp_axi4s_broadcaster_0|vid_reset
vds::export_pin axi4s_reset_bridge|in_reset axi4s_reset_bridge_in_reset
vds::export_pin cpu|dbg_reset_out cpu_dbg_reset_out
vds::connect_net -src cpu_clock_bridge|out_clk -dest vvp_csc_tx|agent_clock
vds::connect_net -src cpu_clock_bridge|out_clk -dest vvp_protocol_conv_tx|agent_clock
vds::connect_net -src cpu_clock_bridge|out_clk -dest vvp_mixer_hdr|agent_clock
vds::connect_net -src cpu_clock_bridge|out_clk -dest vvp_tpg_mixer|agent_clock
vds::connect_net -src cpu_clock_bridge|out_clk -dest vvp_csc_rx|agent_clock
vds::connect_net -src cpu_clock_bridge|out_clk -dest vvp_crs_tx|agent_clock
vds::connect_net -src cpu_clock_bridge|out_clk -dest vvp_clipper_1|agent_clock
vds::connect_net -src cpu_clock_bridge|out_clk -dest vvp_clipper_2|agent_clock
vds::connect_net -src cpu_clock_bridge|out_clk -dest vvp_clipper_0|agent_clock
vds::connect_net -src cpu_clock_bridge|out_clk -dest cpu|clk
vds::connect_net -src cpu_clock_bridge|out_clk -dest cpu_jtag_debug|clk
vds::connect_net -src cpu_clock_bridge|out_clk -dest cpu_reset_bridge|clk
vds::connect_net -src cpu_clock_bridge|out_clk -dest nios_timer|clk
vds::connect_net -src cpu_clock_bridge|out_clk -dest pio_systempll|clk
vds::connect_net -src cpu_clock_bridge|out_clk -dest onchip_mem|clk1
vds::connect_net -src cpu_clock_bridge|out_clk -dest i2c_0|clock
vds::connect_net -src cpu_clock_bridge|out_clk -dest i2c_clocks|clock
vds::connect_net -src cpu_clock_bridge|out_clk -dest i2c_max10|clock
vds::connect_net -src cpu_clock_bridge|out_clk -dest vvp_3d_lut_20|cpu_clock
vds::connect_net -src cpu_clock_bridge|out_clk -dest vvp_3d_lut_10|cpu_clock
vds::connect_net -src cpu_clock_bridge|out_clk -dest sdi_rx_mr|rx_mgmt_clk
vds::connect_net -src cpu_clock_bridge|out_clk -dest sdi_tx_mr|tx_mgmt_clk
vds::export_pin cpu_clock_bridge|in_clk cpu_clock_bridge_in_clk
vds::connect_net -src cpu_reset_bridge|out_reset -dest vvp_csc_tx|agent_reset
vds::connect_net -src cpu_reset_bridge|out_reset -dest vvp_protocol_conv_tx|agent_reset
vds::connect_net -src cpu_reset_bridge|out_reset -dest vvp_mixer_hdr|agent_reset
vds::connect_net -src cpu_reset_bridge|out_reset -dest vvp_tpg_mixer|agent_reset
vds::connect_net -src cpu_reset_bridge|out_reset -dest vvp_csc_rx|agent_reset
vds::connect_net -src cpu_reset_bridge|out_reset -dest vvp_crs_tx|agent_reset
vds::connect_net -src cpu_reset_bridge|out_reset -dest vvp_clipper_1|agent_reset
vds::connect_net -src cpu_reset_bridge|out_reset -dest vvp_clipper_2|agent_reset
vds::connect_net -src cpu_reset_bridge|out_reset -dest vvp_clipper_0|agent_reset
vds::connect_net -src cpu_reset_bridge|out_reset -dest vvp_3d_lut_20|cpu_reset
vds::connect_net -src cpu_reset_bridge|out_reset -dest vvp_3d_lut_10|cpu_reset
vds::connect_net -src cpu_reset_bridge|out_reset -dest cpu|ndm_reset_in
vds::connect_net -src cpu_reset_bridge|out_reset -dest cpu|reset
vds::connect_net -src cpu_reset_bridge|out_reset -dest cpu_jtag_debug|reset
vds::connect_net -src cpu_reset_bridge|out_reset -dest nios_timer|reset
vds::connect_net -src cpu_reset_bridge|out_reset -dest pio_systempll|reset
vds::connect_net -src cpu_reset_bridge|out_reset -dest onchip_mem|reset1
vds::connect_net -src cpu_reset_bridge|out_reset -dest i2c_0|reset_sink
vds::connect_net -src cpu_reset_bridge|out_reset -dest i2c_clocks|reset_sink
vds::connect_net -src cpu_reset_bridge|out_reset -dest i2c_max10|reset_sink
vds::connect_net -src cpu_reset_bridge|out_reset -dest sdi_rx_mr|rx_rst
vds::connect_net -src cpu_reset_bridge|out_reset -dest sdi_tx_mr|tx_rst
vds::export_pin cpu_reset_bridge|in_reset cpu_reset_bridge_in_reset
vds::export_pin sdi_rx_mr|gxb_ltd sdi_rx_mr_gxb_ltd
vds::export_pin sdi_rx_mr|rst_trig_rst sdi_rx_mr_rst_trig_rst
vds::export_pin sdi_rx_mr|rx_align_locked sdi_rx_mr_rx_align_locked
vds::export_pin sdi_rx_mr|rx_clkout_is_ntsc_paln sdi_rx_mr_rx_clkout_is_ntsc_paln
vds::export_pin sdi_rx_mr|rx_f sdi_rx_mr_rx_f
vds::export_pin sdi_rx_mr|rx_format sdi_rx_mr_rx_format
vds::export_pin sdi_rx_mr|rx_frame_locked sdi_rx_mr_rx_frame_locked
vds::export_pin sdi_rx_mr|rx_h sdi_rx_mr_rx_h
vds::export_pin sdi_rx_mr|rx_rst_proto_out sdi_rx_mr_rx_rst_proto_out
vds::export_pin sdi_rx_mr|rx_sdi_start_reconfig sdi_rx_mr_rx_sdi_start_reconfig
vds::export_pin sdi_rx_mr|rx_std sdi_rx_mr_rx_std
vds::export_pin sdi_rx_mr|rx_trs_locked sdi_rx_mr_rx_trs_locked
vds::export_pin sdi_rx_mr|rx_v sdi_rx_mr_rx_v
vds::export_pin sdi_rx_mr|rx_vpid_checksum_error sdi_rx_mr_rx_vpid_checksum_error
vds::export_pin sdi_rx_mr|rx_vpid_checksum_error_b sdi_rx_mr_rx_vpid_checksum_error_b
vds::export_pin sdi_rx_mr|trig_rst_ctrl sdi_rx_mr_trig_rst_ctrl
vds::export_pin sdi_rx_mr|rx_core_refclk sdi_rx_mr_rx_core_refclk
vds::export_pin sdi_rx_mr|rx_datain sdi_rx_mr_rx_datain
vds::export_pin sdi_rx_mr|rx_ready sdi_rx_mr_rx_ready
vds::export_pin sdi_rx_mr|rx_sdi_reconfig_done sdi_rx_mr_rx_sdi_reconfig_done
vds::export_pin sdi_rx_mr|rx_xcvr_reset_ack sdi_rx_mr_rx_xcvr_reset_ack
vds::export_pin sdi_rx_mr|xcvr_rxclk sdi_rx_mr_xcvr_rxclk
vds::export_pin sdi_tx_mr|tx_dataout sdi_tx_mr_tx_dataout
vds::export_pin sdi_tx_mr|tx_dataout_valid sdi_tx_mr_tx_dataout_valid
vds::export_pin sdi_tx_mr|tx_pclk sdi_tx_mr_tx_pclk
vds::set_domain_properties {qsys_mm.burstAdapterImplementation GENERIC_CONVERTER qsys_mm.clockCrossingAdapter AUTO qsys_mm.enableAllPipelines FALSE qsys_mm.enableEccProtection FALSE qsys_mm.enableInstrumentation FALSE qsys_mm.enableOutOfOrderSupport FALSE qsys_mm.fifoDepth 8 qsys_mm.insertDefaultSlave FALSE qsys_mm.interconnectResetSource DEFAULT qsys_mm.maxAdditionalLatency 1 qsys_mm.optimizeRdFifoSize FALSE qsys_mm.piplineType PIPELINE_STAGE qsys_mm.responseFifoType REGISTER_BASED qsys_mm.splitCommandsFor4KBoundary FALSE qsys_mm.syncResets TRUE qsys_mm.widthAdapterImplementation GENERIC_CONVERTER } cpu.data_manager
vds::sync_system_info
vds::validate_system
vds::save_system nios
post_message [pwd]
puts [pwd]
vds::generate_system -design_file $prj_vds -search_path $ -synthesis Verilog
vds::close_system nios

post_message "Script completed successfully."



