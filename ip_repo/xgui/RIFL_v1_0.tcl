#MIT License
#
#Author: Qianfeng (Clark) Shen
#Copyright (c) 2021 swift-link
#
#Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
# Definitional proc to organize widgets for parameters.
source_ipfile "tcl/util.tcl"
proc init_gui {IPINST} {
    ipgui::add_param $IPINST -name "Component_Name"
    #Adding Page
    set Page_0 [ipgui::add_page $IPINST -name "Page 0" -display_name {Basic Parameters}]
    set_property tooltip {Basic Parameters} ${Page_0}
    #Adding Group
    set RIFL_Configurations [ipgui::add_group $IPINST -name "RIFL Configurations" -parent ${Page_0}]
    set_property tooltip {RIFL Configurations} ${RIFL_Configurations}
    set FRAME_WIDTH [ipgui::add_param $IPINST -name "FRAME_WIDTH" -parent ${RIFL_Configurations} -widget comboBox]
    set_property tooltip {RIFL internal frame size. RIFL packs user data into frames. The bigger the frame size is, the larger bandwidth efficiency RIFL can achieve, with the trade off of larger latency.} ${FRAME_WIDTH}
    ipgui::add_param $IPINST -name "USER_WIDTH" -parent ${RIFL_Configurations} -widget comboBox
    set CABLE_LENGTH [ipgui::add_param $IPINST -name "CABLE_LENGTH" -parent ${RIFL_Configurations}]
    set_property tooltip {Max Supported Cable Length: The longest cable length (in meter) this link can support. Larger max cable length leads to higher resource usage. If the operation BER is very high (> 1e-7), larger max cable length can also leads to higher tail latency.} ${CABLE_LENGTH}

    #Adding Group
    set GT_Configurations [ipgui::add_group $IPINST -name "GT Configurations" -parent ${Page_0}]
    set_property tooltip {GT Configurations} ${GT_Configurations}
    ipgui::add_param $IPINST -name "GT_TYPE" -parent ${GT_Configurations} -widget comboBox
    ipgui::add_param $IPINST -name "N_CHANNEL" -parent ${GT_Configurations} -widget comboBox
    ipgui::add_param $IPINST -name "CHANNELS" -parent ${GT_Configurations} -widget comboBox
    ipgui::add_param $IPINST -name "LANE_LINE_RATE" -parent ${GT_Configurations}
    ipgui::add_param $IPINST -name "GT_REF_FREQ" -parent ${GT_Configurations}
    ipgui::add_param $IPINST -name "INIT_FREQ" -parent ${GT_Configurations}

    #Adding Page
    set Error_Injection [ipgui::add_page $IPINST -name "Error Injection"]
    set_property tooltip {Error Injection} ${Error_Injection}
    ipgui::add_param $IPINST -name "ERROR_INJ" -parent ${Error_Injection} -widget comboBox
    ipgui::add_param $IPINST -name "ERROR_SEED" -parent ${Error_Injection} -widget comboBox
}

proc update_PARAM_VALUE.USER_WIDTH {PARAM_VALUE.FRAME_WIDTH PARAM_VALUE.N_CHANNEL PARAM_VALUE.USER_WIDTH PROJECT_PARAM.ARCHITECTURE} {
    # Procedure called to update USER_WIDTH when any of the dependent parameters in the arguments change
    set curr_frame_width [get_property value ${PARAM_VALUE.FRAME_WIDTH}]
    set curr_n_channel [get_property value ${PARAM_VALUE.N_CHANNEL}]
    set user_width_list ""
    for {set i 1} {$i <= $curr_n_channel} {set i [expr $i*2]} {
        lappend user_width_list [expr $curr_frame_width*$i]
    }
    set_property range [join $user_width_list ,] ${PARAM_VALUE.USER_WIDTH}
}

proc update_PARAM_VALUE.GT_TYPE {PARAM_VALUE.GT_TYPE PROJECT_PARAM.ARCHITECTURE} {
    set gt_dict [get_gt_dict]
    set gt_types [dict keys $gt_dict]
    set default_gt_type [lindex $gt_types 0]
    set_property range [join $gt_types ,] ${PARAM_VALUE.GT_TYPE}
    set_property value $default_gt_type ${PARAM_VALUE.GT_TYPE}
}

proc update_PARAM_VALUE.N_CHANNEL {PARAM_VALUE.GT_TYPE PARAM_VALUE.N_CHANNEL PROJECT_PARAM.ARCHITECTURE} {
    # Procedure called to update N_CHANNEL when any of the dependent parameters in the arguments change
    set gt_dict [get_gt_dict]
    set curr_gt_type [get_property value ${PARAM_VALUE.GT_TYPE}]
    set gt_loc_list [dict get $gt_dict $curr_gt_type locs]
    set max_n_channel 1
    for {set i 4} {$i > 1} {set i [expr $i/2]} {
        set gt_loc_option_list [build_gt_loc_options $gt_loc_list $i]
        if {[llength $gt_loc_option_list] != 0} {
            set max_n_channel $i
            break
        }
    }
    set n_channels_list ""
    for {set i 1} {$i <= $max_n_channel} {set i [expr $i*2]} {
        lappend n_channels_list $i
    }
    set_property range [join $n_channels_list ,] ${PARAM_VALUE.N_CHANNEL}
    set curr_val [get_property value ${PARAM_VALUE.N_CHANNEL}]
    if {[lsearch $n_channels_list $curr_val] == -1} {
        set_property value [lindex $n_channels_list 0] ${PARAM_VALUE.N_CHANNEL}
    }
}

proc update_PARAM_VALUE.CHANNELS {PARAM_VALUE.GT_TYPE PARAM_VALUE.N_CHANNEL PARAM_VALUE.CHANNELS PROJECT_PARAM.ARCHITECTURE} {
	# Procedure called to update CHANNELS when any of the dependent parameters in the arguments change
    set gt_dict [get_gt_dict]
    set curr_gt_type [get_property value ${PARAM_VALUE.GT_TYPE}]
    set curr_n_channels [get_property value ${PARAM_VALUE.N_CHANNEL}]
    set curr_loc [get_property value ${PARAM_VALUE.CHANNELS}]
    set gt_loc_list [dict get $gt_dict $curr_gt_type locs]
    set gt_loc_option_list [build_gt_loc_options $gt_loc_list $curr_n_channels]
    set_property range [join $gt_loc_option_list ,] ${PARAM_VALUE.CHANNELS}
    set curr_val [get_property value ${PARAM_VALUE.CHANNELS}]
    if {[lsearch $gt_loc_option_list $curr_val] == -1} {
        set_property value [lindex $gt_loc_option_list 0] ${PARAM_VALUE.CHANNELS}
    }
}

proc update_PARAM_VALUE.LANE_LINE_RATE {PARAM_VALUE.GT_TYPE PARAM_VALUE.LANE_LINE_RATE PROJECT_PARAM.ARCHITECTURE PROJECT_PARAM.SPEEDGRADE} {
	# Procedure called to update LANE_LINE_RATE when any of the dependent parameters in the arguments change
    set curr_gt_type [get_property value ${PARAM_VALUE.GT_TYPE}]
    set speed_grade ${PROJECT_PARAM.SPEEDGRADE}
    set min_val 0.5
    set max_val 16.375
    if {[regexp 1 $speed_grade]} {
        set max_val 12.5
    }
    if {$curr_gt_type == "GTY"} {
        set min_val 0.5
        set max_val 25.785
        if {[regexp 2 $speed_grade]} {
            set max_val 28.21
        } elseif {[regexp 3 $speed_grade]} {
            set max_val 32.75
        }
    } elseif {$curr_gt_type == "GTM"} {
        set min_val 10.31
        set max_val 58.0
    }
    set_property range "${min_val},${max_val}" ${PARAM_VALUE.LANE_LINE_RATE}
    set curr_val [get_property value ${PARAM_VALUE.LANE_LINE_RATE}]
    if {$curr_val < $min_val} {
        set_property value $min_val ${PARAM_VALUE.LANE_LINE_RATE}
    } elseif {$curr_val > $max_val} {
        set_property value $max_val ${PARAM_VALUE.LANE_LINE_RATE}
    }
}

proc update_PARAM_VALUE.GT_REF_FREQ {PARAM_VALUE.LANE_LINE_RATE PARAM_VALUE.GT_REF_FREQ PROJECT_PARAM.ARCHITECTURE} {
    set linerate [get_property value ${PARAM_VALUE.LANE_LINE_RATE}]
    set rate_ratio 1.0
    if {$linerate > 16.375} {
        set rate_ratio 2.0
    }
    set min_val [expr $linerate*1000.0/$rate_ratio/160]
    set max_val [expr $linerate*1000.0/$rate_ratio/16]
    set_property range "${min_val},${max_val}" ${PARAM_VALUE.GT_REF_FREQ}
    set curr_val [get_property value ${PARAM_VALUE.GT_REF_FREQ}]
    if {$curr_val < $min_val} {
        set_property value "$min_val" ${PARAM_VALUE.GT_REF_FREQ}
    } elseif {$curr_val > $max_val} {
        set_property value "$max_val" ${PARAM_VALUE.GT_REF_FREQ}
    }
}

proc update_PARAM_VALUE.INIT_FREQ {PARAM_VALUE.GT_REF_FREQ PARAM_VALUE.INIT_FREQ PROJECT_PARAM.ARCHITECTURE} {
    # Procedure called to update INIT_FREQ when any of the dependent parameters in the arguments change
    set max_val [get_property value ${PARAM_VALUE.GT_REF_FREQ}]
    if {$max_val > 250.0} {
        set max_val 250.0
    }
    set_property range "3.125,${max_val}" ${PARAM_VALUE.INIT_FREQ}
}

proc update_PARAM_VALUE.GT_WIDTH {PARAM_VALUE.GT_WIDTH PARAM_VALUE.GT_TYPE PROJECT_PARAM.ARCHITECTURE} {
    # Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
    set curr_gt_type [get_property value ${PARAM_VALUE.GT_TYPE}]
    set_property value 64 ${PARAM_VALUE.GT_WIDTH}
    if {$curr_gt_type == "GTM"} {
        set_property value 128 ${PARAM_VALUE.GT_WIDTH}
    }
}

proc update_PARAM_VALUE.GT_INT_WIDTH {PARAM_VALUE.GT_INT_WIDTH PARAM_VALUE.GT_TYPE PROJECT_PARAM.ARCHITECTURE} {
    # Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
    set curr_gt_type [get_property value ${PARAM_VALUE.GT_TYPE}]
    set_property value 32 ${PARAM_VALUE.GT_INT_WIDTH}
    if {$curr_gt_type == "GTY"} {
        set_property value 64 ${PARAM_VALUE.GT_INT_WIDTH}
    } elseif {$curr_gt_type == "GTM"} {
        set_property value 128 ${PARAM_VALUE.GT_INT_WIDTH}
    }
}

proc update_MODELPARAM_VALUE.GT_TYPE {MODELPARAM_VALUE.GT_TYPE PARAM_VALUE.GT_TYPE PROJECT_PARAM.ARCHITECTURE} {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.GT_TYPE}] ${MODELPARAM_VALUE.GT_TYPE}
}

proc update_MODELPARAM_VALUE.N_CHANNEL {MODELPARAM_VALUE.N_CHANNEL PARAM_VALUE.N_CHANNEL PROJECT_PARAM.ARCHITECTURE} {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.N_CHANNEL}] ${MODELPARAM_VALUE.N_CHANNEL}
}

proc update_MODELPARAM_VALUE.START_CHAN {MODELPARAM_VALUE.START_CHAN PARAM_VALUE.CHANNELS PROJECT_PARAM.ARCHITECTURE} {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
    set curr_channels [get_property value ${PARAM_VALUE.CHANNELS}]
    set curr_master_channel [lindex [split $curr_channels "~"] 0]
	set_property value $curr_master_channel ${MODELPARAM_VALUE.START_CHAN}
}

proc update_MODELPARAM_VALUE.GT_WIDTH {MODELPARAM_VALUE.GT_WIDTH PARAM_VALUE.GT_TYPE PROJECT_PARAM.ARCHITECTURE} {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
    set curr_gt_type [get_property value ${PARAM_VALUE.GT_TYPE}]
    set_property value 64 ${MODELPARAM_VALUE.GT_WIDTH}
    if {$curr_gt_type == "GTM"} {
        set_property value 128 ${MODELPARAM_VALUE.GT_WIDTH}
    }
}

proc update_MODELPARAM_VALUE.GT_INT_WIDTH {MODELPARAM_VALUE.GT_INT_WIDTH PARAM_VALUE.GT_TYPE PROJECT_PARAM.ARCHITECTURE} {
    # Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
    set curr_gt_type [get_property value ${PARAM_VALUE.GT_TYPE}]
    set_property value 32 ${MODELPARAM_VALUE.GT_INT_WIDTH}
    if {$curr_gt_type == "GTY"} {
        set_property value 64 ${MODELPARAM_VALUE.GT_INT_WIDTH}
    } elseif {$curr_gt_type == "GTM"} {
        set_property value 128 ${MODELPARAM_VALUE.GT_INT_WIDTH}
    }
}

proc update_MODELPARAM_VALUE.LANE_LINE_RATE {MODELPARAM_VALUE.LANE_LINE_RATE PARAM_VALUE.LANE_LINE_RATE PROJECT_PARAM.ARCHITECTURE} {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.LANE_LINE_RATE}] ${MODELPARAM_VALUE.LANE_LINE_RATE}
}

proc update_MODELPARAM_VALUE.GT_REF_FREQ {MODELPARAM_VALUE.GT_REF_FREQ PARAM_VALUE.GT_REF_FREQ PROJECT_PARAM.ARCHITECTURE} {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.GT_REF_FREQ}] ${MODELPARAM_VALUE.GT_REF_FREQ}
}

proc update_MODELPARAM_VALUE.INIT_FREQ {MODELPARAM_VALUE.INIT_FREQ PARAM_VALUE.INIT_FREQ PROJECT_PARAM.ARCHITECTURE} {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.INIT_FREQ}] ${MODELPARAM_VALUE.INIT_FREQ}
}

proc update_MODELPARAM_VALUE.ERROR_INJ {MODELPARAM_VALUE.ERROR_INJ PARAM_VALUE.ERROR_INJ PROJECT_PARAM.ARCHITECTURE} {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ERROR_INJ}] ${MODELPARAM_VALUE.ERROR_INJ}
}

proc update_MODELPARAM_VALUE.ERROR_SEED {MODELPARAM_VALUE.ERROR_SEED PARAM_VALUE.ERROR_SEED PROJECT_PARAM.ARCHITECTURE} {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ERROR_SEED}] ${MODELPARAM_VALUE.ERROR_SEED}
}

proc update_MODELPARAM_VALUE.CABLE_LENGTH {MODELPARAM_VALUE.CABLE_LENGTH PARAM_VALUE.CABLE_LENGTH PROJECT_PARAM.ARCHITECTURE} {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.CABLE_LENGTH}] ${MODELPARAM_VALUE.CABLE_LENGTH}
}

proc update_MODELPARAM_VALUE.USER_WIDTH {MODELPARAM_VALUE.USER_WIDTH PARAM_VALUE.USER_WIDTH PROJECT_PARAM.ARCHITECTURE} {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.USER_WIDTH}] ${MODELPARAM_VALUE.USER_WIDTH}
}

proc update_MODELPARAM_VALUE.FRAME_WIDTH {MODELPARAM_VALUE.FRAME_WIDTH PARAM_VALUE.FRAME_WIDTH PROJECT_PARAM.ARCHITECTURE} {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.FRAME_WIDTH}] ${MODELPARAM_VALUE.FRAME_WIDTH}
}
