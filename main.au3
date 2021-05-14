#NoTrayIcon

#Region
#AutoIt3Wrapper_Icon=pakar.ico
#AutoIt3Wrapper_Outfile=התרעות צבע אדום.exe
#AutoIt3Wrapper_Compression=4
#AutoIt3Wrapper_UseX64=n
#AutoIt3Wrapper_Res_Comment=Yehuda Eisenberg - יהודה אייזנברג
#AutoIt3Wrapper_Res_Description=תוכנה לעדכון על התרעות צבע אדום
#AutoIt3Wrapper_Res_Fileversion=1.0.5
#AutoIt3Wrapper_Res_ProductName=תוכנה לעדכון על התרעות צבע אדום
#AutoIt3Wrapper_Res_ProductVersion=1.0.5
#AutoIt3Wrapper_Res_CompanyName=Yehuda Software
#AutoIt3Wrapper_Res_LegalCopyright=Yehuda Eisenberg - יהודה אייזנברג
#AutoIt3Wrapper_Res_Language=1037
#AutoIt3Wrapper_Res_Field=ProductName|תוכנה לעדכון על התרעות צבע אדום
#AutoIt3Wrapper_Res_Field=ProductVersion|1.0.5
#AutoIt3Wrapper_Res_Field=CompanyName|Yehuda Eisenberg - יהודה אייזנברג
#EndRegion

#include <Inet.au3>
#include <Misc.au3>
#include <Date.au3>
#include <Array.au3>
#include "json/json.au3"
#include "notify/notify.au3"

Global $sProvider = "inn"
Global $bSound = True
Global $sPakarAlertLinkInn = "https://www.inn.co.il/Generic/PakarAlerts/all"
Global $sPakarAlertLinkOref = "https://www.oref.org.il/WarningMessages/History/AlertsHistory.json"
Global $aLastAlertsInn[0]
Global $aLastAlertsOref[0]

Func _ReduceMemory()
	Local $aReturn = DllCall("psapi.dll", "int", "EmptyWorkingSet", "long", -1)
	If @error = 1 Then
		Return SetError(1, 0, 0)
	EndIf
	Return $aReturn[0]
EndFunc   ;==>_ReduceMemory

Func _CheckAlertsInn()
	HttpSetUserAgent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.93 Safari/537.36")
	Local $sData = BinaryToString(InetRead($sPakarAlertLinkInn), 4)
	Local $aAlerts = Json_Decode($sData)

	Local $i = 0

	While (StringLen(Json_Get($aAlerts, '["list"][' & $i & ']["RedWebNo"]')) > 0)
		Local $RedWebNo = Json_Get($aAlerts, '["list"][' & $i & ']["RedWebNo"]')
		Local $alertId = Json_Get($aAlerts, '["list"][' & $i & ']["TtlUniversalTime"]') & Json_Get($aAlerts, '["list"][' & $i & ']["AlertTime"]') & Json_Get($aAlerts, '["list"][' & $i & ']["Header"]') & Json_Get($aAlerts, '["list"][' & $i & ']["RedWebNo"]')

		If $RedWebNo <> "998" And $RedWebNo <> "999" And $RedWebNo <> "0" And $RedWebNo <> "1" And $RedWebNo <> "3002" And $RedWebNo <> "3004" And $RedWebNo <> "3005" And $RedWebNo <> "3006" And $RedWebNo <> "3007" And $RedWebNo <> "3000" Then
			Local $iArrayId = _ArraySearch($aLastAlertsInn, $alertId)
			If $iArrayId = -1 And (@error = 6 Or @error = 3) Then
				ReDim $aLastAlertsInn[UBound($aLastAlertsInn) + 1]
				$aLastAlertsInn[UBound($aLastAlertsInn) - 1] = $alertId

				_ShowAlert(Json_Get($aAlerts, '["list"][' & $i & ']["Header"]'))
			EndIf
		EndIf
		$i = $i + 1
	WEnd

	If $i = 0 Then
		Local $aTmp[0]
		$aLastAlertsInn = $aTmp
	EndIf

EndFunc

Func _CheckAlertsOref()
	HttpSetUserAgent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.93 Safari/537.36")
	Local $sData = BinaryToString(InetRead($sPakarAlertLinkOref), 4)
	Local $aAlerts = Json_Decode($sData)

	Local $i = 0

	While _DateDiff("s", StringReplace(Json_Get($aAlerts, '[' & $i & ']["alertDate"]'), "-", "/"), _NowCalc()) < 30
		Local $alertId = Json_Get($aAlerts, '[' & $i & ']["alertDate"]') & "|" & Json_Get($aAlerts, '[' & $i & ']["data"]')

		Local $iArrayId = _ArraySearch($aLastAlertsOref, $alertId)
		If $iArrayId = -1 And (@error = 6 Or @error = 3) Then
			ReDim $aLastAlertsOref[UBound($aLastAlertsOref) + 1]
			$aLastAlertsOref[UBound($aLastAlertsOref) - 1] = $alertId

			_ShowAlert(Json_Get($aAlerts, '[' & $i & ']["data"]'))
		EndIf

		$i = $i + 1
	WEnd

	If $i = 0 Then
		Local $aTmp[0]
		$aLastAlertsOref = $aTmp
	EndIf

EndFunc

Func _ShowAlert($sZone)
	FileInstall("pakar.ico", @TempDir & "\PAKAR-Icon.ico", 1)
	FileInstall("alarm.mp3", @TempDir & "\PAKAR-Alarm.mp3", 1)

	If $bSound Then _
		SoundPlay(@TempDir & "\PAKAR-Alarm.mp3", 0)
	_Notify_Set(0, 0xFF0000, 0xFFFF00, "Arial", False, 250)
	_Notify_Show(@TempDir & "\PAKAR-Icon.ico", "התרעת צבע אדום!", "התרעת צבע אדום בישוב " & $sZone & ".", 5)
EndFunc

If _Singleton("Pakar-YE-Single", 1) = 0 Then
	MsgBox(BitOR(0x30, 0x100000), "התרעות צבע אדום", "התוכנה כבר פועלת...", 5)
	Exit
EndIf

HttpSetUserAgent("AU3-Pakar-UA")
Local $sCheckVer = BinaryToString(InetRead("https://test.yehudae.net/pakar-i.php?version=" & FileGetVersion(@ScriptFullPath)), 4)
If $sCheckVer = "abc" Then
	MsgBox(BitOR(0x10, 0x100000), "התרעות צבע אדום", "קיימת גרסה מעודכנת יותר. אנא הורד אותה מהקישור:" & @CRLF & "https://files.yehudae.net/redAlarm", 10)
	ShellExecute("https://y-link.ml/redAlarm")
	Exit
EndIf

If Not Ping("inn.co.il", 1000) Then
	MsgBox(BitOR(0x30, 0x100000), "התרעות צבע אדום", "התוכנה זיהתה בעיה באינטרנט, התוכנה לא תדווח על התרעות עד אשר תתחבר לאינטרנט.")
EndIf

FileDelete(@AppDataDir & "\Microsoft\Windows\Start Menu\Programs\StartUp\התראות צבע אדום.exe")

If @ScriptDir <> @AppDataDir & "\Microsoft\Windows\Start Menu\Programs\StartUp" Then
	FileCopy(@ScriptFullPath, @AppDataDir & "\Microsoft\Windows\Start Menu\Programs\StartUp\התרעות צבע אדום.exe", 1)
EndIf

_Notify_RegMsg()
_Notify_Locate(3)

Opt("TrayIconHide", 0)
Opt("TrayMenuMode", 3)

TraySetToolTip("התרעות צבע אדום (v" & FileGetVersion(@ScriptFullPath) & ") - ספק: ערוץ 7")
;Local $idTrayProvider = TrayCreateItem("החלף ספק לפיקוד העורף (פחות מהימן)")
Local $idTrayPause = TrayCreateItem("השהה את פעילות המערכת")
Local $idTraySound = TrayCreateItem("כבה התרעות קוליות")
Local $idTrayDemo = TrayCreateItem("התרעה לבדיקה")
Local $idTrayMail = TrayCreateItem("לשליחת הודעה למתכנת")
Local $idTraySite = TrayCreateItem("אתר התוכנה")
Local $idTrayExit = TrayCreateItem("סגירת התוכנה")
Local $bPause = False

MsgBox(BitOR(0x40, 0x100000), "התרעות צבע אדום", "התוכנה התחילה לרוץ.", 5)
While True
	_ReduceMemory()

	If Not $bPause Then
		If $sProvider = "inn" Then
			_CheckAlertsInn()
		Else
			_CheckAlertsOref()
		EndIf
	EndIf

	Switch TrayGetMsg()
		#cs
		Case $idTrayProvider
			If $sProvider = "inn" Then
				MsgBox(BitOR(0x40, 0x100000), "התרעות צבע אדום", "הספק הוחלף לפיקוד העורף. לתשומך ליבך, ספק זה הינו פחות מיהמן.", 5)
				TrayItemSetText($idTrayProvider, "החלף ספק לערוץ 7 (יותר מהימן)")
				TraySetToolTip("התרעות צבע אדום (v" & FileGetVersion(@ScriptFullPath) & ") - ספק: פיקוד העורף")
				$sProvider = "oref"
			Else
				MsgBox(BitOR(0x40, 0x100000), "התרעות צבע אדום", "הספק הוחלף לערוץ 7.", 5)
				TrayItemSetText($idTrayProvider, "החלף ספק לפיקוד העורף (פחות מהימן)")
				TraySetToolTip("התרעות צבע אדום (v" & FileGetVersion(@ScriptFullPath) & ") - ספק: ערוץ 7")
				$sProvider = "inn"
		EndIf
		#ce
		Case $idTrayPause
			If $bPause Then
				MsgBox(BitOR(0x40, 0x100000), "התרעות צבע אדום", "התוכנה המשיכה את פעולתה.", 5)
				TrayItemSetText($idTrayPause, "השהה את פעילות המערכת")
			Else
				MsgBox(BitOR(0x40, 0x100000), "התרעות צבע אדום", "התוכנה השהתה את פעולתה.", 5)
				TrayItemSetText($idTrayPause, "הפעל את פעילות המערכת")
			EndIf
			$bPause = Not $bPause
		Case $idTraySound
			If $bSound Then
				MsgBox(BitOR(0x40, 0x100000), "התרעות צבע אדום", "ההתרעות הקוליות כבויות.", 5)
				TrayItemSetText($idTraySound, "הפעל התרעות קוליות")
			Else
				MsgBox(BitOR(0x40, 0x100000), "התרעות צבע אדום", "ההתרעות הקוליות דלוקות.", 5)
				TrayItemSetText($idTraySound, "כבה התרעות קוליות")
			EndIf
			$bSound = Not $bSound
		Case $idTrayDemo
			_ShowAlert("***בדיקה***")
		Case $idTrayMail
			ShellExecute("mailto:pakar@yehuade.net")
		Case $idTraySite
			ShellExecute("https://y-link.ml/redAlarm")
		Case $idTrayExit
			MsgBox(BitOR(0x40, 0x100000), "התרעות צבע אדום", "להתראות.", 3)
			Exit
	EndSwitch
WEnd