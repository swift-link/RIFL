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
proc create_sim_bd {rifl_config project_dir project_name} {
    set bd_name "rifl_ex_sim"
    create_bd_design ${bd_name}
    current_bd_design [get_bd_designs ${bd_name}]
    
    set traffic_dwidth [dict get ${rifl_config} CONFIG.USER_WIDTH]
    set n_channel [dict get ${rifl_config} CONFIG.N_CHANNEL]
    set gt_ref_freq [expr int([dic get ${rifl_config} CONFIG.GT_REF_FREQ]*10**6)]
    set init_freq [expr int([dic get ${rifl_config} CONFIG.INIT_FREQ]*10**6)]

    dict set rifl_config CONFIG.ERROR_INJ 1

    #RIFL
    set RIFL [ addip RIFL RIFL_0 ]
    set_property -dict ${rifl_config} $RIFL
    
    #easyobv_axis_randgen
    set easyobv_axis_randgen [ addip easyobv_axis_randgen easyobv_axis_randgen_0 ]
    set_property -dict [ list \
        CONFIG.DWIDTH $traffic_dwidth \
        CONFIG.EN_AXIL {0} \
        CONFIG.HAS_KEEP {1} \
        CONFIG.HAS_LAST {1} \
        CONFIG.HAS_READY {1} \
    ] $easyobv_axis_randgen
    
    #easyobv_axis_mon
    set easyobv_axis_mon [ addip easyobv_axis_mon easyobv_axis_mon_0 ]
    set_property -dict [ list \
        CONFIG.CMP_FIFO_DEPTH {512} \
        CONFIG.DWIDTH $traffic_dwidth \
        CONFIG.EN_AXIL {0} \
        CONFIG.HAS_KEEP {1} \
        CONFIG.HAS_LAST {1} \
        CONFIG.HAS_READY {1} \
        CONFIG.LOOPBACK {1} \
    ] $easyobv_axis_mon
    
    #axis_dummy_slave
    set axis_dummy_slave [ addip axis_dummy_slave axis_dummy_slave_0 ]
    set_property -dict [ list \
        CONFIG.DWIDTH $traffic_dwidth \
        CONFIG.HAS_READY {1} \
        CONFIG.HAS_KEEP {1} \
        CONFIG.HAS_LAST {1} \
    ] $axis_dummy_slave
    
    #constants################################################################
    #gt_loopback_code
    set code [string repeat "000" $n_channel]
    set code_width [expr $n_channel*3]
    set gt_loopback_code [ addip xlconstant gt_loopback_code ]
    set_property -dict [ list \
        CONFIG.CONST_VAL "b$code" \
        CONFIG.CONST_WIDTH $code_width \
    ] $gt_loopback_code
    
    # external ports
    make_bd_pins_external [get_bd_pins RIFL_0/init_clk] -name init_clk
    make_bd_pins_external [get_bd_pins RIFL_0/rst] -name rifl_rst
    make_bd_pins_external [get_bd_pins easyobv_axis_randgen_0/rst] -name traffic_rst
    make_bd_pins_external [get_bd_pins easyobv_axis_randgen_0/start] -name start
    make_bd_pins_external [get_bd_pins easyobv_axis_randgen_0/pkt_cnt_limit] -name pkt_cnt_limit
    make_bd_pins_external [get_bd_pins easyobv_axis_randgen_0/idle_ratio_code] -name idle_ratio_code
    make_bd_pins_external [get_bd_pins easyobv_axis_randgen_0/pkt_len_min] -name pkt_len_min
    make_bd_pins_external [get_bd_pins easyobv_axis_randgen_0/pkt_len_max] -name pkt_len_max
    make_bd_pins_external [get_bd_pins easyobv_axis_randgen_0/done] -name done
    make_bd_pins_external [get_bd_pins RIFL_0/ber_code] -name ber_code
    make_bd_pins_external [get_bd_pins easyobv_axis_mon_0/clear] -name clear
    make_bd_pins_external [get_bd_pins axis_dummy_slave_0/bp_ratio_code] -name bp_ratio_code
    make_bd_intf_pins_external [get_bd_intf_pins RIFL_0/gt_ref] -name gt_ref
    make_bd_intf_pins_external [get_bd_intf_pins RIFL_0/rifl_gt] -name rifl_gt
    make_bd_intf_pins_external [get_bd_intf_pins RIFL_0/rifl_stat] -name rifl_stat
    make_bd_intf_pins_external [get_bd_intf_pins easyobv_axis_mon_0/dbg] -name dbg

    set_property CONFIG.FREQ_HZ $gt_ref_freq [get_bd_intf_ports gt_ref]
    set_property CONFIG.FREQ_HZ $init_freq [get_bd_ports /init_clk]

    connect_bd_net [get_bd_pins RIFL_0/usr_clk] \
                    [get_bd_pins easyobv_axis_randgen_0/clk] \
                    [get_bd_pins easyobv_axis_mon_0/clk] \
                    [get_bd_pins axis_dummy_slave_0/clk]

    connect_bd_net [get_bd_ports rifl_rst] [get_bd_pins RIFL_0/gt_rst]
    connect_bd_net [get_bd_ports traffic_rst] [get_bd_pins easyobv_axis_mon_0/rst]
    connect_bd_net [get_bd_pins gt_loopback_code/dout] [get_bd_pins RIFL_0/gt_loopback_in]

    connect_bd_intf_net [get_bd_intf_pins easyobv_axis_randgen_0/traffic] [get_bd_intf_pins RIFL_0/s_axis]
    connect_bd_intf_net [get_bd_intf_pins RIFL_0/m_axis] [get_bd_intf_pins axis_dummy_slave_0/s_axis]
    connect_bd_intf_net [get_bd_intf_pins easyobv_axis_mon_0/tx_mon] [get_bd_intf_pins RIFL_0/s_axis]
    connect_bd_intf_net [get_bd_intf_pins easyobv_axis_mon_0/rx_mon] [get_bd_intf_pins axis_dummy_slave_0/s_axis]
    regenerate_bd_layout

    set_property USED_IN {simulation} [get_files ${project_dir}/${project_name}.srcs/sources_1/bd/${bd_name}/${bd_name}.bd]
    set_property -name {xsim.compile.xvlog.more_options} -value {-d SIM_SPEED_UP} -objects [get_filesets sim_1]
    set_property -name {xsim.simulate.log_all_signals} -value {true} -objects [get_filesets sim_1]
}