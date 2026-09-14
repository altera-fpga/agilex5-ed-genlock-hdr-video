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

#ifndef __INTEL_CV2AXI_REGS_H__
#define __INTEL_CV2AXI_REGS_H__

#define INTEL_CV2AXI_STATUS_REG                   0x50 //RO
#define INTEL_CV2AXI_USED_WORDS                   0x51
#define INTEL_CV2AXI_ACTIVE_SAMPLE_COUNT          0x52
#define INTEL_CV2AXI_ACTIVE_LINE_COUNT_F0         0x53
#define INTEL_CV2AXI_ACTIVE_LINE_COUNT_F1         0x54
#define INTEL_CV2AXI_TOTAL_SAMPLE_COUNT           0x55
#define INTEL_CV2AXI_TOTAL_LINE_COUNT_F0          0x56
#define INTEL_CV2AXI_TOTAL_LINE_COUNT_F1          0x57
#define INTEL_CV2AXI_VID_STANDARD                 0x58
#define INTEL_CV2AXI_COLOR_PATTERN                0x5C
#define INTEL_CV2AXI_VPID_BYTE1                   0x5D
#define INTEL_CV2AXI_VPID_BYTE2                   0x5E
#define INTEL_CV2AXI_VPID_BYTE3                   0x5F
#define INTEL_CV2AXI_VPID_BYTE4                   0x60
#define INTEL_CV2AXI_ANCILLARY_PACKET             0x62
#define INTEL_CV2AXI_CONTROL_REG                  0x50+15+1+4 //RW
#define INTEL_CV2AXI_INTERRUPT_REG                0x50+15+1+4+1 //RW

/**
 * Each bit in the CVI Control register enables/disables a different
 * feature of the core.These are the addresses of each bit (indexed from 0)
 *
 * STATUS_UPDATE interrupt:
 * Fires whenever there is a change to the REGISTER_STATUS register
 *
 * END_OF_FIELD_FRAME interrupt:
 * If the Qsys synchronization settings are set to "Any field first", the EOF
 * interrupt is triggered on the falling edge of the vsync.
 * If the Qsys synchronization settings are set to "F1 first", the EOF
 * interrupt is triggered on the falling edge of the F1 vsync.
 * If the Qsys synchronization settings are set to "F0 first", the EOF
 * interrupt is triggered on the falling edge of the F0 vsync.
 * You can use this interrupt to trigger the reading of the ancillary packets
 * from the control interface before the packets are overwritten by the next
 * frame.
 *
 */
enum CVIControlBit {
    // Interrupts:
    CVI_IRQ_STATUS_UPDATE      = 1,
    CVI_IRQ_END_OF_FIELD_FRAME = 2,
};

/**
 * Each bit in the status register has a different meaning. These are the
 * addresses of each bit (indexed from 0)
 */
enum CVIStatusBit {
    CVI_PRODUCING_DATA         = 0,
    // Bits 1-6 are reserved
    CVI_INTERLACED             = 7,
    CVI_STABLE_INPUT_WIDTH     = 8,
    CVI_OVERFLOW               = 9,
    CVI_VALID_RESOLUTION       = 10,
    CVI_VIDEO_LOCKED           = 11,
    CVI_VIDEO_CLIPPING         = 12,
    CVI_VIDEO_PADDING          = 13,
    CVI_VIDEO_PICTURE_DROP     = 14,
};

#endif // __INTEL_CV2AXI_REGS_H__
