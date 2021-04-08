proc init { cell_name undefined_params } {}

proc post_config_ip { cell_name args } {
    set ip [get_bd_cells $cell_name]
    set_property CONFIG.ASSOCIATED_BUSIF {s_axis} [get_bd_pins $cell_name/clk]
}

proc propagate { cell_name prop_info } {
}
