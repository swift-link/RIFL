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
proc init { cell_name undefined_params } {}

proc post_config_ip { cell_name args } {
    set ip [get_bd_cells $cell_name]
    set_property CONFIG.POLARITY {ACTIVE_HIGH} [get_bd_pins $cell_name/rst]
    set_property CONFIG.POLARITY {ACTIVE_HIGH} [get_bd_pins $cell_name/gt_rst]
    set gt_ref_freq [get_property CONFIG.GT_REF_FREQ $ip]
    set_property CONFIG.FREQ_HZ [expr int($gt_ref_freq*10**6)] [get_bd_intf_pins $cell_name/gt_ref]
    set init_freq [get_property CONFIG.INIT_FREQ $ip]
    set_property CONFIG.FREQ_HZ [expr int($init_freq*10**6)] [get_bd_pins $cell_name/init_clk]
    set FRAME_WIDTH [get_property CONFIG.FRAME_WIDTH $ip]
    set LANE_LINE_RATE [get_property CONFIG.LANE_LINE_RATE $ip]
    set N_CHANNEL [get_property CONFIG.N_CHANNEL $ip]
    set USER_WIDTH [get_property CONFIG.USER_WIDTH $ip]
    set usr_clk_freq [expr int($N_CHANNEL*$LANE_LINE_RATE*10**9/$USER_WIDTH)]
    set_property CONFIG.FREQ_HZ $usr_clk_freq [get_bd_pins $cell_name/usr_clk]
    set_property CONFIG.ASSOCIATED_BUSIF {s_axis:m_axis:rifl_stat} [get_bd_pins $cell_name/usr_clk]
}

proc propagate { cell_name prop_info } {}