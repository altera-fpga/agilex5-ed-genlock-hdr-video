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

#include "intel_cv2axi.h"
#include "intel_cv2axi_regs.h"

 //=========================================================================================
int intel_cv2axi_init(intel_cv2axi_instance* instance, intel_vab_core_base base)
{
    int init_ret;

    init_ret = intel_vab_core_init(&(instance->core_instance), base, INTEL_CV2AXI_PRODUCT_ID);

    if (0 == init_ret)
    {
       instance->_can_debug = 0;
        //instance->_can_debug = (0 != INTEL_CV2AXI_REG_IORD(instance, INTEL_CV2AXI_DEBUG_REG));
    }

    return init_ret;
}
    
//=========================================================================================
bool intel_cv2axi_get_debug_enabled(intel_cv2axi_instance* instance)
{
    if (instance != NULL)
        return instance->_can_debug;
    return 0;
}

//TODO Commented functions are those inherited from Clocked_Video_Input.hpp but not yet implemented in here
////=========================================================================================
///**
// * @brief  Enable the status update interrupt
// * @post   Request an HW interrupt when the status register content changes
// */
//inline void enable_status_update_interrupt() {
//    enable_interrupt(CVI_IRQ_STATUS_UPDATE);
//}
///**
// * @brief  Disable the status update interrupt
// */
//inline void disable_status_update_interrupt() {
//    disable_interrupt(CVI_IRQ_STATUS_UPDATE);
//}
//
///**
// * @brief  Enable the end of field/frame interrupt
// * @post   Request an HW interrupt at EOF
// *         If parameterized with "Any field first", the EOF interrupt is triggered on the falling edge of the vsync.
// *         If parameterized with "F1 first", the EOF interrupt is triggered on the falling edge of the F1 vsync.
// *         If parameterized with "F0 first", the EOF interrupt is triggered on the falling edge of the F0 vsync.
// */
//inline void enable_end_of_field_frame_interrupt() {
//    enable_interrupt(CVI_IRQ_END_OF_FIELD_FRAME);
//}
///**
// * @brief  Disable the end of field/frame interrupt
// */
//inline void disable_end_of_field_frame_interrupt() {
//    disable_interrupt(CVI_IRQ_END_OF_FIELD_FRAME);
//}
//
///**
// * @brief   Check the state of the status_update interrupt
// * @return  true if the status update interrupt has fired and is still on
// */
//inline bool has_status_update_interrupt_fired() {
//    return has_interrupt_fired(read_interrupt_register(), CVI_IRQ_STATUS_UPDATE);
//}
///**
// * @brief   Check the state of the status_update interrupt
// * @param   the content of the status register (to avoid the need to poll it again)
// * @return  true if the status update interrupt has fired and is still on
// */
//inline static bool has_status_update_interrupt_fired(unsigned int interrupt_register) {
//    return has_interrupt_fired(interrupt_register, CVI_IRQ_STATUS_UPDATE);
//}
//
///**
// * @brief   Check the state of the end of field/frame interrupt
// * @return  true if the end of field/frame interrupt has fired and is still on
// */
//inline bool has_end_of_field_frame_interrupt_fired() {
//    return has_interrupt_fired(read_interrupt_register(), CVI_IRQ_END_OF_FIELD_FRAME);
//}
///**
// * @brief   Check the state of the end of field/frame interrupt
// * @param   the content of the status register (to avoid the need to poll it again)
// * @return  true if the end of field/frame interrupt has fired and is still on
// */
//inline static bool has_end_of_field_frame_interrupt_fired(unsigned int interrupt_register) {
//    return has_interrupt_fired(interrupt_register, CVI_IRQ_END_OF_FIELD_FRAME);
//}
//
///**
// * @brief   Clear the status update interrupt
// * @post    Issues a write to the interrupt to clear the status update interrupt (and no other!)
// */
//inline void clear_status_update_interrupt() {
//    clear_interrupt(CVI_IRQ_STATUS_UPDATE);
//}
//
///**
// * @brief   Clear the end of field/frame interrupt
// * @post    Issues a write to the interrupt to clear the end of field/frame interrupt (and no other!)
// */
//inline void clear_end_of_field_frame_interrupt() {
//    clear_interrupt(CVI_IRQ_END_OF_FIELD_FRAME);
//}
//
///**
// * @brief   is_producing_data is an alias to VipCoreAXI::is_running()
// * @see     VipCoreAXI::is_running()
// */
//inline bool is_producing_data() {
//    return is_running();
//}

/**
 * @brief   Poll the status register and check the CVI_INTERLACED bit
 * @return  The value of the interlaced bit in the status register
 */
bool intel_cv2axi_is_interlaced(intel_cv2axi_instance* instance) {
    return intel_cv2axi_read_status_register_bit(instance, CVI_INTERLACED);
}

/**
 * @brief   Poll the status register and check the CVI_STABLE_INPUT_WIDTH bit
 * @return  The value of the stable_width bit in the status register
 */
bool intel_cv2axi_is_input_width_stable(intel_cv2axi_instance* instance) {
    return intel_cv2axi_read_status_register_bit(instance, CVI_STABLE_INPUT_WIDTH);
}

/**
 * @brief   Poll the status register and check the CVI_OVERFLOW bit
 * @return  The value of the (sticky) overflow bit in the status register
 */
bool intel_cv2axi_is_overflowed(intel_cv2axi_instance* instance) {
    return intel_cv2axi_read_status_register_bit(instance, CVI_OVERFLOW);
}

/**
 * @brief   Poll the status register and check the CVI_VALID_RESOLUTION bit
 * @return  The value of the valid_resolution bit in the status register
 */
bool intel_cv2axi_is_valid_resolution(intel_cv2axi_instance* instance) {
    return intel_cv2axi_read_status_register_bit(instance, CVI_VALID_RESOLUTION);
}

/**
 * @brief   Poll the status register and check the CVI_VIDEO_LOCKED bit
 * @return  The value of the video_locked bit in the status register
 */
bool intel_cv2axi_is_locked(intel_cv2axi_instance* instance) {
    return intel_cv2axi_read_status_register_bit(instance, CVI_VIDEO_LOCKED);
}

/**
 * @brief   Poll the status register and check the CVI_VIDEO_LOCKED, CVI_STABLE_INPUT_WIDTH and CVI_VALID_RESOLUTION bits
 * @return  true if all the three bits are set (video_locked && stable_width && valid_resolution)
 * @post    Unfortunately, this may not be enough to guarantee that the stream is "stable". So multiple calls
 *          over successive frames may be necessary
 */
bool intel_cv2axi_is_stream_stable(intel_cv2axi_instance* instance) {
    unsigned int mask = (1 << CVI_VIDEO_LOCKED) | (1 << CVI_STABLE_INPUT_WIDTH) | (1 << CVI_VALID_RESOLUTION);
    return ((intel_cv2axi_read_status_register(instance) & mask) == mask);
}

/**
 * @brief   Poll the status register and check the CVI_VIDEO_PICTURE_DROP bit
 * @return  The value of the (sticky) picture drop bit in the status register
 */
bool intel_cv2axi_is_picture_drop(intel_cv2axi_instance* instance) {
    return intel_cv2axi_read_status_register_bit(instance, CVI_VIDEO_PICTURE_DROP);
}

/**
 * Returns the used words level of the input FIFO. Used in conjunction with the
 * total depth of the input FIFO will give you the percentage of the FIFO that
 * is filled with data.
 */
unsigned int intel_cv2axi_get_fifo_used_words(intel_cv2axi_instance* instance) {
    return INTEL_CV2AXI_REG_IORD(instance, INTEL_CV2AXI_USED_WORDS);
}

/**
 * @return   the detected sample count of the video streams (excluding blanking)
 */
unsigned int intel_cv2axi_get_active_sample_count(intel_cv2axi_instance* instance) {
    return INTEL_CV2AXI_REG_IORD(instance, INTEL_CV2AXI_ACTIVE_SAMPLE_COUNT);
}

/**
 * @return   the detected line count of the video streams F0 field (excluding blanking)
 */
unsigned int intel_cv2axi_get_active_line_count_f0(intel_cv2axi_instance* instance) {
    return INTEL_CV2AXI_REG_IORD(instance, INTEL_CV2AXI_ACTIVE_LINE_COUNT_F0);
}

/**
 * @return   the detected line count of the video streams F1 field (excluding blanking)
 */
unsigned int intel_cv2axi_get_active_line_count_f1(intel_cv2axi_instance* instance) {
    return INTEL_CV2AXI_REG_IORD(instance, INTEL_CV2AXI_ACTIVE_LINE_COUNT_F1);
}

/**
 * @return   the detected sample count of the video streams (including blanking)
 */
unsigned int intel_cv2axi_get_total_sample_count(intel_cv2axi_instance* instance) {
    return INTEL_CV2AXI_REG_IORD(instance, INTEL_CV2AXI_TOTAL_SAMPLE_COUNT);
}

/**
 * @return   the detected line count of the video streams F0 field (including blanking)
 */
unsigned int intel_cv2axi_get_total_line_count_f0(intel_cv2axi_instance* instance) {
    return INTEL_CV2AXI_REG_IORD(instance, INTEL_CV2AXI_TOTAL_LINE_COUNT_F0);
}

/**
 * @return   the detected line count of the video streams F1 field (including blanking)
 */
unsigned int intel_cv2axi_get_total_line_count_f1(intel_cv2axi_instance* instance) {
    return INTEL_CV2AXI_REG_IORD(instance, INTEL_CV2AXI_TOTAL_LINE_COUNT_F1);
}

/**
 * @return   the video standard
 */
unsigned int intel_cv2axi_get_vid_standard(intel_cv2axi_instance* instance) {
    return INTEL_CV2AXI_REG_IORD(instance, INTEL_CV2AXI_VID_STANDARD);
}

/**
 * @return   the 8-bit code of the value driven on the vid_color_encoding input.
 */
unsigned int intel_cv2axi_get_color_pattern(intel_cv2axi_instance* instance) {
    return INTEL_CV2AXI_REG_IORD(instance, INTEL_CV2AXI_COLOR_PATTERN) & 0x3FF;
}

/**
 * @return   the 8-bit code of the value driven on the vid_bit_width input.
 */
unsigned int intel_cv2axi_get_bit_width(intel_cv2axi_instance* instance) {
    return (INTEL_CV2AXI_REG_IORD(instance, INTEL_CV2AXI_COLOR_PATTERN) >> 10) & 0xFF;
}

/**
 * @param    sample   the sample
 * @return   Selected sample of the ancillary packet
 * @pre      0 <= sample < ancillary packet mem depth
 */
unsigned int intel_cv2axi_get_ancillary_packet_sample(intel_cv2axi_instance* instance, unsigned int sample) {
    return INTEL_CV2AXI_REG_IORD(instance, INTEL_CV2AXI_ANCILLARY_PACKET + sample);
}

/**
 * @return  Give the picture drop count. When picture drop sticky bit is asserted, 
 *          this drop count provides the number of frame/field dropped at the input.
 *          Count resets when you clear the picture drop sticky bit.
 *          Counter is at bits 15-21 of the Status Register.
 */
unsigned int intel_cv2axi_get_picture_drop_count(intel_cv2axi_instance* instance) {
    return (intel_cv2axi_read_status_register(instance) >> CVI_VIDEO_PICTURE_DROP) & 0x7F;
}

/**
 * Reset the overflow sticky bit to 0. When overflow of the input FIFO is
 * detected, the overflow bit will be asserted and stay asserted until reset
 * using this method. The CVI is one of the unusual core allowing writes to
 * the status register
 * @see is_overflowed()
 */
void intel_cv2axi_clear_overflow_flag(intel_cv2axi_instance* instance) {
    INTEL_CV2AXI_REG_IOWR(instance, INTEL_CV2AXI_STATUS_REG, 1 << CVI_OVERFLOW);
}

/**
 * Reset the picture drop sticky bit to 0. Reset the picture drop counter
 */
void intel_cv2axi_clear_picture_drop_flag(intel_cv2axi_instance* instance) {
    INTEL_CV2AXI_REG_IOWR(instance, INTEL_CV2AXI_STATUS_REG, 1 << CVI_VIDEO_PICTURE_DROP);
}

void intel_cv2axi_start(intel_cv2axi_instance* instance) {
    unsigned int control_reg = INTEL_CV2AXI_REG_IORD(instance, INTEL_CV2AXI_CONTROL_REG);
    INTEL_CV2AXI_REG_IOWR(instance, INTEL_CV2AXI_CONTROL_REG, control_reg | 1);
}

void intel_cv2axi_stop(intel_cv2axi_instance* instance) {
    unsigned int control_reg = INTEL_CV2AXI_REG_IORD(instance, INTEL_CV2AXI_CONTROL_REG);
    INTEL_CV2AXI_REG_IOWR(instance, INTEL_CV2AXI_CONTROL_REG, control_reg & ~1);
}


uint32_t intel_cv2axi_read_status_register (intel_cv2axi_instance* instance) {
    return INTEL_CV2AXI_REG_IORD(instance, INTEL_CV2AXI_STATUS_REG);
}

bool intel_cv2axi_read_status_register_bit (intel_cv2axi_instance* instance, unsigned int bit) {
    return INTEL_CV2AXI_REG_IORD(instance, INTEL_CV2AXI_STATUS_REG) & (1 << bit);
}

unsigned int intel_cv2axi_get_vpid(intel_cv2axi_instance* instance, unsigned int byte_num) {
    return INTEL_CV2AXI_REG_IORD(instance, INTEL_CV2AXI_VPID_BYTE1 + byte_num - 1);
}


//=========================================================================================
//eof
