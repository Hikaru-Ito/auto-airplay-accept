-- AirPlay Auto Accept
-- (1) macOSのAirPlay受信通知バナーの「受け入れる」ボタンを自動でクリックする。
-- (2) AirPlayミラーリング開始でOSが自動pauseした Spotify / ミュージックを、
--     ミラーリング終了時に自動で再生再開する。
--
-- セッションの開始/終了は pmset -g assertions の "com.apple.airplay.audio"
-- アサーション（ControlCenter が立てる）の有無で判定する。

property pollInterval : 1
property airplayBadge : "AIRPLAY"
property sessionAssertionMarker : "com.apple.airplay.audio"
-- assertion が立つのは Spotify が auto-pause された数秒後。
-- 最後に "playing" を観測した時刻がこの秒数以内なら「直前まで再生中だった」と扱う。
property recentPlayingThreshold : 15

property wasAirPlayActive : false
property spotifyLastPlayingAt : 0
property musicLastPlayingAt : 0
property shouldResumeSpotify : false
property shouldResumeMusic : false

on run
	set wasAirPlayActive to false
	set shouldResumeSpotify to false
	set shouldResumeMusic to false
	set spotifyLastPlayingAt to 0
	set musicLastPlayingAt to 0
end run

on idle
	try
		handleAirPlay()
	end try
	try
		handleSessionTransition()
	end try
	return pollInterval
end idle

-- --- (1) 受信バナーの自動承諾 ---

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

-- グループ内のボタンのうち画面上で一番下にあるもの（=「受け入れる」）をクリック。
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

-- --- (2) セッション終了時の音楽再生再開 ---

on handleSessionTransition()
	set nowAt to my getNowEpoch()
	set active to my isAirPlaySessionActive()

	-- 毎ポーリングで "playing" 観測時刻を更新する。
	-- OSがアプリを自動pauseするのは pmset assertion が立つ数秒前なので、
	-- assertion 検出時点では state が既に "paused" になっている。
	-- 直前の "playing" 観測時刻を持ち続けることでこのラグを補正する。
	if my isPlayerPlaying("Spotify") then set spotifyLastPlayingAt to nowAt
	if my isPlayerPlaying("Music") then set musicLastPlayingAt to nowAt

	if active and (not wasAirPlayActive) then
		set shouldResumeSpotify to my wasRecentlyPlaying(spotifyLastPlayingAt, nowAt)
		set shouldResumeMusic to my wasRecentlyPlaying(musicLastPlayingAt, nowAt)
	else if (not active) and wasAirPlayActive then
		if shouldResumeSpotify then my safePlay("Spotify")
		if shouldResumeMusic then my safePlay("Music")
		set shouldResumeSpotify to false
		set shouldResumeMusic to false
	end if
	set wasAirPlayActive to active
end handleSessionTransition

on isAirPlaySessionActive()
	try
		set sh to "if pmset -g assertions | grep -q '" & sessionAssertionMarker & "'; then echo 1; else echo 0; fi"
		return ((do shell script sh) as integer is 1)
	on error
		return false
	end try
end isAirPlaySessionActive

on getNowEpoch()
	try
		return (do shell script "date +%s") as integer
	on error
		return 0
	end try
end getNowEpoch

on wasRecentlyPlaying(lastAt, nowAt)
	if lastAt is 0 then return false
	return (nowAt - lastAt) ≤ recentPlayingThreshold
end wasRecentlyPlaying

-- Spotify / Music の player state は enum constant で返り、`tell application` の
-- ブロック内でないと `playing` などの定数識別子をコンパイルできない。Spotify は
-- CIランナーに未インストール、Music も `fast forwarding` のような複合語が環境
-- 依存でコンパイルエラーを起こすため、`run script` を使って当該アプリ内で
-- 動的に評価する。これによりコンパイル時に対象アプリの辞書が不要になる。
on isPlayerPlaying(appName)
	tell application "System Events"
		if not (exists (process appName)) then return false
	end tell
	try
		return (run script "tell application \"" & appName & "\" to return (player state is playing)") as boolean
	on error
		return false
	end try
end isPlayerPlaying

on safePlay(appName)
	tell application "System Events"
		if not (exists (process appName)) then return
	end tell
	try
		run script "tell application \"" & appName & "\" to play"
	end try
end safePlay

on quit
	continue quit
end quit
