# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "CRC_POLY" -parent ${Page_0}
  ipgui::add_param $IPINST -name "CRC_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "DWIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "FRAME_ID_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "FRAME_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "N_CHANNEL" -parent ${Page_0}
  ipgui::add_param $IPINST -name "SCRAMBLER_N1" -parent ${Page_0}
  ipgui::add_param $IPINST -name "SCRAMBLER_N2" -parent ${Page_0}


}

proc update_PARAM_VALUE.CRC_POLY { PARAM_VALUE.CRC_POLY } {
	# Procedure called to update CRC_POLY when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.CRC_POLY { PARAM_VALUE.CRC_POLY } {
	# Procedure called to validate CRC_POLY
	return true
}

proc update_PARAM_VALUE.CRC_WIDTH { PARAM_VALUE.CRC_WIDTH } {
	# Procedure called to update CRC_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.CRC_WIDTH { PARAM_VALUE.CRC_WIDTH } {
	# Procedure called to validate CRC_WIDTH
	return true
}

proc update_PARAM_VALUE.DWIDTH { PARAM_VALUE.DWIDTH } {
	# Procedure called to update DWIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DWIDTH { PARAM_VALUE.DWIDTH } {
	# Procedure called to validate DWIDTH
	return true
}

proc update_PARAM_VALUE.FRAME_ID_WIDTH { PARAM_VALUE.FRAME_ID_WIDTH } {
	# Procedure called to update FRAME_ID_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.FRAME_ID_WIDTH { PARAM_VALUE.FRAME_ID_WIDTH } {
	# Procedure called to validate FRAME_ID_WIDTH
	return true
}

proc update_PARAM_VALUE.FRAME_WIDTH { PARAM_VALUE.FRAME_WIDTH } {
	# Procedure called to update FRAME_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.FRAME_WIDTH { PARAM_VALUE.FRAME_WIDTH } {
	# Procedure called to validate FRAME_WIDTH
	return true
}

proc update_PARAM_VALUE.N_CHANNEL { PARAM_VALUE.N_CHANNEL } {
	# Procedure called to update N_CHANNEL when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.N_CHANNEL { PARAM_VALUE.N_CHANNEL } {
	# Procedure called to validate N_CHANNEL
	return true
}

proc update_PARAM_VALUE.SCRAMBLER_N1 { PARAM_VALUE.SCRAMBLER_N1 } {
	# Procedure called to update SCRAMBLER_N1 when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.SCRAMBLER_N1 { PARAM_VALUE.SCRAMBLER_N1 } {
	# Procedure called to validate SCRAMBLER_N1
	return true
}

proc update_PARAM_VALUE.SCRAMBLER_N2 { PARAM_VALUE.SCRAMBLER_N2 } {
	# Procedure called to update SCRAMBLER_N2 when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.SCRAMBLER_N2 { PARAM_VALUE.SCRAMBLER_N2 } {
	# Procedure called to validate SCRAMBLER_N2
	return true
}


proc update_MODELPARAM_VALUE.N_CHANNEL { MODELPARAM_VALUE.N_CHANNEL PARAM_VALUE.N_CHANNEL } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.N_CHANNEL}] ${MODELPARAM_VALUE.N_CHANNEL}
}

proc update_MODELPARAM_VALUE.DWIDTH { MODELPARAM_VALUE.DWIDTH PARAM_VALUE.DWIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DWIDTH}] ${MODELPARAM_VALUE.DWIDTH}
}

proc update_MODELPARAM_VALUE.FRAME_WIDTH { MODELPARAM_VALUE.FRAME_WIDTH PARAM_VALUE.FRAME_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.FRAME_WIDTH}] ${MODELPARAM_VALUE.FRAME_WIDTH}
}

proc update_MODELPARAM_VALUE.CRC_WIDTH { MODELPARAM_VALUE.CRC_WIDTH PARAM_VALUE.CRC_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.CRC_WIDTH}] ${MODELPARAM_VALUE.CRC_WIDTH}
}

proc update_MODELPARAM_VALUE.CRC_POLY { MODELPARAM_VALUE.CRC_POLY PARAM_VALUE.CRC_POLY } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.CRC_POLY}] ${MODELPARAM_VALUE.CRC_POLY}
}

proc update_MODELPARAM_VALUE.FRAME_ID_WIDTH { MODELPARAM_VALUE.FRAME_ID_WIDTH PARAM_VALUE.FRAME_ID_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.FRAME_ID_WIDTH}] ${MODELPARAM_VALUE.FRAME_ID_WIDTH}
}

proc update_MODELPARAM_VALUE.SCRAMBLER_N1 { MODELPARAM_VALUE.SCRAMBLER_N1 PARAM_VALUE.SCRAMBLER_N1 } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.SCRAMBLER_N1}] ${MODELPARAM_VALUE.SCRAMBLER_N1}
}

proc update_MODELPARAM_VALUE.SCRAMBLER_N2 { MODELPARAM_VALUE.SCRAMBLER_N2 PARAM_VALUE.SCRAMBLER_N2 } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.SCRAMBLER_N2}] ${MODELPARAM_VALUE.SCRAMBLER_N2}
}

