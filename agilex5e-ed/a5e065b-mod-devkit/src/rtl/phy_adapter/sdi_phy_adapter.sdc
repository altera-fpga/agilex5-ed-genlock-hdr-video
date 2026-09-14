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


set rx_12g_fifo_clrn_collection [get_pins -nowarn -nocase -compatibility_mode *rx_comp_gen.rxdata_12g_gen.rxdata_12g_fifo_inst*|*|clrn]
foreach_in_collection pin $rx_12g_fifo_clrn_collection {
   set_false_path -to [get_pins -nocase -compatibility_mode *rx_comp_gen.rxdata_12g_gen.rxdata_12g_fifo_inst*|*|clrn]
}

set rx_6g_fifo_clrn_collection [get_pins -nowarn -nocase -compatibility_mode *rx_comp_gen.rxdata_6g_gen.rxdata_6g_fifo_inst*|*|clrn]
foreach_in_collection pin $rx_6g_fifo_clrn_collection {
   set_false_path -to [get_pins -nocase -compatibility_mode *rx_comp_gen.rxdata_6g_gen.rxdata_6g_fifo_inst*|*|clrn]
}

set rx_3ghd_fifo_clrn_collection [get_pins -nowarn -nocase -compatibility_mode *rx_comp_gen.rxdata_3ghd_gen.rxdata_3ghd_fifo_inst*|*|clrn]
foreach_in_collection pin $rx_3ghd_fifo_clrn_collection {
   set_false_path -to [get_pins -nocase -compatibility_mode *rx_comp_gen.rxdata_3ghd_gen.rxdata_3ghd_fifo_inst*|*|clrn]
}

set tx_fifo_clrn_collection [get_pins -nowarn -nocase -compatibility_mode *tx_comp_gen.txdata_dcfifo_inst*|*|clrn]
foreach_in_collection pin $tx_fifo_clrn_collection {
   set_false_path -to [get_pins -nocase -compatibility_mode *tx_comp_gen.txdata_dcfifo_inst*|*|clrn]
}
