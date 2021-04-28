#MIT License
#
#Author: Qianfeng (Clark) Shen;Contact: qianfeng.shen@gmail.com
#
#Copyright (c) 2021 swift-link
#
#Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
proc create_syn_bd {rifl_config project_dir project_name} {
    set bd_name "rifl_ex_syn"
    create_bd_design ${bd_name}
    current_bd_design [get_bd_designs ${bd_name}]
    
    set traffic_dwidth [dict get ${rifl_config} CONFIG.USER_WIDTH]
    set n_channel [dict get ${rifl_config} CONFIG.N_CHANNEL]
    set err_inj [dic get ${rifl_config} CONFIG.ERROR_INJ]
    set gt_ref_freq [expr int([dic get ${rifl_config} CONFIG.GT_REF_FREQ]*10**6)]
    set init_freq [expr int([dic get ${rifl_config} CONFIG.INIT_FREQ]*10**6)]

    # external ports
    set gt_ref [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 gt_ref ]
    set init [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 init ]
    set rifl_gt [ create_bd_intf_port -mode Master -vlnv clarkshen.com:user:rifl_gt_rtl:1.0 rifl_gt ]
    
    set_property CONFIG.FREQ_HZ $gt_ref_freq [get_bd_intf_ports /gt_ref]
    set_property CONFIG.FREQ_HZ $init_freq [get_bd_intf_ports /init]
    
    # init clock
    set util_ds_buf_0 [ addip util_ds_buf util_ds_buf_0 ]
    
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
    set code [string repeat "010" $n_channel]
    set code_width [expr $n_channel*3]
    set gt_loopback_code [ addip xlconstant gt_loopback_code ]
    set_property -dict [ list \
        CONFIG.CONST_VAL "b$code" \
        CONFIG.CONST_WIDTH $code_width \
    ] $gt_loopback_code
    
    #ila_rstn
    set ila_rstn [ addip xlconstant ila_rstn ]
    ##########################################################################
    #rifl_ex_ila
    set rifl_ex_ila [ addip system_ila rifl_ex_ila ]
    set_property -dict [ list \
        CONFIG.C_BRAM_CNT {46.5} \
        CONFIG.C_MON_TYPE {MIX} \
        CONFIG.C_NUM_MONITOR_SLOTS {4} \
        CONFIG.C_SLOT {3} \
        CONFIG.C_SLOT_0_INTF_TYPE {xilinx.com:interface:axis_rtl:1.0} \
        CONFIG.C_SLOT_1_INTF_TYPE {xilinx.com:interface:axis_rtl:1.0} \
        CONFIG.C_SLOT_2_INTF_TYPE {clarkshen.com:user:dbg_easyobv_rtl:1.0} \
        CONFIG.C_SLOT_3_INTF_TYPE {clarkshen.com:user:rifl_stat_rtl:1.0} \
    ] $rifl_ex_ila
    
    #vios#####################################################################
    set backpressure_ratio_code [ addip vio backpressure_ratio_code ]
    set_property -dict [ list \
        CONFIG.C_EN_PROBE_IN_ACTIVITY {0} \
        CONFIG.C_NUM_PROBE_IN {0} \
        CONFIG.C_PROBE_OUT0_WIDTH {64} \
    ] $backpressure_ratio_code
    
    set rifl_rst [ addip vio rifl_rst ]
    set_property -dict [ list \
        CONFIG.C_EN_PROBE_IN_ACTIVITY {0} \
        CONFIG.C_NUM_PROBE_IN {0} \
        CONFIG.C_NUM_PROBE_OUT {2} \
    ] $rifl_rst
    
    set traffic_gen_params [ addip vio traffic_gen_params ]
    set_property -dict [ list \
        CONFIG.C_EN_PROBE_IN_ACTIVITY {0} \
        CONFIG.C_NUM_PROBE_IN {0} \
        CONFIG.C_NUM_PROBE_OUT {5} \
        CONFIG.C_PROBE_OUT1_WIDTH {32} \
        CONFIG.C_PROBE_OUT2_WIDTH {64} \
        CONFIG.C_PROBE_OUT3_WIDTH {16} \
        CONFIG.C_PROBE_OUT4_WIDTH {16} \
    ] $traffic_gen_params
    
    set traffic_mon_clear [ addip vio traffic_mon_clear ]
    set_property -dict [ list \
        CONFIG.C_EN_PROBE_IN_ACTIVITY {0} \
        CONFIG.C_NUM_PROBE_IN {0} \
    ] $traffic_mon_clear
    
    set traffic_rst [ addip vio traffic_rst ]
    set_property -dict [ list \
        CONFIG.C_EN_PROBE_IN_ACTIVITY {0} \
        CONFIG.C_NUM_PROBE_IN {0} \
    ] $traffic_rst
    ##########################################################################
    
    create_bd_cell -type hier VIOs
    move_bd_cells [get_bd_cells VIOs] [get_bd_cells traffic_gen_params]
    move_bd_cells [get_bd_cells VIOs] [get_bd_cells traffic_rst]
    move_bd_cells [get_bd_cells VIOs] [get_bd_cells traffic_mon_clear]
    move_bd_cells [get_bd_cells VIOs] [get_bd_cells backpressure_ratio_code]
    move_bd_cells [get_bd_cells VIOs] [get_bd_cells rifl_rst]
    
    connect_bd_intf_net -intf_net RIFL_0_rifl_gt [get_bd_intf_ports rifl_gt] [get_bd_intf_pins RIFL_0/rifl_gt]
    connect_bd_intf_net -intf_net RIFL_0_rifl_stat [get_bd_intf_pins RIFL_0/rifl_stat] [get_bd_intf_pins rifl_ex_ila/SLOT_3_RIFL_STAT]
    connect_bd_intf_net -intf_net axis_register_slice_0_M_AXIS [get_bd_intf_pins RIFL_0/m_axis] [get_bd_intf_pins axis_dummy_slave_0/s_axis]
    connect_bd_intf_net -intf_net [get_bd_intf_nets axis_register_slice_0_M_AXIS] [get_bd_intf_pins RIFL_0/m_axis] [get_bd_intf_pins easyobv_axis_mon_0/rx_mon]
    connect_bd_intf_net -intf_net [get_bd_intf_nets axis_register_slice_0_M_AXIS] [get_bd_intf_pins RIFL_0/m_axis] [get_bd_intf_pins rifl_ex_ila/SLOT_1_AXIS]
    connect_bd_intf_net -intf_net easyobv_axis_mon_0_dbg [get_bd_intf_pins easyobv_axis_mon_0/dbg] [get_bd_intf_pins rifl_ex_ila/SLOT_2_DBG_EASYOBV]
    connect_bd_intf_net -intf_net easyobv_axis_randgen_0_traffic [get_bd_intf_pins RIFL_0/s_axis] [get_bd_intf_pins easyobv_axis_randgen_0/traffic]
    connect_bd_intf_net -intf_net [get_bd_intf_nets easyobv_axis_randgen_0_traffic] [get_bd_intf_pins RIFL_0/s_axis] [get_bd_intf_pins easyobv_axis_mon_0/tx_mon]
    connect_bd_intf_net -intf_net [get_bd_intf_nets easyobv_axis_randgen_0_traffic] [get_bd_intf_pins RIFL_0/s_axis] [get_bd_intf_pins rifl_ex_ila/SLOT_0_AXIS]
    connect_bd_intf_net -intf_net gt_ref_clk_diff [get_bd_intf_ports gt_ref] [get_bd_intf_pins RIFL_0/gt_ref]
    connect_bd_intf_net -intf_net init_clk_diff [get_bd_intf_ports init] [get_bd_intf_pins util_ds_buf_0/CLK_IN_D]
    
    connect_bd_net -net init_clk [get_bd_pins util_ds_buf_0/IBUF_OUT] [get_bd_pins RIFL_0/init_clk]
    connect_bd_net [get_bd_pins util_ds_buf_0/IBUF_OUT] [get_bd_pins /VIOs/rifl_rst/clk]
    
    connect_bd_net -net usr_clk [get_bd_pins RIFL_0/usr_clk] \
                        [get_bd_pins axis_dummy_slave_0/clk] \
                        [get_bd_pins easyobv_axis_mon_0/clk] \
                        [get_bd_pins easyobv_axis_randgen_0/clk] \
                        [get_bd_pins rifl_ex_ila/clk]
    connect_bd_net [get_bd_pins RIFL_0/usr_clk] \
                        [get_bd_pins /VIOs/backpressure_ratio_code/clk] \
                        [get_bd_pins /VIOs/traffic_gen_params/clk] \
                        [get_bd_pins /VIOs/traffic_mon_clear/clk] \
                        [get_bd_pins /VIOs/traffic_rst/clk]
    connect_bd_net -net ila_rstn [get_bd_pins ila_rstn/dout] [get_bd_pins rifl_ex_ila/resetn]
    connect_bd_net -net gt_loopback_code [get_bd_pins RIFL_0/gt_loopback_in] [get_bd_pins gt_loopback_code/dout]
    connect_bd_net -net randgen_done [get_bd_pins easyobv_axis_randgen_0/done] [get_bd_pins rifl_ex_ila/probe0]
    
    connect_bd_net [get_bd_pins /VIOs/backpressure_ratio_code/probe_out0] [get_bd_pins axis_dummy_slave_0/bp_ratio_code]
    connect_bd_net [get_bd_pins /VIOs/rifl_rst/probe_out1] [get_bd_pins RIFL_0/gt_rst]
    connect_bd_net [get_bd_pins /VIOs/traffic_gen_params/probe_out2] [get_bd_pins easyobv_axis_randgen_0/idle_ratio_code]
    connect_bd_net [get_bd_pins /VIOs/traffic_gen_params/probe_out1] [get_bd_pins easyobv_axis_randgen_0/pkt_cnt_limit]
    connect_bd_net [get_bd_pins /VIOs/traffic_gen_params/probe_out4] [get_bd_pins easyobv_axis_randgen_0/pkt_len_max]
    connect_bd_net [get_bd_pins /VIOs/traffic_gen_params/probe_out3] [get_bd_pins easyobv_axis_randgen_0/pkt_len_min]
    connect_bd_net [get_bd_pins /VIOs/rifl_rst/probe_out0] [get_bd_pins RIFL_0/rst]
    connect_bd_net [get_bd_pins /VIOs/traffic_gen_params/probe_out0] [get_bd_pins easyobv_axis_randgen_0/start]
    connect_bd_net [get_bd_pins /VIOs/traffic_mon_clear/probe_out0] [get_bd_pins easyobv_axis_mon_0/clear]
    connect_bd_net [get_bd_pins /VIOs/traffic_rst/probe_out0] \
                    [get_bd_pins easyobv_axis_mon_0/rst] \
                    [get_bd_pins easyobv_axis_randgen_0/rst]
    
    set_property name bp_ratio_code [get_bd_pins VIOs/probe_out0]
    set_property name gt_rst [get_bd_pins VIOs/probe_out1]
    set_property name idle_ratio_code [get_bd_pins VIOs/probe_out2]
    set_property name pkt_cnt_limit [get_bd_pins VIOs/probe_out3]
    set_property name pkt_len_max [get_bd_pins VIOs/probe_out4]
    set_property name pkt_len_min [get_bd_pins VIOs/probe_out5]
    set_property name rifl_rst [get_bd_pins VIOs/probe_out6]
    set_property name start [get_bd_pins VIOs/probe_out7]
    set_property name traffic_mon_clear [get_bd_pins VIOs/probe_out8]
    set_property name traffic_rst [get_bd_pins VIOs/probe_out9]
    
    set_property name bp_ratio_code [get_bd_nets VIOs_probe_out0]
    set_property name gt_rst [get_bd_nets VIOs_probe_out1]
    set_property name idle_ratio_code [get_bd_nets VIOs_probe_out2]
    set_property name pkt_cnt_limit [get_bd_nets VIOs_probe_out3]
    set_property name pkt_len_max [get_bd_nets VIOs_probe_out4]
    set_property name pkt_len_min [get_bd_nets VIOs_probe_out5]
    set_property name rifl_rst [get_bd_nets VIOs_probe_out6]
    set_property name start [get_bd_nets VIOs_probe_out7]
    set_property name traffic_mon_clear [get_bd_nets VIOs_probe_out8]
    set_property name traffic_rst [get_bd_nets VIOs_probe_out9]
    
    set_property name bp_ratio_code [get_bd_nets VIOs/backpressure_ratio_code_probe_out0]
    set_property name gt_rst [get_bd_nets VIOs/rifl_rst_probe_out1]
    set_property name idle_ratio_code [get_bd_nets VIOs/traffic_gen_params_probe_out2]
    set_property name pkt_cnt_limit [get_bd_nets VIOs/traffic_gen_params_probe_out1]
    set_property name pkt_len_max [get_bd_nets VIOs/traffic_gen_params_probe_out4]
    set_property name pkt_len_min [get_bd_nets VIOs/traffic_gen_params_probe_out3]
    set_property name rifl_rst [get_bd_nets VIOs/rifl_rst_probe_out0]
    set_property name start [get_bd_nets VIOs/traffic_gen_params_probe_out0]
    set_property name traffic_mon_clear [get_bd_nets VIOs/traffic_mon_clear_probe_out0]
    set_property name traffic_rst [get_bd_nets VIOs/traffic_rst_probe_out0]
    
    if {$err_inj != 0} {
        set ber_code [ addip vio ber_code ]
        set_property -dict [list \
            CONFIG.C_PROBE_OUT0_WIDTH {64} \
            CONFIG.C_EN_PROBE_IN_ACTIVITY {0} \
            CONFIG.C_NUM_PROBE_IN {0} \
        ] $ber_code
        move_bd_cells [get_bd_cells VIOs] [get_bd_cells ber_code]
        connect_bd_net [get_bd_pins RIFL_0/usr_clk] [get_bd_pins /VIOs/ber_code/clk]
        connect_bd_net [get_bd_pins /VIOs/ber_code/probe_out0] [get_bd_pins RIFL_0/ber_code]
        set_property name ber_code [get_bd_pins VIOs/probe_out0]
        set_property name ber_code [get_bd_nets VIOs_probe_out0]
        set_property name ber_code [get_bd_nets VIOs/ber_code_probe_out0]
    }
    
    set_property USED_IN {synthesis implementation} [get_files ${project_dir}/${project_name}.srcs/sources_1/bd/${bd_name}/${bd_name}.bd]
    make_wrapper -files [get_files ${project_dir}/${project_name}.srcs/sources_1/bd/${bd_name}/${bd_name}.bd] -top
    add_files -fileset sources_1 -norecurse ${project_dir}/${project_name}.srcs/sources_1/bd/${bd_name}/hdl/${bd_name}_wrapper.v
    set_property USED_IN {synthesis implementation} [get_files ${project_dir}/${project_name}.srcs/sources_1/bd/${bd_name}/hdl/${bd_name}_wrapper.v]

    regenerate_bd_layout
    set_property top ${bd_name}_wrapper [get_filesets sources_1]
}