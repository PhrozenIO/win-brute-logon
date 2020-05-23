(*******************************************************************************

  Jean-Pierre LESUEUR (@DarkCoderSc)
  https://www.phrozen.io/
  jplesueur@phrozen.io

  License : MIT

*******************************************************************************)

unit UntTypeDefs;

interface

uses SysUtils;

type
  TWordlistMode = (
                    wmUndefined,
                    wmFile,
                    wmStdin
  );

  EOptionException = class(Exception);

implementation

end.
