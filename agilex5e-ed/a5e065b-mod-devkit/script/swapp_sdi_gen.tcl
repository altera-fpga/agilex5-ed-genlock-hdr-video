#  ###############################################################################
#   
#  INTEL CONFIDENTIAL
#  
#  Copyright 2020-2021 Intel Corporation.
#  
#  This software and the related documents are Intel copyrighted materials, and
#  your use of them is governed by the express license under which they were
#  provided to you ("License"). Unless the License provides otherwise, you may
#  not use, modify, copy, publish, distribute, disclose or transmit this software
#  or the related documents without Intel's prior written permission.
#  
#  This software and the related documents are provided as is, with no express or
#  implied warranties, other than those that are expressly stated in the License.
#  
#  ###############################################################################
package require ::quartus::project
package require ::quartus::flow

# Get script directory
set script_dir [file dirname [info script]]

puts [pwd]

# Go to quartus directory
set prj_path [file normalize [file join $script_dir ..]]
cd $prj_path
post_message [pwd]

# Project handling
set need_to_close_project 0

if {[is_project_open]} {
    if {[string compare $quartus(project) "sdi_genlock_hdr_ed"]} {
        error "Project sdi_genlock_hdr_ed is not open"
    }
} else {
    if {[project_exists sdi_genlock_hdr_ed]} {
        project_open -revision sdi_genlock_hdr_ed sdi_genlock_hdr_ed
    } else {
        error "Project sdi_genlock_hdr_ed does not exist"
    }
    set need_to_close_project 1
}

# Go to script directory
set script_path [file normalize [file join script]]
cd $script_path
post_message [pwd]

post_message "##############################################"
post_message "# INFO : Nios project generation             #"
post_message "##############################################"

# Cross-platform quartus_py
set quartus_py [auto_execok quartus_py]
if {$quartus_py eq ""} {
    error "quartus_py not found in PATH"
}

exec -ignorestderr -- $quartus_py build_niosv_sw.py -d -b

# Go to root
set root_path [file normalize [file join $script_dir ..]]
cd $root_path
post_message [pwd]

post_message "##############################################"
post_message "# INFO : Integrating Nios .elf(.hex) in .sof #"
post_message "##############################################"

set src_hex [file join src sw build mem_init nios_onchip_mem_onchip_mem.hex]
set dst_hex [file join gen vds nios ip nios_onchip_mem intel_onchip_memory_200 synth nios_onchip_mem_onchip_mem.hex]

file copy -force -- $src_hex $dst_hex

# Close project if needed
if {$need_to_close_project} {
    project_close
}

# Return to script dir
set scripts_path [file normalize [file join script]]
cd $scripts_path
post_message [pwd]


