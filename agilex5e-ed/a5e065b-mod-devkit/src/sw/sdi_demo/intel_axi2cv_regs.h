/*
 * ##########################################################################
 * 
 * Copyright 2021 Intel Corporation. All rights reserved.
 *
 * Your use of Intel Corporation's design tools, logic functions and other
 * software and tools, and its AMPP partner logic functions, and any output
 * files from any of the foregoing (including device programming or simulation
 * files), and any associated documentation or information are expressly subject
 * to the terms and conditions of the Intel Program License Subscription
 * Agreement, Intel FPGA IP License Agreement, or other applicable
 * license agreement, including, without limitation, that your use is for the
 * sole purpose of programming logic devices manufactured by Intel and sold by
 * Intel or its authorized distributors.  Please refer to the applicable
 * agreement for further details.
 * 
 * ##########################################################################
 */

#ifndef __INTEL_AXI2CV_REGS_H__
#define __INTEL_AXI2CV_REGS_H__

#define INTEL_AXI2CV_STATUS_REG                       0x50 //RO
#define INTEL_AXI2CV_VIDEO_MODE_MATCH                 0x51 //RW
#define INTEL_AXI2CV_CONTROL_REG                      0x52 //RW
#define INTEL_AXI2CV_BANK_SELECT                      0x53 //RW
#define INTEL_AXI2CV_MODEX_CONTROL                    0x54 //RW
#define INTEL_AXI2CV_MODEX_SAMPLE_COUNT               0x55 //RW
#define INTEL_AXI2CV_MODEX_F0_LINE_COUNT              0x56 //RW
#define INTEL_AXI2CV_MODEX_F1_LINE_COUNT              0x57 //RW
#define INTEL_AXI2CV_MODEX_HORIZONTAL_FRONT_PORCH     0x58 //RW
#define INTEL_AXI2CV_MODEX_HORIZONTAL_SYNC_LENGTH     0x59 //RW
#define INTEL_AXI2CV_MODEX_HORIZONTAL_BLANKING        0x5A //RW
#define INTEL_AXI2CV_MODEX_VERTICAL_FRONT_PORCH       0x5B //RW
#define INTEL_AXI2CV_MODEX_VERTICAL_SYNC_LENGTH       0x5C //RW
#define INTEL_AXI2CV_MODEX_VERTICAL_BLANKING          0x5D //RW
#define INTEL_AXI2CV_MODEX_F0_VERTICAL_FRONT_PORCH    0x5E //RW
#define INTEL_AXI2CV_MODEX_F0_VERTICAL_SYNC_LENGTH    0x5F //RW
#define INTEL_AXI2CV_MODEX_F0_VERTICAL_BLANKING       0x60 //RW
#define INTEL_AXI2CV_MODEX_ACTIVE_PICTURE_LINE        0x61 //RW
#define INTEL_AXI2CV_MODEX_F0_VERTICAL_RISING         0x62 //RW
#define INTEL_AXI2CV_MODEX_FIELD_RISING               0x63 //RW
#define INTEL_AXI2CV_MODEX_FIELD_FALLING              0x64 //RW
#define INTEL_AXI2CV_MODEX_STANDARD                   0x65 //RW
#define INTEL_AXI2CV_MODEX_VPID_BYTE1                 0x66 //RW
#define INTEL_AXI2CV_MODEX_VPID_BYTE2                 0x67 //RW
#define INTEL_AXI2CV_MODEX_VPID_BYTE3                 0x68 //RW
#define INTEL_AXI2CV_MODEX_VPID_BYTE4                 0x69 //RW
#define INTEL_AXI2CV_MODEX_HSYNC_POLARITY             0x6B //RW
#define INTEL_AXI2CV_MODEX_VSYNC_POLARITY             0x6C //RW
#define INTEL_AXI2CV_MODEX_VALID                      0x6D //RW

#endif // __INTEL_AXI2CV_REGS_H__
