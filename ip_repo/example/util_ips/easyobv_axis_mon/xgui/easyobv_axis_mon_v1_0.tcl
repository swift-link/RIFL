
# Loading additional proc with user specified bodies to compute parameter values.
source [file join [file dirname [file dirname [info script]]] gui/easyobv_axis_mon_v1_0.gtcl]

# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0" -display_name {AXI4-Stream Configuration}]
  set_property tooltip {AXI4-Stream Configuration} ${Page_0}
  set DWIDTH [ipgui::add_param $IPINST -name "DWIDTH" -parent ${Page_0}]
  set_property tooltip {AXI4-Stream Data Width} ${DWIDTH}
  ipgui::add_param $IPINST -name "HAS_READY" -parent ${Page_0} -widget comboBox
  ipgui::add_param $IPINST -name "HAS_KEEP" -parent ${Page_0} -widget comboBox
  ipgui::add_param $IPINST -name "HAS_LAST" -parent ${Page_0} -widget comboBox
  ipgui::add_param $IPINST -name "HAS_STRB" -parent ${Page_0} -widget comboBox
  ipgui::add_param $IPINST -name "DEST_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "USER_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "ID_WIDTH" -parent ${Page_0}

  #Adding Page
  set Traffic_Monitor_Configuration [ipgui::add_page $IPINST -name "Traffic Monitor Configuration"]
  set_property tooltip {Traffic Monitor Configuration} ${Traffic_Monitor_Configuration}
  ipgui::add_param $IPINST -name "EN_AXIL" -parent ${Traffic_Monitor_Configuration} -widget comboBox
  ipgui::add_param $IPINST -name "LOOPBACK" -parent ${Traffic_Monitor_Configuration} -widget comboBox
  ipgui::add_param $IPINST -name "CMP_FIFO_DEPTH" -parent ${Traffic_Monitor_Configuration}


}

proc update_PARAM_VALUE.CMP_FIFO_DEPTH { PARAM_VALUE.CMP_FIFO_DEPTH PARAM_VALUE.LOOPBACK } {
	# Procedure called to update CMP_FIFO_DEPTH when any of the dependent parameters in the arguments change
	
	set CMP_FIFO_DEPTH ${PARAM_VALUE.CMP_FIFO_DEPTH}
	set LOOPBACK ${PARAM_VALUE.LOOPBACK}
	set values(LOOPBACK) [get_property value $LOOPBACK]
	if { [gen_USERPARAMETER_CMP_FIFO_DEPTH_ENABLEMENT $values(LOOPBACK)] } {
		set_property enabled true $CMP_FIFO_DEPTH
	} else {
		set_property enabled false $CMP_FIFO_DEPTH
	}
}

proc validate_PARAM_VALUE.CMP_FIFO_DEPTH { PARAM_VALUE.CMP_FIFO_DEPTH } {
	# Procedure called to validate CMP_FIFO_DEPTH
	return true
}

proc update_PARAM_VALUE.CLK_FREQ { PARAM_VALUE.CLK_FREQ } {
	# Procedure called to update CLK_FREQ when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.CLK_FREQ { PARAM_VALUE.CLK_FREQ } {
	# Procedure called to validate CLK_FREQ
	return true
}

proc update_PARAM_VALUE.DEST_WIDTH { PARAM_VALUE.DEST_WIDTH } {
	# Procedure called to update DEST_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DEST_WIDTH { PARAM_VALUE.DEST_WIDTH } {
	# Procedure called to validate DEST_WIDTH
	return true
}

proc update_PARAM_VALUE.DWIDTH { PARAM_VALUE.DWIDTH } {
	# Procedure called to update DWIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DWIDTH { PARAM_VALUE.DWIDTH } {
	# Procedure called to validate DWIDTH
	return true
}

proc update_PARAM_VALUE.EN_AXIL { PARAM_VALUE.EN_AXIL } {
	# Procedure called to update EN_AXIL when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.EN_AXIL { PARAM_VALUE.EN_AXIL } {
	# Procedure called to validate EN_AXIL
	return true
}

proc update_PARAM_VALUE.HAS_KEEP { PARAM_VALUE.HAS_KEEP } {
	# Procedure called to update HAS_KEEP when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.HAS_KEEP { PARAM_VALUE.HAS_KEEP } {
	# Procedure called to validate HAS_KEEP
	return true
}

proc update_PARAM_VALUE.HAS_LAST { PARAM_VALUE.HAS_LAST } {
	# Procedure called to update HAS_LAST when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.HAS_LAST { PARAM_VALUE.HAS_LAST } {
	# Procedure called to validate HAS_LAST
	return true
}

proc update_PARAM_VALUE.HAS_READY { PARAM_VALUE.HAS_READY } {
	# Procedure called to update HAS_READY when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.HAS_READY { PARAM_VALUE.HAS_READY } {
	# Procedure called to validate HAS_READY
	return true
}

proc update_PARAM_VALUE.HAS_STRB { PARAM_VALUE.HAS_STRB } {
	# Procedure called to update HAS_STRB when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.HAS_STRB { PARAM_VALUE.HAS_STRB } {
	# Procedure called to validate HAS_STRB
	return true
}

proc update_PARAM_VALUE.ID_WIDTH { PARAM_VALUE.ID_WIDTH } {
	# Procedure called to update ID_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ID_WIDTH { PARAM_VALUE.ID_WIDTH } {
	# Procedure called to validate ID_WIDTH
	return true
}

proc update_PARAM_VALUE.LOOPBACK { PARAM_VALUE.LOOPBACK } {
	# Procedure called to update LOOPBACK when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.LOOPBACK { PARAM_VALUE.LOOPBACK } {
	# Procedure called to validate LOOPBACK
	return true
}

proc update_PARAM_VALUE.USER_WIDTH { PARAM_VALUE.USER_WIDTH } {
	# Procedure called to update USER_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.USER_WIDTH { PARAM_VALUE.USER_WIDTH } {
	# Procedure called to validate USER_WIDTH
	return true
}


proc update_MODELPARAM_VALUE.EN_AXIL { MODELPARAM_VALUE.EN_AXIL PARAM_VALUE.EN_AXIL } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.EN_AXIL}] ${MODELPARAM_VALUE.EN_AXIL}
}

proc update_MODELPARAM_VALUE.LOOPBACK { MODELPARAM_VALUE.LOOPBACK PARAM_VALUE.LOOPBACK } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.LOOPBACK}] ${MODELPARAM_VALUE.LOOPBACK}
}

proc update_MODELPARAM_VALUE.DWIDTH { MODELPARAM_VALUE.DWIDTH PARAM_VALUE.DWIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DWIDTH}] ${MODELPARAM_VALUE.DWIDTH}
}

proc update_MODELPARAM_VALUE.HAS_READY { MODELPARAM_VALUE.HAS_READY PARAM_VALUE.HAS_READY } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.HAS_READY}] ${MODELPARAM_VALUE.HAS_READY}
}

proc update_MODELPARAM_VALUE.HAS_KEEP { MODELPARAM_VALUE.HAS_KEEP PARAM_VALUE.HAS_KEEP } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.HAS_KEEP}] ${MODELPARAM_VALUE.HAS_KEEP}
}

proc update_MODELPARAM_VALUE.HAS_LAST { MODELPARAM_VALUE.HAS_LAST PARAM_VALUE.HAS_LAST } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.HAS_LAST}] ${MODELPARAM_VALUE.HAS_LAST}
}

proc update_MODELPARAM_VALUE.HAS_STRB { MODELPARAM_VALUE.HAS_STRB PARAM_VALUE.HAS_STRB } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.HAS_STRB}] ${MODELPARAM_VALUE.HAS_STRB}
}

proc update_MODELPARAM_VALUE.DEST_WIDTH { MODELPARAM_VALUE.DEST_WIDTH PARAM_VALUE.DEST_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DEST_WIDTH}] ${MODELPARAM_VALUE.DEST_WIDTH}
}

proc update_MODELPARAM_VALUE.USER_WIDTH { MODELPARAM_VALUE.USER_WIDTH PARAM_VALUE.USER_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.USER_WIDTH}] ${MODELPARAM_VALUE.USER_WIDTH}
}

proc update_MODELPARAM_VALUE.ID_WIDTH { MODELPARAM_VALUE.ID_WIDTH PARAM_VALUE.ID_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ID_WIDTH}] ${MODELPARAM_VALUE.ID_WIDTH}
}

proc update_MODELPARAM_VALUE.CMP_FIFO_DEPTH { MODELPARAM_VALUE.CMP_FIFO_DEPTH PARAM_VALUE.CMP_FIFO_DEPTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.CMP_FIFO_DEPTH}] ${MODELPARAM_VALUE.CMP_FIFO_DEPTH}
}

proc update_MODELPARAM_VALUE.CLK_FREQ { MODELPARAM_VALUE.CLK_FREQ PARAM_VALUE.CLK_FREQ } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.CLK_FREQ}] ${MODELPARAM_VALUE.CLK_FREQ}
}

