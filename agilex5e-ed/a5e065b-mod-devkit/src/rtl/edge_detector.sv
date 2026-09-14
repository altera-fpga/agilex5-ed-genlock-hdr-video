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


//**********************************************************************************
// Edge Detector
//**********************************************************************************
`timescale 1 ns / 1 ps

module edge_detector #(
   parameter EDGE_DETECT = "POSEDGE"
) (
   input wire clk,
   input wire rst,
   input wire d,
   output reg q
);

reg d_reg;
always @ (posedge clk or posedge rst)
begin
   if (rst) begin
      d_reg <= 1'b0;
      q <= 1'b0;
   end else begin 
      d_reg <= d;

      if (EDGE_DETECT == "POSEDGE") begin
         q <= d & ~d_reg;
      end else if (EDGE_DETECT == "NEGEDGE") begin
         q <= ~d & d_reg;
      end else if (EDGE_DETECT == "DUAL_EDGE") begin
         q <= d ^ d_reg;
      end
   end
end

endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "B1jX1eSmksrlkd8lAXcyKkr8jziX0V56m1FWHuGFSGge+pEUkt/d2rLZJkewbmrxcTMj/JXnsn3QhcoK2LomdJUZMBUi5nRXGNv/0kmMhRSqMxsKPAQcVCD5aZKrEPzCIhpM6C8PPeUlRKSDZ0v0pHSspq1Q2azT6NerDE/Cxz3qBja6xhbB3TS4as5Dtbc70cyYht+yuVIsb7HBV4rES/fGfsaGitKL9geqDgMw2MQRMbi+b5YQgEdvJ7wJTxhUp6F7qp0iq+s5GRo6qOe3Yg2N/hMejtOJ4hwSmr44zcwK0lM0GFKYBfPGDpOABRyXHl+iffFhbir9GeWe0aUea+7okAr8Dd/bLu8QVTRHiLaiqkZEiBXHIMLpvr9qMQ0i6KjJ3iCYBHNMVs8QwOKmGyLUsmh4+oXDrlke/peWuq3FLl2PyVzW0BG+bU7D0ddD1/LTCVTM66pnDajezsTj1B8wVDkV+0G4SqkX43lczDa6i1RIM1o6WMKZwoktSpQcZ0BCBANoP35h934j9GZ1Qy/5BC2IXnpVztvk0m4sFDy50giT/rWdgSAFr+y5pusRsn9P0UdwuGsxZOx13ptgK9+ugGzxDvgT4+rWLcn2ImyjhRnHZCZr97kojiUvpqnUHqd2lWmX2IrQEOXOh+PRdR4qQbHlnt/o5nKUy5uEpZv4rLEM3MU2neR0Pb9lgs9nd9QSUilM0yOKFRwVHvqidychnfoB16EFrEhthu0CgKfBF9y7ospeJctn0iXmav1BL8tQ5OHpCbDcH+Mm/LkjNHONOGtKbe3qSWwBE0lwWUFl1/bm9HVqEyzdumTjlS2QCHglFxbPoRRJFM1RNXnqjsFiZLSR+n2XzQgMu56ik1C7Bfd9PPfdx7A1DftsTJLHyWYophZ60ylF+vTOIS5DanShO+7USjwIBCOxFswEtLFy5MjUyUu219wfxfUDzK07c7N1RM5zyrUgVu9ez8pcqkDAixZCKvEu149l4CnBzGlGBYnuAHi1Vzpl6jqOhc8C"
`endif