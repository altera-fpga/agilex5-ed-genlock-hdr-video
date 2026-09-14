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


// Copyright 2010 Altera Corporation. All rights reserved.  
// Altera products are protected under numerous U.S. and foreign patents, 
// maskwork rights, copyrights and other intellectual property laws.  
//
// This reference design file, and your use thereof, is subject to and governed
// by the terms and conditions of the applicable Altera Reference Design 
// License Agreement (either as signed by you or found at www.altera.com).  By
// using this reference design file, you indicate your acceptance of such terms
// and conditions between you and Altera Corporation.  In the event that you do
// not agree with such terms and conditions, you may not use the reference 
// design file and please promptly destroy any copies you have made.
//
// This reference design file is being provided on an "as-is" basis and as an 
// accommodation and therefore all warranties, representations or guarantees of 
// any kind (whether express, implied or statutory) including, without 
// limitation, warranties of merchantability, non-infringement, or fitness for
// a particular purpose, are specifically disclaimed.  By making this reference
// design file available, Altera expressly does not recommend, suggest or 
// require that this reference design file be used in combination with any 
// other product not provided by Altera.
/////////////////////////////////////////////////////////////////////////////

`timescale 1 ps / 1 ps
// baeckler - 12-17-2009

// when not ready_in - immediately not ready_out
// when ready_in - wait for counter, then ready out synchronously

// DESCRIPTION
// 
// This is a more elaborate version of aclr_filter, typically used for bringing up SERDES pins or PLLs. When
// the input ready condition is not met the output is immediately driven to not ready. When the input
// ready becomes true the output will become ready after a programmable delay.
// 



// CONFIDENCE
// This is used very liberally in Altera test and demo designs
// 

module alt_reset_delay #(
	parameter CNTR_BITS = 16
)
(
	input clk,
	input ready_in,
	output ready_out
);

reg [2:0] rs_meta /* synthesis preserve dont_replicate */
/* synthesis ALTERA_ATTRIBUTE = "-name SDC_STATEMENT \"set_false_path -from [get_fanins -async *reset_delay*rs_meta\[*\]] -to [get_keepers *reset_delay*rs_meta\[*\]]\" " */;

always @(posedge clk or negedge ready_in) begin
	if (!ready_in) rs_meta <= 3'b000;
	else rs_meta <= {rs_meta[1:0],1'b1};
end
wire ready_sync = rs_meta[2];

reg [CNTR_BITS-1:0] cntr /* synthesis preserve */;
assign ready_out = cntr[CNTR_BITS-1];
always @(posedge clk or negedge ready_sync) begin
	if (!ready_sync) cntr <= {CNTR_BITS{1'b0}};
	else if (!ready_out) cntr <= cntr + 1'b1;
end

endmodule

// BENCHMARK INFO :  10AX115U2F45I2SGE2
// BENCHMARK INFO :  Quartus Prime Version 15.1.0 Internal Build 99 06/10/2015 TO Standard Edition
// BENCHMARK INFO :  Uses helper file :  alt_reset_delay.v
// BENCHMARK INFO :  Max depth :  3.4 LUTs
// BENCHMARK INFO :  Total registers : 19
// BENCHMARK INFO :  Total pins : 3
// BENCHMARK INFO :  Total virtual pins : 0
// BENCHMARK INFO :  Total block memory bits : 0
// BENCHMARK INFO :  Comb ALUTs :  17                 
// BENCHMARK INFO :  ALMs : 9 / 427,200 ( < 1 % )
// BENCHMARK INFO :  Worst setup path @ 468.75MHz : 0.796 ns, From cntr[15], To ready_out}
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "B1jX1eSmksrlkd8lAXcyKkr8jziX0V56m1FWHuGFSGge+pEUkt/d2rLZJkewbmrxcTMj/JXnsn3QhcoK2LomdJUZMBUi5nRXGNv/0kmMhRSqMxsKPAQcVCD5aZKrEPzCIhpM6C8PPeUlRKSDZ0v0pHSspq1Q2azT6NerDE/Cxz3qBja6xhbB3TS4as5Dtbc70cyYht+yuVIsb7HBV4rES/fGfsaGitKL9geqDgMw2MQVLmBy5lkYZ8zzxsHdm9a4ipKsDbjYbK68dusZd7m8ODhc+mcwydBwcF5jaic7+Ot8DOM7fMOGXRGibK7qLiqBvPX/SyK0uzLaOV8bYrvxPkQuJ06PY+rVv92y179pOxjY49vDRZQjpta02J/Tk/sZmqIBLAU63+6VM/WvwB6Glkv6VffJetHeWl4q/0twgHNXgPv+s4GTvAhvjS5XC5J8Ht8h866AESBw/nwFKXcwrgA7ccoaphw9NPogdTU2WpofhwtOzwpRJxf3a5Ijw5r4C8bRWEydwGtfrRfpmjnAaVrX7CEWUJfRshWAU0NHwopHU4fgPqOcfvAkrOSveCIxlW8HlolTuwbPWdUHxtdn+oR/QZ4B+tWRJYOgx1gfgGxxw6b8tCCZlY4nJ1a+VudUOj6axUK26000HkB9k3b5xRUee3Sz7ttm6rxlL6on/goq9CXVpr6j7P0Ao3ZWZev6Nuxt7L5fZHZ0DQE0zz/v+06u06mMc/dG8MMF8UGgHejatttyAqealZJ+z2BoIQlXvtmBrD6FZbeo5V8oQl3nTV7yJKLwieVG6EShe1ddaUsWEN7A0i6DwpB+0DMEFd+twsgsTPlH6K0hH+T7Svx/HWtM3h6wCsMQWrehzfcHILB+TA1mZ6HWcxyUeTYM9F1zrgfLUS8PfXcIuohgQcy1BP+RfKc7/AfMno1nWpaZcPpW0Z3dyPyeV6xk5XPa5h0ZIDY+72M+JEEOMYkFT/2i5BtUcX11Fnk3swu3mzfuZJAjVN+pQ0mKPfwnwphubFUW"
`endif