//MIT License
//
//Author: Qianfeng (Clark) Shen
//Copyright (c) 2021 swift-link
//
//Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
proc addip {ipName displayName} {
    set vlnv_version_independent [lindex [get_ipdefs -all -filter "NAME == $ipName"] end]
    return [create_bd_cell -type ip -vlnv $vlnv_version_independent $displayName]
}

set script_dir [file dirname [file normalize [info script]]]
#get RIFL configuration
set rifl_config {}
foreach pp { \
    FRAME_WIDTH \
    USER_WIDTH \
    CABLE_LENGTH \
    GT_TYPE \
    N_CHANNEL \
    CHANNELS \
    LANE_LINE_RATE \
    GT_REF_FREQ \
    INIT_FREQ \
    ERROR_INJ \
    ERROR_SEED
} {
    dict append rifl_config CONFIG.${pp} [get_property CONFIG.${pp} [get_ips]]
}
set project_dir [get_property DIRECTORY [current_project]]
set project_name [get_property NAME [current_project]]
remove_files  ${project_dir}/${project_name}.srcs/sources_1/ip/RIFL_*/RIFL_*.xci
file delete -force ${project_dir}/${project_name}.srcs/sources_1/ip/RIFL_*
source $script_dir/example_syn_bd.tcl
source $script_dir/example_sim_bd.tcl
create_syn_bd $rifl_config $project_dir $project_name
create_sim_bd $rifl_config $project_dir $project_name