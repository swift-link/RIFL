proc init { cell_name undefined_params } {}

proc post_config_ip { cell_name args } {
    set ip [get_bd_cells $cell_name]
    set_property CONFIG.POLARITY {ACTIVE_HIGH} [get_bd_pins $cell_name/rst]
    set en_axil [get_property CONFIG.EN_AXIL $ip]
    if {$en_axil != 0} {
        set_property CONFIG.ASSOCIATED_BUSIF {s_axil} [get_bd_pins $cell_name/s_axil_aclk]
    }
    set loopback [get_property CONFIG.LOOPBACK $ip]
    if {$loopback != 0} {
        set_property CONFIG.ASSOCIATED_BUSIF {dbg:tx_mon:rx_mon} [get_bd_pins $cell_name/clk]
    } else {
        set_property CONFIG.ASSOCIATED_BUSIF {dbg:tx_mon} [get_bd_pins $cell_name/clk]
    }
}

proc propagate { cell_name prop_info } {
    set ip [get_bd_cells $cell_name]
    set clk_freq [get_property CONFIG.FREQ_HZ [get_bd_pins $cell_name/clk]]
    set_property CONFIG.CLK_FREQ.VALUE_SRC DEFAULT $ip
    set_property CONFIG.CLK_FREQ $clk_freq $ip
}
