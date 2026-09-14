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


`timescale 1ps/1ps
module reset_ctrl #(
  parameter SOURCES = 3,
  parameter LOCKS   = 2
) (
    input   wire               mgmt_clk,
    input   wire [SOURCES-1:0] async_resetn,
    input   wire [LOCKS-1:0]   async_locked,

    input   wire               sysclk_startup,
    output  logic              sysclk_ready,
    output  logic              emif_core_init_n,
    output  logic              cold_reset,
    output  logic              cold_resetn,
    output  logic              mgmt_reset,
    output  logic              mgmt_resetn
);

`ifdef ALTERA_RESERVED_QIS
localparam CNT_BITS = 24;
`else
localparam CNT_BITS = 8;
`endif
  logic [SOURCES:0]  sync_resetn_all;
  logic              sync_resetn;
  logic [LOCKS-1:0]  sync_locked_all;
  logic              sync_locked;
  logic              ninit_done;
  logic              sysclk_startup_mgmt;
  
  logic [CNT_BITS-1:0]       stage1_reset_cnt;
  logic [CNT_BITS-1:0]       stage2_reset_cnt;
  
`ifdef ALTERA_RESERVED_QIS
   reset_release s10_rst_release_inst ( .ninit_done (ninit_done) );
`else
  initial begin
   ninit_done = 1'b1;
   #200000;
   ninit_done = 1'b0;
  end 
`endif

  // EMIF Must be connected to reset-release. This is a hard rule of the EMIF IP
  // All EMIF Reference clocks must be correct, BEFORE fpga is configured
  // EMIF Cannot be reset
  assign emif_core_init_n = ~ninit_done;
  
  //---------------------------------------------------------------------------
  // Retime all inputs to common domain
  //---------------------------------------------------------------------------
  altera_std_synchronizer_bundle #(.depth(3),.width(SOURCES+1+1)) i_rst_sync (
      .clk        (mgmt_clk),
      .reset_n    (1'b1),
      .din        ({sysclk_startup,~ninit_done,async_resetn}),
      .dout       ({sysclk_startup_mgmt,sync_resetn_all})
  );
  
  logic ninit_done_mgmt;
  altera_std_synchronizer_bundle #(.depth(3),.width(1)) i_ninit_done_sync (
      .clk        (mgmt_clk),
      .reset_n    (1'b1),
      .din        (ninit_done),
      .dout       (ninit_done_mgmt)
  );

  //---------------------------------------------------------------------------
  // OneShot release of systempll refclk ready. 
  //
  // After board clock configured software activates systempll. 
  // This can only be done *** ONCE *** - SystemPLL cannot be restarted.
  //
  // Software will check this status on a GBD-restart and avoid touching board clock
  //---------------------------------------------------------------------------
  always @(posedge mgmt_clk or posedge ninit_done_mgmt) begin
    if (ninit_done_mgmt) begin
      sysclk_ready <= 1'b0;
    end else if (sysclk_startup_mgmt) begin
      sysclk_ready <= 1'b1;
    end
  end

  //---------------------------------------------------------------------------
  // Retime all inputs to common domain
  //---------------------------------------------------------------------------
  altera_std_synchronizer_bundle #(.depth(3),.width(LOCKS)) i_lock_sync (
      .clk        (mgmt_clk),
      .reset_n    (1'b1),
      .din        (async_locked),
      .dout       (sync_locked_all)
  );
  
  assign sync_resetn = &sync_resetn_all;
  assign sync_locked = &sync_locked_all;
  
  //---------------------------------------------------------------------------
  // Two Stage reset
  //
  // Stage 1 - Cold = Infrastructure like PLLs
  // Stage 2 - Mgmt = Everything else
  // 
  // Cold-Reset is stretched whenever a top level reset request comes in.
  // Allows PLLs and other circuitry to see a wide reset
  //
  // Once cold-reset is released, core waits for all status signals to report good
  // Once good, main reset is stretched further to allow all IP using PLLs to see
  // a wide reset.
  //---------------------------------------------------------------------------
  always @(posedge mgmt_clk) begin
    // Cold Reset
    if (~sync_resetn) begin
      stage1_reset_cnt <= '0;
    end else if (~stage1_reset_cnt[CNT_BITS-1]) begin
      stage1_reset_cnt <= stage1_reset_cnt + 1'b1;
    end      

    // Once all PLLs are locked, EMIF is calibrated etc.. Then release system-reset.
    if (~sync_resetn | ~sync_locked | ~stage1_reset_cnt[CNT_BITS-1]) begin
      stage2_reset_cnt <= '0;
    end else if (~stage2_reset_cnt[CNT_BITS-1]) begin
      stage2_reset_cnt <= stage2_reset_cnt + 1'b1;
    end  

    cold_reset   = ~stage1_reset_cnt[CNT_BITS-1];
    cold_resetn  =  stage1_reset_cnt[CNT_BITS-1];
    
    mgmt_reset   <= ~stage2_reset_cnt[CNT_BITS-1];
    mgmt_resetn  <=  stage2_reset_cnt[CNT_BITS-1];    
  end
  
endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "bMpV0aTTyzyyiuaKAqRhFcRU8NdR2omXdg7fgPc7ja6BHWxeFMr97Tltj5HDZvjuofW78tV/T4+X6IfqAwCwQg2LxhGsKBkKrrLcuqeUUbEEcXlyTTJ1ZjXE8aZ+Y6GrFYXGcuVpdp39GwsocSv8EhSPf87yP+HF2wBmRMeymnCVVuyJv+y4NVFpN7QYQ5+S3MHCEss2jBNBsHsEDvrIc41X+j0tn98VBYV5Ac0lbX9kjCIlH7o+QETmQKA0QsWFC99+D38C0PeNtOHV1Btbd9BmjGq+QHWos7JmnHQHySpuBypDS0ui9H2UMHx/OEf1Ie45P49ng24VU2gPzA3xQlcBxnhlcZSnvE5HBpg3CO1J8wM9m57YUslSs5o5TFMRk+mLRqugQCKkX2jTflLlXDwRbH0JCojUxmpRrzzgvFhIxaIFUZ0g0M2oaE5jS0FieywKFyXqf5rS6TRu3Afpxe/bk51Ajv/HXMFYCxCSwnMqrqpGfEtXa3qFVCjoBZi4cujMwObh9msr6cK7muXIER94UkID2xmxZxz2QhecwdodJqqbr4KZjG3pRC3MEB/H9segmVwm1XZz3mN+2vxs9gDD3e6Hy5cWTphid80x+xFSGuNikcrCmerBcHKvE9FpHwTxR8EgCbCEePivtBN6oLPyyZIDQyvilFdXooGMfaWvPQj7jhsrU50Yxc3udZ+cwC6uJgoUNSh2cKEHwEILLu4K9kxQ6Tw5RBf3HkxikOIfJB21D5xtk7e06TRZV3RMWfKJdF3uJRy8EoeWo6CA2JgGH05+rsLZPHxDWJG6nx0LBC+d00kzlU+6rtS7HiX7rNxUXGbxzdCgbRreZ7D8TFcsqbMguT1nhqwVlXolqBkNDT9xrq4PYANN4I4Z7Jrb/hNGwospCbBeLGKKyRwXo0bii60KWsjKQUfLbs7AuajVrOici1QF/4N6XMKOwvApkq1X+p44fiuDQGNkAfbNpU7N0E4hWIN4ySt4Em81yfLMTTYTpAydu2fzcf5zV4w3"
`endif