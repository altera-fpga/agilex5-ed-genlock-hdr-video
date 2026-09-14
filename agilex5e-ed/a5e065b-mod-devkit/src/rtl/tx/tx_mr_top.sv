// (C) 2001-2026 Altera Corporation. All rights reserved.
// Your use of Altera Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files from any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Altera Program License Subscription 
// Agreement, Altera IP License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Altera and sold by 
// Altera or its authorized distributors.  Please refer to the applicable 
// agreement for further details.


module tx_mr_top #(
    parameter           NUM_STREAMS = 1,
    parameter           TXPLL_REFCLK_PWRUP_FREQ = "148.5",
    parameter [14:0]    MRPHY_TX_BASE_PROFILE = 15'd1
)(
    // TX SDI clock
    input  logic                        sdi_tx_pclk,

    // TX Reference Reset
    input  logic                        tx_phy_reset,
    output logic                        tx_vid_clkout,

    // TX Video Signal Interface
    input logic [NUM_STREAMS*20-1:0]    sdi_tx_dataout,

    // System PLL Link clock
    input  logic                        system_pll_clk,

    // TX Transceiver clock
    input  logic                        tx_pll_refclk,

    // TX Reset Sequencer Interface
    input  logic                        pma_cu_clk,
    input  logic                        system_pll_lock,
    input  logic                        src_rs_grant,
    output logic                        src_rs_req,

    // TX Transceiver Interface
    output logic                        tx_pll_locked,
    output logic                        gxb_tx_reset_ack,
    output logic                        gxb_tx_serial_data,
    output logic                        gxb_tx_serial_data_n,
    output logic                        gxb_tx_ready
);

// ----------------------
// Signal Declaration
// ----------------------
logic                       tx_syspll_clkout;
logic [79:0]                tx_parallel_data;
logic                       tx_cadence;

sdi_phy_adapter #(
    .VIDEO_STANDARD     ("mr"),
    .DIRECTION          ("tx")
) sdi_phy_adapter_inst (
// Input Clocks and reset
    .tx_reset           (tx_phy_reset),
    .tx_syspll_clkout   (tx_syspll_clkout),
    .tx_vid_clkout      (sdi_tx_pclk),
    .rx_reset           (1'b0),
    .rx_syspll_clkout   (1'b0),
    .rx_vid_clkout      (1'b0),

// Inputs
    .gxb_tx_ready       (gxb_tx_ready),
    .tx_cadence         (tx_cadence),
    .sdi_txdata         (sdi_tx_dataout),
    .gxb_rx_ready       (1'b0),
    .rx_parallel_data   (80'd0),
    .rx_vid_std         (3'd0),

// Outputs
    .tx_parallel_data   (tx_parallel_data),
    .rxdata_to_sdi      ()
);


// -----------
// SDI Tx PHY
// -----------
dphy_tx sdi_tx_phy_inst (
// Input Clocks and reset
    .i_tx_coreclkin                     (tx_syspll_clkout),
    .i_tx_cadence_fast_clk              (tx_syspll_clkout),
    .i_tx_cadence_slow_clk              (sdi_tx_pclk),
    .i_system_pll_clk                   (system_pll_clk),
    .i_pma_cu_clk                       (pma_cu_clk),
    .i_tx_pll_refclk_p                  (tx_pll_refclk),
    .i_tx_reset                         (tx_phy_reset),
// Output clocks and reset
    .o_tx_clkout                        (tx_syspll_clkout),
    .o_tx_clkout2                       (tx_vid_clkout),
    .o_tx_reset_ack                     (gxb_tx_reset_ack),
// Input
    .i_system_pll_lock                  (system_pll_lock),
    .i_src_rs_grant                     (src_rs_grant),
    .i_tx_parallel_data                 (tx_parallel_data),

// Outputs
    .o_tx_serial_data                   (gxb_tx_serial_data),
    .o_tx_serial_data_n                 (gxb_tx_serial_data_n),
    .o_tx_ready                         (gxb_tx_ready),
    .o_src_rs_req                       (src_rs_req),
    .o_tx_cadence                       (tx_cadence),
    .o_tx_pll_locked                    (tx_pll_locked)
);
endmodule

