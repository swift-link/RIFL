# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "DWIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "EN_AXIL" -parent ${Page_0}
  ipgui::add_param $IPINST -name "HAS_KEEP" -parent ${Page_0}
  ipgui::add_param $IPINST -name "HAS_LAST" -parent ${Page_0}
  ipgui::add_param $IPINST -name "HAS_READY" -parent ${Page_0}
  ipgui::add_param $IPINST -name "SEED" -parent ${Page_0}


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

proc update_PARAM_VALUE.SEED { PARAM_VALUE.SEED } {
	# Procedure called to update SEED when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.SEED { PARAM_VALUE.SEED } {
	# Procedure called to validate SEED
	return true
}


proc update_MODELPARAM_VALUE.EN_AXIL { MODELPARAM_VALUE.EN_AXIL PARAM_VALUE.EN_AXIL } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.EN_AXIL}] ${MODELPARAM_VALUE.EN_AXIL}
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

proc update_MODELPARAM_VALUE.SEED { MODELPARAM_VALUE.SEED PARAM_VALUE.SEED } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.SEED}] ${MODELPARAM_VALUE.SEED}
}

