defineProperty("cl", globalPropertyf("sim/aircraft/controls/acf_flap_cl"))
defineProperty("cd", globalPropertyf("sim/aircraft/controls/acf_flap_cd"))
defineProperty("cm", globalPropertyf("sim/aircraft/controls/acf_flap_cm"))

defineProperty("cl2", globalPropertyf("sim/aircraft/controls/acf_flap2_cl"))
defineProperty("cd2", globalPropertyf("sim/aircraft/controls/acf_flap2_cd"))
defineProperty("cm2", globalPropertyf("sim/aircraft/controls/acf_flap2_cm"))

defineProperty("flap_inn_L", globalPropertyf("sim/flightmodel/controls/wing1l_fla1def"))
defineProperty("flap_inn_R", globalPropertyf("sim/flightmodel/controls/wing1r_fla1def"))
defineProperty("flap_mid_L", globalPropertyf("sim/flightmodel/controls/wing2l_fla2def"))
defineProperty("flap_mid_R", globalPropertyf("sim/flightmodel/controls/wing2r_fla2def"))


-- Tu-154M v4.2.6: same coupled correction as flap_aero.lua.
-- This temporary variant intentionally writes exactly the same six outputs,
-- so the two components cannot fight each other when both are loaded.
local FLAP1_CL = 1.029
local FLAP1_CD = 0.064

local FLAP2_CL = 1.165
local FLAP2_CD = 0.068

local flap1_cm_tbl = {
	{-10, -0.4480},
	{0,   -0.4480},
	{15,  -0.4480},
	{28,  -0.3490},
	{36,  -0.4102},
	{45,  -0.3762},
	{100, -0.3762}
}

local flap2_cm_tbl = {
	{-10, -0.5071},
	{0,   -0.5071},
	{13,  -0.5071},
	{25,  -0.3950},
	{32,  -0.4642},
	{40,  -0.4257},
	{100, -0.4257}
}


function update()
	local flap_inn = 0.5 * (get(flap_inn_L) + get(flap_inn_R))
	local flap_mid = 0.5 * (get(flap_mid_L) + get(flap_mid_R))

	set(cl, FLAP1_CL)
	set(cd, FLAP1_CD)
	set(cm, interpolate(flap1_cm_tbl, flap_inn))

	set(cl2, FLAP2_CL)
	set(cd2, FLAP2_CD)
	set(cm2, interpolate(flap2_cm_tbl, flap_mid))
end
