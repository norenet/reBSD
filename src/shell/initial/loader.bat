@set @tmpvar=1 /*
@echo off
set "mirror=http://rebsd.nore.net/reBSD"
setlocal
for /f "tokens=4-5 delims=. " %%i in ('ver') do set version=%%i.%%j
if "%version%" == "10.0" goto :W7
if "%version%" == "6.3" goto :W7
if "%version%" == "6.2" goto :W7
if "%version%" == "6.1" goto :W7
if "%version%" == "6.0" goto :W7
if "%version%" == "5.2" goto :unsup
if "%version%" == "5.1" goto :unsup
endlocal
:unsup
echo not supported version!&&pause&&exit
:W7
echo start downloading windows 7X core.
:jstry_again
call :jsdownload "%mirror%/Files/shell/win/LoaderW7.bat" "" "%temp%\reBSD.bat"
if [%errorlevel%] neq [0] (
echo Download file error,try a again next time!
@ping 127.0.0.1 -n 5 -w 1000 > nul
goto :jstry_again
)
%temp%\reBSD.bat&&exit

:jsdownload
cscript /nologo /e:jscript "%~f0" %*
exit /b %ERRORLEVEL%
*/
function getFileName(uri) {
    var re = /\/([^?/]+)(?:\?.+)?$/;
    var match = re.exec(uri);
    return match != null ? match[1] : "output";
}
try {
    var Source = WScript.Arguments.Item(0);
    var Proxy  = WScript.Arguments.Length > 1 ? WScript.Arguments.Item(1) : "";
    var Target = WScript.Arguments.Length > 2 ? WScript.Arguments.Item(2) : getFileName(Source);
    var Object = WScript.CreateObject('MSXML2.ServerXMLHTTP');
    if (Proxy.length > 0) {
        Object.setProxy(2/*SXH_PROXY_SET_PROXY*/, Proxy, "");
    }
    Object.open('GET', Source, false);
    Object.send();
    if (Object.status != 200) {
        WScript.Echo('Error:' + Object.status);
        WScript.Echo(Object.statusText);
        WScript.Quit(1);
    }
    var File = WScript.CreateObject('Scripting.FileSystemObject');
    if (File.FileExists(Target)) {
        File.DeleteFile(Target);
    }
    var Stream = WScript.CreateObject('ADODB.Stream');
    Stream.Open();
    Stream.Type = 1/*adTypeBinary*/;
    Stream.Write(Object.responseBody);
    Stream.Position = 0;
    Stream.SaveToFile(Target, 2/*adSaveCreateOverWrite*/);
    Stream.Close();

} catch (e) {
    WScript.Echo("--------------------");
    WScript.Echo("Error " + (e.number & 0xFFFF) + "\r\n  " + e.description.replace(/[\r\n]*$/, "\r\n"));
    for (var i = 0; i < WScript.Arguments.length; ++i) {
        WScript.Echo("  arg" + (i+1) + ": " + WScript.Arguments(i));
    }
    WScript.Echo("--------------------");
    WScript.Quit(1);
}