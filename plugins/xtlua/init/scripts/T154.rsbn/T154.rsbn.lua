function tu154_channel_change_DRhandler() end
function tu154_channel_DRhandler() end
function deferred_dataref(name,type,notifier)
	print("Deffered dataref: "..name)
	dref=XLuaCreateDataRef(name, type,"yes",notifier)
	return wrap_dref_any(dref,type) 
end


simDR_rsbn_azi					= find_dataref("tu154/custom/rsbn/azimuth")
simDR_passed                    = find_dataref("sim/operation/misc/frame_rate_period")
simDR_time                    = find_dataref("sim/time/zulu_time_sec")
simDR_rsbn_10					= find_dataref("tu154/custom/buttons/ovhd/rsbn_ch_ten")
simDR_rsbn_1					= find_dataref("tu154/custom/buttons/ovhd/rsbn_ch_one")
simDR_real_dist					= find_dataref("tu154/custom/rsbn/distance")
simDR_rsbn_power					= find_dataref("tu154/custom/radio/rsbn_cc")
simDR_control_azim = find_dataref("tu154/custom/buttons/ovhd/rsbn_control_azimuth")
simDR_control_dist = find_dataref("tu154/custom/buttons/ovhd/rsbn_control_distance")
tu154_real_azimuth = deferred_dataref("tu154/custom/rsbn/real_azimuth", "number")
no_signal = deferred_dataref("tu154/custom/rsbn/no_signal", "number")
rsbn_channel = deferred_dataref("tu154/custom/rsbn/channel", "number",tu154_channel_DRhandler)
channel_change = deferred_dataref("tu154/custom/rsbn/channel_change", "number",tu154_channel_change_DRhandler)
local tu154_channel_false = 0
local rsbn_channel_timer = 0
local rsbn_current_dist = 0
local rsbn_current_azi = 0
local rsbn_change_time = 0
local rsbn_started = 0




function rsbn_l_CMDhandler(phase, duration)
    if phase == 0 then
            if rsbn_channel > 0 then
            rsbn_channel = rsbn_channel -1
            channel_change = -1
            end
     elseif phase == 1 then
        if duration > 0.3 then
            if rsbn_channel > 0 then
            rsbn_channel = rsbn_channel -1
            end
            if duration > 2 then
            if rsbn_channel > 0 then
                rsbn_channel = rsbn_channel -5
            end
            end
        end
    end   
    if phase == 2 then
        channel_change = 0
    end
end

function rsbn_r_CMDhandler(phase, duration)
    if phase == 0 then
            rsbn_channel = rsbn_channel +1
            channel_change = 1
     elseif phase == 1 then
        if duration > 0.3 then
            rsbn_channel = rsbn_channel +1
        end
        if duration > 2 then
            rsbn_channel = rsbn_channel +5
        end
    end  
    if phase == 2 then
        channel_change = 0
    end  	
end


rsbn_cmnd_l	= create_command("rsbn/channel_l", "RSBN CH L", rsbn_l_CMDhandler)
rsbn_cmnd_r	= create_command("rsbn/channel_r", "RSBN CH R", rsbn_r_CMDhandler)






function tu154_rsbn()
    
    
 
        
        
    if simDR_rsbn_azi < 0 then
        tu154_real_azimuth = 360 + simDR_rsbn_azi
    else
        tu154_real_azimuth = simDR_rsbn_azi
    end
    simDR_rsbn_10 = math.floor(rsbn_channel / 10)
    simDR_rsbn_1 = rsbn_channel - (simDR_rsbn_10 * 10)
    
end


function rsbn_reset()

    if rsbn_change_time < 1 and no_signal < 1 and rsbn_channel > 0 then
        rsbn_change_time = simDR_time
        rsbn_current_dist = simDR_real_dist
        rsbn_current_azi = tu154_real_azimuth
    end

    if (simDR_time - rsbn_change_time) > 20 then
            if (rsbn_current_dist == simDR_real_dist) and (rsbn_current_azi == tu154_real_azimuth) then
                no_signal = 1
            end
        rsbn_change_time = 0
    end
    
    if no_signal > 0 and rsbn_channel > 0 then
      if (rsbn_current_dist - simDR_real_dist) > 0 then
        no_signal = 0
      elseif (rsbn_current_dist - simDR_real_dist) < 0 then
        no_signal = 0
      end
      if (rsbn_current_azi - tu154_real_azimuth) > 0 then
        no_signal = 0
      elseif (rsbn_current_azi - tu154_real_azimuth) < 0 then
        no_signal = 0
      end
    end

    if rsbn_channel == 0 and simDR_control_azim < 1 and simDR_control_dist < 1 then
        no_signal = 1
    elseif rsbn_channel == 0 then
        no_signal = 0
    end
    
end



function after_physics()
tu154_rsbn()
rsbn_reset()
end