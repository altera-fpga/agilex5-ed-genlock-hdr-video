# (C) 2001-2026 Altera Corporation. All rights reserved.
# Your use of Altera Corporation's design tools, logic functions and other 
# software and tools, and its AMPP partner logic functions, and any output 
# files from any of the foregoing (including device programming or simulation 
# files), and any associated documentation or information are expressly subject 
# to the terms and conditions of the Altera Program License Subscription 
# Agreement, Altera IP License Agreement, or other applicable 
# license agreement, including, without limitation, that your use is for the 
# sole purpose of programming logic devices manufactured by Altera and sold by 
# Altera or its authorized distributors.  Please refer to the applicable 
# agreement for further details.


# *********************************************************************
# Description
# 
# Script for compiling the SDI Example Design software
#
# *********************************************************************

from pathlib import Path
import sys
import os
import argparse
import platform
import shutil

# Check that we are using the built-in "quartus_py" interpreter
python_interpreter=sys.executable
if ( (not (python_interpreter.endswith("quartus_py.exe"))) & (not (python_interpreter.endswith("quartus_py"))) ):
    print('[ERROR]: Invalid python interpreter, please use "quartus_py". {0}'.format(python_interpreter))
    sys.exit(1)

# The script path
script_path = Path(sys.argv[0]).parent

# The directory containing the software source code and where we want to build
software_path = script_path.joinpath('../src/sw')
software_path_vds = script_path.joinpath('src/sw')


# Variables

# The build directory
BUILD_DIR = software_path.joinpath("build")

# The name of the output elf file
ELF_NAME="sdi_demo.elf"
HEX_NAME="nios_onchip_mem_onchip_mem.hex"

# Application Source Directory
APP_DIR = software_path.joinpath("sdi_demo")

# ::WARNING:: If you used spaces in your ACDS install location
# this script will not work. You will need to copy the software
# directory to another location and update this script appropriately

# BSP Directory
BSP_DIR = software_path.joinpath("sdi_demo_bsp")
BSP_DIR_VDS = software_path_vds.joinpath("sdi_demo_bsp")
BSP_SETTINGS_FILENAME = BSP_DIR_VDS.joinpath("settings.bsp")

# # BSP options
SIMULATION_OPTIMIZED_SUPPORT="false"
OPTIMIZATION_LEVEL="-Oz"
SOPC_CODE_MEMORY_NAME="onchip_mem"
SOPC_CPU_NAME="cpu"
SOPC_UART_NAME="cpu_jtag_debug"
SOPC_TIMER_NAME="nios_timer"

BSP_TYPE = "hal"
BSP_SETTINGS = []
BSP_SETTINGS.append(["hal.enable_instruction_related_exceptions_api", "1"])
BSP_SETTINGS.append(["hal.enable_c_plus_plus", "1"])
BSP_SETTINGS.append(["hal.enable_lightweight_device_driver_api", "0"])
BSP_SETTINGS.append(["hal.make.cflags_optimization", OPTIMIZATION_LEVEL])
BSP_SETTINGS.append(["hal.stderr", SOPC_UART_NAME])
BSP_SETTINGS.append(["hal.stdin", SOPC_UART_NAME])
BSP_SETTINGS.append(["hal.stdout", SOPC_UART_NAME])
BSP_SETTINGS.append(["hal.sys_clk_timer", SOPC_TIMER_NAME])
BSP_SETTINGS.append(["hal.timestamp_timer", "none"])
BSP_SETTINGS.append(["hal.make.enable_cflag_fstack_protector_strong", "1"])

QPF_PATH = script_path.joinpath('../', "sdi_genlock_hdr_ed.qpf")
# VDS_PATH is relative to where the .QSF file is located
VDS_PATH = script_path.joinpath('src/vds/nios', "nios.vds")
###############################################################################################################
# Functions

# Function to determine if running on windows
def is_windows() -> bool:
    return platform.system() == 'Windows'

# Function to recursively copy a directory
def copy_directory(src, dst):
    shutil.copytree(src, dst, dirs_exist_ok=True)

# Function to write the text to a file
def write_to_file(file_path, text, bAppend=False):
    if ( bAppend ):
        mode = 'at'
    else:
        mode = 'wt'
    with open(file_path, mode) as f:
        f.write(text + '\n')

# Function to run a shell command
def run_shell_cmd(cmd):
    print('Running: {0}'.format(cmd))
    rc = os.system(cmd)
    if ( rc != 0 ):
        print ('CMD: \'{0}\' returned error code: {1}'.format(cmd, rc), file=sys.stderr)
        sys.exit(1)

# Function to run a shell command
def run_niosv_shell_cmd(cmd):
    print('Running: {0}'.format(cmd))
    # Need to preserve the double quotes when the niosv-shell calls the command
    # Primarily for windows execution
    the_cmd = cmd.replace("\"", "\\\\\\\"")
    niosv_cmd = '''niosv-shell -r "{0}" -w'''.format(the_cmd)
    rc = os.system(niosv_cmd)
    if ( rc != 0 ):
        print ('CMD: \'{0}\' returned error code: {1}'.format(niosv_cmd, rc), file=sys.stderr)
        sys.exit(1)

# Main function
def build_software():

    #Generate BSP config files
    if ( not BSP_DIR.exists() ):
        print("[INFO ]: Create BSP")
        if (Path(VDS_PATH).suffix == '.vds'):
            # VDS flow
            vds_bsp_script = open('bsp.tcl', 'w')
            tcl  = 'project_open -no_cmp {{{0}}}\n'.format(QPF_PATH)
            tcl += 'load_package vds\n'
            tcl += 'vds::open_system {{{0}}}\n'.format(VDS_PATH)
            tcl += 'vds::create_bsp {{{0}}} -bsp_type {1} -target_directory {{{2}}} -cpu_instance {3}\n'.format(
                    BSP_SETTINGS_FILENAME, BSP_TYPE, BSP_DIR_VDS, SOPC_CPU_NAME)
            tcl += 'vds::set_bsp_properties {{{0}}} {{'.format(BSP_SETTINGS_FILENAME)
            for s in BSP_SETTINGS:
                tcl += ' settings:{0} {1}'.format(s[0], s[1])
            tcl += ' }\n'
            tcl += 'vds::generate_bsp {{{0}}}'.format(BSP_SETTINGS_FILENAME)
            vds_bsp_script.write(tcl)
            vds_bsp_script.close()
            os.mkdir(BSP_DIR)
            run_shell_cmd('quartus_sh -t bsp.tcl')
            os.remove('bsp.tcl')
        else:
            print("[ERROR]: This script does not support the QSYS flow to build the BSP")
    else:
        print("[INFO ]: Re-using BSP")

    #Generate APP config files
    print("[INFO ]: Create Application")
    run_shell_cmd( 'niosv-app --bsp-dir={0} --app-dir={1} --srcs={2} --elf-name={3}'.
                  format(BSP_DIR, APP_DIR, APP_DIR, ELF_NAME) )

    # Create the CMAKE build project, Note: Formatting requirement to run on windows
    print("[INFO ]: Create build folder")
    run_niosv_shell_cmd( 'cmake -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release -B {0} -S {1}'.format(BUILD_DIR, APP_DIR) )

    # Build the software using CMAKE
    print("[INFO ]: Build the software")
    run_niosv_shell_cmd( 'cmake --build {0}'.format(BUILD_DIR))

    # Create the RAM init file
    print("[INFO ]: Creating RAM init file...")
    mem_init_path=Path(BUILD_DIR).joinpath("mem_init")
    if ( not mem_init_path.exists() ):
        os.mkdir( mem_init_path )

    run_shell_cmd( 'elf2hex {0} -o {1}  -b 0x00000 -w 32 -e 0x3ffff -r 4'.
                  format( Path(BUILD_DIR).joinpath(ELF_NAME), mem_init_path.joinpath(HEX_NAME)) )
    # Create qip for hex file
    write_to_file(mem_init_path.joinpath("meminit.qip"), 'set_global_assignment -name SEARCH_PATH $::quartus(qip_path)')

    print("[INFO ]: Done")

    # Tidy empty directories
    for dirpath, dirnames, filenames in os.walk(Path(BUILD_DIR)):
        if not filenames and not dirnames:
           os.rmdir(dirpath)

# If running directly then call the main function
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Build Genlock-HDR SDI Subsystem Software")
    parser.add_argument('-d', '--delete_build_dir', required=False, action='store_true', default=False, help="Delete the build directory prior to build")
    parser.add_argument('-b', '--delete_bsp_dir', required=False, action='store_true', default=False, help="Delete the BSP directory prior to build")
    parser.add_argument('-n', '--no_build',required=False, action='store_true', default=False, help="Disable build")
    parser.add_argument('-H', '--hdcp',required=False, action='store_true', default=False, help="Copy the HDCP code to the build directory")
    args = parser.parse_args()

    if ( args.delete_build_dir ):
        if ( BUILD_DIR.exists() ):
            shutil.rmtree(BUILD_DIR)
    
    if ( args.delete_bsp_dir ):
        if ( BSP_DIR.exists() ):
            shutil.rmtree(BSP_DIR)

    if ( not args.no_build ):
        build_software()

# Define the exports
__all__ = [ "build_software", "copy_directory", "APP_DIR", "BSP_DIR", "BUILD_DIR" ]

