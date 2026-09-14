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


module sdi_phy_adapter #(
    parameter   VIDEO_STANDARD = "mr",
    parameter   DIRECTION = "du"
)(
    input  logic                                            tx_reset,
    input  logic                                            rx_reset,
    input  logic                                            tx_syspll_clkout,
    input  logic                                            rx_syspll_clkout,
    input  logic                                            tx_vid_clkout,
    input  logic                                            rx_vid_clkout,
    input  logic                                            gxb_tx_ready,
    input  logic                                            gxb_rx_ready,
    input  logic                                            tx_cadence,
    input  logic [60*(VIDEO_STANDARD == "mr"  | 
                      VIDEO_STANDARD == "twelveg")+20-1:0]  sdi_txdata,
    input  logic [79:0]                                     rx_parallel_data,
    input  logic  [2:0]                                     rx_vid_std,

    output logic [79:0]                                     tx_parallel_data,
    output logic [60*(VIDEO_STANDARD == "mr" | 
                      VIDEO_STANDARD == "twelveg")+20-1:0]  rxdata_to_sdi
);

`ifndef __TILE_IP__
//----------------------------------------------------------------------------------------
// Generate for Tx
//----------------------------------------------------------------------------------------
generate if (DIRECTION == "tx" || DIRECTION == "du")
begin : tx_comp_gen
    logic                                           txfifo_rdreq;
    logic                                           tx_fifo_data_valid;
    logic                                           gxb_tx_ready_sync;
    logic                                           tx_rst_sync;
    logic [2*(VIDEO_STANDARD == "mr"  | 
              VIDEO_STANDARD == "twelveg")+4-1:0]   txfifo_rdusedw;
    logic [39:0]                                    txfifo_dataout;

    altera_reset_controller #(
        .NUM_RESET_INPUTS          (1),
        .RESET_REQ_WAIT_TIME       (1),
        .MIN_RST_ASSERTION_TIME    (3),
        .RESET_REQ_EARLY_DSRT_TIME (1)
    ) tx_rst_sync_inst (
    // Input Clock and reset
        .reset_in0      (tx_reset),
        .clk            (tx_syspll_clkout),
    // Outputs
        .reset_out      (tx_rst_sync)
    );

    altera_std_synchronizer #(
        .depth(3)
    ) gxb_tx_ready_sync_inst (
        .clk(tx_vid_clkout),
        .reset_n(1'b1),
        .din(gxb_tx_ready),
        .dout(gxb_tx_ready_sync)
    );

    txdata_fifo txdata_dcfifo_inst (
    // Input Clocks and reset
        .aclr  (tx_reset),
        .rdclk (tx_syspll_clkout),
        .wrclk (tx_vid_clkout),
    // Inputs
        .data (sdi_txdata),
        .rdreq (txfifo_rdreq),
        .wrreq (gxb_tx_ready_sync),
    // Outputs
        .q (txfifo_dataout),
        .rdempty (),
        .rdusedw (txfifo_rdusedw),
        .wrfull (),
        .wrusedw ()
    );

    always @(posedge tx_syspll_clkout) begin
        tx_fifo_data_valid  <= txfifo_rdreq;
    end

    if (VIDEO_STANDARD == "mr" | VIDEO_STANDARD == "twelveg")
    begin : mr_fifo_rdreq_gen
        //----------------------------------------------------------------------------------------
        // Generate Fifo Rdreq for Multi rate mode
        //----------------------------------------------------------------------------------------
        logic tx_cadence_dly;

        always @(posedge tx_syspll_clkout) begin
            tx_cadence_dly <= tx_cadence;
        end

        always @(posedge tx_syspll_clkout) begin
            if (tx_rst_sync) begin
                txfifo_rdreq <= 1'b0;
            end else if (txfifo_rdusedw[5]) begin
                txfifo_rdreq <= tx_cadence || tx_cadence_dly;
            end
        end
    end else
    begin : non_mr_fifo_rdreq_gen
        //----------------------------------------------------------------------------------------
        // Generate Fifo Rdreq for Triple rate / Single rate HD or 3G mode
        //----------------------------------------------------------------------------------------
        logic [1:0] tx_cadence_cnt;
        assign txfifo_rdreq = tx_cadence_cnt[1];

        always @(posedge tx_syspll_clkout) begin
            if (tx_rst_sync) begin
                tx_cadence_cnt <= 2'd0;
            end else if (txfifo_rdusedw[3]) begin
                if (tx_cadence_cnt[1]) begin
                    tx_cadence_cnt  <= tx_cadence;
                end else begin
                    tx_cadence_cnt  <= tx_cadence_cnt + tx_cadence;
                end
            end
        end
    end

    assign tx_parallel_data = {20'd0, txfifo_dataout[39:20], 1'b0, tx_fifo_data_valid, 18'd0, txfifo_dataout[19:0]};
end else 
begin : txdata_empty_gen
    assign tx_parallel_data = 80'd0;
end
endgenerate

//----------------------------------------------------------------------------------------
// Generate for Rx
//----------------------------------------------------------------------------------------
generate if (DIRECTION == "rx" || DIRECTION == "du")
begin : rx_comp_gen
    logic                                           gxb_rx_ready_sync;
    logic                                           rx_rst_sync;
    logic [39:0]                                    rx_parallel_data_reg;
    logic                                           rx_parallel_data_valid;
    logic [19:0]                                    rx_3ghd_fifo_dataout;
    logic [39:0]                                    rx_6g_fifo_dataout;
    logic [79:0]                                    rx_12g_fifo_dataout;

    altera_reset_controller #(
        .NUM_RESET_INPUTS          (1),
        .RESET_REQ_WAIT_TIME       (1),
        .MIN_RST_ASSERTION_TIME    (3),
        .RESET_REQ_EARLY_DSRT_TIME (1)
    ) rx_rst_sync_inst (
    // Input Clock and reset
        .reset_in0      (rx_reset),
        .clk            (rx_vid_clkout),
    // Outputs
        .reset_out      (rx_rst_sync)
    );

    altera_std_synchronizer #(
        .depth(3)
    ) gxb_rx_ready_sync_inst (
        .clk(rx_syspll_clkout),
        .reset_n(1'b1),
        .din(gxb_rx_ready),
        .dout(gxb_rx_ready_sync)
    );

    // M20K block may be placed far from transceiver hard block in certain compilation.
    // Placing flops in between PHY and FIFO to relax timing
    always @ (posedge rx_syspll_clkout)
    begin
        rx_parallel_data_reg <= {rx_parallel_data[59:40],rx_parallel_data[19:0]};
        rx_parallel_data_valid <= gxb_rx_ready_sync & rx_parallel_data[38];
    end

    if (VIDEO_STANDARD != "twelveg")
    begin : rxdata_3ghd_gen
        logic       rx_3ghd_fifo_rdreq;
        logic [5:0] rx_3ghd_fifo_rdusedw;

        rxdata_3ghd_fifo rxdata_3ghd_fifo_inst (
        // Input Clocks and reset
            .aclr       (rx_reset),
            .rdclk      (rx_vid_clkout),
            .wrclk      (rx_syspll_clkout),
        // Inputs
            .data       (rx_parallel_data_reg),
            .wrreq      (rx_parallel_data_valid),
            .rdreq      (rx_3ghd_fifo_rdreq),
        // Outputs
            .q          (rx_3ghd_fifo_dataout),
            .rdempty    (),
            .rdusedw    (rx_3ghd_fifo_rdusedw),
            .wrfull     (),
            .wrusedw    ()
        );

        // Wait until FIFO half full before start reading
        always @ (posedge rx_vid_clkout)
        begin
            if (rx_rst_sync) begin
                rx_3ghd_fifo_rdreq <= 1'b0;
            end else begin
                if (rx_3ghd_fifo_rdusedw[5]) begin
                    rx_3ghd_fifo_rdreq <= 1'b1;
                end
            end
        end
    end else
    begin : rxdata_3ghd_empty_gen
        assign rx_3ghd_fifo_dataout = 20'd0;
    end

    if (VIDEO_STANDARD == "mr")
    begin : rxdata_6g_gen
        logic       rx_6g_fifo_rdreq;
        logic [4:0] rx_6g_fifo_rdusedw;

        rxdata_6g_fifo rxdata_6g_fifo_inst (
        // Input Clocks and reset
            .aclr       (rx_reset),
            .rdclk      (rx_vid_clkout),
            .wrclk      (rx_syspll_clkout),
        // Inputs
            .data       (rx_parallel_data_reg),
            .wrreq      (rx_parallel_data_valid),
            .rdreq      (rx_6g_fifo_rdreq),
        // Outputs
            .q          (rx_6g_fifo_dataout),
            .rdempty    (),
            .rdusedw    (rx_6g_fifo_rdusedw),
            .wrfull     (),
            .wrusedw    ()
        );

        // Wait until FIFO half full before start reading
        always @ (posedge rx_vid_clkout)
        begin
            if (rx_rst_sync) begin
                rx_6g_fifo_rdreq <= 1'b0;
            end else begin
                if (rx_6g_fifo_rdusedw[4]) begin
                    rx_6g_fifo_rdreq <= 1'b1;
                end
            end
        end
    end else
    begin : rxdata_6g_empty_gen
        assign rx_6g_fifo_dataout = 40'd0;
    end

    if (VIDEO_STANDARD == "mr" | VIDEO_STANDARD == "twelveg")
    begin : rxdata_12g_gen
        logic           rx_12g_fifo_rdreq;
        logic [3:0]     rx_12g_fifo_rdusedw;

        rxdata_12g_fifo rxdata_12g_fifo_inst (
        // Input Clocks and reset
            .aclr       (rx_reset),
            .rdclk      (rx_vid_clkout),
            .wrclk      (rx_syspll_clkout),
        // Inputs
            .data       (rx_parallel_data_reg),
            .wrreq      (rx_parallel_data_valid),
            .rdreq      (rx_12g_fifo_rdreq),
        // Outputs
            .q          (rx_12g_fifo_dataout),
            .rdempty    (),
            .rdusedw    (rx_12g_fifo_rdusedw),
            .wrfull     (),
            .wrusedw    ()
        );

        // Wait until FIFO half full before start reading
        always @ (posedge rx_vid_clkout)
        begin
            if (rx_rst_sync) begin
                rx_12g_fifo_rdreq <= 1'b0;
            end else begin
                if (rx_12g_fifo_rdusedw[3]) begin
                    rx_12g_fifo_rdreq <= 1'b1;
                end
            end
        end
    end else
    begin : rxdata_12g_empty_gen
        assign rx_12g_fifo_dataout = 80'd0;
    end

    if (VIDEO_STANDARD == "mr")
    begin : rxdata_to_mr_sdi_gen
        logic [79:0]    rxdata_tmp;
        always @ (posedge rx_vid_clkout)
        begin
            if (rx_vid_std[2:1] == 2'b11) begin
                rxdata_tmp <= rx_12g_fifo_dataout;
            end else if (rx_vid_std[2:1] == 2'b10) begin
                rxdata_tmp <= {40'd0, rx_6g_fifo_dataout};
            end else begin
                rxdata_tmp <= {60'd0, rx_3ghd_fifo_dataout};
            end
        end

        assign rxdata_to_sdi = rxdata_tmp;
    end else if (VIDEO_STANDARD == "twelveg")
    begin : rxdata_to_twelveg_sdi_gen
        assign rxdata_to_sdi = rx_12g_fifo_dataout;
    end else
    begin : rxdata_to_3ghd_sdi_gen
        assign rxdata_to_sdi = rx_3ghd_fifo_dataout;
    end
end else
begin : rxdata_empty_gen
    assign rxdata_to_sdi = 80'd0;
end
endgenerate
`endif

endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "B1jX1eSmksrlkd8lAXcyKkr8jziX0V56m1FWHuGFSGge+pEUkt/d2rLZJkewbmrxcTMj/JXnsn3QhcoK2LomdJUZMBUi5nRXGNv/0kmMhRSqMxsKPAQcVCD5aZKrEPzCIhpM6C8PPeUlRKSDZ0v0pHSspq1Q2azT6NerDE/Cxz3qBja6xhbB3TS4as5Dtbc70cyYht+yuVIsb7HBV4rES/fGfsaGitKL9geqDgMw2MQA+2qbk3+HmPCC70AoT5+QC1ikMV5ydulrZ2vlTVp/unULa9uyczQwZnMTEcdf+7dGpLabm7OQ61REyWb4JWP31gEYgK434Wsi6GITUf5cKDEGY9FnjvRQpKYy0m2uRpx/d/LD1xFFrAZIkBYqSXCfWStSJbJfbRM0flwpfQBsI7SzSUDI5UQJOub7mGhuBYkqAS8k/wTGQ3HRP2Mf2IEgLBNFc3yThZIQWIEaBtgA30wdhIOnaaLMUwXGfLQOOXAblEyVZ3UW7oaYBqZwsIiuMis0Zi0ZEdcro+WZivSDOnIwXYMQ7mUFLpMOwkuDVjJcsKtg3/SYPujjhnxleJVrJAZbN7+3LOLlXP5gle2ioijG7Hy/8sGUQzM7sr2e8fL1/rZHTfqz+4ifPJC5jbQJPz7Y4glT/NOW3pzPcJzS5WaWCpZTzjyyu92xbJTM0vo+ptBg16wkuQ42PfXRDXfaIC/FALfhiW/zJ7UYYIuR+D5bC8+mZrv1K1Ayp/L2qfDhJrNQ/bU1WAFM4nyy7CRSnj/IZebQUFG1V2G9aMzpWvuM5Smue4jXNpBAvbZD5tmNBO90iTW7pMr3IYa0jlGQgqGHtlOalvIl/6UGaxtimVuXimn2dX7doNLdDQPgMMfK0hjV33ggE1OIsfqivWklaoiZG+Nhb+f8dEQFN+9+QmVNXCpdjlwGUZ2g9SpPMiR5t9DFXk0nUGhbAgqjLWLxfCLysJxXwt2K58h7DQkFCvUWyO4bt/2G9Bx2J+eB2q7CaajxOWI72CvEY92HM/uh"
`endif