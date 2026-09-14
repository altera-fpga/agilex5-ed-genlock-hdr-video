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


module en_refclk_buffer //#()
(
    input  logic        clk,
    input  logic        reset,
    input  logic        pdp_avmm_waitrequest,
    input  logic [31:0] pdp_avmm_readdata,
    input  logic        pdp_avmm_readdatavalid,
    output logic [3:0 ] pdp_byte_enable,
    output logic        pdp_avmm_write,
    output logic        pdp_avmm_read,
    output logic [19:0] pdp_avmm_address,
    output logic [31:0] pdp_avmm_writedata
);

//--------------------------------------
// state assignments
//--------------------------------------
localparam  [2:0]   IDLE                    = 3'd0;
localparam  [2:0]   PHY_RD                  = 3'd1; 
localparam  [2:0]   PHY_CHK_RDDATA          = 3'd2; 
localparam  [2:0]   PHY_WR                  = 3'd3; 
localparam  [2:0]   DONE                    = 3'd4;  // Added DONE state

//--------------------------------------
// signals
//--------------------------------------
logic [2:0]     next_state;
logic [2:0]     state;
logic           first_check;  // Added first_check signal

// state register
always @(posedge clk or posedge reset)
begin
    if (reset) begin
        state <= IDLE;
    end else begin
        state <= next_state;
    end
end

// First check logic
always_ff @(posedge clk or posedge reset) begin
    if (reset)
        first_check <= 1'b0;
    else if (state == DONE)
        first_check <= 1'b1;
end

// next state logic
always @ (*) begin
  case(state)
    IDLE: begin
        if (!first_check || pdp_avmm_readdata[15:8] != 8'h00 )
            next_state = PHY_RD;
        else
            next_state = IDLE;
    end
    PHY_RD: begin
        if (pdp_avmm_waitrequest)
            next_state = PHY_RD;
        else
            next_state = PHY_CHK_RDDATA;
    end
    PHY_CHK_RDDATA: begin
        if (pdp_avmm_readdatavalid)
            next_state = PHY_WR;
        else
            next_state = PHY_CHK_RDDATA;
    end
    PHY_WR: begin
        if (pdp_avmm_waitrequest)
            next_state = PHY_WR;
        else
            next_state = DONE;
    end
    DONE: begin
        next_state = IDLE;
    end
    default : next_state = IDLE;
  endcase
end

//********************************************************************************
//*****************Generate PHY_Access signals for single PDP Interface***************
//PHY_Access read
always @(posedge clk or posedge reset)
begin
    if (reset)
        pdp_avmm_read  <= 1'b0; 
    else begin
        if(next_state == PHY_RD)
            pdp_avmm_read  <= 1'b1; 
        else
            pdp_avmm_read  <= 1'b0; 
    end
end

//PHY_Access write
always @(posedge clk or posedge reset)
begin
    if (reset)
        pdp_avmm_write  <= 1'b0; 
    else begin
        if(next_state == PHY_WR)
            pdp_avmm_write  <= 1'b1; 
        else 
            pdp_avmm_write  <= 1'b0; 
    end
end

//PHY_Access writedata
always @(posedge clk or posedge reset)
begin
    if (reset) begin
        pdp_avmm_writedata  <= 32'h0;
    end else begin
        if(next_state == PHY_WR)
            pdp_avmm_writedata <= {pdp_avmm_readdata[31:24], pdp_avmm_readdata[15:8], pdp_avmm_readdata[15:0]};
    end
end

//PHY_Access address
always @ (posedge clk or posedge reset)
begin
    if (reset)
        pdp_avmm_address  <= 20'd0;
    else begin
        if (next_state == PHY_RD)
            pdp_avmm_address <= 20'hA6038;
    end
end

assign pdp_byte_enable = pdp_avmm_write ? 4'b0100 : 4'b1111;

endmodule

`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "MFoiUcKj6cLCq8D2MF6zRu+lBwPGbv+XWCED1e+wD2+JFkcn9hBMFtquqdL/znibx84+yDNcUCuLyox9Dcn2/0T0RmjHvSj3W0Y1HqpWOIHEEPxFUA+OSm5OF4kfCN2jmQonQ6+hf+IIX3GUSQq0r5gc2EItaU91XsSxrzDcJZAWttYjfD5ojY9qctSmbCiJ/wojDKgyDNG5XF0bVsDqNvAGU+8XIQRL6Kvdzv9mD5i590RjukIGbIU2OhZn8xGrIE8x2HntTC1Gq/o5DNE/Mx6XVsuJOnVl0SCUG4Q7Xl2hC41rUEis8FOAX3Wau5K48hhk4A7SuI5G/Kyln+WvAuGTZkX0R6K4dNxE4nVDB2C86bX2f4+wDLOaf9gCFql2HvcftBCYO0a/ofoaXMau5/igGg/+OqKmZjvVHQK8OzU48MrS9UTeF0DJRKeFKYfjF/GWmOl8g6qt5ZOyq6uumEG8XDIzf4YpUU+OVMbV73GBAvnUjggli5p1udRUFl4Et3ckckyUT8IMRtCEbkWMwDfJtItvpZifXqUl8IkJ9iNJFWzt4dWqXL/h74VoyxLzgR1dsmnzw2z8GhwlAZrwVyuooIb+g2FWoFn/k76GUzMaL6X3ofuXrG0nxsEmFVCLJFaJEotfzGrw5MYZlynRLNl9Xoxi1Kcmv7YIlBvw40AwWhfqnX2hMr/5y6XKtUgRZ15qbvBudb61tj4K04dXF7XurepjwMC1hlDclGrIe5OWOcueD4N1SeKmj81rCQC/rfB+srU/r63O2eztkGEfRM6oYZkWRia4UbztBlUz3iGFBriw8rQ2P+5rCjXBHk8QoSLX4BQQzeLazW2e20HkviW9l9iSOXP8NNW3WgU8KdnVMUWBZwlMq3UkJaJQ0bdz3CIPYQ9R8pytOLobala/r6XP5T/biXMZT7WFRnYTu3gVqfOBPHfF1dBs1S0CsgnF7cQSo33fMPG8HkmvY+PSSig2tiaEGT6bIF/7ItXza0/vxc7H72RYinwq+ILKL6Kw"
`endif