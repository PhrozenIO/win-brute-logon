(*******************************************************************************

  Jean-Pierre LESUEUR (@DarkCoderSc)
  https://www.phrozen.io/
  jplesueur@phrozen.io

  License : MIT

*******************************************************************************)

unit UntFunctions;

interface

uses Windows, SysUtils;

type
  TDebugLevel = (
                  dlInfo,
                  dlSuccess,
                  dlWarning,
                  dlError,
                  dlProcess,
                  dlDone
  );

function RandomToken(ATokenLength : Integer) : String;
function GetAvailableCoreCount() : Integer;
procedure DumpLastError(APrefix : String = '');
procedure Debug(AMessage : String; ADebugLevel : TDebugLevel = dlInfo; AForce : Boolean = False);
function GetCommandLineOption(AOption : String; var AValue : Integer; ACommandLine : String = '') : Boolean; overload;
function GetCommandLineOption(AOption : String; var AValue : String; var AOptionExists : Boolean; ACommandLine : String = '') : Boolean; overload;
function GetCommandLineOption(AOption : String; var AValue : String; ACommandLine : String = '') : Boolean; overload;
function CommandLineOptionExists(AOption : String; ACommandLine : String = '') : Boolean;

implementation

uses UntGlobalDefs;

{-------------------------------------------------------------------------------
  Check if commandline option is set
-------------------------------------------------------------------------------}
function CommandLineOptionExists(AOption : String; ACommandLine : String = '') : Boolean;
var ADummy : String;
begin
  GetCommandLineOption(AOption, ADummy, result, ACommandLine);
end;

{-------------------------------------------------------------------------------
  Command Line Parser

  AOption       : Search for specific option Ex: -c.
  AValue        : Next argument string if option is found.
  AOptionExists : Set to true if option is found in command line string.
  ACommandLine  : Command Line String to parse, by default, actual program command line.
-------------------------------------------------------------------------------}
function GetCommandLineOption(AOption : String; var AValue : String; var AOptionExists : Boolean; ACommandLine : String = '') : Boolean;
var ACount    : Integer;
    pElements : Pointer;
    I         : Integer;
    ACurArg   : String;
    hShell32  : THandle;

    CommandLineToArgvW : function(lpCmdLine : LPCWSTR; var pNumArgs : Integer) : LPWSTR; stdcall;
type
  TArgv = array[0..0] of PWideChar;
begin
  result := False;
  ///

  AOptionExists := False;

  CommandLineToArgvW := nil;

  hShell32 := LoadLibrary('SHELL32.DLL');
  if (hShell32 = 0) then
    Exit();
  ///
  try
    @CommandLineToArgvW := GetProcAddress(hShell32, 'CommandLineToArgvW');

    if NOT Assigned(CommandLineToArgvW) then
      Exit();

    if (ACommandLine = '') then begin
      ACommandLine := GetCommandLineW();
    end;

    pElements := CommandLineToArgvW(PWideChar(ACommandLine), ACount);

    if NOT Assigned(pElements) then
      Exit();

    AOption := '-' + AOption;

    if (Length(AOption) > 2) then
      AOption := '-' + AOption;

    for I := 0 to ACount -1 do begin
      ACurArg := UnicodeString((TArgv(pElements^)[I]));
      ///

      if (ACurArg <> AOption) then
        continue;

      AOptionExists := True;

      // Retrieve Next Arg
      if I <> (ACount -1) then begin
        AValue := UnicodeString((TArgv(pElements^)[I+1]));

        ///
        result := True;
      end;
    end;
  finally
    FreeLibrary(hShell32);
  end;
end;

function GetCommandLineOption(AOption : String; var AValue : String; ACommandLine : String = '') : Boolean;
var AExists : Boolean;
begin
  result := GetCommandLineOption(AOption, AValue, AExists, ACommandLine);
end;

function GetCommandLineOption(AOption : String; var AValue : Integer; ACommandLine : String = '') : Boolean;
var AStrValue : String;
begin
  result := False;
  ///

  AStrValue := '';
  if NOT GetCommandLineOption(AOption, AStrValue, ACommandLine) then
    Exit();
  ///

  if NOT TryStrToInt(AStrValue, AValue) then
    Exit();
  ///

  result := True;
end;


{-------------------------------------------------------------------------------
  Debug Defs
-------------------------------------------------------------------------------}
procedure Debug(AMessage : String; ADebugLevel : TDebugLevel = dlInfo; AForce : Boolean = False);
var AConsoleHandle        : THandle;
    AConsoleScreenBufInfo : TConsoleScreenBufferInfo;
    b                     : Boolean;
    AStatus               : String;
    AColor                : Integer;
begin
  if (NOT G_DEBUG) and (NOT AForce) then
    Exit();
  ///

  AConsoleHandle := GetStdHandle(STD_OUTPUT_HANDLE);
  if (AConsoleHandle = INVALID_HANDLE_VALUE) then
    Exit();
  ///

  b := GetConsoleScreenBufferInfo(AConsoleHandle, AConsoleScreenBufInfo);

  case ADebugLevel of
    dlSuccess : begin
      AStatus := #32 + 'OK' + #32;
      AColor  := FOREGROUND_GREEN;
    end;

    dlWarning : begin
      AStatus := #32 + '!!' + #32;
      AColor  := (FOREGROUND_RED or FOREGROUND_GREEN);
    end;

    dlError : begin
      AStatus := #32 + 'KO' + #32;
      AColor  := FOREGROUND_RED;
    end;

    dlProcess : begin
      AStatus := #32 + '..' + #32;
      AColor  := (FOREGROUND_RED or FOREGROUND_BLUE);
    end;

    dlDone : begin
      AStatus := 'DONE';
      AColor  := (FOREGROUND_BLUE or FOREGROUND_GREEN);
    end;

    else begin
      AStatus := 'INFO';
      AColor  := FOREGROUND_BLUE;
    end;
  end;

  Write('[');
  if b then
    b := SetConsoleTextAttribute(AConsoleHandle, FOREGROUND_INTENSITY or (AColor));
  try
    Write(AStatus);
  finally
    if b then
      SetConsoleTextAttribute(AConsoleHandle, AConsoleScreenBufInfo.wAttributes);
  end;
  Write(']' + #32);

  ///
  WriteLn(AMessage);
end;

procedure DumpLastError(APrefix : String = '');
var ACode         : Integer;
    AFinalMessage : String;
begin
  ACode := GetLastError();

  AFinalMessage := '';

  if (ACode <> 0) then begin
    AFinalMessage := Format('Error_Msg=[%s], Error_Code=[%d]', [SysErrorMessage(ACode), ACode]);

    if (APrefix <> '') then
      AFinalMessage := Format('%s: %s', [APrefix, AFinalMessage]);

    ///
    Debug(AFinalMessage, dlError);
  end;
end;

{-------------------------------------------------------------------------------
  Retrieve number of available proc cores for multithreading
-------------------------------------------------------------------------------}
function GetAvailableCoreCount() : Integer;
var ASystemInfo: TSystemInfo;
begin
  ZeroMemory(@ASystemInfo, SizeOf(TSystemInfo));
  ///

  GetSystemInfo(ASystemInfo);

  result := ASystemInfo.dwNumberOfProcessors;
end;

{-------------------------------------------------------------------------------
  Generate a Random String from 0..9 and a..f
-------------------------------------------------------------------------------}
function RandomToken(ATokenLength : Integer) : String;
const ATokenChars = '0123456789abcdef';
var   i : integer;
begin
  result := '';

  randomize();
  ///

  for i := 1 to ATokenLength do begin
      result := result + ATokenChars[random(length(ATokenChars))+1];
  end;
end;

end.
