#include "Json.au3"
$failedtxt = ""
For $x = 1 To 6
	ConsoleWrite("> ========= Test" & $x & " Start   =========================" & @CRLF)
	If Not Call("Test" & $x) Then
		ConsoleWrite("! ========= Test" & $x & " Failed! =========================" & @CRLF & @CRLF)
		$failedtxt &=  "Test" & $x & " Failed!" & @CRLF
	Else
		ConsoleWrite("+ ========= Test" & $x & " Passed! =========================" & @CRLF & @CRLF)
	EndIf
Next
If $failedtxt <> ""  Then
	MsgBox(262144+16, 'Tests failed', $failedtxt)
Else
	MsgBox(262144+64, 'All Tests Passed.','All Tests Passed.')
EndIf

Func Test1()
	Local $Json1 = FileRead(@ScriptDir & "\test.json")
	Local $Data1 = Json_Decode($Json1)
	Local $Json2 = Json_Encode($Data1)

	Local $Data2 = Json_Decode($Json2)
	Local $Json3 = Json_Encode($Data2)

	ConsoleWrite("Test1 Result: " & $Json3 & @LF)
	Return ($Json2 = $Json3)
EndFunc   ;==>Test1

Func Test2()
	Local $Json1 = '["100","hello world",{"key":"value","number":100}]'
	Local $Data1 = Json_Decode($Json1)

	Local $Json2 = Json_Encode($Data1, $Json_UNQUOTED_STRING)
	Local $Data2 = Json_Decode($Json2)

	Local $Json3 = Json_Encode($Data2, $Json_PRETTY_PRINT, "  ", "\n", "\n", ",")
	Local $Data3 = Json_Decode($Json3)

	Local $Json4 = Json_Encode($Data3, $Json_STRICT_PRINT)

	ConsoleWrite("Test2 Unquoted Result: " & $Json2 & @LF)
	ConsoleWrite("Test2 Pretty Result: " & $Json3 & @LF)
	Return ($Json1 = $Json4)
EndFunc   ;==>Test2

Func Test3()
	Local $Obj
	Json_Put($Obj, ".foo", "foo")
	Json_Put($Obj, ".bar[0]", "bar")
	Json_Put($Obj, ".test[1].foo.bar[2].foo.bar", "Test") ; dot notation

	Local $Json = Json_Encode($Obj)
	ConsoleWrite("Test3 Result: " & $Json & @LF)

	Return Json_Get($Obj, '["test"][1]["foo"]["bar"][2]["foo"]["bar"]') = "Test" ; square bracket notation
EndFunc   ;==>Test3

Func Test4()
	ConsoleWrite("Test4 will show all keys: " & @LF)
	Local $Json1 = '["100","hello world",{"key":"value","number":100}]'
	Json_Dump($Json1)
	ConsoleWrite("Test4 done." & @LF)
	Return 1
EndFunc   ;==>Test4

Func Test5()
	ConsoleWrite("Test5 test primitive/true/false/0 cases: " & @LF)
	Local $Json1 = '{"null_item": null, "zero_primitive_item": 0,"false_item": false,"true_item": true,"string_item": "This is a string","array_item": [0,1,2]}'
	Json_Dump($Json1)
	Local $testresult = "+-> .null_item  =Null" & @CRLF & _
			"+-> .zero_primitive_item  =0" & @CRLF & _
			"+-> .false_item  =False" & @CRLF & _
			"+-> .true_item  =True" & @CRLF & _
			"+-> .string_item  =This is a string" & @CRLF & _
			"+=> .array_item[0]=>0" & @CRLF & _
			"+=> .array_item[1]=>1" & @CRLF & _
			"+=> .array_item[2]=>2" & @CRLF
	Return $Total_JSON_DUMP_Output = $testresult
EndFunc   ;==>Test5

Func Test6()
	$sJson = '{"d": {"5": {"4": {"6": {"h": [{"id": "1286","status": "sunny","earth": true}]}}}}}'
	Json_dump($sJson)
	$oTemp = Json_Decode($sJson)
	If Json_IsObject($oTemp) Then
		$result = Test6b($oTemp, "d", True) = Test6b($oTemp, "d.5", True) = Test6b($oTemp, "d.5.4", True) = Test6b($oTemp, "d.5.4.6", True) = Test6b($oTemp, "d.5.4.6.h", True) = Test6b($oTemp, "d.5.4.6.x", False)
		$oTempb = Json_ObjGet($oTemp, "d.5.4.6.h")
		$result = $result = Test6c($oTempb, '[0].id', '1286')
		$oTempb = Json_ObjGet($oTemp, "d.5.4.6.x")
		$result = $result = Test6c($oTempb, '[0].id', '')
	EndIf
	return $result
EndFunc

Func Test6b($oTemp,$test,$expresult)
	$chk = Json_ObjExists($oTemp, $test)
	if $chk = $expresult then
		ConsoleWrite("+")
	Else
		ConsoleWrite("!!!!")
	EndIf
	ConsoleWrite('@@ Json_ObjExists($oTemp, "'& $test& '") = ' & $chk & @CRLF) ;### Debug Console
	Return $chk = $expresult
EndFunc
Func Test6c($oTemp,$test,$expresult)
	$chk = Json_Get($oTemp, $test)
	if $chk = $expresult then
		ConsoleWrite("+")
	Else
		ConsoleWrite("!!!!")
	EndIf
	ConsoleWrite('@@ Json_Get($oTemp, "'& $test& '") = ' & $chk & @CRLF) ;### Debug Console
	Return $chk = $expresult
EndFunc