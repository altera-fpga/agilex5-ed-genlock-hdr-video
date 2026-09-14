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

#include <stdio.h>
#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#include "intel_vab_core.h"

#ifndef __INTEL_CV2AXI_H__
#define __INTEL_CV2AXI_H__

#ifdef __cplusplus
extern "C"
{
#endif /* __cplusplus */
// NOTE: CVI is ClockedVideoOutput

#define INTEL_CV2AXI_PRODUCT_ID                           0x0340u              ///< CVI product ID
#define INTEL_CV2AXI_MIN_SUPPORTED_REGMAP_VERSION         1                    ///< Minimum supported register map version
#define INTEL_CV2AXI_MAX_SUPPORTED_REGMAP_VERSION         1                    ///< Maximum supported register map version

#define INTEL_CV2AXI_REG_IORD(instance, reg)          INTEL_VAB_CORE_REG_IORD((&(instance->core_instance)), (reg))           ///< 3D LUT register read function
#define INTEL_CV2AXI_REG_IOWR(instance, reg, value)   INTEL_VAB_CORE_REG_IOWR((&(instance->core_instance)), (reg), (value))  ///< 3D LUT register write function

// Some convenient defines to use when calling the set_output_mode function
//                           interl,   seq, width, height, f1_h,      h blanking,  v_blanking,   f0_blanking,  active_line, field_toggles, ancillary,   sync_pol,
#define CVI_720P_MODE         false, false,  1280,    720,    0,    110, 40, 370,    5, 5, 30,      0, 0,  0,           26,    0,   0, 0,   10,   0,   true, true
//#define CVI_1080I_MODE         true, false,  1920,    540,  540,     88, 44, 280,    3, 5, 22,      2, 5, 23,           22,  540, 0, 0,   10, 562,   true, true
#define CVI_1080I_MODE         true, false,  1920,    540,  540,     88, 44, 280,    2, 5, 22,      2, 5, 23,           22,  562, 564, 2,   10, 562,   true, true
#define CVI_1080I_SDI_MODE     true, false,  1920,    540,  540,      0,  0, 280,    0, 0, 22,      0, 0, 23,           21,  561, 564, 1,   10, 562,   true, true
#define CVI_1080P_MODE        false, false,  1920,   1080,    0,     88, 44, 280,    4, 5, 45,      0, 0,  0,           42,    0,   0, 0,   10,   0,   true, true
#define CVI_2160P_MODE        false, false,  3840,   2160,    0,    176, 88, 560,   8, 10, 90,      0, 0,  0,           84,    0,   0, 0,   20,   0,   true, true

enum CVIModeXControlBit {
    CVI_INTERLACED_OUTPUT      = 0,
    CVI_SEQUENTIAL_OUTPUT      = 1,
};

typedef struct intel_cv2axi_instance_s
{
    intel_vab_core_instance core_instance;           ///< Base intel_vab_core_instance
    bool        _can_debug;
} intel_cv2axi_instance;	   

/**
 * \brief Initialise a CVI instance
 * 
 * Initialization function for a VAB CVI instance.
 * Attempts to initialize the fields of the CVI and its base core
 * 
 * \param[in]    instance, pointer to the intel_vab_crs_instance to initialize
 * \param[in]    base, the accessor for the core (on Nios this is a pointer to the base address of the core)
 * \return        0 success
 *               -1 if the vendor id of the core is not the IntelFPGA vendor ID (0x6AF7).
 *               -2 if the product id of the core is not the CVI product id (0x0165)
 * \remarks      On returning a non-zero error code the instance will not be initialized and
 *               cannot be used further by the application using this driver
 */

int intel_cv2axi_init(intel_cv2axi_instance* instance, intel_vab_core_base base);

//====================================================================================
//   \brief Get debug status of IP core
//  
// \param[in]     instance, pointer to the intel_vab_pip_conv_instance
// \return        true can read(debug) register values
//                false can NOT read(debug) register values

bool intel_cv2axi_get_debug_enabled(intel_cv2axi_instance* instance);


//=========================================================================================
//   \brief Set the current output mode
//  
// \param[in]     instance, pointer to the intel_vab_pip_conv_instance
// \param[in]     output_mode, new output mode
// \return        a bitmask of modes supported

/**
 * @brief   Poll the status register and check the CVI_INTERLACED bit
 * @return  The value of the interlaced bit in the status register
 */
bool intel_cv2axi_is_interlaced(intel_cv2axi_instance* instance);

/**
 * @brief   Poll the status register and check the CVI_STABLE_INPUT_WIDTH bit
 * @return  The value of the stable_width bit in the status register
 */
bool intel_cv2axi_is_input_width_stable(intel_cv2axi_instance* instance);

/**
 * @brief   Poll the status register and check the CVI_OVERFLOW bit
 * @return  The value of the (sticky) overflow bit in the status register
 */
bool intel_cv2axi_is_overflowed(intel_cv2axi_instance* instance);

/**
 * @brief   Poll the status register and check the CVI_VALID_RESOLUTION bit
 * @return  The value of the valid_resolution bit in the status register
 */
bool intel_cv2axi_is_valid_resolution(intel_cv2axi_instance* instance);

/**
 * @brief   Poll the status register and check the CVI_VIDEO_LOCKED bit
 * @return  The value of the video_locked bit in the status register
 */
bool intel_cv2axi_is_locked(intel_cv2axi_instance* instance);

/**
 * @brief   Poll the status register and check the CVI_VIDEO_LOCKED, CVI_STABLE_INPUT_WIDTH and CVI_VALID_RESOLUTION bits
 * @return  true if all the three bits are set (video_locked && stable_width && valid_resolution)
 * @post    Unfortunately, this may not be enough to guarantee that the stream is "stable". So multiple calls
 *          over successive frames may be necessary
 */
bool intel_cv2axi_is_stream_stable(intel_cv2axi_instance* instance);

/**
 * @brief   Poll the status register and check the CVI_VIDEO_PICTURE_DROP bit
 * @return  The value of the (sticky) picture drop bit in the status register
 */
bool intel_cv2axi_is_picture_drop(intel_cv2axi_instance* instance);

/**
 * Returns the used words level of the input FIFO. Used in conjunction with the
 * total depth of the input FIFO will give you the percentage of the FIFO that
 * is filled with data.
 */
unsigned int intel_cv2axi_get_fifo_used_words(intel_cv2axi_instance* instance);

/**
 * @return   the detected sample count of the video streams (excluding blanking)
 */
unsigned int intel_cv2axi_get_active_sample_count(intel_cv2axi_instance* instance);

/**
 * @return   the detected line count of the video streams F0 field (excluding blanking)
 */
unsigned int intel_cv2axi_get_active_line_count_f0(intel_cv2axi_instance* instance);

/**
 * @return   the detected line count of the video streams F1 field (excluding blanking)
 */
unsigned int intel_cv2axi_get_active_line_count_f1(intel_cv2axi_instance* instance);

/**
 * @return   the detected sample count of the video streams (including blanking)
 */
unsigned int intel_cv2axi_get_total_sample_count(intel_cv2axi_instance* instance);

/**
 * @return   the detected line count of the video streams F0 field (including blanking)
 */
unsigned int intel_cv2axi_get_total_line_count_f0(intel_cv2axi_instance* instance);

/**
 * @return   the detected line count of the video streams F1 field (including blanking)
 */
unsigned int intel_cv2axi_get_total_line_count_f1(intel_cv2axi_instance* instance);

/**
 * @return   the video standard
 */
unsigned int intel_cv2axi_get_vid_standard(intel_cv2axi_instance* instance);

/**
 * @return   the 8-bit code of the value driven on the vid_color_encoding input.
 */
unsigned int intel_cv2axi_get_color_pattern(intel_cv2axi_instance* instance);

/**
 * @return   the 8-bit code of the value driven on the vid_bit_width input.
 */
unsigned int intel_cv2axi_get_bit_width(intel_cv2axi_instance* instance);

/**
 * @param    sample   the sample
 * @return   Selected sample of the ancillary packet
 * @pre      0 <= sample < ancillary packet mem depth
 */
unsigned int intel_cv2axi_get_ancillary_packet_sample(intel_cv2axi_instance* instance, unsigned int sample);

/**
 * @return  Give the picture drop count. When picture drop sticky bit is asserted, 
 *          this drop count provides the number of frame/field dropped at the input.
 *          Count resets when you clear the picture drop sticky bit.
 *          Counter is at bits 15-21 of the Status Register.
 */
unsigned int intel_cv2axi_get_picture_drop_count(intel_cv2axi_instance* instance);

/**
 * Reset the overflow sticky bit to 0. When overflow of the input FIFO is
 * detected, the overflow bit will be asserted and stay asserted until reset
 * using this method. The CVI is one of the unusual core allowing writes to
 * the status register
 * @see is_overflowed()
 */
void intel_cv2axi_clear_overflow_flag(intel_cv2axi_instance* instance);

/**
 * Reset the picture drop sticky bit to 0. Reset the picture drop counter
 */
void intel_cv2axi_clear_picture_drop_flag(intel_cv2axi_instance* instance);

uint32_t intel_cv2axi_read_status_register (intel_cv2axi_instance* instance);

bool intel_cv2axi_read_status_register_bit (intel_cv2axi_instance* instance, unsigned int bit);

unsigned int intel_cv2axi_get_vpid(intel_cv2axi_instance* instance, unsigned int byte_num);

void intel_cv2axi_start(intel_cv2axi_instance* instance);

void intel_cv2axi_stop(intel_cv2axi_instance* instance);

#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif // __INTEL_CV2AXI_H__
