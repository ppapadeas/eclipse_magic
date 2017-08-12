-- Eclipse Magic
-- Programmed exposure sequence for a solar eclipse


-- Eclipse Magic
--
-- Version 1.7.0
--
-- Copyright 2017 by Brian Greenberg, grnbrg@grnbrg.org.
-- Distributed under the GNU General Public License.
--
--
-- ***************************************************************************************************
-- ***************************************************************************************************
--
-- **NOTE** At the current time, the "camera.burst()" functionality requires the "lua_fix"
-- beta build of Magic Lantern which can be found at https://builds.magiclantern.fm/experiments.html.
-- Hopefully this function will be merged into the mainline soon.  
--
-- ***************************************************************************************************
-- ***************************************************************************************************
--
--
-- Read through the comments at the top of the script, and modify the contact points to suit
-- your location, and the exposure settings to suit your camera.  Copy the script to 
-- the ML/SCRIPTS directory on your camera's media, and run it from the menu.
--
-- If you have issues, (and you aren't running with the test flag set) you should be able to 
-- reboot your camera, and it will pick up where it left off.  Exposure events are tied to 
-- particular times, not a sequence that needs to start at a specific time.  This is useful if 
-- (for example) you need to change batteries in mid-eclipse.
--
-- See http://xjubier.free.fr/en/site_pages/SolarEclipseExposure.html for suggestions for
-- exposure values.
--
-- The previously released 1.5.0 version of this script can be found at:
--
--		http://www.grnbrg.org/eclipse_magic-1.5.0.lua
--
--
-- If this script is useful, feel free to send a PayPal donation to Eclipse-Magic@grnbrg.org,
-- or a Bitcoin donation to 1grnbrg3Ea4t6bxHvQKRvorbBeLNDXv2N.
--
-- ***************************************************************************************************
-- ***************************************************************************************************
-- ***************************************************************************************************

require ("logger")

-- Variable definitons that have to go here.  Ignore them.
c1 = {}
c2 = {}
c3 = {}
c4 = {}


--
--  If you are testing, set this to 1, and the shutter won't be used.
--  Set it to 0 for the real event.
--
--  This changes how the contact times are interpreted!  If TestBeepNoShutter
--  is set to 1, then the contact times are time elapsed after the script is started.
--  it is set to 0, then the contact times reference the realtime clock of the camera.
--
--  For example:
--
--  If C1 is set to 10:30:00 (ie: 10:30:00 am), and the current time on the camera is set
--  to 08:00:00 (ie: 8:00:00 am), then
--
--  If TestBeepNoShutter is set to 1, then the script will start demonstrating eclipse exposures
--  in ten hours and thirty minutes.
--
--  If TestBeepNoShutter is set to 0, the script will start taking actual exposures in two 
--  hours and thirty minutes (ie: at 10:30:00).
--
--  The intent was that (for testing) you could set C1 to 00:00:30 or so, and the other contacts to
--  similar offsets, and not worry about messing with the clock on the camera.  (This may not have
--  been the best choice on my part!  :) )
TestBeepNoShutter = 0 

--
-- Send log information (essentially everything shown on the screen) to a file (ECLIPSE.LOG) at the
-- top directory of the camera card.  Useful for testing.
--
LogToFile = 1
LoggingFile = nil

--
-- Set the 4 contact times here.  Time zone is irrelevant, as long as your camera and these
-- times are the same.  Make sure the times are correct for your location, and that your camera
-- is accurately set to GPS time.
--
if ( TestBeepNoShutter == 1 )
then
	-- Esterbrook: 10:23:32 11:44:37 11:46:53 13:11:42
	c1.hr = 10; c1.min = 23; c1.sec = 32
	c2.hr = 11; c2.min = 44; c2.sec = 37;
	c3.hr = 11; c3.min = 46; c3.sec = 53;
	c4.hr = 13; c4.min = 11; c4.sec = 42;
else
	-- Testing:
	c1.hr = 0; c1.min =  1; c1.sec = 00;
	c2.hr = 0; c2.min =  4; c2.sec = 00;
	c3.hr = 0; c3.min =  6; c3.sec = 20;
	c4.hr = 0; c4.min =  9; c4.sec = 00;
end


-- Set an aperture value.  The script assumes that the aperture stays constant throughout the
-- eclipe.  The camera will (try to) set this aperture (f-number) at the beginning of the script.
-- Useful, as it is easy to forget this, if you are shooting with a regular camera lens.
-- If the script and camera are being used with a fixed aperture lens (or telescope), then
-- set the "SetAperture" to 0.
SetAperture = 1
Aperture = 5

--
-- If you shoot with LiveView active, you will reduce the amount of mirror slap, giving
-- less vibration.  But.  Some cameras (Such as the 5DmkII.) have a limited range of shutter 
-- speed when LV and Movie mode are enabled.  This reduces the available speeds from 30 seconds 
-- through 1/8000th of a second to 1/30th to 1/4000th of a second.  Exceeding that range while 
-- LV and Movie mode are enabled will crash the script.
--
-- Setting this variable to 1 will, before taking any images, check if LV is running, and if it
-- is, will tell you to turn it off.  If you have disabled movie mode (A menu option on some cameras,
-- like the 5DmkII, and a hardware switch on others) you should set this to 0.
--
-- Test your camera.  If the exposure speeds you want crash the script in LV, check how to disable
-- movie mode.
--
WarnLiveView = 0


--
-- If you're shooting in Live View (to reduce mirror slap) you'll probably still want to check
-- your focus occasionally.  However, the status display of the script pretty much fills the screen,
-- making this difficult.  Enabling HideConsole will display the console for the indicated number
-- of seconds both before and after the next shutter event, and turn the console off between.  This
-- also gives you an idea of how much time you have before the next shutter event -- if the console
-- is hidden, you have at least ConsoleShowDelay seconds to mess around.  If you turn this off, the
-- script will start with the console displayed, and you will have to manage it through the Magic
-- Lantern menu.  If you turn it off, it stays off until you turn it on again.
--
HideConsole = 1
ConsoleShowDelay = 30


--
-- Even if you shoot with Live View with Silent Mode 1 (which forces the mirror to be 
-- locked up, and eliminates the vibration from the shutter opening) there will be slight 
-- vibrations introduced as the shutter closes.  According to Jerry Lodriguss at
-- http://www.astropix.com/wp/2017/07/17/mirror-slap-and-shutter-shock/ these vibrations
-- are most prominent between 0.125s and 2s, and can be somewhat mitigated by a slight 
-- delay before exposure, to allow the vibration to dampen a bit.
--
-- Enabling this option lets you set a range of shutter speeds to delay before, and 
-- how long (in milliseconds) to pause.
--
DoShutterShockDelay = 1
SlowestDelayedShutter = 2
FastestDelayedShutter = (1/8)
ShutterShockDelayMS = 300		-- Value is in milliseconds!


--
-- Partial phase settings. 
--
PartialISO = 100
PartialShutterSpeed = (1/2000)
PartialMarginTime = 15			-- Number of seconds after C1 or C3 and before C2 or C4 to start exposures
PartialExposureCount = 2		-- Number of partial phase exposures before and after totality
PartialDoBkt = 1				-- Do you want to do exposure bracketing?  1 - yes, 0 - no
PartialBktStep = 1				-- Number of f-stops in each step.  Can 0.333333, 1, 2, etc
PartialBktCount = 1				-- How many brackets on each side of the neutral exposure?


--
-- Optionally enable high speed burst mode
--
-- As originally written, the script used the camera.burst() function, to take a burst of
-- images as quickly as possible, as though the shutter button was held down.  This had two issues:
-- The first being that the buffer in the camera fills after around 2-3 seconds when shooting
-- RAW, and then slows drastically, and the second being that once called, the camera will take
-- exposures until the requested number of images are captured, and if the buffer fills, this may
-- take considerably longer than expected.
--
-- I have (by default) replaced this function with a burst function that tries to take a given number 
-- of images over a set period of time, each with a single shutter release call.  This is much slower 
-- (two or three frames per second, tops) but therefor fills the buffer more slowly, and allows the script
-- to abort the burst (and take fewer than the requested number of images) if the capture runs past the 
-- specified time limit.
--
-- If you prefer the old high speed burst call, set this variable to 1.
--
UseBurst = 0

--
-- Do a fast burst of exposures at C2 and C3, to try to get Baily's beads and chromosphere.
-- You will need to know how many exposures your camera will buffer, and how long it takes the
-- buffer to fill.  At "StartOffset" seconds before C2 or C3, the camera will take "BurstCount"
-- exposures, as fast as it can.  You should adjust C23StartOffset so that burst of image straddles 
-- the contact time.  Note that, between the setting of the camera clock and the jitter in this
-- script, there will be some error in the timing.  +/- half a second or more is possible.
--
C23BurstCount = 14			-- Note that most Canon DSLRs can't take more than 13-14 RAW images
								-- in a burst before the buffer is full, and they slow to ~1 image/second.
C2BurstStartOffset = 3
C2BurstTime = 8
C3BurstStartOffset = 2
C3BurstTime = 8
C23BurstISO = 100
C23BurstShutterSpeed = (1/8000)


--
-- Do a fast burst of exposures before C2 and after C3, to try to get the diamond ring.
--
-- Be careful setting the RingStartOffset, Count and Time.  If the burst of images for the
-- pre-C2 rings runs longer than expected, it can cause the pre-C2 Baily's Beads exposures to
-- be skipped.
--
-- The post-C3 Rings exposures (if enabled) will run immediately after the post-C3 Baily's Beads
-- exposures.
--
DoRing = 1		-- Are we going to try for a burst for the diamond ring?
RingStartOffset = C2BurstStartOffset + 5  -- How long before C2/after C3 to start?  Be careful that
												-- this does not interfere with the Baily's burst!
RingBurstCount = 8  -- How many images?
RingBurstTime = 4	-- If we're doing a manual burst, how long should it last?
RingBurstISO = 100
RingBurstShutterSpeed = 1/30


--
-- During the time between C2 and C3, the script will run back and forth between the 
-- "MinShutterSpeed" and "MaxShutterSpeed" as quickly as possible, with an extra 2 long exposures
-- at midpoint.  "ExpStep" is the size of the f-stop variation, and can be set to 0.333333, 1, 2, etc.
-- Min, Max and PrefISO:  Totality exposures will run (where possible) at PrefISO.  However, there
-- will also be exposures at MinShutterSpeed from MinISO to PrefISO, and MaxShutterSpeed from
-- PrefISO to MaxISO.
--
TotalityMinISO = 100 
TotalityMaxISO = 800
TotalityPrefISO = 100
TotalityMinShutterSpeed = (1/8000) -- (MinShutterSpeed is the *fastest* speed to use.)
TotalityMaxShutterSpeed = 1/4 -- 1 sec (MaxShutterSpeed is the *slowest*, longest speed used.)
TotalityExpStep = 1

--
-- One of the more difficult exposures to capture is earthshine -- the surface of the moon,
-- illuminated by light reflected from the earth.
--
-- The best time to do this is at the point of maximum eclipse, where the sun is centred behind
-- the moon, as much as possible.  Exposures here are kind of guesswork, and I have actually turned this
-- off by default.
--
DoMaxExposures = 1		-- Number of (possibly bracketed) exposures to take at max-eclipse.
MaxOffset = (7/2) 		-- How long before max eclipse to start these exposures.  You'll have to test
						-- or use math to determine this value.  (Value is in seconds.)
NumMaxExposures = 1
DoMaxBrackets = 1		-- Brackets?
NumMaxBrackets = 2
MaxBracketStep = 1
MaxISO = 3200
MaxShutterSpeed = 1.0

---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
--
--                                       HERE THERE BE DRAGONS
--
---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------

--
-- Times are easiest to deal with in seconds.  This would be painful if they crossed over midnight,
-- but late-night solar eclipses are rare.
--
c1_sec = c1.hr * 3600 + c1.min * 60 + c1.sec 
c2_sec = c2.hr * 3600 + c2.min * 60 + c2.sec 
c3_sec = c3.hr * 3600 + c3.min * 60 + c3.sec 
c4_sec = c4.hr * 3600 + c4.min * 60 + c4.sec 
max_sec = math.floor(c2_sec + ((c3_sec - c2_sec) / 2))

MaxOffset = MaxOffset * DoMaxExposures -- This is ugly, and shouldn't be here.

tick_offset = 0
TestStartTime = 0


--
-- Log to stdout and optionally to a file
--
function log (s, ...)
	local str = string.format (s, ...)
	str = str .. "\n"
	if (LogToFile == 0 or LoggingFile == nil)
	then
		io.write (str)
	else
		LoggingFile:write (str)
	end
	return
end

--
-- Open log file
--
function log_start ()
	if (LogToFile ~= 0)
	then
		local cur_time = dryos.date
		-- Opening logger with long filename fails. Works with short name.
		--local filename = string.format("eclipse_%04d%02d%02d_%02d%02d%02d.log", cur_time.year, cur_time.month, cur_time.day, cur_time.hour, cur_time.min, cur_time.sec)
		local filename = string.format("eclipse.log")
		print (string.format ("Open log file %s", filename))
		LoggingFile = logger (filename)
	else
		print (string.format ("Logging not configured"))
	end
end

--
-- Close log file
--
function log_stop ()
	if (LogToFile ~= 0)
	then
		print (string.format ("Close log file"))
		LoggingFile:close ()
	end
end

--
-- Get the current time (in seconds) from the camera's clock.
--
function get_cur_secs ()

	local cur_time = dryos.date
	local cur_secs = (cur_time.hour * 3600 + cur_time.min * 60 + cur_time.sec)
	
	if ( TestBeepNoShutter == 1 )
	then
	
		cur_secs = (cur_secs - TestStartTime)		-- If we're testing, start the clock at 
													-- now, not actual time.
		
	end
	
	return cur_secs

end


--
-- Take a time variable expressed in seconds (which is what all times are 
-- stored as) and convert it back to HH:MM:SS
--
function pretty_time (time_secs)

	local text_time = ""
	local hrs = 0
	local mins = 0
	local secs = 0
	
	hrs =  math.floor(time_secs / 3600)
    mins = math.floor((time_secs - (hrs * 3600)) / 60)
	secs = (time_secs - (hrs*3600) - (mins * 60))
	
	text_time = string.format("%02d:%02d:%02d", hrs, mins, secs)
	
	return text_time

end


--
-- Take a shutter speed expressed in (fractional) seconds and convert it to 1/x.
--
function pretty_shutter (shutter_speed)

	local text_time = ""
	if (shutter_speed >= 1.0)
	then
		text_time = tostring (shutter_speed)
	else
		text_time = string.format ("1/%s", tostring (1/shutter_speed))
	end
	return text_time

end


--
-- Hurry up and wait for the next important time to arrive.
--
-- Leave the console displayed for 60 seconds at the start and end of 
-- a wait.  Turn it off between, so that tracking can be done via live view, etc.
--
function wait_until (done_waiting)

	local counter = get_cur_secs()
	local next_sec = 0
	local show_console = ConsoleShowDelay
	local console_visible = 1
	
	console.show()
	
	log ("Waiting for %s in %d seconds.", pretty_time(done_waiting), done_waiting - counter)
	
	repeat

		task.yield (1000) -- Let the camera do other tasks for a second.
		
		if ((HideConsole == 1) and (show_console > 0))
		then
			
			show_console = show_console -1
			
		elseif ((HideConsole == 1) and (show_console == 0))
		then
		
			console.hide()
			
			show_console = -1
			
			console_visible = 0
			
		end
		
		if ((HideConsole == 1) and ((done_waiting - counter) < 30 ) and (console_visible == 0))
		then
			
			console.show()
			
			console_visible = 1
			
		end
		
		counter = get_cur_secs()
					
	until (counter >= (done_waiting - 1))
			
	if ( counter < done_waiting)	
	then
									-- Loop /should/ exit the second before we are done. But
									--  It's possible that it could exit early in our target
									--  second. If so, we don't want to wait around to 
									--  (done_waiting + 1) to exit.
	
		next_sec = (1000 - ((dryos.ms_clock - tick_offset) % 1000))
	
		msleep (next_sec) -- Hard sleep, don't let anything else have priority.
		
	end
				
end


--
-- Say "CHEESE!".  Set up the camera, and take a picture.  Also deals with any requested
-- bracketing.
--
function take_shot(iso, shutter_speed, dobkt, bktstep, bktcount)

	local bktspeed = 0.0
	
	if ((lv.enabled == true) and (WarnLiveView == 1))
	then
	
		print ("TURN LIVEVIEW OFF (OR DISABLE MOVIE MODE) AND PRESS A BUTTON!!!")
		
		do_beep()
		
		key.wait()
		
	end
	
	camera.iso.value = iso
	
	if (dobkt == 0)
	then	-- Single exposure

		camera.shutter.value = shutter_speed
	
		log ("Click! Time: %s  ISO: %s  shutter: %s", 
			pretty_time(get_cur_secs()), tostring(camera.iso.value), pretty_shutter(camera.shutter.value))
				
		if (DoShutterShockDelay == 1)
		then
			
			if ((shutter_speed >= FastestDelayedShutter) and (shutter_speed 
				<= SlowestDelayedShutter))
			then
				
				task.yield(ShutterShockDelayMS)
					
			end
				
		end
	
		if (TestBeepNoShutter == 0) 
		then
		
			camera.shoot(false)
			task.yield(10) -- Exposures can take time.  Give other stuff a chance to run.
			
		else
		
			beep(1,50)
			task.yield (600 + camera.shutter.ms)
			
		end
		
	else	-- Bracketing exposure
	
		-- Loop through the requested number of exposure brackets.
		for bktnum = bktcount,(-1 * bktcount),-1 do

			bktspeed = shutter_speed * (2.0^(bktnum * bktstep))
			
			camera.shutter.value = bktspeed
			
			log ("Click! Time: %s  ISO: %s  shutter: %s", 
				pretty_time(get_cur_secs()), tostring(camera.iso.value), pretty_shutter(camera.shutter.value))
				
			if (DoShutterShockDelay == 1)
			then
			
				if ((shutter_speed >= FastestDelayedShutter) and (shutter_speed 
					<= SlowestDelayedShutter))
				then
				
					task.yield(ShutterShockDelayMS)
					
				end
				
			end
			
			if (TestBeepNoShutter == 0) then
		
				camera.shoot(false)
				task.yield(10) -- Give other stuff a chance to run
			
			else
		
				beep(1,50)
				task.yield ((600 + camera.shutter.ms))
						
			end

		end
	end
end


--
-- Burst is simpler than single shot, because no brackets.  Set the camera, pull the trigger.
--
-- I have tried replacing this with multiple calls to "camera.shoot()", but it is still considerably
-- slower than "camera.burst()", and can also crash the camera -- nothing permanent, but still
-- not something I want to put out.
--
function take_burst (count, iso, speed)

	camera.shutter.value = speed
	camera.iso.value = iso
	
	if ((lv.enabled == true) and (WarnLiveView == 1))
	then
	
		print ("TURN LIVEVIEW OFF (OR DISABLE MOVIE MODE) AND PRESS A BUTTON!!!")
		
		do_beep()
		
		key.wait()
		
	end
	
	
	log ("Burst! Time: %s  ISO: %s  shutter: %s  count: %d", 
		pretty_time(get_cur_secs()), tostring(camera.iso.value), pretty_shutter(camera.shutter.value), count)
	
	if (TestBeepNoShutter == 0)
	then
	
		camera.burst(count)
		
		task.yield(10)
				
	else
	
		beep(3,50)
		task.yield (4000 + (count * camera.shutter.ms))		
		
	end

end


--
-- Take X pictures over Y seconds
--
-- The camera.burst() function is useful for taking exposures as fast as possible, but is
-- limited by the camera's buffer space.  Depending on the body, burst mode will fill the buffer in 
-- around 2 seconds.  Even the slower cameras will fill the buffer with RAW images in 3-4 seconds, 
-- which is too fast to reliably capture Baily's Beads.  Switching to JPG would help, but must be 
-- done manually.  Not a good option for several reasons.
--
-- This function implements a manually controlled burst mode, which stretches out the exposure speed.
-- This spreads the time where the ~14 exposures that generally fit into the buffer out over a longer
-- time, and also gives the camera time to write to the card.  Instead of 14 frames over 4 seconds,
-- (~4fps) then slowing to maybe 4 frames every 3 seconds (1.5fps), we might be able to sustain 
-- 2fps for 10 seconds.  Actual best framerate and duration will need testing for each camera and
-- memory card.
--
-- Timing is more important than number of exposures, so this function will exit at the end of the
-- specificed timespan, even if the required number of images have not been taken yet.
function take_timed_burst(count, timespan, iso, speed)

	local start_time = dryos.ms_clock -- Millisecond clock time that we're starting.
	local end_time = (dryos.ms_clock + (timespan * 1000)) -- Clock time (in milliseconds) where that we're done.
	local burst_interval = ((timespan * 1000) / count) -- Time between shutters, in milliseconds.
	local time_now = start_time
	local pause_time = 0
	local exposure_num = 0
	local last_time=0
	
	for exposure_num = 1, count, 1
	do
		
		last_time=time_now
		time_now = dryos.ms_clock
						
		take_shot (iso, speed, 0, 0, 0)
				
		if (time_now > end_time)
		then
			
			return -- No time for another image.
			
		else
					
			pause_time = ((start_time + burst_interval * exposure_num) - (dryos.ms_clock + 75))
			
			if (pause_time > 0) -- Pause for the next interval to pass, if we're not running late.
			then
			
				task.yield(pause_time)
				
			end
			
		end
		
	end

end


-- 
-- Simple annoying camera beep.
--
function do_beep()

		beep (5,100)
		
		task.yield (250)
		
		beep (5,100)
		
		task.yield (250)
		
		beep (5,100)

end
--
-- Take the spaced exposures for the C1-C2 and C3-C4 periods.  Take the margin times off either
-- end, split the time into the right intervals, and fire off take_picture()
--
function do_partial (start_phase, stop_phase, which_partial)

	local image_time = 0
	local image_interval = math.floor((stop_phase - start_phase) / (PartialExposureCount))
	local exposure_count = 0
		
	
	-- In a series of (PartialCount + 1) images, totality is either
	--	the first or last image.  This arranges the timing so that there
	--	will be a equidistance set of ((2 x PartialCount) + 1) exposures,
	--	with totality properly centered.
	
	if (which_partial == "Pre")
	then
	
		image_time = start_phase
		
	else
	
		image_time = start_phase + image_interval
		
	end
	
	if ( get_cur_secs() >= stop_phase ) -- Are we past this phase already?
	then
	
		log ("Skip %s Partial. Finished %d seconds ago.", which_partial, (get_cur_secs() - stop_phase))
		return
		
	end
	
	repeat
	
		log ("%s Partial: %d/%d  Interval: %d s  Remaining: %d",
			which_partial, exposure_count, PartialExposureCount, image_interval, stop_phase - get_cur_secs())
		if (get_cur_secs() <= image_time)
		then
		
			wait_until(image_time)
			
			take_shot (PartialISO, PartialShutterSpeed, PartialDoBkt, PartialBktStep, PartialBktCount)
			
		end
		
		image_time = image_time + image_interval
		
		exposure_count = exposure_count + 1
	
	until (exposure_count >= PartialExposureCount)
	
end


--
-- Start the burst shot a little before C2, then start running through exposure settings, going from
-- short, fast exposures to slow, long exposures and then back to short, until just before the midpoint
-- of the eclipse.  <strikethrough>Take two long exposures at that point, for good measure.</strikethrough>
--
function do_c2max()

	local cur_shutter_speed = 0
	local CurISO = 0
	
	if ( get_cur_secs() >= max_sec ) -- Are we past this phase already?
	then
	
		log ("Skip C2->Max. Finished %d seconds ago.", (get_cur_secs() - max_sec))
		return
		
	end
	
	if (get_cur_secs() <= (c2_sec - (math.max(RingStartOffset, C2BurstStartOffset) + 30)))
	then
	
		log ("Main C2->Max loop for %d seconds.", (c2_sec - (math.max(RingStartOffset, C2BurstStartOffset) + 30)))
		
		wait_until (c2_sec - (math.max(RingStartOffset, C2BurstStartOffset) + 30))
		
		print()
		print("********************************************************")
		log  ("30 seconds to C2!  Remove Filter!")
		print("********************************************************")
		print()
		
		do_beep()
		
	end
		
	
	if ((get_cur_secs() <= (c2_sec - RingStartOffset) ) and ( DoRing == 1)) -- Are we taking Diamond Ring shots?
	then
	
		wait_until (c2_sec - RingStartOffset)
		
		if (UseBurst == 1)
		then
		
			take_burst (RingBurstCount, RingBurstISO, RingBurstShutterSpeed)
			
		else
		
			take_timed_burst (RingBurstCount, RingBurstTime, RingBurstISO, RingBurstShutterSpeed)
			
		end
		
	end
	
	if ( get_cur_secs() < c2_sec ) -- Have we passed the burst for Baily's beads?
	then
			
		wait_until (c2_sec - C2BurstStartOffset)
		
		if (UseBurst == 1)
		then
		
			take_burst (C23BurstCount, C23BurstISO, C23BurstShutterSpeed)
			
		else
		
			take_timed_burst (C23BurstCount, C2BurstTime, C23BurstISO, C23BurstShutterSpeed)
			
		end

		print()
		print("********************************************************")
		log  ("Post C2 warning!")
		print("********************************************************")
		print()		
		
		do_beep()
		
	end
	
	cur_shutter_speed = TotalityMinShutterSpeed
	
	CurISO = TotalityMinISO
	
	repeat
	
		take_shot(CurISO, cur_shutter_speed, 0, 0, 0)
		
		if (CurISO < (TotalityPrefISO * 0.95))
		then
			
			CurISO = CurISO * 2.0^TotalityExpStep
			
		elseif ((CurISO < (TotalityPrefISO * 1.1)) and (cur_shutter_speed < (TotalityMaxShutterSpeed * 0.95)))
		then
		
			cur_shutter_speed = cur_shutter_speed * 2.0^TotalityExpStep
		
		elseif (CurISO < (TotalityMaxISO * 0.95))
		then
		
			CurISO = CurISO * 2.0^TotalityExpStep
		
		else
		
			cur_shutter_speed = TotalityMinShutterSpeed
			
			CurISO = TotalityMinISO
			
		end
			
	until (get_cur_secs() >= (max_sec - MaxOffset)) -- Stop, and leave time to do the mid-eclipse earthshine
													-- exposures.
end


--
-- do_max -- Take a number of long exposures at the time of maximum eclipse, to try to capture
-- an earthshine image.  These can be bracketed.
--
function do_max()

	if (DoMaxExposures == 0)  -- Are we doing this?
	then
	
		log ("Skip Max Eclipse long exposures. Not configured.")
		return 		-- Nope.
	
	end

	if ( get_cur_secs() >= max_sec) -- Have we passed max already?
	then
	
		log ("Skip Max. Finished %d seconds ago.", (get_cur_secs() - max_sec))
		return
		
	end
	for count_max_exp = NumMaxExposures , 1 , -1 do
	
		log ("do_max: MaxISO=%d, MaxShutterSpeed=%s, DoMaxBrackets=%d, NumMaxBrackets=%d, MaxBracketStep=%d",
			MaxISO, tostring(MaxShutterSpeed), DoMaxBrackets, NumMaxBrackets, MaxBracketStep)
			
		take_shot(MaxISO, MaxShutterSpeed, DoMaxBrackets, MaxBracketStep, NumMaxBrackets)
		
	end
	
end
 

--
-- Similar to do_c2max, but reversed.  Exposures run from longest to shortest (and then repeat), 
-- the burst starts just before C3, and there are no bonus exposures.
--
function do_maxc3()

	local cur_shutter_speed = 0
	local CurISO = 0

	if ( get_cur_secs() >= (c3_sec + RingStartOffset) ) -- Are we past this phase already?
	then
	
		log ("Skip Max->C3. Finished %d seconds ago.", (get_cur_secs() - (c3_sec + C3BurstStartOffset)))
		return
		
	elseif ( get_cur_secs() < (c3_sec - C3BurstStartOffset) ) -- Do we have time for some totality exposures?
	then
	
		cur_shutter_speed = TotalityMaxShutterSpeed
		CurISO = TotalityMaxISO
		
		log ("Main Max->C3 loop for %d seconds.", (c3_sec - C3BurstStartOffset - get_cur_secs()))
	
		repeat
	
			take_shot(CurISO, cur_shutter_speed, 0, 0, 0)
			
			if (CurISO > (TotalityPrefISO * 1.05))
			then
			
				CurISO = CurISO / 2.0^TotalityExpStep
			
			elseif ((CurISO > (TotalityPrefISO * 0.95)) and (cur_shutter_speed > (TotalityMinShutterSpeed * 1.05)))
			then
		
				cur_shutter_speed = cur_shutter_speed / 2.0^TotalityExpStep
		
			elseif (CurISO > (TotalityMinISO * 1.01))
			then
		
				CurISO = CurISO / 2.0^TotalityExpStep
		
			else
		
				cur_shutter_speed = TotalityMaxShutterSpeed
				
				CurISO = TotalityMaxISO
			
			end
						
		until (get_cur_secs() >= (c3_sec - (C3BurstStartOffset + 3)))

		print()
		print("********************************************************")
		log  ("3 seconds to C3!  Filter warning!")
		print("********************************************************")
		print()
		
		do_beep()
			
	end
	
	wait_until (c3_sec - C3BurstStartOffset)
	
	if (UseBurst == 1)
	then
	
		take_burst (C23BurstCount, C23BurstISO, C23BurstShutterSpeed)
		
	else
	
		take_timed_burst(C23BurstCount, C3BurstTime, C23BurstISO, C23BurstShutterSpeed)
		
	end
	
	if (DoRing == 1)
	then
	
		if (UseBurst == 1)
		then
	
			take_burst (RingBurstCount, RingBurstISO, RingBurstShutterSpeed)
		
		else
	
			take_timed_burst(RingBurstCount, RingBurstTime, RingBurstISO, RingBurstShutterSpeed)
		
		end
		
	end

	print()
	print("********************************************************")
	log  ("End of totality! Replace filter!")
	print("********************************************************")
	print()
		
	do_beep()

end


--
-- The ringleader.
--
function main()

	local starttime
	local offset = 0
	local offset_count = 0

	starttime = get_cur_secs()
	
	TestStartTime = starttime
	
    menu.close()
    console.show()
	log_start ()

	--
	-- The camera maintains a millisecond timer since power-on.  We can use this to
	-- get close to the beginning of a given second.  I think.
	--
	event.seconds_clock = function (ignore)
	
		offset = offset + (dryos.ms_clock - (1000 * offset_count))
		offset_count = offset_count + 1
			
	return true
	
end
	print ()
	print ()
	print ("-------------------------------------")
	print ("  Eclipse Magic")
	print ("  Copyright 2017, grnbrg@grnbrg.org")
	print ("  Released under the GNU GPL")
	print ("-------------------------------------")
	print ()
	print ("Starting 10 second timing calibration....")

	--
	-- There is a fair amount of jitter in the event timer.  Averaging over 10 seconds will
	-- give us a reasonable offset.
	--
	task.yield(10500)

	-- Turn off the second_clock event timer.
	event.seconds_clock = nil
	
	tick_offset = (math.floor(offset / offset_count) % 1000)
	
	print ("Done!")
	print ()
	log ("TestBeepNoShutter: %d", TestBeepNoShutter)
	log ("C1: %s", pretty_time(c1_sec))
	log ("C2: %s", pretty_time(c2_sec))
	log ("C3: %s", pretty_time(c3_sec))
	log ("C4: %s", pretty_time(c4_sec))

	-- If the camera is not in manual mode, trying to set the shutter speed throws errors.
	-- Check to make sure we are in manual mode, and refuse to run if we're not.
	if (camera.mode == MODE.M)
	then
	
		if (SetAperture == 1)
		then
		
			camera.aperture.value = Aperture
			
		end
	
		do_partial ((c1_sec + PartialMarginTime), c2_sec, "Pre")
	
		do_c2max()
		
		do_max()
	
		do_maxc3()
	
		do_partial (c3_sec, (c4_sec - PartialMarginTime), "Post")
		
	else
		
		beep (5, 100)
		
		log  ("Camera must be in manual (M) mode!!")
		print()
		print("Press any button to exit the script.  Change the mode and re-run.")
		
		key.wait()
		
	end
		
	log ("All done. Normal exit.")
	log_stop ()
	print("Press any button to exit the script.")
	key.wait()
    console.hide()
	
end -- Done.  Hope there were no clouds.


main() -- Run the program.

-- CHANGES

-- 1.0.1
	-- Stopped running the seconds_clock event at all times, and moved the tick_offset
		-- calculation to the setup at the start of execution
	-- Fixed the pretty-printing of the timer
	-- Fixed the sign of the C23BurstStartOffset in do_maxc3
	-- Fixed the calculation of the difference between current time and the next second
		-- in wait_until()
	-- Added code to turn off the console during long waits
	-- Massaged the end-of-exposure-bracketing conditions in do_c2max() and do_maxc3()
	
-- 1.1
	-- Changed the partial phase exposure logic, so that instead of there being an exposure
		-- at C1 and C2, there is an exposure at C1 and an exposure at (C2 - exposure_interval)
		-- so that the totality images are properly centered between the requested partial phase
		-- exposures.
	-- Added an alarm at 30 seconds before C2 and 3 seconds before C3 to alert for any filter changes.  
		-- There is also a beep after the C2 and C3 bursts to flag any needed changes.
	-- Split the C23BurstStartOffset into separate variables, to allow an asymmetric burst over
		-- each period.  (ie: 10 seconds before C2 to 3 seconds after C2)
		
-- 1.2
	-- Added ISO brackets to totality exposure sequence.  Totality now has a preferred ISO, 
		-- and will shift to that ISO at the fastest or slowest shutter speeds, then use that
		-- preferred ISO for the requested range of shutter speeds, then shift ISO to the end of
		-- the requested range.
	-- Option to stop LiveView before touching the shutter controls.
	-- Removed the two long exposures at max eclipse -- probably not needed.
	
-- 1.2.1
	-- Changed call to lv.stop() to a beep, and instruction to the user to turn off LV.
		-- lv.stop() doesn't seem to work.
	-- Added print statements to explain filter warning beeps.
	
-- 1.3.0
	-- Changed the startup timing loop to be more accurate if the script is started close to
	    -- a second boundary.  (The average offset of 999ms and 1ms is 1ms, not 500ms)
	-- Corrected an error in wait_until() -- Used div, where modulus was correct, and had
	    -- the tick_offset correction wrong.  Don't code while tired.  Thanks to
		-- matman730 for pointing out this goof.
	-- Improved the configuration comments around TestBeepNoShutter.  They apparently weren't
	    -- clear as I thought.
		
-- 1.4.0  (Not released)
		-- Attempt to implment the changing of the file prefix for the saved images.  It didn't
			-- work well, and I scrapped it.
		
-- 1.5.0
	-- Make it optional to hide the console during script running, and allow the delay before
		-- and after the next image to be configured.
	-- Shutter shock reduction:  Add a configurable (in milliseconds) delay before an exposure
		-- where the shutter speed is within a (also configurable) range.
	-- Add a mid-eclipse section.  This is a short section around the max eclipse point to optionally
		-- try for some earthshine exposures.
	-- Set the aperture on program start.
	
-- 1.6.0 -- Contributions from Eric Krohn, <krohn@ekrohn.com> (Many thanks!)
	-- Added logging to permanent file, "ECLIPSE.LOG" at top level of the memory card
	-- More extensive logging added throughout the script
	-- Bugfix:  In do_max() the last two arguments to take_shot() were reversed. 
	-- Bugfix:  do_max() is unguarded as far as current time
	-- Added pretty_shutter() to make the shutter speed numbers more sensible

-- 1.7.0
	-- Added optional function to take some diamond ring images before and after the Baily's Beads
		-- exposures.  Be careful not to overlap the Ring and Beads exposures before C2!
	-- Added a new burst function that takes a burst of images, one at a time, rather than using the
		-- camera's burst function.  Slower, but slower is better for the buffer, and gives us the
		-- opportunity to stop shooting at a specific time, where a burst will run until the requested
		-- number of images have been captured.

