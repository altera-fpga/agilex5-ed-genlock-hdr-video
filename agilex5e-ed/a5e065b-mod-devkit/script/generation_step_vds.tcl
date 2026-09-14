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
package require ::quartus::vds

# Script directory
set script_dir [file dirname [info script]]

puts [pwd]

# Go to .qsf project
set prj_path [file normalize [file join $script_dir ..]]
cd $prj_path
puts "########################################################"
puts "# INFO : generation_step_vds -> .QSF location          #"
puts "########################################################"
post_message [pwd]

# Project handling
set need_to_close_project 0

if {[is_project_open]} {
    if {[string compare $quartus(project) "sdi_genlock_hdr_ed"]} {
        error "Wrong project open"
    }
} else {
    if {[project_exists sdi_genlock_hdr_ed]} {
        project_open -revision sdi_genlock_hdr_ed sdi_genlock_hdr_ed
    } else {
        error "Project does not exist"
    }
    set need_to_close_project 1
}

# Check if the VDS project has been built before.
# If so, do not rebuild it again.
set dirname_vds [file normalize [file join gen vds]]
if {[file isdirectory $dirname_vds]} {
    puts "Directory already exists, hence just compile the project in its current form"
} else {
    puts "Directory does not exist, hence we need to create the VDS project"
    # Go to RTL
    set vds_path [file normalize [file join src vds]]
    cd $vds_path
    puts "########################################################"
    puts "# INFO : generation_step_vds -> VDS location           #"
    puts "########################################################"
    post_message [pwd]

    #########################
    # ---- Define cube files ----
    set lut_dir [file join [pwd] test_luts]

    set lut_hlg_bt709           [string map {\\ /} [file join $lut_dir "hlg_to_bt709.cube"]]
    set lut_slog3_bt709_opt2    [string map {\\ /} [file join $lut_dir "slog3_to_bt709_opt2.cube"]]
    set lut_pq_bt709            [string map {\\ /} [file join $lut_dir "pq_to_bt709.cube"]]
    set lut_slog3_bt709         [string map {\\ /} [file join $lut_dir "slog3_to_bt709.cube"]]
    set lut_unitylut            [string map {\\ /} [file join $lut_dir "id_nrm_33.cube"]]

    # ---- Read file once ----
    set fileName "nios_sdi_ss.tcl"
    set fh [open $fileName r]
    fconfigure $fh -translation auto
    set content [read $fh]
    close $fh

    # ---- Perform ALL substitutions ----
    set replacements {
        hlg_bt709           lut_hlg_bt709
        slog3_bt709_opt2    lut_slog3_bt709_opt2
        pq_bt709            lut_pq_bt709
        slog3_bt709         lut_slog3_bt709
        unitylut            lut_unitylut
    }

    # Apply replacements
    foreach {key varname} $replacements {
        set value [set $varname]
        set content [regsub -all "\\m${key}\\M" $content $value]
    }

    # ---- Write file once ----
    set fh [open $fileName w]
    puts -nonewline $fh $content
    close $fh

    # Generate the VDS project
    set quartus_sh [auto_execok quartus_sh]
    if {$quartus_sh eq ""} {
       error "quartus_sh not found"
    }
    exec -ignorestderr -- $quartus_sh -t nios_sdi_ss.tcl

    # Return to script dir
    set scripts_path [file normalize [file join .. .. script]]
    cd $scripts_path
    post_message [pwd]

    # Close project
    if {$need_to_close_project} {
       project_close
    }

    puts "########################################################"
    puts "# INFO : SDI SW APP rebuild                             #"
    puts "########################################################"
    source [file join swapp_sdi_gen.tcl]      

    set prj_path [file normalize [file join ..]]
    cd $prj_path
    post_message [pwd]

    set temp1 "set_global_assignment -name SDC_FILE src/rtl/jtag.sdc"
    set temp2 "set_global_assignment -name SDC_FILE src/rtl/sdi_genlock_hdr_ed.sdc"
    set temp3 "set_global_assignment -name DESIGN_ASSISTANT_WAIVER_FILE da_drc.dawf"

    set filename "sdi_genlock_hdr_ed.qsf"
    set fileId [open $filename "a"]
    puts $fileId $temp1
    puts $fileId $temp2
    puts $fileId $temp3
    flush $fileId 
    close $fileId

    set script_path [file normalize [file join script]]
    cd $script_path
    post_message [pwd]
}


