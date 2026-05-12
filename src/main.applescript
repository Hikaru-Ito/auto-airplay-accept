-- AirPlay Auto Accept
-- macOSのAirPlay受信通知バナーの「受け入れる」ボタンを自動でクリックする。
-- AirPlay受信ダイアログは NotificationCenter プロセスが描画する通知バナーで、
-- ボタンのラベルは AX 経由では取得できないため、構造（AIRPLAYバッジ + 2ボタン）と
-- 画面上のY座標（下にある方が受け入れる）で識別する。

property pollInterval : 1
property airplayBadge : "AIRPLAY"

on run
end run

on idle
	try
		handleAirPlay()
	end try
	return pollInterval
end idle

on handleAirPlay()
	tell application "System Events"
		if not (exists process "NotificationCenter") then return
		set wins to windows of process "NotificationCenter"
	end tell
	repeat with w in wins
		try
			if my findAndAcceptInElement(w, 0) then return
		end try
	end repeat
end handleAirPlay

on findAndAcceptInElement(e, depth)
	if depth > 8 then return false
	if my isAirPlayBannerGroup(e) then
		return my clickAcceptInGroup(e)
	end if
	set kids to {}
	tell application "System Events"
		try
			set kids to UI elements of e
		end try
	end tell
	repeat with k in kids
		try
			if my findAndAcceptInElement(k, depth + 1) then return true
		end try
	end repeat
	return false
end findAndAcceptInElement

on isAirPlayBannerGroup(e)
	set hasBadge to false
	set btnCount to 0
	tell application "System Events"
		try
			repeat with t in (static texts of e)
				try
					if (value of t as string) is airplayBadge then
						set hasBadge to true
						exit repeat
					end if
				end try
			end repeat
		end try
		try
			set btnCount to count of (buttons of e)
		end try
	end tell
	return (hasBadge and btnCount ≥ 2)
end isAirPlayBannerGroup

-- グループ内のボタンのうち画面上で一番下にあるものをクリックする。
-- macOSのAirPlay通知バナーでは「受け入れる」が下、「辞退」が上に並ぶ。
on clickAcceptInGroup(g)
	set targetBtn to missing value
	set bestY to -1
	tell application "System Events"
		try
			set btns to buttons of g
		on error
			return false
		end try
		repeat with b in btns
			try
				set pos to value of attribute "AXPosition" of b
				set y to (item 2 of pos) as integer
				if y > bestY then
					set bestY to y
					set targetBtn to b
				end if
			end try
		end repeat
		if targetBtn is missing value then return false
		try
			click targetBtn
			return true
		on error
			return false
		end try
	end tell
end clickAcceptInGroup

on quit
	continue quit
end quit
