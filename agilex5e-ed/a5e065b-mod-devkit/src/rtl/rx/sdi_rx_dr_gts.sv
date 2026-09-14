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


module sdi_rx_dr_gts #(
    parameter           VIDEO_STANDARD              = "tr",
    parameter [14:0]    MRPHY_RX_BASE_PROFILE       = 15'd1,
    parameter           RCFG_CLK_SDI_CORECLK_DIFF   = 1
) (
    input  logic        clk,
    input  logic        reset,
    input  logic        xcvr_reset_ack,
    input  logic        sdi_reconfig_request,
    input  logic [2:0]  sdi_rx_std,
    input  logic        dr_in_progress,

    input  logic [14:0] dr_curr_profile_id,
    input  logic        dr_avmm_readdata_valid,
    input  logic        dr_avmm_waitrequest,
    input  logic [31:0] dr_avmm_readdata,
    output logic        cdr_reconfig_busy,
    output logic        reconfig_done,
    output logic        dr_avmm_write,
    output logic        dr_avmm_read,
    output logic  [6:0] dr_avmm_address,
    output logic [31:0] dr_avmm_writedata
);

localparam [14:0] DR_12G_PROFILE  = (VIDEO_STANDARD == "mr") ? (MRPHY_RX_BASE_PROFILE+0) : 15'd1;
localparam [14:0] DR_6G_PROFILE   = (VIDEO_STANDARD == "mr") ? (MRPHY_RX_BASE_PROFILE+1) : 15'd2;
localparam [14:0] DR_3GSD_PROFILE = (VIDEO_STANDARD == "mr") ? (MRPHY_RX_BASE_PROFILE+2) : (MRPHY_RX_BASE_PROFILE+0);
localparam [14:0] DR_HD_PROFILE   = (VIDEO_STANDARD == "mr") ? (MRPHY_RX_BASE_PROFILE+3) : (MRPHY_RX_BASE_PROFILE+1);

//--------------------------------------
// state assignments
//--------------------------------------
localparam  [2:0]   IDLE                = 3'd0;
localparam  [2:0]   DR_STATUS           = 3'd1;
localparam  [2:0]   RD                  = 3'd2; 
localparam  [2:0]   CHK_RDDATA          = 3'd3; 
localparam  [2:0]   WR                  = 3'd4; 
localparam  [2:0]   TRANS               = 3'd5;
localparam  [2:0]   WAIT_DR_DONE        = 3'd6;
localparam [15:0]   DR_CSR_BASE_ADDR    = 16'h2000;
localparam  [2:0]   TOTAL_OFFSET        = 3'd4;

//--------------------------------------
// signals
//--------------------------------------
logic           wait_dr_ready;
logic           disable_curr_profile;
logic           enable_curr_profile;
logic           trigger_reconfig;
logic           reconfig_write_done;
logic           rcfg_req_posedge_dly;
logic           reconfig_req_posedge;
logic           trigger_reconfig_posedge;
logic           dr_in_progress_negedge;
logic           reconfig_done_negedge;
logic           xcvr_reset_ack_sync;
logic           sdi_rcfg_req_sync;
logic [2:0]     num_exec;
logic [2:0]     sdi_rx_std_sync;
logic [2:0]     next_state;
logic [2:0]     state;
logic [14:0]    tmp_profile;
logic [14:0]    current_profile;
logic           dr_avmm_readdata_valid_dly;
logic [31:0]    dr_avmm_readdata_dly;

generate if (RCFG_CLK_SDI_CORECLK_DIFF)
begin : rcfg_req_sync_gen
    altera_std_synchronizer #(
        .depth      (3)
    ) rcfg_req_sync_sync_inst (
        .clk        (clk),
        .reset_n    (1'b1),
        .din        (sdi_reconfig_request),
        .dout       (sdi_rcfg_req_sync)
    );
end else begin
    assign sdi_rcfg_req_sync = sdi_reconfig_request;
end
endgenerate

altera_std_synchronizer #(
    .depth      (3)
) xcvr_reset_ack_sync_inst (
    .clk        (clk),
    .reset_n    (1'b1),
    .din        (xcvr_reset_ack),
    .dout       (xcvr_reset_ack_sync)
);

altera_std_synchronizer_bundle #(
    .width      (3),
    .depth      (3)
) u_cdr_reconfig_sel_sync (
    .clk        (clk),
    .reset_n    (1'b1),
    .din        (sdi_rx_std),
    .dout       (sdi_rx_std_sync)
);

edge_detector #(
    .EDGE_DETECT ("POSEDGE")
) reconfig_req_posedge_det_inst (
    .clk        (clk),
    .rst        (reset),
    .d          (sdi_rcfg_req_sync & xcvr_reset_ack_sync),
    .q          (reconfig_req_posedge)
);

edge_detector #(
    .EDGE_DETECT    ("POSEDGE")
) trigger_reconfig_posedge_det (
    .clk            (clk),
    .rst            (reset),
    .d              (trigger_reconfig),
    .q              (trigger_reconfig_posedge)
);

edge_detector #(
    .EDGE_DETECT    ("NEGEDGE")
) dr_in_progress_negedge_det (
    .clk            (clk),
    .rst            (reset),
    .d              (dr_in_progress),
    .q              (dr_in_progress_negedge)
);

edge_detector #(
    .EDGE_DETECT    ("NEGEDGE")
) u_reconfig_done_det (
    .clk            (clk),
    .rst            (reset),
    .d              (reconfig_write_done),
    .q              (reconfig_done_negedge)
);
//*********************************************************************
//******Number of execution required for the whole CDR reconfig process (SDI)************
always @(posedge clk or posedge reset)
begin
    if (reset) begin
        num_exec <= TOTAL_OFFSET;
    end else begin
        if (next_state == IDLE) begin
            num_exec <= TOTAL_OFFSET;
        end else if (next_state == TRANS) begin
            num_exec <= num_exec - 1'b1;
        end
    end
end

assign wait_dr_ready        = (num_exec == TOTAL_OFFSET);
assign disable_curr_profile = (num_exec == (TOTAL_OFFSET - 2'h1));
assign enable_curr_profile  = (num_exec == (TOTAL_OFFSET - 2'h2));
assign trigger_reconfig     = (num_exec == 2'h1);
assign reconfig_write_done  = (num_exec == 2'h0);
//***********************************************************************************
//***************************Control State Machine***********************************
// state register
always @(posedge clk or posedge reset)
begin
    if (reset) begin
        state <= IDLE;
        rcfg_req_posedge_dly <= 1'b0;
    end else begin
        state <= next_state;
        // Delay reconfig request to state machine to allow the busy signal to arbiter 1 clock cycle earlier.
        rcfg_req_posedge_dly <= reconfig_req_posedge;
        dr_avmm_readdata_valid_dly <= dr_avmm_readdata_valid;
        dr_avmm_readdata_dly <= dr_avmm_readdata;
    end
end   

// next state logic
always @ (*) begin
  case(state)
    IDLE: begin
      if (rcfg_req_posedge_dly)
        next_state = DR_STATUS;
      else    
        next_state = IDLE;
    end
    DR_STATUS: begin
      if (!dr_in_progress)
        next_state = RD;
      else    
        next_state = DR_STATUS;
    end
    RD: begin
      if (dr_avmm_waitrequest)
        next_state = RD;
      else
        next_state = CHK_RDDATA;
    end
    CHK_RDDATA: begin
      if (dr_avmm_readdata_valid_dly) begin
        if (wait_dr_ready & (dr_avmm_readdata_dly == 32'h1))
            next_state = TRANS;
        else if (disable_curr_profile & (dr_avmm_readdata_dly == 32'h0))
            next_state = WR;
        else if (reconfig_write_done & (dr_avmm_readdata_dly == 32'h1))
            next_state = WAIT_DR_DONE;
        else
            next_state = RD;
      end else begin
        next_state = CHK_RDDATA;
      end
    end
    WR: begin
      if (dr_avmm_waitrequest)
        next_state = WR;
      else
        next_state = TRANS;
    end
    TRANS : begin
      if (disable_curr_profile | reconfig_write_done)
          next_state = RD;
      else
          next_state = WR;
    end
    WAIT_DR_DONE : begin
        if (dr_in_progress_negedge)
            next_state = IDLE;
        else
            next_state = WAIT_DR_DONE;
    end

    default : next_state = IDLE;
  endcase
end

//*********************************************************************
//************************** cdr_reconfig_busy****************************
always @(posedge clk or posedge reset)
begin
    if (reset)
      cdr_reconfig_busy <= 1'd0;
    else begin
      if (reconfig_req_posedge)
        cdr_reconfig_busy <= 1'b1; 
      else if (next_state == IDLE) 
        cdr_reconfig_busy <= 1'b0;
    end
end

//********************************************************************************
//*****************Generate DPRIO signals for single XCVR Interface***************
//DPRIO read
always @(posedge clk or posedge reset)
begin
    if (reset)
        dr_avmm_read  <= 1'b0; 
    else begin
        if(next_state == RD)
            dr_avmm_read  <= 1'b1; 
        else
            dr_avmm_read  <= 1'b0; 
    end
end

//DPRIO write
always @(posedge clk or posedge reset)
begin
    if (reset)
        dr_avmm_write  <= 1'b0; 
    else begin
        if(next_state == WR)
            dr_avmm_write  <= 1'b1; 
        else 
            dr_avmm_write  <= 1'b0; 
    end
end

//DPRIO writedata
always @(posedge clk or posedge reset)
begin
    if (reset) begin
        dr_avmm_writedata  <= 32'h0;
        tmp_profile <= MRPHY_RX_BASE_PROFILE;
    end else begin
        if(next_state == WR) begin
            if (disable_curr_profile)
                dr_avmm_writedata[15:0] <= {1'h0, current_profile};
            else if (enable_curr_profile) begin
                if (sdi_rx_std_sync[2:1] == 2'b11) begin
                    dr_avmm_writedata[31:16] <= {1'h1, DR_12G_PROFILE};
                    tmp_profile <= DR_12G_PROFILE;
                end else if (sdi_rx_std_sync[2:1] == 2'b10) begin
                    dr_avmm_writedata[31:16] <= {1'h1, DR_6G_PROFILE};
                    tmp_profile <= DR_6G_PROFILE;
                end else if (sdi_rx_std_sync == 3'b001) begin
                    dr_avmm_writedata[31:16] <= {1'h1, DR_HD_PROFILE};
                    tmp_profile <= DR_HD_PROFILE;
                end else begin
                    dr_avmm_writedata[31:16] <= {1'h1, DR_3GSD_PROFILE};
                    tmp_profile <= DR_3GSD_PROFILE;
                end
            end else if (trigger_reconfig)
                dr_avmm_writedata <= 32'h1;
        end
    end
end

//DPRIO address
always @ (posedge clk or posedge reset)
begin
    if (reset)
        dr_avmm_address  <= 7'h70;
    else begin
        if ((wait_dr_ready && next_state == RD))
            dr_avmm_address <= 7'h70;
        else if (disable_curr_profile && next_state == RD)
            dr_avmm_address <= 7'h74;
        else if ((disable_curr_profile && next_state == WR) || enable_curr_profile)
            dr_avmm_address <= 7'h00;
        else if (trigger_reconfig)
            dr_avmm_address <= 7'h50;
    end
end

always @ (posedge clk or posedge reset)
begin
    if (reset) begin
        reconfig_done <= 1'b0;
        current_profile <= MRPHY_RX_BASE_PROFILE;
    end else begin
        reconfig_done <= reconfig_done_negedge;
        if (trigger_reconfig_posedge) begin
            current_profile <= tmp_profile;
        end
    end
end

endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "B1jX1eSmksrlkd8lAXcyKkr8jziX0V56m1FWHuGFSGge+pEUkt/d2rLZJkewbmrxcTMj/JXnsn3QhcoK2LomdJUZMBUi5nRXGNv/0kmMhRSqMxsKPAQcVCD5aZKrEPzCIhpM6C8PPeUlRKSDZ0v0pHSspq1Q2azT6NerDE/Cxz3qBja6xhbB3TS4as5Dtbc70cyYht+yuVIsb7HBV4rES/fGfsaGitKL9geqDgMw2MQHoPSQH0ZaMlZoijAaFWlce3ZoXgeaMEIdhrrhxWH8YdvzAFIxWxtmN7F5Y8P1cnkurkyqEelXx02ZNm5nQuoAz7Hos52D4dDfth8B1aOD3C0QtyKjPfDR+rU0kERXHfGL5/hbIF2WHgXuot4f2TlIobZttNYVbnfpzmcty4rzDGtihhgI0aGucpBQviKxva1/69xZyPBPJlPmZwp5hL38Gp5RCRPnqOMxwQfAZL0efTFFSQSFobhxW/hsBIhnFh2RBuvyAf1uRddhwJ/3z/BE6DNEJbo0L+dSn/MmPaL3OrWX+F7JM3XawFDpPaNygtwJeam86MHJmF/jB2AiP1FTw7tBpYozNHIN9b3BNKOsL6swlsIKUzIxByFEQYCpNTU1Czff2FEKWysNqZ50XeGeTVJvm+qiAP8Vuewgd5OdO1rGJRiEBCpEorba075FpApEdeE+SMiCReMMNLGBaaGJID9wFGkIertmb1E9nI1bjCEUcrbgxYh081p/hkL3CPpyWoM8OM5uV2AA3QklePNXmyAlXxlhIyblahSYVlDJp04hRRSozfe+w1OC+VW+MSM7gU1X0QY8SepSU7SMfOnXYVRsxirpW3N1YWQaC76sAnGXICEmp868Ia/bkOnZ5CXxOOY4EwCNyCrn6kQ6ie4KPh/BTBV5TJ3uBpNKLiYfBPzX9GtuFasdhjz7QLWsixnJ6fBXqv5/gYiaKXLn4H2GvGOXSB8F/o3iqwjTun8uFa0dfJIYiIIjbLv/NSZvMJcf4T0dZ4QNGNA0AaNrj7PC"
`endif