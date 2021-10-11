
program Phone;

uses
  Forms,
  TElDov in 'TElDov.pas' {PhoneForm},
  Thread in 'THREAD.PAS',
  Progress in 'PROGRESS.PAS' {MainForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
