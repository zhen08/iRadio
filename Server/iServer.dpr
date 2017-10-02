program iServer;

uses
  SvcMgr,
  UnitServiceiServer in 'UnitServiceiServer.pas' {ServiceiServer: TService},
  UnitDataModuleDatabase in 'UnitDataModuleDatabase.pas' {DataModuleDatabase: TDataModule},
  UnitDefinations in 'UnitDefinations.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TServiceiServer, ServiceiServer);
  Application.CreateForm(TDataModuleDatabase, DataModuleDatabase);
  Application.Run;
end.
