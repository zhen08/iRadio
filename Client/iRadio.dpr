program iRadio;

uses
  Forms,
  UnitFormMain in 'UnitFormMain.pas' {FormMain},
  UnitDataModuleSignal in 'UnitDataModuleSignal.pas' {DataModuleSignal: TDataModule},
  UnitDialogUserInfo in 'UnitDialogUserInfo.pas' {DialogUserInfo},
  UnitFormCall in 'UnitFormCall.pas' {FormCall},
  UnitAboutBox in 'UnitAboutBox.pas' {AboutBox};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'iRadio ¿Í»§¶ËÈí¼þ';
  Application.CreateForm(TFormMain, FormMain);
  Application.CreateForm(TDataModuleSignal, DataModuleSignal);
  Application.Run;
end.
