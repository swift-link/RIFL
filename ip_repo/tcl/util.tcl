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
proc get_gt_types {} {
    set gt_types_raw [xit::get_device_data D_AVAILABLE_GT_TYPES -of [xit::current_scope]]
    set gt_dict [dict create]
#    foreach gt_type {"GTH" "GTY" "GTM"} gt_primitive {"GTHE4_CHANNEL" "GTYE4_CHANNEL" "GTM_DUAL"}
    foreach gt_type {"GTH" "GTY"} gt_primitive {"GTHE4_CHANNEL" "GTYE4_CHANNEL"} {
        foreach gt_type_raw $gt_types_raw {
            if {$gt_primitive == $gt_type_raw} {
                dict set gt_dict $gt_type [dict create]
                dict set gt_dict $gt_type primitive $gt_primitive
                break
            }
        }
    }
    return $gt_dict
}

proc get_gt_locations {gt_primitive} {
    set gt_sites [xit::get_device_data D_AVAILABLE_GT_SITES $gt_primitive -of [xit::current_scope]]
    set gt_locs ""
    foreach site $gt_sites {
        if {[::xit::get_device_data D_GT_SITE_IS_BONDED $site -of [xit::current_scope]]} {
            set loc_raw [::xit::get_device_data D_GT_SITE_LOC $site -of [xit::current_scope]]
            lappend gt_locs "X[lindex $loc_raw 0]Y[lindex $loc_raw 1]"
        }
    }
    set gt_locs [lsort -dict $gt_locs]
    return $gt_locs
}

proc build_gt_loc_options {gt_loc_list n_channels} {
    if {$n_channels == 1} {
        return $gt_loc_list
    }
    set gt_loc_option_list ""
    foreach gt_loc $gt_loc_list {
        set loc_header "[lindex [split $gt_loc Y] 0]Y"
        set loc_idx_start [lindex [split $gt_loc Y] 1]
        set loc_idx_end [expr $loc_idx_start + $n_channels - 1]
        set option_valid 1
        for {set i $loc_idx_start} {$i <= $loc_idx_end} {incr i 1} {
            set curr_loc "${loc_header}$i"
            if {[lsearch $gt_loc_list $curr_loc] == -1} {
                set option_valid 0
                break
            }
        }
        if {$option_valid == 1} {
            lappend gt_loc_option_list "${loc_header}${loc_idx_start}~${loc_header}${loc_idx_end}"
        }
    }
    return $gt_loc_option_list
}

proc get_gt_dict {} {
    set gt_dict [get_gt_types]
    set gt_types [dict keys $gt_dict]
    foreach gt_type $gt_types {
        set gt_primitive [dict get $gt_dict $gt_type primitive]
        set gt_locs [get_gt_locations $gt_primitive]
        if {[llength $gt_locs] != 0} {
            dict set gt_dict $gt_type locs $gt_locs
        } else {
            dict unset gt_dict $gt_type
        }
    }
    return $gt_dict
}
