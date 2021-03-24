proc init { cell_name undefined_params } {}

proc post_config_ip { cell_name args } {
    set ip [get_bd_cells $cell_name]
    set_property CONFIG.POLARITY {ACTIVE_HIGH} [get_bd_pins $cell_name/rst]
    set_property CONFIG.POLARITY {ACTIVE_HIGH} [get_bd_pins $cell_name/gt_rst]
    set_property CONFIG.FREQ_HZ {100000000} [get_bd_pins $cell_name/init_clk]
    set gt_ref_freq [get_property CONFIG.GT_REF_FREQ $ip]
    set_property CONFIG.FREQ_HZ [expr int($gt_ref_freq*10**6)] [get_bd_intf_pins $cell_name/gt_ref]
    set FRAME_WIDTH [get_property CONFIG.FRAME_WIDTH $ip]
    set LANE_LINE_RATE [get_property CONFIG.LANE_LINE_RATE $ip]
    set N_CHANNEL [get_property CONFIG.N_CHANNEL $ip]
    set USER_WIDTH [get_property CONFIG.USER_WIDTH $ip]
    set usr_clk_freq [expr int($N_CHANNEL*$LANE_LINE_RATE*10**9/$USER_WIDTH)]
    set_property CONFIG.FREQ_HZ $usr_clk_freq [get_bd_pins $cell_name/usr_clk]
    set_property CONFIG.ASSOCIATED_BUSIF {s_axis:m_axis:rifl_stat} [get_bd_pins $cell_name/usr_clk]
}

proc propagate { cell_name prop_info } {}