#include <stdio.h>
#include <unistd.h>
#include <io.h>
#include <fcntl.h>
#include <string.h>
#include <math.h>
#include "sys/alt_timestamp.h"
#include "sys/alt_stdio.h"
#include "alt_types.h"
#include "sys/alt_irq.h"
#include "intel_axi2cv.h"
#include "intel_cv2axi.h"
#include "system.h"
#include "intel_fpga_i2c.h"
#include <stdlib.h>

#include "intel_vvp_crs.h"
#include "intel_vvp_csc.h"
#include "intel_vvp_3d_lut.h"
#include "intel_vvp_clipper.h"
#include "intel_vvp_tpg.h"
#include "intel_vvp_mixer.h"
#include "intel_vvp_protocol_conv.h"

#define TIMEOUT_LIMIT 100000  // Adjust this value as needed
#define RAW_I2C_SLAVE_ADDR  0x17   // <-- Replace with your actual slave address

#define IMG_INFO_COLORSPACE_RGB   0
#define IMG_INFO_COLORSPACE_YUV   1

#define IMG_INFO_SUBSAMPLING_420  0
#define IMG_INFO_SUBSAMPLING_422  2
#define IMG_INFO_SUBSAMPLING_444  3

#define INIT_HSIZE  1920
#define INIT_VSIZE  1080

struct color_info {
    int space;
    int depth;
    int wcg;   /* SDR color (bt.709/sRGB) or HDR gamut (bt2020) */
};
struct image_config {
    int x;
    int y;
    bool interlace;
    struct color_info image_color;
    unsigned int std;
    unsigned int vpid_byte1;
    unsigned int vpid_byte2;
    unsigned int vpid_byte3;
    unsigned int vpid_byte4;
};

intel_vvp_csc_instance csc_sdi_rx;
intel_vvp_3d_lut_instance vvp_3d_lut_ch1_0;
intel_vvp_3d_lut_instance vvp_3d_lut_ch2_0;
intel_vvp_clipper_instance clipper_ch0;
intel_vvp_clipper_instance clipper_ch1;
intel_vvp_clipper_instance clipper_ch2;
intel_vvp_tpg_instance tpg_mixer;
intel_vvp_mixer_instance mixer;
intel_vvp_protocol_conv_instance proto_lite_to_full; 
intel_vvp_csc_instance csc_sdi_tx;
intel_vvp_crs_instance crs_sdi_tx;

intel_cv2axi_instance cv2axi; 
intel_axi2cv_instance axi2cv;
void cvi_res_switch(intel_cv2axi_instance* cvi, intel_axi2cv_instance* cvo, struct image_config *current_image_config);
void cvo_program_mode_bank(intel_axi2cv_instance* cvo, unsigned int sel, unsigned int vid_std, unsigned int vpid_byte1, unsigned int vpid_byte2, unsigned int vpid_byte3, unsigned int vpid_byte4);
void send_raw_cmd_masked(long i2c_base, unsigned char slave_addr, unsigned char reg, unsigned char data, unsigned char mask);
int res_switch = 1;
int prev_vid_standard = -1;
struct image_config cvi_image_config = {.x = 0, .y = 0, .interlace = false, .image_color.space = 0, .image_color.depth = 0, .image_color.wcg = 0, .std=0, .vpid_byte1=0, .vpid_byte2=0, .vpid_byte3=0, .vpid_byte4=0};
void set_max10(long i2c_base, const int i2c_addr);
int set_si54x(long i2c_base, const int i2c_addr, const double Output_Freq, const int is546, const char SpeedGrade);
void start_systempll(void);
void board_init(void);

int main()
{

    printf("\n===========================================================");
    printf("\nDemo   : 4Kp60 SDI-based Genlock HDR Video Example Design");
    printf("\nDevkit : Agilex 5E Group B MDK Rev C");
    printf("\nFMC    : Nextera SDI 12G-FMC");
    printf("\nOptions from the Keyboard:");
    printf("\n===========================================================\n");
        
    printf("board_init has started...\n");
    intel_fpga_i2c_init(I2C_0_BASE, I2C_0_FREQ);
    intel_fpga_i2c_init(I2C_CLOCKS_BASE, I2C_0_FREQ);    
    intel_fpga_i2c_init(I2C_MAX10_BASE, I2C_0_FREQ);  

    // Initialize the devkit
    board_init();    

    // Force non-blocking jtag uart
    int res_in = 0;
    int res_out = 0;
    res_out = fcntl(STDOUT_FILENO, F_SETFL, O_NONBLOCK);
    res_in = fcntl(STDIN_FILENO, F_SETFL, O_NONBLOCK);
    if ( (res_in == -1) || (res_out == -1) )
    {
        printf("FCNTL Failed\n");
    }

//////////////////////////////////////
    printf("\nStarting VVP IP Cores Configuration\n");

    uint32_t width_layer_1          = 0;
    uint32_t width_layer_2          = 0;       
    uint32_t width_layer_3          = 0;       
    uint32_t current_x_dim          = 0;       
    uint32_t current_mixer_mode     = 0;

    // const intel_vvp_coefficients csc_passthrough            = CSC_PASSTHROUGH_COEFFS;
    const intel_vvp_coefficients csc_ycchd_to_rgb_10bits    = CSC_YCCHD_TO_RGB_COEFFS; // 10-bit data   
    const intel_vvp_coefficients csc_rgb_to_ycchd_10bits    = CSC_RGB_TO_YCCHD_COEFFS; // 8-bit data

    // SDI Tx CVO (VVP-Full)
    intel_vab_core_base axi2cv_addr_base = (intel_vab_core_base)(SDI_TX_MR_BASE);
    intel_axi2cv_init (&axi2cv, axi2cv_addr_base);

    // Output CRS (VVP-Full)
    intel_vvp_crs_init(&crs_sdi_tx, (intel_vvp_core_base)VVP_CRS_TX_BASE);
    //kIntelVvpCrsSubsampling422, kIntelVvpCrsSubsampling444
    intel_vvp_crs_set_output_subsampling(&crs_sdi_tx, kIntelVvpCrsSubsampling422);
    intel_vvp_crs_commit_writes(&crs_sdi_tx);     

    // Output CSC (VVP-Full)
    intel_vvp_csc_init(&csc_sdi_tx, (intel_vvp_core_base)VVP_CSC_TX_BASE);
    //  kIntelVvpCsYcc (YCbCr) == 1, kIntelVvpCsRgb == 0
    intel_vvp_csc_set_output_color_space(&csc_sdi_tx, kIntelVvpCsYcc);
    // csc_rgb_to_ycchd_10bits, csc_ycchd_to_rgb_10bits, csc_passthrough 
    intel_vvp_csc_set_coeff_data(&csc_sdi_tx, &csc_rgb_to_ycchd_10bits, 2);
    intel_vvp_csc_commit_writes(&csc_sdi_tx);     

    // Protocol converter Lite to Full
    intel_vvp_protocol_conv_init(&proto_lite_to_full, (intel_vvp_core_base)VVP_PROTOCOL_CONV_TX_BASE);
    intel_vvp_protocol_conv_enable(&proto_lite_to_full, false);
    intel_vvp_core_set_img_info_width(&proto_lite_to_full.core_instance, INIT_HSIZE);
    intel_vvp_core_set_img_info_height(&proto_lite_to_full.core_instance, INIT_VSIZE);
    intel_vvp_core_set_img_info_interlace(&proto_lite_to_full.core_instance, 0);
    intel_vvp_core_set_img_info_colorspace(&proto_lite_to_full.core_instance, IMG_INFO_COLORSPACE_RGB);
    intel_vvp_core_set_img_info_subsampling(&proto_lite_to_full.core_instance, IMG_INFO_SUBSAMPLING_444);
    intel_vvp_core_set_img_info_cositing(&proto_lite_to_full.core_instance, 0);
    intel_vvp_protocol_conv_enable(&proto_lite_to_full, true);    
   
    // Mixer (VVP-Lite)
    intel_vvp_mixer_init(&mixer, (intel_vvp_core_base)VVP_MIXER_HDR_BASE);
    intel_vvp_core_set_img_info_width(&mixer.core_instance, INIT_HSIZE);
    intel_vvp_core_set_img_info_height(&mixer.core_instance, INIT_VSIZE);
    intel_vvp_core_set_img_info_subsampling(&mixer.core_instance, IMG_INFO_SUBSAMPLING_444);

    // Mixer Input 1 : Bypass channel
    intel_vvp_mixer_set_blend_mode(&mixer, 1, kIntelVvpMixerBlendOpaque);
    intel_vvp_mixer_set_horiz_offset(&mixer, 1, 0);
    intel_vvp_mixer_set_vert_offset(&mixer, 1, 0);
    intel_vvp_mixer_set_width(&mixer, 1, INIT_HSIZE);
    intel_vvp_mixer_set_height(&mixer, 1, INIT_VSIZE);

    // Mixer Input 2 : input video from 1D-LUT CH1
    intel_vvp_mixer_set_blend_mode(&mixer, 2, kIntelVvpMixerBlendOpaque);
    intel_vvp_mixer_set_horiz_offset(&mixer, 2, 0);
    intel_vvp_mixer_set_vert_offset(&mixer, 2, 0);
    intel_vvp_mixer_set_width(&mixer, 2, INIT_HSIZE);
    intel_vvp_mixer_set_height(&mixer, 2, INIT_VSIZE);

    // Mixer Input 3 : input video from 1D-LUT CH2
    intel_vvp_mixer_set_blend_mode(&mixer, 3, kIntelVvpMixerBlendOpaque);
    intel_vvp_mixer_set_horiz_offset(&mixer, 3, 0);
    intel_vvp_mixer_set_vert_offset(&mixer, 3, 0);
    intel_vvp_mixer_set_width(&mixer, 3, INIT_HSIZE);
    intel_vvp_mixer_set_height(&mixer, 3, INIT_VSIZE);

    intel_vvp_mixer_set_input_mode(&mixer, 1, true, false, true); //enable, consume, soft start
    intel_vvp_mixer_set_input_mode(&mixer, 2, true, false, true); //enable, consume, soft start
    intel_vvp_mixer_set_input_mode(&mixer, 3, true, false, true); //enable, consume, soft start
    intel_vvp_mixer_commit_writes(&mixer);

    // TPG Mixer (VVP-Lite)
    intel_vvp_tpg_init(&tpg_mixer, (intel_vvp_core_base)VVP_TPG_MIXER_BASE);
    intel_vvp_tpg_stop(&tpg_mixer);
    intel_vvp_core_set_img_info_width(&tpg_mixer.core_instance, INIT_HSIZE);
    intel_vvp_core_set_img_info_height(&tpg_mixer.core_instance, INIT_VSIZE);
    intel_vvp_core_set_img_info_interlace(&tpg_mixer.core_instance, 0);
    intel_vvp_tpg_set_pattern(&tpg_mixer, 0); // Solid colours = 0
    intel_vvp_tpg_set_colors(&tpg_mixer, 1023, 0, 0); // BGR
    intel_vvp_tpg_commit_writes(&tpg_mixer);
    intel_vvp_tpg_start(&tpg_mixer);

    // Clipper (VVP-Lite)
    intel_vvp_clipper_init(&clipper_ch0, (intel_vvp_core_base)VVP_CLIPPER_0_BASE);
    intel_vvp_core_set_img_info_width(&clipper_ch0.core_instance, INIT_HSIZE);
    intel_vvp_core_set_img_info_height(&clipper_ch0.core_instance, INIT_VSIZE);
    intel_vvp_core_set_img_info_interlace(&clipper_ch0.core_instance, 0);
    intel_vvp_core_set_img_info_colorspace(&clipper_ch0.core_instance, IMG_INFO_COLORSPACE_RGB);
    intel_vvp_core_set_img_info_subsampling(&clipper_ch0.core_instance, IMG_INFO_SUBSAMPLING_444);
    intel_vvp_core_set_img_info_cositing(&clipper_ch0.core_instance, 0);
    intel_vvp_clipper_set_left_offset(&clipper_ch0, 0);    
    intel_vvp_clipper_set_top_offset(&clipper_ch0, 0);    
    intel_vvp_clipper_set_clip_width(&clipper_ch0, INIT_HSIZE);    
    intel_vvp_clipper_set_clip_height(&clipper_ch0, INIT_VSIZE); 
    intel_vvp_clipper_commit_writes(&clipper_ch0); 

    intel_vvp_clipper_init(&clipper_ch1, (intel_vvp_core_base)VVP_CLIPPER_1_BASE);
    intel_vvp_core_set_img_info_width(&clipper_ch1.core_instance, INIT_HSIZE);
    intel_vvp_core_set_img_info_height(&clipper_ch1.core_instance, INIT_VSIZE);
    intel_vvp_core_set_img_info_interlace(&clipper_ch1.core_instance, 0);
    intel_vvp_core_set_img_info_colorspace(&clipper_ch1.core_instance, IMG_INFO_COLORSPACE_RGB);
    intel_vvp_core_set_img_info_subsampling(&clipper_ch1.core_instance, IMG_INFO_SUBSAMPLING_444);
    intel_vvp_core_set_img_info_cositing(&clipper_ch1.core_instance, 0);
    intel_vvp_clipper_set_left_offset(&clipper_ch1, 0);    
    intel_vvp_clipper_set_top_offset(&clipper_ch1, 0);    
    intel_vvp_clipper_set_clip_width(&clipper_ch1, INIT_HSIZE);    
    intel_vvp_clipper_set_clip_height(&clipper_ch1, INIT_VSIZE); 
    intel_vvp_clipper_commit_writes(&clipper_ch1); 

    intel_vvp_clipper_init(&clipper_ch2, (intel_vvp_core_base)VVP_CLIPPER_2_BASE);
    intel_vvp_core_set_img_info_width(&clipper_ch2.core_instance, INIT_HSIZE);
    intel_vvp_core_set_img_info_height(&clipper_ch2.core_instance, INIT_VSIZE);
    intel_vvp_core_set_img_info_interlace(&clipper_ch2.core_instance, 0);
    intel_vvp_core_set_img_info_colorspace(&clipper_ch2.core_instance, IMG_INFO_COLORSPACE_RGB);
    intel_vvp_core_set_img_info_subsampling(&clipper_ch2.core_instance, IMG_INFO_SUBSAMPLING_444);
    intel_vvp_core_set_img_info_cositing(&clipper_ch2.core_instance, 0);
    intel_vvp_clipper_set_left_offset(&clipper_ch2, 0);    
    intel_vvp_clipper_set_top_offset(&clipper_ch2, 0);    
    intel_vvp_clipper_set_clip_width(&clipper_ch2, INIT_HSIZE);    
    intel_vvp_clipper_set_clip_height(&clipper_ch2, INIT_VSIZE); 
    intel_vvp_clipper_commit_writes(&clipper_ch2); 

    // 3D LUTs (VVP-Lite)
    intel_vvp_3d_lut_init(&vvp_3d_lut_ch1_0, (intel_vvp_core_base)VVP_3D_LUT_10_BASE);
    intel_vvp_3d_lut_enable(&vvp_3d_lut_ch1_0, 0);

    intel_vvp_3d_lut_init(&vvp_3d_lut_ch2_0, (intel_vvp_core_base)VVP_3D_LUT_20_BASE);
    intel_vvp_3d_lut_enable(&vvp_3d_lut_ch2_0, 0);

    // Input CSC (VVP-Full)
    intel_vvp_csc_init(&csc_sdi_rx, (intel_vvp_core_base)VVP_CSC_RX_BASE);
    //  kIntelVvpCsYcc (YCbCr) == 1, RGB == 0
    intel_vvp_csc_set_output_color_space(&csc_sdi_rx, kIntelVvpCsRgb);
    // csc_rgb_to_ycchd_10bits, csc_ycchd_to_rgb_10bits, csc_ycchd_to_rgb_10bits 
    intel_vvp_csc_set_coeff_data(&csc_sdi_rx, &csc_ycchd_to_rgb_10bits, 0);
    intel_vvp_csc_commit_writes(&csc_sdi_rx);  

    // SDI Rx CVI (VVP-Full)
    intel_vab_core_base cv2axi_addr_base = (intel_vab_core_base)(SDI_RX_MR_BASE);
    intel_cv2axi_init (&cv2axi, cv2axi_addr_base);

    printf("Please press 'h' to see the menu\n");

    while (1) 
    {
        int cur_vid_standard = intel_cv2axi_get_vid_standard(&cv2axi);

        if (cur_vid_standard == 8 && prev_vid_standard != 8) 
        {
            send_raw_cmd_masked(I2C_0_BASE, RAW_I2C_SLAVE_ADDR, 0xFF, 0x04, 0x07); // RAW FF 04 07
            send_raw_cmd_masked(I2C_0_BASE, RAW_I2C_SLAVE_ADDR, 0xA0, 0x0F, 0x1F); // RAW A0 0F 1F
            send_raw_cmd_masked(I2C_0_BASE, RAW_I2C_SLAVE_ADDR, 0x0A, 0x0C, 0x0C); // RAW 0A 0C 0C
            send_raw_cmd_masked(I2C_0_BASE, RAW_I2C_SLAVE_ADDR, 0x0A, 0x00, 0x0C); // RAW 0A 00 0C
            printf("\n");
        }
        else if (cur_vid_standard != 8 && prev_vid_standard == 8) 
        {
            send_raw_cmd_masked(I2C_0_BASE, RAW_I2C_SLAVE_ADDR, 0xA0, 0x1F, 0x1F); // RAW A0 1F 1F
            send_raw_cmd_masked(I2C_0_BASE, RAW_I2C_SLAVE_ADDR, 0x0A, 0x0C, 0x0C); // RAW 0A 0C 0C
            send_raw_cmd_masked(I2C_0_BASE, RAW_I2C_SLAVE_ADDR, 0x0A, 0x00, 0x0C); // RAW 0A 00 0C
            printf("\n");
        }
        prev_vid_standard = cur_vid_standard;
        
        if (res_switch == 0 && (intel_cv2axi_is_locked(&cv2axi) == 0 || intel_cv2axi_is_valid_resolution(&cv2axi) == 0 || intel_cv2axi_is_stream_stable(&cv2axi) == 0)) 
        {
            res_switch = 1;
            // Stop the IPs before the reconfiguration
            intel_vvp_protocol_conv_enable(&proto_lite_to_full, false);
            intel_cv2axi_stop(&cv2axi);
        }
        
        if (res_switch == 1 &&  intel_cv2axi_is_stream_stable(&cv2axi) == 1 && intel_cv2axi_is_valid_resolution(&cv2axi) == 1 && intel_cv2axi_is_locked(&cv2axi) == 1) 
        {
            res_switch = 0;
            cvi_res_switch(&cv2axi, &axi2cv, &cvi_image_config);
        }

        int cmd;

        cmd = alt_getchar();
        if (cmd != EOF && cmd != 0)
        {
            switch (cmd)
            {
                case 'h':
                    printf("\f");
                    printf("\n===========================================================");
                    printf("\nDemo   : 4Kp60 SDI-based Genlock HDR Video Example Design");
                    printf("\nDevkit : Agilex 5E Group B MDK Rev C");
                    printf("\nFMC    : Nextera SDI 12G-FMC");
                    printf("\nOptions from the Keyboard:");
                    printf("\n==========================================================="); 
                    printf("\n'h' : Help Menu");
                    printf("\n'c' : CVI Video Info\n");
                    
                    printf("\n'1' : Bypass Mode");
                    printf("\n'2' : HDR to SDR Conversion: PQ-BT2100             -> SDR-BT709");  
                    printf("\n'3' : HDR to SDR Conversion: HLG-BT2100            -> SDR-BT709");  
                    printf("\n'4' : HDR to SDR Conversion: SLog3 (S-Gamut3.Cine) -> SDR-BT709"); 
                    printf("\n'5' : HDR to SDR Conversion: SLog3                 -> SDR-BT709\n");
        
                    printf("\n'n' : Side by Side View: move slider to left-hand side");
                    printf("\n'm' : Side by Side View: move slider to right-hand side");
                    printf("\n===========================================================\n");                    
                break;
    
                case 'c':
                    printf("\n===========================================================");
                    printf("\nCVI Video Info");
                    unsigned int datan = intel_cv2axi_get_active_sample_count(&cv2axi);

                    datan = intel_cv2axi_is_locked(&cv2axi) & (0x1);
                    printf("\nCVI locked                : %s", (datan == 1) ? ("Yes") : "No");

                    datan = intel_cv2axi_is_valid_resolution(&cv2axi) & (0x1);
                    printf("\nCVI with valid resolution : %s", (datan == 1) ? ("Yes") : "No");

                    datan = intel_cv2axi_is_stream_stable(&cv2axi) & (0x1);
                    printf("\nCVI Stream Stable         : %s", (datan == 1) ? ("Yes") : "No");

                    datan = intel_cv2axi_get_total_sample_count(&cv2axi);                    
                    printf("\nFull-Raster Pixels        : %d", datan);

                    datan = intel_cv2axi_get_total_line_count_f0(&cv2axi);                    
                    printf("\nFull-Raster Lines         : %d", datan);

                    datan = intel_cv2axi_get_active_sample_count(&cv2axi);
                    printf("\nActive Pixels             : %d", datan);

                    datan = intel_cv2axi_get_active_line_count_f0(&cv2axi);
                    printf("\nActive Lines              : %d", datan);

                    // 444 == 3; 422 == 2; 420 == 0
                    // crs_val = (intel_cv2axi_get_color_pattern(cvi) >> 7) & (0x3);
                    // RGB == 0, YUV = 1
                    // csc_val = (intel_cv2axi_get_color_pattern(cvi)) & (0x1);
                    datan = (intel_cv2axi_get_color_pattern(&cv2axi)) & (0x1);
                    printf("\nCSC Format                : %s", (datan == 1) ? ("YCbCr") : "RGB");

                    datan = (intel_cv2axi_get_color_pattern(&cv2axi) >> 7) & (0x3);
                    printf("\nCRS Format                : %s", (datan == 3) ? ("444") : 
                                                              (datan == 2) ? ("422") : 
                                                              (datan == 0) ? ("420") : "Unsupported Format");

                    datan = intel_cv2axi_get_vpid(&cv2axi, 1);
                    printf("\nVPID byte # 1             : %d", datan);
                    datan = intel_cv2axi_get_vpid(&cv2axi, 2);
                    printf("\nVPID byte # 2             : %d", datan);
                    datan = intel_cv2axi_get_vpid(&cv2axi, 3);
                    printf("\nVPID byte # 3             : %d", datan);
                    datan = intel_cv2axi_get_vpid(&cv2axi, 4);
                    printf("\nVPID byte # 4             : %d", datan);
                    printf("\n===========================================================\n");
                break;
    
                case '1':
                    printf("\n===========================================================");
                    printf("\nHDR Conversion Type: Bypass Mode");                
                    current_mixer_mode = 0;
                    current_x_dim = intel_vvp_core_get_img_info_width(&tpg_mixer.core_instance);
        
                    intel_vvp_mixer_set_width(&mixer, 3, current_x_dim);
                    intel_vvp_mixer_set_width(&mixer, 2, current_x_dim);
                    intel_vvp_mixer_set_width(&mixer, 1, current_x_dim);
                    intel_vvp_clipper_set_clip_width(&clipper_ch2, current_x_dim);    
                    intel_vvp_clipper_set_clip_width(&clipper_ch1, current_x_dim);    
                    intel_vvp_clipper_set_clip_width(&clipper_ch0, current_x_dim);    
                    intel_vvp_clipper_commit_writes(&clipper_ch2);                     
                    intel_vvp_clipper_commit_writes(&clipper_ch1);                     
                    intel_vvp_clipper_commit_writes(&clipper_ch0);                     
        
                    intel_vvp_3d_lut_enable(&vvp_3d_lut_ch2_0, 0);
                    intel_vvp_3d_lut_enable(&vvp_3d_lut_ch1_0, 0);
                    printf("\n===========================================================\n");
                break;
                case '2':
                    printf("\n===========================================================");
                    printf("\nHDR Conversion Type: PQ-BT2100 -> SDR-BT709");
                                    
                    current_mixer_mode = 1;
                    current_x_dim = intel_vvp_core_get_img_info_width(&tpg_mixer.core_instance);
            
                    intel_vvp_mixer_set_width(&mixer, 3, 0);
                    intel_vvp_mixer_set_width(&mixer, 2, current_x_dim);
                    intel_vvp_mixer_set_width(&mixer, 1, current_x_dim);
                    intel_vvp_clipper_set_clip_width(&clipper_ch2, 0);    
                    intel_vvp_clipper_set_clip_width(&clipper_ch1, current_x_dim);    
                    intel_vvp_clipper_set_clip_width(&clipper_ch0, current_x_dim);    
                    intel_vvp_clipper_commit_writes(&clipper_ch2);                     
                    intel_vvp_clipper_commit_writes(&clipper_ch1);                     
                    intel_vvp_clipper_commit_writes(&clipper_ch0);                        
                    
                    intel_vvp_3d_lut_buffer_select(&vvp_3d_lut_ch1_0, 0); // pq_to_bt709 (Buffer 0)
                    intel_vvp_3d_lut_enable(&vvp_3d_lut_ch1_0, 1);
                    
                    intel_vvp_3d_lut_enable(&vvp_3d_lut_ch2_0, 0);
                    // intel_vvp_3d_lut_enable(&vvp_3d_lut_ch1_0, 0);
                    printf("\n===========================================================\n");
                break;
                case '3':
                    printf("\n===========================================================");
                    printf("\nHDR Conversion Type: HLG-BT2100 -> SDR-BT709");
        
                    current_mixer_mode = 1;
                    current_x_dim = intel_vvp_core_get_img_info_width(&tpg_mixer.core_instance);
    
                    intel_vvp_mixer_set_width(&mixer, 3, 0);
                    intel_vvp_mixer_set_width(&mixer, 2, current_x_dim);
                    intel_vvp_mixer_set_width(&mixer, 1, current_x_dim);
                    intel_vvp_clipper_set_clip_width(&clipper_ch2, 0);    
                    intel_vvp_clipper_set_clip_width(&clipper_ch1, current_x_dim);    
                    intel_vvp_clipper_set_clip_width(&clipper_ch0, current_x_dim);    
                    intel_vvp_clipper_commit_writes(&clipper_ch2);                     
                    intel_vvp_clipper_commit_writes(&clipper_ch1);                     
                    intel_vvp_clipper_commit_writes(&clipper_ch0);                        
                    
                    intel_vvp_3d_lut_buffer_select(&vvp_3d_lut_ch1_0, 1); // hlg_to_bt709 (Buffer 1)
                    intel_vvp_3d_lut_enable(&vvp_3d_lut_ch1_0, 1);
                    
                    intel_vvp_3d_lut_enable(&vvp_3d_lut_ch2_0, 0);
                    // intel_vvp_3d_lut_enable(&vvp_3d_lut_ch1_0, 0);              
                    printf("\n===========================================================\n");
            break;
            case '4':
                    printf("\n===========================================================");
                    printf("\nHDR Conversion Type: SLog3 (S-Gamut3.Cine) -> SDR-BT709");
    
                    current_mixer_mode = 2;
                    current_x_dim = intel_vvp_core_get_img_info_width(&tpg_mixer.core_instance);
    
                    intel_vvp_mixer_set_width(&mixer, 3, current_x_dim);
                    intel_vvp_mixer_set_width(&mixer, 2, current_x_dim);
                    intel_vvp_mixer_set_width(&mixer, 1, current_x_dim);
                    intel_vvp_clipper_set_clip_width(&clipper_ch2, current_x_dim);    
                    intel_vvp_clipper_set_clip_width(&clipper_ch1, current_x_dim);    
                    intel_vvp_clipper_set_clip_width(&clipper_ch0, current_x_dim);    
                    intel_vvp_clipper_commit_writes(&clipper_ch2);                     
                    intel_vvp_clipper_commit_writes(&clipper_ch1);                     
                    intel_vvp_clipper_commit_writes(&clipper_ch0);                        
                    
                    intel_vvp_3d_lut_buffer_select(&vvp_3d_lut_ch2_0, 1); // slog3_to_bt709_opt2 (Buffer 1)
                    intel_vvp_3d_lut_enable(&vvp_3d_lut_ch2_0, 1);
                    
                    // intel_vvp_3d_lut_enable(&vvp_3d_lut_ch2_0, 0); 
                    intel_vvp_3d_lut_enable(&vvp_3d_lut_ch1_0, 0);
                    printf("\n===========================================================\n");
                break;
                case '5':
                    printf("\n===========================================================");
                    printf("\nHDR Conversion Type: SLog3 -> SDR-BT709");
        
                    current_mixer_mode = 2;
                    current_x_dim = intel_vvp_core_get_img_info_width(&tpg_mixer.core_instance);
    
                    intel_vvp_mixer_set_width(&mixer, 3, current_x_dim);
                    intel_vvp_mixer_set_width(&mixer, 2, current_x_dim);
                    intel_vvp_mixer_set_width(&mixer, 1, current_x_dim);
                    intel_vvp_clipper_set_clip_width(&clipper_ch2, current_x_dim);    
                    intel_vvp_clipper_set_clip_width(&clipper_ch1, current_x_dim);    
                    intel_vvp_clipper_set_clip_width(&clipper_ch0, current_x_dim);    
                    intel_vvp_clipper_commit_writes(&clipper_ch2);                     
                    intel_vvp_clipper_commit_writes(&clipper_ch1);                     
                    intel_vvp_clipper_commit_writes(&clipper_ch0);                        
                    
                    intel_vvp_3d_lut_buffer_select(&vvp_3d_lut_ch2_0, 0); // slog3_to_bt709 (Buffer 0)
                    intel_vvp_3d_lut_enable(&vvp_3d_lut_ch2_0, 1);
                    
                    // intel_vvp_3d_lut_enable(&vvp_3d_lut_ch2_0, 0); 
                    intel_vvp_3d_lut_enable(&vvp_3d_lut_ch1_0, 0);
                    printf("\n===========================================================\n");
                break;                 
                case 'n':
                case 'N':
                    printf("\n===========================================================");
                    printf("\nMixer side by side: move to the left-hand side");
                    width_layer_1 = intel_vvp_mixer_get_width(&mixer, 1);
                    width_layer_2 = intel_vvp_mixer_get_width(&mixer, 2);
                    width_layer_3 = intel_vvp_mixer_get_width(&mixer, 3);
                
                    if (current_mixer_mode == 2) {
                       if (width_layer_3 < 8) {
                           intel_vvp_mixer_set_width(&mixer, 3, 0);
                           intel_vvp_clipper_set_clip_width(&clipper_ch2, 0);    
                           intel_vvp_clipper_commit_writes(&clipper_ch2);                    
                       }
                       else {
                           width_layer_3 = width_layer_3 - 8;
                           intel_vvp_mixer_set_width(&mixer, 3, width_layer_3);
                           intel_vvp_clipper_set_clip_width(&clipper_ch2, width_layer_3);    
                           intel_vvp_clipper_commit_writes(&clipper_ch2);
                       }
                    }
                    else if (current_mixer_mode == 1) {
                       if (width_layer_2 < 8) {
                           intel_vvp_mixer_set_width(&mixer, 2, 0);
                           intel_vvp_clipper_set_clip_width(&clipper_ch1, 0);    
                           intel_vvp_clipper_commit_writes(&clipper_ch1);                    
                       }
                       else {
                           width_layer_2 = width_layer_2 - 8;
                           intel_vvp_mixer_set_width(&mixer, 2, width_layer_2);
                           intel_vvp_clipper_set_clip_width(&clipper_ch1, width_layer_2);    
                           intel_vvp_clipper_commit_writes(&clipper_ch1);
                       }
                    }                     
                    else {
                        printf("\nMixer side by side: Command not available at this moment");
                    }
    
                    width_layer_1 = intel_vvp_mixer_get_width(&mixer, 1);
                    width_layer_2 = intel_vvp_mixer_get_width(&mixer, 2);
                    width_layer_3 = intel_vvp_mixer_get_width(&mixer, 3);
                    printf("\n===========================================================\n");
                break;                
                case 'm':
                case 'M':
                    printf("\n===========================================================");
                    printf("\nMixer side by side: move to the right-hand side");
                    width_layer_1 = intel_vvp_mixer_get_width(&mixer, 1);
                    width_layer_2 = intel_vvp_mixer_get_width(&mixer, 2);
                    width_layer_3 = intel_vvp_mixer_get_width(&mixer, 3);
    
                    if (current_mixer_mode == 2) {
                       if (width_layer_3 >= (width_layer_2-8)) {
                           intel_vvp_mixer_set_width(&mixer, 3, width_layer_2);
                           intel_vvp_clipper_set_clip_width(&clipper_ch2, width_layer_2);    
                           intel_vvp_clipper_commit_writes(&clipper_ch2);                    
                       }
                       else {
                           width_layer_3 = width_layer_3 + 8;
                           intel_vvp_mixer_set_width(&mixer, 3, width_layer_3);
                           intel_vvp_clipper_set_clip_width(&clipper_ch2, width_layer_3);    
                           intel_vvp_clipper_commit_writes(&clipper_ch2);
                       }
                    }
                    else if (current_mixer_mode == 1) {
                       if (width_layer_2 >= (width_layer_1-8)) {
                           intel_vvp_mixer_set_width(&mixer, 2, width_layer_1);
                           intel_vvp_clipper_set_clip_width(&clipper_ch1, width_layer_1);    
                           intel_vvp_clipper_commit_writes(&clipper_ch1);                    
                       }
                       else {
                           width_layer_2 = width_layer_2 + 8;
                           intel_vvp_mixer_set_width(&mixer, 2, width_layer_2);
                           intel_vvp_clipper_set_clip_width(&clipper_ch1, width_layer_2);    
                           intel_vvp_clipper_commit_writes(&clipper_ch1);
                       }
                    }                     
                    else {
                        printf("\nMixer side by side: Command not available at this moment");
                    }
    
                    width_layer_1 = intel_vvp_mixer_get_width(&mixer, 1);
                    width_layer_2 = intel_vvp_mixer_get_width(&mixer, 2);
                    width_layer_3 = intel_vvp_mixer_get_width(&mixer, 3);
                    printf("\n===========================================================\n");
                break;
    
                default:
                break;
            }
        }        
     
    } // while (1)
    return 0; // Should never get here
}

//--Program the supported resolution to the cvo mode bank
void cvo_program_mode_bank(intel_axi2cv_instance* cvo, unsigned int sel, unsigned int vid_std, unsigned int vpid_byte1, unsigned int vpid_byte2, unsigned int vpid_byte3, unsigned int vpid_byte4) {
   switch (sel) {
      case 0:
         //intel_axi2cv_set_output_mode_sdi(cvo,0,CVO_480P_MODE,0,0,0,0,0);
         break;
      case 1:
         intel_axi2cv_set_output_mode_sdi(cvo,0,CVO_720P_SDI_MODE,vid_std,vpid_byte1, vpid_byte2, vpid_byte3, vpid_byte4);
         break;
      case 2:
         intel_axi2cv_set_output_mode_sdi(cvo,0,CVO_1080I_SDI_MODE,vid_std,vpid_byte1, vpid_byte2, vpid_byte3, vpid_byte4);
         break;
      case 3:
         intel_axi2cv_set_output_mode_sdi(cvo,0,CVO_1080P_SDI_MODE_1920,vid_std,vpid_byte1, vpid_byte2, vpid_byte3, vpid_byte4);
         break;
      case 4:
         intel_axi2cv_set_output_mode_sdi(cvo,0,CVO_2160P_SDI_MODE_3840,vid_std,vpid_byte1, vpid_byte2, vpid_byte3, vpid_byte4);
         break;
      case 5:
         //intel_axi2cv_set_output_mode_sdi(cvo,0,CVO_2160P_420_MODE,0,0,0,0,0);
         break;
      case 6:
         //intel_axi2cv_set_output_mode_sdi(cvo,0,CVO_4320P_MODE,0,0,0,0,0);
         break;
      case 7:
         //intel_axi2cv_set_output_mode_sdi(cvo,0,CVO_4320P_420_MODE,0,0,0,0,0);
         break;
      case 8:
         intel_axi2cv_set_output_mode_sdi(cvo,0,CVO_576I_SDI_MODE,vid_std,vpid_byte1, vpid_byte2, vpid_byte3, vpid_byte4);
         break;
      case 9:
         intel_axi2cv_set_output_mode_sdi(cvo,0,CVO_486I_SDI_MODE,vid_std,vpid_byte1, vpid_byte2, vpid_byte3, vpid_byte4);
         break;
      case 10:
         intel_axi2cv_set_output_mode_sdi(cvo,0,CVO_1080P_SDI_MODE_2048,vid_std,vpid_byte1, vpid_byte2, vpid_byte3, vpid_byte4);
         break;
      case 11:
         intel_axi2cv_set_output_mode_sdi(cvo,0,CVO_2160P_SDI_MODE_4096,vid_std,vpid_byte1, vpid_byte2, vpid_byte3, vpid_byte4);
         break;
      default:
         break;
   }
}

void cvi_res_switch(intel_cv2axi_instance* cvi, intel_axi2cv_instance* cvo, struct image_config *current_image_config) {
    struct image_config new_image_config = {.x = 0, .y = 0, .interlace = false, .image_color.space = 0, .image_color.depth = 0, .image_color.wcg = 0, .std=0, .vpid_byte1=0, .vpid_byte2=0, .vpid_byte3=0, .vpid_byte4=0};
    int res_changed = 0;
    unsigned int csc_val = 0;
    unsigned int crs_val = 0;    

    const intel_vvp_coefficients csc_passthrough                = CSC_PASSTHROUGH_COEFFS;
    const intel_vvp_coefficients csc_ycchd_to_rgb_10bits_ext    = CSC_YCCHD_TO_RGB_COEFFS; // 10-bit data   
    const intel_vvp_coefficients csc_rgb_to_ycchd_10bits_ext    = CSC_RGB_TO_YCCHD_COEFFS; // 8-bit data

    new_image_config.x = intel_cv2axi_get_active_sample_count(cvi);  //-- Width
    new_image_config.y = intel_cv2axi_get_active_line_count_f0(cvi); //-- Using f0 height only

    // 444 == 3; 422 == 2; 420 == 0
    crs_val = (intel_cv2axi_get_color_pattern(cvi) >> 7) & (0x3);
    // RGB == 0, YUV = 1
    csc_val = (intel_cv2axi_get_color_pattern(cvi)) & (0x1);

    new_image_config.interlace = intel_cv2axi_is_interlaced(cvi);
    new_image_config.image_color.space = intel_cv2axi_get_color_pattern(cvi) >> 7;
    new_image_config.image_color.depth = intel_cv2axi_get_bit_width(cvi);
    new_image_config.std = intel_cv2axi_get_vid_standard(cvi);
    new_image_config.vpid_byte1 = intel_cv2axi_get_vpid(cvi, 1);
    new_image_config.vpid_byte2 = intel_cv2axi_get_vpid(cvi, 2);
    new_image_config.vpid_byte3 = intel_cv2axi_get_vpid(cvi, 3);
    new_image_config.vpid_byte4 = intel_cv2axi_get_vpid(cvi, 4);

    if (new_image_config.interlace) {
        new_image_config.y += intel_cv2axi_get_active_line_count_f1(cvi); // height is f0 + f1
    }

    //Compare current_image_config and new_image_config
    if (new_image_config.x != current_image_config->x || 
        new_image_config.y != current_image_config->y || 
        new_image_config.interlace != current_image_config->interlace ||
        new_image_config.std != current_image_config->std ||
        new_image_config.vpid_byte1 != current_image_config->vpid_byte1 ||
        new_image_config.vpid_byte2 != current_image_config->vpid_byte2 ||
        new_image_config.vpid_byte3 != current_image_config->vpid_byte3 ||
        new_image_config.vpid_byte4 != current_image_config->vpid_byte4 ) {

        res_changed = 1;
    }

    if (res_changed) {
        
        if (csc_val)
        {
            // The input is YUV. 
            // Hence we do CSC from RGB to YUV on the output to match the input (Bypass mode only)
            
            // CSC Tx
            // kIntelVvpCsYcc (YCbCr) == 1, kIntelVvpCsRgb (RGB) == 0
            intel_vvp_csc_set_output_color_space(&csc_sdi_tx, kIntelVvpCsYcc);
            // csc_rgb_to_ycchd_10bits_ext, csc_passthrough 
            // A scale of 2x is needed to process 10-bit data 
            intel_vvp_csc_set_coeff_data(&csc_sdi_tx, &csc_rgb_to_ycchd_10bits_ext, 2);
        
            // CSC Rx
            // csc_ycchd_to_rgb_10bits_ext, csc_passthrough        
            intel_vvp_csc_set_coeff_data(&csc_sdi_rx, &csc_ycchd_to_rgb_10bits_ext, 0);
        
            if (crs_val == 0)
            {
                // Output CRS: YUV 420 Case
                //kIntelVvpCrsSubsampling420, kIntelVvpCrsSubsampling422, kIntelVvpCrsSubsampling444
                intel_vvp_crs_set_output_subsampling(&crs_sdi_tx, kIntelVvpCrsSubsampling420);          
            }
            else if (crs_val == 2)
            {
                // Output CRS: YUV 422 Case
                //kIntelVvpCrsSubsampling420, kIntelVvpCrsSubsampling422, kIntelVvpCrsSubsampling444
                intel_vvp_crs_set_output_subsampling(&crs_sdi_tx, kIntelVvpCrsSubsampling422);          
            }
            else
            {
                // Output CRS: YUV 444 Case
                //kIntelVvpCrsSubsampling420, kIntelVvpCrsSubsampling422, kIntelVvpCrsSubsampling444
                intel_vvp_crs_set_output_subsampling(&crs_sdi_tx, kIntelVvpCrsSubsampling444);             
            }
        }
        else
        {
            // The input is RGB. 
            // Hence we do passthrough
        
            // Output CRS
            //kIntelVvpCrsSubsampling422, kIntelVvpCrsSubsampling444
            intel_vvp_crs_set_output_subsampling(&crs_sdi_tx, kIntelVvpCrsSubsampling444);
        
            // CSI Tx
            //  kIntelVvpCsYcc (YCbCr) == 1, kIntelVvpCsRgb (RGB) == 0
            intel_vvp_csc_set_output_color_space(&csc_sdi_tx, kIntelVvpCsRgb);
            // csc_ycchd_to_rgb_10bits, csc_passthrough 
            intel_vvp_csc_set_coeff_data(&csc_sdi_tx, &csc_passthrough, 0);

            // CSI Rx
            // csc_rgb_to_ycchd_8bits, csc_passthrough 
            intel_vvp_csc_set_coeff_data(&csc_sdi_rx, &csc_passthrough, 0);
        }        
        
        current_image_config->x = new_image_config.x;
        current_image_config->y = new_image_config.y;
        current_image_config->interlace = new_image_config.interlace;
        current_image_config->image_color = new_image_config.image_color;
        current_image_config->std = new_image_config.std;
        current_image_config->vpid_byte1 = new_image_config.vpid_byte1;
        current_image_config->vpid_byte2 = new_image_config.vpid_byte2;
        current_image_config->vpid_byte3 = new_image_config.vpid_byte3;
        current_image_config->vpid_byte4 = new_image_config.vpid_byte4;
        // Update VVP Core video resolution (for Lite mode only)
        intel_vvp_core_set_img_info_width(&proto_lite_to_full.core_instance, new_image_config.x);
        intel_vvp_core_set_img_info_height(&proto_lite_to_full.core_instance, new_image_config.y);
        intel_vvp_core_set_img_info_width(&mixer.core_instance, new_image_config.x);
        intel_vvp_core_set_img_info_height(&mixer.core_instance, new_image_config.y);
        intel_vvp_mixer_set_width(&mixer, 1, new_image_config.x);
        intel_vvp_mixer_set_height(&mixer, 1, new_image_config.y);
        intel_vvp_mixer_set_width(&mixer, 2, new_image_config.x);
        intel_vvp_mixer_set_height(&mixer, 2, new_image_config.y);
        intel_vvp_mixer_set_width(&mixer, 3, new_image_config.x);
        intel_vvp_mixer_set_height(&mixer, 3, new_image_config.y);
        intel_vvp_core_set_img_info_width(&tpg_mixer.core_instance, new_image_config.x);
        intel_vvp_core_set_img_info_height(&tpg_mixer.core_instance, new_image_config.y);
        intel_vvp_core_set_img_info_width(&clipper_ch0.core_instance, new_image_config.x);
        intel_vvp_core_set_img_info_height(&clipper_ch0.core_instance, new_image_config.y);
        intel_vvp_clipper_set_clip_width(&clipper_ch0, new_image_config.x);    
        intel_vvp_clipper_set_clip_height(&clipper_ch0, new_image_config.y); 
        intel_vvp_core_set_img_info_width(&clipper_ch1.core_instance, new_image_config.x);
        intel_vvp_core_set_img_info_height(&clipper_ch1.core_instance, new_image_config.y);
        intel_vvp_clipper_set_clip_width(&clipper_ch1, new_image_config.x);    
        intel_vvp_clipper_set_clip_height(&clipper_ch1, new_image_config.y);     
        intel_vvp_core_set_img_info_width(&clipper_ch2.core_instance, new_image_config.x);
        intel_vvp_core_set_img_info_height(&clipper_ch2.core_instance, new_image_config.y);
        intel_vvp_clipper_set_clip_width(&clipper_ch2, new_image_config.x);    
        intel_vvp_clipper_set_clip_height(&clipper_ch2, new_image_config.y);       
      
        if (current_image_config->interlace == 1) {
            if (new_image_config.y == 1080) {
                cvo_program_mode_bank(cvo,2, new_image_config.std, new_image_config.vpid_byte1, new_image_config.vpid_byte2, new_image_config.vpid_byte3, new_image_config.vpid_byte4);
            } 
            else if (new_image_config.y == 576) {
                cvo_program_mode_bank(cvo,8, new_image_config.std, new_image_config.vpid_byte1, new_image_config.vpid_byte2, new_image_config.vpid_byte3, new_image_config.vpid_byte4);
            } 
            else {
                cvo_program_mode_bank(cvo,9, new_image_config.std, new_image_config.vpid_byte1, new_image_config.vpid_byte2, new_image_config.vpid_byte3, new_image_config.vpid_byte4);
            }
        } 
        else if (current_image_config->image_color.space == 0)  { // 'b00 = 4:2:0 ; 'b10 = 4:2:2; 'b11 = 4:4:4
            switch (new_image_config.y) {
                case 2160:
                    cvo_program_mode_bank(cvo,5, new_image_config.std, new_image_config.vpid_byte1, new_image_config.vpid_byte2, new_image_config.vpid_byte3, new_image_config.vpid_byte4);
                break;
                case 4320:
                    cvo_program_mode_bank(cvo,7, new_image_config.std, new_image_config.vpid_byte1, new_image_config.vpid_byte2, new_image_config.vpid_byte3, new_image_config.vpid_byte4);
                break;
                default:
                break;
            }
        } 
        else {
            switch (new_image_config.y) {
                case 480:
                    cvo_program_mode_bank(cvo,0, new_image_config.std, new_image_config.vpid_byte1, new_image_config.vpid_byte2, new_image_config.vpid_byte3, new_image_config.vpid_byte4);
                break;
                case 720:
                    cvo_program_mode_bank(cvo,1, new_image_config.std, new_image_config.vpid_byte1, new_image_config.vpid_byte2, new_image_config.vpid_byte3, new_image_config.vpid_byte4);
                break;
                case 1080:
                    if (new_image_config.x == 2048) {
                        cvo_program_mode_bank(cvo,10, new_image_config.std, new_image_config.vpid_byte1, new_image_config.vpid_byte2, new_image_config.vpid_byte3, new_image_config.vpid_byte4);
                    } 
                    else {
                        cvo_program_mode_bank(cvo,3, new_image_config.std, new_image_config.vpid_byte1, new_image_config.vpid_byte2, new_image_config.vpid_byte3, new_image_config.vpid_byte4);
                    }
                break;
                case 2160:
                    if (new_image_config.x == 4096) {
                        cvo_program_mode_bank(cvo,11, new_image_config.std, new_image_config.vpid_byte1, new_image_config.vpid_byte2, new_image_config.vpid_byte3, new_image_config.vpid_byte4);
                    } 
                    else {
                        cvo_program_mode_bank(cvo,4, new_image_config.std, new_image_config.vpid_byte1, new_image_config.vpid_byte2, new_image_config.vpid_byte3, new_image_config.vpid_byte4);
                    }    
                break;
                case 4320:
                    cvo_program_mode_bank(cvo,1, new_image_config.std, new_image_config.vpid_byte1, new_image_config.vpid_byte2, new_image_config.vpid_byte3, new_image_config.vpid_byte4);
                break;
                default:
                break;
            }
        }
    }

    // Here we enable the IP cores
    intel_vvp_crs_commit_writes(&crs_sdi_tx);  
    intel_vvp_csc_commit_writes(&csc_sdi_tx); 
    intel_vvp_protocol_conv_enable(&proto_lite_to_full, true);
    intel_vvp_mixer_commit_writes(&mixer);
    intel_vvp_tpg_commit_writes(&tpg_mixer);
    intel_vvp_clipper_commit_writes(&clipper_ch0); 
    intel_vvp_clipper_commit_writes(&clipper_ch1); 
    intel_vvp_clipper_commit_writes(&clipper_ch2);    
    intel_vvp_csc_commit_writes(&csc_sdi_rx);  
    intel_cv2axi_start(cvi);
}

// Write to a register using data/mask logic
void send_raw_cmd_masked(long i2c_base, unsigned char slave_addr, unsigned char reg, unsigned char data, unsigned char mask) {
    unsigned char orig = intel_fpga_i2c_read_extended(i2c_base, slave_addr, reg);
    unsigned char newval = (orig & ~mask) | (data & mask);
    intel_fpga_i2c_write_extended(i2c_base, slave_addr, reg, newval);
    printf("RAW %02X %02X %02X : orig=%02X, new=%02X\n", reg, data, mask, orig, newval);
}

//==================================================================
// SI54x/SI56x I2C configuration sequence.
//==================================================================
int set_si54x(long i2c_base, const int i2c_addr, const double Output_Freq, const int is546, const char SpeedGrade)
{

  double Fvco_min;  // Fvco Min per Table 5.3
  double Xtal_freq; // Xtal_Freq per Table 5.3
  double Fout_min;  // Minimum output frequency
  double Fout_max;  // Maximum output frequency

  // Device divider limits (see Tables 5.1 & 5.2)
  int HSDIV_UpperLimit = 2046;
  int HSDIV_LowerLimit_Odd = 5;  // min count for odd HSDIV divisor
  int HSDIV_UpperLimit_Odd = 33; // max count for odd HSDIV divisor

  // Working variables
  double Min_HSLS_Div;
  double LSDIV_Div; // actual LSDIV divide ratio
  int LSDIV_Reg;    // LSDIV as encoded in power of 2 for device register use
  double HSDIV;
  uint32_t HSDIV_Int;
  double FBDIV;
  double Fvco;
  uint32_t FBDIV_Int;
  uint32_t FBDIV_Frac;
  uint32_t Reg23 = 0; // HSDIV[7:0]
  uint32_t Reg24 = 0; // OD_LSDIV[2:0],HSDIV[10:8] (*2^4,/2^8)
  uint32_t Reg26 = 0; // FBDIV[7:0]
  uint32_t Reg27 = 0; // FBDIV[15:8] (/2^8)
  uint32_t Reg28 = 0; // FBDIV[23:16] (/2^16)
  uint32_t Reg29 = 0; // FBDIV[31:24] (/2^24)
  uint32_t Reg30 = 0; // FBDIV[39:32] (/2^32)
  uint32_t Reg31 = 0; // FBDIV[42:40] (/2^40)

  int ReturnCode = 0;
  Xtal_freq = 152600000.0;
  if (SpeedGrade == 'A')
  {
    Fvco_min = 10800000000.0;
    Fout_min = 200000.0;
    Fout_max = 1500000000.0;
    if ((Output_Freq < Fout_min) || (Output_Freq > Fout_max))
    {
      ReturnCode = -1;
    }
  }
  else if (SpeedGrade == 'B')
  {
    Fvco_min = 10800000000.0;
    Fout_min = 200000.0;
    Fout_max = 800000000.0;
    if ((Output_Freq < Fout_min) || (Output_Freq > Fout_max))
    {
      ReturnCode = -1;
    }
  }
  else if (SpeedGrade == 'C')
  {
    Fvco_min = 10800000000.0;
    Fout_min = 200000.0;
    Fout_max = 325000000.0;
    if ((Output_Freq < Fout_min) || (Output_Freq > Fout_max))
    {
      ReturnCode = -1;
    }
  }
  else
  {
    ReturnCode = -1;
  }

  // Set device limits based on device type and speed grade.
  // (Checks if desired output frequency is valid based on device and speed grade)
  if (ReturnCode == 0)
  {
    // If limits are set and output frequency is valid, calculate frequency plan...
    //***********************************************************************************************
    // Step 1: Find theoretical HSDIV *LSDIV value based on lowest valid VCO frequency...
    // (Assumes "Output_Freq" has been tested and is in valid range for the device grade according to Table 5.3)
    Min_HSLS_Div = Fvco_min / Output_Freq; // Floating point HS*LS div value. Remember to first bounds check Output_Freq!
    // Step 2: Find LSDIV divisor value given Min_HSLS_Div value
    LSDIV_Div = ceil(Min_HSLS_Div / HSDIV_UpperLimit); // Divisor value of LSDIV, NOT yet encoded as power of 2
    if (LSDIV_Div > 32)
      LSDIV_Div = 32; // clip at 32 (max LSDIV divisor)

    // Encode LSDIV divisor value into next nearest 'power of 2' value if not already. This will be LSDIV_Reg
    LSDIV_Reg = ceil(log(LSDIV_Div) / log(2)); // LSDIV_Reg now encoded as proper power of 2. Will range from 0 to 5.
    // Adjust LSDIV_Div (holder of divisor) based on rounded power of 2 value in LSDIV_Reg
    LSDIV_Div = pow(2, LSDIV_Reg); // LSDIV_Div divisor now synchronized to actual LSDIV_Reg.

    // Step 3: Find HSDIV divisor value using known LSDIV divisor
    HSDIV = ceil(Min_HSLS_Div / LSDIV_Div);
    if ((HSDIV >= HSDIV_LowerLimit_Odd) && (HSDIV <= HSDIV_UpperLimit_Odd))
    {
      HSDIV = HSDIV; // Leaves HSDIV as even or odd only if HSDIV is from 5 to 33.
    }
    else
    {
      // Round to nearest even.
      HSDIV = round(HSDIV / 2) * 2;
    }

    // Step 4: Now calculate Fvco and FBDIV
    Fvco = (HSDIV * LSDIV_Div * Output_Freq); // Calculate Fvco based on valid HSDIV, LSDIV, and Fout
    FBDIV = Fvco / Xtal_freq;                 // Finally, calculate FBDIV based on xtal freq
    // Calculate 11.32 fixed point FBDIV value (MCTL_M)
    // Extract Integer part
    FBDIV_Int = (uint32_t)FBDIV;
    HSDIV_Int = (uint32_t)HSDIV;
    // Extract fractional part
    FBDIV = (FBDIV - FBDIV_Int);
    FBDIV = FBDIV * pow(2, 32);
    FBDIV_Frac = (uint32_t)FBDIV;

    // Generate Register values based on LSDIV, HSDIV, and FBDIV (MCTL_M)
    Reg23 = (HSDIV_Int & 0xFF);
    Reg24 = ((HSDIV_Int >> 8) & 0x7) | ((LSDIV_Reg & 0x7) << 4);
    Reg26 = (FBDIV_Frac & 0xFF);
    Reg27 = (FBDIV_Frac >> 8) & 0xFF;
    Reg28 = (FBDIV_Frac >> 16) & 0xFF;
    Reg29 = (FBDIV_Frac >> 24) & 0xFF;
    Reg30 = (FBDIV_Int) & 0xFF;
    Reg31 = (FBDIV_Int >> 8) & 0x7;
    intel_fpga_i2c_write_extended(i2c_base, i2c_addr, 255, 0);
    intel_fpga_i2c_write_extended(i2c_base, i2c_addr, 69, 0);
    intel_fpga_i2c_write_extended(i2c_base, i2c_addr, 17, 0);

    intel_fpga_i2c_write_extended(i2c_base, i2c_addr, 23, Reg23);
    intel_fpga_i2c_write_extended(i2c_base, i2c_addr, 24, Reg24);
    intel_fpga_i2c_write_extended(i2c_base, i2c_addr, 26, Reg26);
    intel_fpga_i2c_write_extended(i2c_base, i2c_addr, 27, Reg27);
    intel_fpga_i2c_write_extended(i2c_base, i2c_addr, 28, Reg28);
    intel_fpga_i2c_write_extended(i2c_base, i2c_addr, 29, Reg29);
    intel_fpga_i2c_write_extended(i2c_base, i2c_addr, 30, Reg30);
    intel_fpga_i2c_write_extended(i2c_base, i2c_addr, 31, Reg31);

    intel_fpga_i2c_write_extended(i2c_base, i2c_addr, 7, 8);
    // Wait 50mS for SI54x/SI56x to reboot...
    usleep(50000);
    intel_fpga_i2c_write_extended(i2c_base, i2c_addr, 17, 1);

    return 0;
  }

  printf("*** Device invalid or Device limits exceeded. Frequency plan not calculated.\n");
  return -1;
}

//==================================================================
// MAX10 I2C configuration sequence.
//==================================================================
void set_max10(long i2c_base, const int i2c_addr)
{
    // Instruct the MAX10 to route the SI569 to the TX/Rx Refclock pin
    unsigned char bmc_reg[2];
    unsigned char bmc_data[4];
    
    bmc_reg[1] = 0x10 << 2;
    bmc_reg[0] = 0;
    intel_fpga_i2c_burst_read_two_reg_extended(i2c_base, i2c_addr, bmc_reg, 4, bmc_data);
    //logPrint(kDebug, "Max 10 : %02x\n", bmc_data[0]);
    bmc_data[0] |= (1 << 0); // Route SDI SI569 into Quad (Tx Refclk)
    bmc_data[0] |= (1 << 4); // Route HDMI SI569 into Quad (Tx Refclk)
    bmc_data[0] |= (1 << 5); // Route FMC RX into Quad  (Rx Refclk)
    bmc_data[0] |= (1 << 6); // Route HDMI SI569 into Fabric (clk_vid_tx)      
    intel_fpga_i2c_burst_write_two_reg_extended(i2c_base, i2c_addr, bmc_reg, 4, bmc_data);
        
    // Wait 50mS for SI54x/SI56x to reboot...
    usleep(50000);
}

//==================================================================
// Make Sure System PLL is running before starting it.
//==================================================================
void start_systempll(void) {

  unsigned int syspll_status;
  
  syspll_status = IORD(PIO_SYSTEMPLL_BASE,0);
  if (!syspll_status) {
    printf("System PLL Is now enabled\n");   
    // 50 ms To ensure Clocks are stable.
    usleep(50000);
    // Start System-PLL.
    IOWR(PIO_SYSTEMPLL_BASE,0,1);
    
    usleep(50000);    
  } else {
    printf("System PLL Reference clock already initialised\n");   
  }
}

//==================================================================
// Initialise Board specific features
//==================================================================
void board_init(void)
{
  // Here the MAx10 is reconfigured to route the clocks.
  set_max10(I2C_MAX10_BASE, 0x55);

  // Here SDI VCXO SI569 is reconfigured to 148.5MHz.
  // MDK Rev B: U33 in clocking Wizard
  set_si54x(I2C_CLOCKS_BASE, 0x55, 148500000, 0, 'B');

  // Make Sure System PLL is running before starting it.  
  start_systempll();
}






