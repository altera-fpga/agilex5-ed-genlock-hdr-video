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


module rx_mr_top #(
    parameter           NUM_STREAMS             = 1,
    parameter [14:0]    MRPHY_RX_BASE_PROFILE   = 15'd1
)(
    // RX clock
    input  logic                        rx_rcfg_mgmt_clk,

    // RX Reference Reset
    input  logic                        rx_rcfg_mgmt_reset,

    // RX Video Signal Interface (Could be Interface with CVI)
    input  logic                        rx_vid_clkout,
    input  logic [2:0]                  rx_vid_std,
    input  logic                        rx_sdi_start_reconfig,
    output logic                        trig_rst_ctrl,
    output logic [NUM_STREAMS*20-1:0]   sdi_rx_datain,

    // RX Transceiver Interface
    input  logic                        gxb_rx_reset_ack,
    input  logic                        gxb_rx_ready,
    input  logic                        rx_syspll_clkout,
    input  logic [79:0]                 rx_parallel_data,

    // DR Interface
    input  logic [14:0]                 profile_id,
    input  logic                        dr_in_progress,
    input  logic                        dr_rx_avmm_readdata_valid,
    input  logic                        dr_rx_avmm_waitrequest,
    input  logic [31:0]                 dr_rx_avmm_readdata,
    output logic                        dr_rx_avmm_write,
    output logic                        dr_rx_avmm_read,
    output logic [31:0]                 dr_rx_avmm_writedata,
    output logic  [6:0]                 dr_rx_avmm_address,
    output logic                        cdr_reconfig_busy,
    output logic                        rx_sdi_reconfig_done
);

sdi_phy_adapter   #(
    .VIDEO_STANDARD     ("mr"),
    .DIRECTION          ("rx")
) sdi_phy_adapter_inst (
// Input Clocks and reset
    .rx_reset           (trig_rst_ctrl),
    .rx_syspll_clkout   (rx_syspll_clkout),
    .rx_vid_clkout      (rx_vid_clkout),
    .tx_reset           (1'b0),
    .tx_syspll_clkout   (1'b0),
    .tx_vid_clkout      (1'b0),

// Inputs
    .gxb_rx_ready       (gxb_rx_ready),
    .rx_parallel_data   (rx_parallel_data),

    .rx_vid_std         (rx_vid_std),
    .sdi_txdata         ({NUM_STREAMS{20'd0}}),
    .gxb_tx_ready       (1'b0),
    .tx_cadence         (1'b0),

// Outputs
    .tx_parallel_data   (),
    .rxdata_to_sdi      (sdi_rx_datain)
);

sdi_rx_dr_gts #(
    .MRPHY_RX_BASE_PROFILE  (MRPHY_RX_BASE_PROFILE),
    .VIDEO_STANDARD         ("mr")
) rx_rcfg_inst (
// Input Clocks and reset
    .clk                    (rx_rcfg_mgmt_clk),
    .reset                  (rx_rcfg_mgmt_reset),

// Inputs
    .xcvr_reset_ack         (gxb_rx_reset_ack),
    .sdi_reconfig_request   (rx_sdi_start_reconfig),
    .sdi_rx_std             (rx_vid_std),
    .dr_in_progress         (dr_in_progress),    
    .dr_curr_profile_id     (profile_id),
    .dr_avmm_readdata_valid (dr_rx_avmm_readdata_valid),
    .dr_avmm_waitrequest    (dr_rx_avmm_waitrequest),
    .dr_avmm_readdata       (dr_rx_avmm_readdata),

// Outputs
    .cdr_reconfig_busy      (cdr_reconfig_busy),
    .reconfig_done          (rx_sdi_reconfig_done),
    .dr_avmm_write          (dr_rx_avmm_write),
    .dr_avmm_read           (dr_rx_avmm_read),
    .dr_avmm_address        (dr_rx_avmm_address),
    .dr_avmm_writedata      (dr_rx_avmm_writedata)
);
endmodule

