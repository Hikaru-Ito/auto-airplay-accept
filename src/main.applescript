-- AirPlay Auto Accept
-- macOSのAirPlay受信ダイアログを自動的に「受け入れる」ボタンでクリックする。
-- stay-openアプレットとしてビルドし、idle handlerで定期的にダイアログを監視する。

property targetButtons : {"受け入れる", "Accept", "許可", "Allow", "OK"}
property candidateProcesses : {"ControlCenter", "Control Center", "AirPlayUIAgent", "sharingd", "UserNotificationCenter", "NotificationCenter"}
property pollInterval : 1

on run
	-- 起動時は何もしない。idle handlerが定期的に呼ばれる。
end run

on idle
	try
		tell application "System Events"
			repeat with procName in candidateProcesses
				try
					if exists (process procName) then
						tell process procName
							repeat with w in windows
								repeat with btnLabel in targetButtons
									try
										set b to button (btnLabel as string) of w
										if exists b then
											click b
										end if
									end try
								end repeat
							end repeat
						end tell
					end if
				end try
			end repeat
		end tell
	end try
	return pollInterval
end idle

on quit
	continue quit
end quit
