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

# Get script directory
set script_dir [file dirname [info script]]

puts [pwd]

# Go to .qsf project
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

puts "##############################################"
puts "# INFO : Quartus compilation                 #"
puts "##############################################"
execute_flow -compile

# Close project if needed
if {$need_to_close_project} {
    project_close
}

# Return to script dir
set scripts_path [file normalize [file join script]]
cd $scripts_path
post_message [pwd]

puts "##############################################"
puts "# INFO : The project has been built :)       #"
puts "##############################################"
