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


//This reference design file, and your use thereof, is subject to and         
//governed by the terms and conditions of the applicable Altera Reference     
//Design License Agreement.  By using this reference design file, you         
//indicate your acceptance of such terms and conditions between you and       
//Altera Corporation.  In the event that you do not agree with such terms and 
//conditions, you may not use the reference design file. Please promptly      
//destroy any copies you have made.                                           
//                                                                            
//This reference design file being provided on an "as-is" basis and as an     
//accommodation and therefore all warranties, representations or guarantees   
//of any kind (whether express, implied or statutory) including, without      
//limitation, warranties of merchantability, non-infringement, or fitness for 
//a particular purpose, are specifically disclaimed.  By making this          
//reference design file available, Altera expressly does not recommend,       
//suggest or require that this reference design file be used in combination   
//with any other product not provided by Altera.


// Uncomment this macro if you are using LMH1981 as sync separator for SD-SDI.
// `define USING_LMH1981_FOR_SD 1

module sdi_genlock_hdr_ed (
//Clocks Inputs
    input           syspll_refclk,      // 312.5 MHz default from Nextera FMC.
    input           clk_100mhz,         // 100 MHz default.
    input           xcvr_refclk_1485,   // 148.35 MHz default from Si569 U33 tab. Programed to 148.5 MHz via SW App.
    inout           i2c_sdi_sda,
    inout           i2c_sdi_scl,

//User-IO--------------------------------------------------------
    input           fpga_core_resetn,
    
//Clock Configuration--------------------------------------------
    inout           i2c_clocks_scl,
    inout           i2c_clocks_sda,
    inout           i2c_max10_scl,
    inout           i2c_max10_sda,
    
//SDI daughter card-----------------------------------------------
    input           txpll_refclk,       // Transceiver Ref Clocks - 297 / 296.7Mhz
    input           fmc_rx2_p,          // Transceiver Data FPGA RX
    input           fmc_rx2_n,
    output          lmk03328_pdn,       // LMK03328 Device Power Down (active low)
    output          fmc_lmh1983_init,   // LMH1983 Init
    output          fmc_fpga_fldn,      // Field sync signal to LMH1983
    output          fmc_fpga_vsyncn,    // V sync signal to LMH1983
    output          fmc_fpga_hsyncn,    // H sync signal to LMH1983    
    output          fmc_tx0_p,          // Transceiver Data FPGA TX
    output          fmc_tx0_n
);

localparam NUM_STREAMS = 4;
localparam NUM_DR_HOST = 1;
localparam DR_AVMM_ADDR_WIDTH = 7;
localparam DR_AVMM_DATA_WIDTH = 32;
localparam NUM_PROFILES = 4;
localparam DRMIFMEM_INIT_FILE = "support_logic/dr_top/synth/dr.mif";
// --------------------------------------------
// Signal Declaration
// --------------------------------------------
logic                                       sys_reset;
logic                                       sys_resetn;
logic                                       axi4s_reset;
logic                                       axi4s_clk;
logic                                       sdi_tx_reset;
logic                                       out_systempll_clk;
logic                                       sdi_rx_clkout;
logic                                       sdi_tx_clkout;
logic [NUM_STREAMS*20-1:0]                  sdi_tx_dataout;
logic [2:0]                                 sdi_rx_std;
logic [2:0]                                 rx_std_sync;
logic                                       sdi_rx_align_locked;
logic [NUM_STREAMS-1:0]                     sdi_rx_trs_locked;
logic                                       sdi_rx_frame_locked;
logic [NUM_STREAMS-1:0]                     sdi_rx_h;
logic [NUM_STREAMS-1:0]                     sdi_rx_f;
logic [NUM_STREAMS-1:0]                     sdi_rx_v;
logic                                       tx_pll_locked;
logic                                       gxb_tx_ready;
logic                                       cdr_reconfig_busy;
logic                                       rx_sdi_reconfig_done;
logic                                       gxb_ltd;
logic                                       gxb_ltd_sync;
logic                                       host_avmm_read;
logic                                       host_avmm_write;
logic                                       host_avmm_readdata_valid;
logic                                       host_avmm_waitrequest;
logic [DR_AVMM_ADDR_WIDTH-1:0]              host_avmm_address;
logic [DR_AVMM_DATA_WIDTH-1:0]              host_avmm_readdata;
logic [DR_AVMM_DATA_WIDTH-1:0]              host_avmm_writedata;
logic [14:0]                                profile_id;
logic                                       dr_in_progress;
logic                                       err_status;
logic                                       fast_sim_clk_sel; // Sim only, no connect in hardware
logic [NUM_PROFILES-1:0]                    dr_one_hot_sel;
logic                                       dr_src_pause_request;
logic                                       dr_src_pause_grant;
logic                                       dr_ch0_lavmm_rstn;
logic [20:0]                                dr_ch0_lavmm_addr;
logic [3:0]                                 dr_ch0_lavmm_be;
logic                                       dr_ch0_lavmm_write;
logic                                       dr_ch0_lavmm_read;
logic [31:0]                                dr_ch0_lavmm_wdata;
logic [31:0]                                dr_ch0_lavmm_rdata;
logic                                       dr_ch0_lavmm_rdata_valid;
logic                                       dr_ch0_lavmm_waitreq;
logic [1:0]                                 src_rs_req;
logic [1:0]                                 src_rs_grant;
logic                                       gxb_rx_ready;
logic                                       gxb_rx_reset_ack;
logic                                       rx_syspll_clkout;
logic [79:0]                                rx_parallel_data;
logic                                       rst_trig_rst;
logic                                       pma_cu_clk;
logic                                       system_pll_lock;
logic                                       rx_align_locked_sync;
logic [NUM_STREAMS-1:0]                     rx_trs_locked_sync;
logic                                       rx_frame_locked_sync;
logic                                       cold_reset;
logic                                       cold_resetn;
logic                                       gxb_i_reconfig_write;
logic                                       gxb_i_reconfig_read;
logic [19:0]                                gxb_i_reconfig_address;
logic [3:0]                                 gxb_i_reconfig_byteenable;
logic [31:0]                                gxb_i_reconfig_writedata;
logic [31:0]                                gxb_o_reconfig_readdata;
logic                                       gxb_o_reconfig_waitrequest;
logic                                       gxb_o_reconfig_readdatavalid;
logic                                       trig_rst_ctrl;
logic [NUM_STREAMS*20-1:0]                  sdi_rx_datain;
logic                                       rx_sdi_start_reconfig;
logic                                       swpio_sysclk_startup_en;
logic                                       sysclk_ready_o;

//------------------------------------------------------------------------------
// Output pins assignment
//------------------------------------------------------------------------------
assign fmc_lmh1983_init = sdi_rx_frame_locked;
assign fmc_fpga_fldn    = ~sdi_rx_f[0];
assign fmc_fpga_vsyncn  = ~sdi_rx_v[0];
assign fmc_fpga_hsyncn  = ~sdi_rx_h[0];
assign lmk03328_pdn     = 1'b1;

//-------------------------------------------------------------------------------
// GTS System Pll Clocks
//-------------------------------------------------------------------------------
xcvr_ref_sysclk xcvr_ref_sysclk_inst (
// Input
    .i_refclk               (syspll_refclk),
    .i_refclk_ready         (sysclk_ready_o),

// Output
    .o_syspll_c0            (out_systempll_clk),
    .o_pll_lock             (system_pll_lock)
);

//------------------------------------------------------------------------------
// System Reset Controller
//------------------------------------------------------------------------------
    reset_ctrl #(
      .SOURCES           (1),
      .LOCKS             (1)
    ) i_reset_ctrl (
        .mgmt_clk           (clk_100mhz), 
        .async_resetn       (fpga_core_resetn),
        .async_locked       (1'b1),
        
        .emif_core_init_n   (),
        .sysclk_startup     (swpio_sysclk_startup_en), // Input from SW app to indicate the system_pll Ref clocks clocks are ready
        .sysclk_ready       (sysclk_ready_o), // Output port to the systemPLL to indicate it can start the locking process
        .cold_reset         (cold_reset),
        .cold_resetn        (cold_resetn),
        .mgmt_reset         (sys_reset),
        .mgmt_resetn        (sys_resetn)
    );

altera_reset_controller #(
    .NUM_RESET_INPUTS          (1),
    .RESET_REQ_WAIT_TIME       (1),
    .MIN_RST_ASSERTION_TIME    (3),
    .RESET_REQ_EARLY_DSRT_TIME (1)
) gxb_ltd_sync_inst (
// Input Clock and reset
    .reset_in0      (gxb_ltd),
    .clk            (clk_100mhz),
// Outputs
    .reset_out      (gxb_ltd_sync)
);

//-------------------------------------------------------------------------------
// Synchronize sys_reset to axi4s clock
//-------------------------------------------------------------------------------
altera_reset_controller #(
    .NUM_RESET_INPUTS          (1),
    .RESET_REQ_WAIT_TIME       (1),
    .MIN_RST_ASSERTION_TIME    (3),
    .RESET_REQ_EARLY_DSRT_TIME (1)
) axi4s_reset_inst (
// Input Clock and reset
    .reset_in0      (sys_reset),
    .clk            (axi4s_clk),
// Outputs
    .reset_out      (axi4s_reset)
);

//-------------------------------------------------------------------------------
// GTS Reset Sequencer
//-------------------------------------------------------------------------------
reset_seq rs_inst (
// Input
    .i_src_rs_priority    (),
    .i_src_rs_req         (src_rs_req),

// Output
    .o_src_rs_grant       (src_rs_grant),
    .o_pma_cu_clk         (pma_cu_clk)
);

altera_reset_controller #(
    .NUM_RESET_INPUTS          (2),
    .RESET_REQ_WAIT_TIME       (1),
    .MIN_RST_ASSERTION_TIME    (3),
    .RESET_REQ_EARLY_DSRT_TIME (1)
) tx_reset_sync_inst (
// Input Clock and reset
    .reset_in0      (sys_reset),
    .reset_in1      (~sdi_rx_frame_locked),
    .clk            (clk_100mhz),
// Outputs
    .reset_out      (sdi_tx_reset)
);

//-------------------------------------------------------------------------------
// Clkrx refclk Re-enable 
//-------------------------------------------------------------------------------
en_refclk_buffer en_refclk_buffer_inst (
    .clk                      (clk_100mhz),
    .reset                    (cold_reset),
    .pdp_avmm_waitrequest     (gxb_o_reconfig_waitrequest),
    .pdp_avmm_readdata        (gxb_o_reconfig_readdata),
    .pdp_byte_enable          (gxb_i_reconfig_byteenable),
    .pdp_avmm_write           (gxb_i_reconfig_write),
    .pdp_avmm_read            (gxb_i_reconfig_read),
    .pdp_avmm_readdatavalid   (gxb_o_reconfig_readdatavalid),
    .pdp_avmm_address         (gxb_i_reconfig_address),
    .pdp_avmm_writedata       (gxb_i_reconfig_writedata)
);

//---------------------------------------------------------------------------
// I2C Buffers for retimer tuning
//---------------------------------------------------------------------------
logic i2c_sdi_sda_in, i2c_sdi_scl_in, i2c_sdi_sda_oe, i2c_sdi_scl_oe;

output_buf_i2c u_i2c_sdi_scl_buf (.datain(1'b0),.padio(i2c_sdi_scl),.oe(i2c_sdi_scl_oe),.dataout(i2c_sdi_scl_in));
output_buf_i2c u_i2c_sdi_sda_buf (.datain(1'b0),.padio(i2c_sdi_sda),.oe(i2c_sdi_sda_oe),.dataout(i2c_sdi_sda_in));

//---------------------------------------------------------------------------
// I2C Buffers for control of board infrastructure clocks
//---------------------------------------------------------------------------
logic i2c_clocks_sda_in,i2c_clocks_scl_in,i2c_clocks_sda_oe,i2c_clocks_scl_oe;
logic i2c_max10_sda_in,i2c_max10_scl_in,i2c_max10_sda_oe,i2c_max10_scl_oe;

output_buf_i2c u_i2c_clocks_scl_buf (.datain(1'b0),.padio(i2c_clocks_scl),.oe(i2c_clocks_scl_oe),.dataout(i2c_clocks_scl_in));
output_buf_i2c u_i2c_clocks_sda_buf (.datain(1'b0),.padio(i2c_clocks_sda),.oe(i2c_clocks_sda_oe),.dataout(i2c_clocks_sda_in));

output_buf_i2c u_i2c_max10_scl_buf (.datain(1'b0),.padio(i2c_max10_scl),.oe(i2c_max10_scl_oe),.dataout(i2c_max10_scl_in));
output_buf_i2c u_i2c_max10_sda_buf (.datain(1'b0),.padio(i2c_max10_sda),.oe(i2c_max10_sda_oe),.dataout(i2c_max10_sda_in));

// -------------------------------------------------------------------------
// Nios qsys
// -------------------------------------------------------------------------
nios nios_inst (
//  Clock and reset
    .cpu_clock_bridge_in_clk_clk                ( clk_100mhz                     ),
    .cpu_reset_bridge_in_reset_reset            ( sys_reset                      ),
    
    .axi4s_clock_bridge_in_clk_clk              ( axi4s_clk                      ),
    .axi4s_reset_bridge_in_reset_reset          ( axi4s_reset                    ),

    .sdi_rx_mr_rx_core_refclk_clk               ( clk_100mhz                     ),
    .sdi_rx_mr_xcvr_rxclk_clk                   ( sdi_rx_clkout                  ),
    .sdi_tx_mr_tx_pclk_clk                      ( sdi_tx_clkout                  ),
    .sdi_rx_mr_trig_rst_ctrl_reset              ( trig_rst_ctrl                  ),
    .sdi_rx_mr_rst_trig_rst_reset               ( rst_trig_rst                   ),

    // I2C Clock Control
    .i2c_clocks_i2c_serial_sda_in               (i2c_clocks_sda_in               ),
    .i2c_clocks_i2c_serial_scl_in               (i2c_clocks_scl_in               ),
    .i2c_clocks_i2c_serial_sda_oe               (i2c_clocks_sda_oe               ),
    .i2c_clocks_i2c_serial_scl_oe               (i2c_clocks_scl_oe               ),

    .i2c_serial_sda_in                          (i2c_max10_sda_in                ),                        
    .i2c_serial_scl_in                          (i2c_max10_scl_in                ),                        
    .i2c_serial_sda_oe                          (i2c_max10_sda_oe                ),                        
    .i2c_serial_scl_oe                          (i2c_max10_scl_oe                ),                        

    .pio_systempll_external_connection_in_port  (sysclk_ready_o                  ),
    .pio_systempll_external_connection_out_port (swpio_sysclk_startup_en         ),

//  Inputs
    .sdi_rx_mr_rx_sdi_reconfig_done_export      ( rx_sdi_reconfig_done           ),
    .sdi_rx_mr_rx_datain_rx_parallel_data       ( sdi_rx_datain                  ),
    .sdi_rx_mr_rx_ready_rx_ready                ( gxb_rx_ready                   ),
    .sdi_rx_mr_rx_xcvr_reset_ack_rx_reset_ack   ( gxb_rx_reset_ack               ),
    .i2c_0_i2c_serial_sda_in                    ( i2c_sdi_sda_in                 ),
    .i2c_0_i2c_serial_scl_in                    ( i2c_sdi_scl_in                 ),

//  Outputs
    .i2c_0_i2c_serial_sda_oe                    ( i2c_sdi_sda_oe                 ),
    .i2c_0_i2c_serial_scl_oe                    ( i2c_sdi_scl_oe                 ),
    .sdi_rx_mr_rx_align_locked_export           ( sdi_rx_align_locked            ),
    .sdi_rx_mr_rx_trs_locked_export             ( sdi_rx_trs_locked              ),
    .sdi_rx_mr_rx_frame_locked_export           ( sdi_rx_frame_locked            ),
    .sdi_rx_mr_rx_std_export                    ( sdi_rx_std                     ),
    .sdi_rx_mr_rx_sdi_start_reconfig_export     ( rx_sdi_start_reconfig          ),
    .sdi_rx_mr_gxb_ltd_gxb_ltd                  ( gxb_ltd                        ),
    .sdi_rx_mr_rx_h_export                      ( sdi_rx_h                       ),
    .sdi_rx_mr_rx_f_export                      ( sdi_rx_f                       ),
    .sdi_rx_mr_rx_v_export                      ( sdi_rx_v                       ),
    .sdi_rx_mr_rx_format_export                 (                                ),
    .sdi_rx_mr_rx_clkout_is_ntsc_paln_export    (                                ),
    .sdi_rx_mr_rx_rst_proto_out_export          (                                ),    
    .sdi_tx_mr_tx_dataout_valid_export          (                                ),
    .sdi_tx_mr_tx_dataout_tx_parallel_data      ( sdi_tx_dataout                 ) 
);

// -------------------------------------------------------------------------
// Receiver IP Top Level
// -------------------------------------------------------------------------
rx_mr_top #(
    .MRPHY_RX_BASE_PROFILE          (15'd1),
    .NUM_STREAMS                    (NUM_STREAMS)
) rx_inst (
// Clock and reset
    .rx_rcfg_mgmt_clk               (clk_100mhz),
    .rx_rcfg_mgmt_reset             (cold_reset),
    .trig_rst_ctrl                  (trig_rst_ctrl),

// Inputs
    .rx_parallel_data               (rx_parallel_data),
    .profile_id                     (profile_id),
    .dr_in_progress                 (dr_in_progress),
    .dr_rx_avmm_readdata_valid      (host_avmm_readdatavalid),
    .dr_rx_avmm_waitrequest         (host_avmm_waitrequest),
    .dr_rx_avmm_readdata            (host_avmm_readdata),
    .rx_syspll_clkout               (rx_syspll_clkout),
    .rx_vid_clkout                  (sdi_rx_clkout),
    .rx_sdi_start_reconfig          (rx_sdi_start_reconfig),

// Outputs
    .sdi_rx_datain                  (sdi_rx_datain),
    .rx_vid_std                     (sdi_rx_std),
    .cdr_reconfig_busy              (cdr_reconfig_busy),
    .rx_sdi_reconfig_done           (rx_sdi_reconfig_done),
    .dr_rx_avmm_write               (host_avmm_write),
    .dr_rx_avmm_read                (host_avmm_read),
    .dr_rx_avmm_writedata           (host_avmm_writedata),
    .dr_rx_avmm_address             (host_avmm_address),
    .gxb_rx_reset_ack               (gxb_rx_reset_ack),
    .gxb_rx_ready                   (gxb_rx_ready)
);

// -------------------------------------------------------------------------
// Transmitter IP Top Level
// -------------------------------------------------------------------------
tx_mr_top #(
    .NUM_STREAMS                                (NUM_STREAMS)
)   tx_inst (
// Clocks and reset
    .sdi_tx_pclk                                (sdi_tx_clkout),
    .system_pll_clk                             (out_systempll_clk),
    .pma_cu_clk                                 (pma_cu_clk),
    .tx_pll_refclk                              (txpll_refclk),
    .tx_phy_reset                               (sys_reset),

// Inputs
    .sdi_tx_dataout                             (sdi_tx_dataout),
    .src_rs_grant                               (src_rs_grant[0]),
    .system_pll_lock                            (system_pll_lock),

// Outputs
    .src_rs_req                                 (src_rs_req[0]),
    .tx_vid_clkout                              (sdi_tx_clkout),
    .tx_pll_locked                              (tx_pll_locked),
    .gxb_tx_serial_data                         (fmc_tx0_p),
    .gxb_tx_serial_data_n                       (fmc_tx0_n),
    .gxb_tx_ready                               (gxb_tx_ready)
);

dr_ctrl #(
    .DRMIFMEM_INIT_FILE        (DRMIFMEM_INIT_FILE)
) dr_ctrl_inst (
    // Clock & reset
    .i_rst_n                   (cold_resetn),
    .i_csr_clk                 (clk_100mhz),
    .i_cpu_clk                 (clk_100mhz),
    // Control & Status
    .o_profile_id              (profile_id),
    .o_in_progress             (dr_in_progress),
    .o_err_status              (err_status),
    .o_fast_sim_clk_sel        (fast_sim_clk_sel), // Sim only, no connect in hardware
    // Host AVMM
    .i_host_avmm_address       (host_avmm_address),
    .o_host_avmm_readdatavalid (host_avmm_readdatavalid),
    .i_host_avmm_read          (host_avmm_read),
    .i_host_avmm_write         (host_avmm_write),
    .o_host_avmm_readdata      (host_avmm_readdata),
    .i_host_avmm_writedata     (host_avmm_writedata),
    .o_host_avmm_waitrequest   (host_avmm_waitrequest),
    // Interfaces to generated netlist from DR Tool
    // ..Mux Selector Interface
    .o_one_hot_sel             (dr_one_hot_sel),
    // ..SRC Interface
    .o_src_pause_request       (dr_src_pause_request),
    .i_src_pause_grant         (dr_src_pause_grant),
    // ..LAVMM Interface
    .o_ch0_lavmm_addr          (dr_ch0_lavmm_addr),
    .o_ch0_lavmm_be            (dr_ch0_lavmm_be),
    .o_ch0_lavmm_write         (dr_ch0_lavmm_write),
    .o_ch0_lavmm_read          (dr_ch0_lavmm_read),
    .o_ch0_lavmm_wdata         (dr_ch0_lavmm_wdata),
    .i_ch0_lavmm_rdata         (dr_ch0_lavmm_rdata),
    .i_ch0_lavmm_rdata_valid   (dr_ch0_lavmm_rdata_valid),
    .i_ch0_lavmm_waitreq       (dr_ch0_lavmm_waitreq),
    .o_ch0_lavmm_rstn          (dr_ch0_lavmm_rstn) // Not a reset signal, used for clock gating
);

dr_top   dr_top_inst (
    .i_dr_lavmm_addr_ch0                    (dr_ch0_lavmm_addr),
    .i_dr_lavmm_be_ch0                      (dr_ch0_lavmm_be),
    .i_dr_lavmm_clk_ch0                     (clk_100mhz),
    .i_dr_lavmm_read_ch0                    (dr_ch0_lavmm_read),
    .i_dr_lavmm_rstn_ch0                    (dr_ch0_lavmm_rstn),
    .i_dr_lavmm_wdata_ch0                   (dr_ch0_lavmm_wdata),
    .i_dr_lavmm_write_ch0                   (dr_ch0_lavmm_write),
    .i_pma_cu_clk_bank0                     (pma_cu_clk),
    .i_rx_cdr_refclk_p_dphy_rx_inst         (xcvr_refclk_1485),
    .i_rx_coreclkin_dphy_rx_inst            (rx_syspll_clkout),
    .i_rx_reset_dphy_rx_inst                (rst_trig_rst),
    .i_rx_set_locktoref_dphy_rx_inst        (~gxb_ltd_sync),
    .i_src_pause_request_ch0                (dr_src_pause_request),
    .i_system_pll_clk_dphy_rx_inst          (out_systempll_clk),
    .i_system_pll_lock_dphy_rx_inst         (system_pll_lock),
    .i_rs_grant_ch0                         (src_rs_grant[1]),
    .i_rx_serial_data_n_ch0                 (fmc_rx2_n),
    .i_rx_serial_data_p_ch0                 (fmc_rx2_p),
    .o_rs_request_ch0                       (src_rs_req[1]),
    .o_dr_lavmm_rdata_ch0                   (dr_ch0_lavmm_rdata),
    .o_dr_lavmm_rdata_valid_ch0             (dr_ch0_lavmm_rdata_valid),
    .o_dr_lavmm_waitreq_ch0                 (dr_ch0_lavmm_waitreq),
    .o_rx_clkout_dphy_rx_inst               (rx_syspll_clkout),
    .o_rx_clkout2_dphy_rx_inst              (sdi_rx_clkout),
    .o_rx_is_lockedtodata_dphy_rx_inst      (),
    .o_rx_is_lockedtoref_dphy_rx_inst       (),
    .o_rx_parallel_data_dphy_rx_inst        (rx_parallel_data),
    .o_rx_ready_dphy_rx_inst                (gxb_rx_ready),
    .o_rx_reset_ack_dphy_rx_inst            (gxb_rx_reset_ack),
    .o_src_pause_grant_ch0                  (dr_src_pause_grant),
    .one_hot_sel                            (dr_one_hot_sel),
    // Reconfig
    // Note: Reconfig interface is not needed functionally, but must be 
    // present to avoid the DPHY tri-stating the clock and reset signals.
    .i_reconfig_address_dphy_rx_inst        (gxb_i_reconfig_address[19:2]),
    .i_reconfig_byteenable_dphy_rx_inst     (gxb_i_reconfig_byteenable),
    .i_reconfig_clk_dphy_rx_inst            (clk_100mhz),
    .i_reconfig_read_dphy_rx_inst           (gxb_i_reconfig_read),
    .i_reconfig_reset_dphy_rx_inst          (cold_reset),
    .i_reconfig_write_dphy_rx_inst          (gxb_i_reconfig_write),
    .i_reconfig_writedata_dphy_rx_inst      (gxb_i_reconfig_writedata),
    .o_reconfig_readdata_dphy_rx_inst       (gxb_o_reconfig_readdata),
    .o_reconfig_readdatavalid_dphy_rx_inst  (gxb_o_reconfig_readdatavalid),
    .o_reconfig_waitrequest_dphy_rx_inst    (gxb_o_reconfig_waitrequest)
);


axi4s_clk_iopll axi4s_clk_iopll_inst (
// Clock and reset
    .rst      (sys_reset), 
    .refclk   (clk_100mhz),

// Output
    .outclk_0 (axi4s_clk)
);

endmodule

