unit UnitDataModuleDatabase;

interface

uses
  SysUtils, Classes, DBXpress, DB, SqlExpr, DBClient, SimpleDS, FMTBcd;

type
  TDataModuleDatabase = class(TDataModule)
    SQLConnectionDatabase: TSQLConnection;
    SQLQueryUserInfo: TSQLQuery;
    SQLQueryLog: TSQLQuery;
    SQLQueryOnlineUser: TSQLQuery;
  private
    { Private declarations }
  public
    { Public declarations }
    procedure SaveLog(LgProcess : String ; LgType : String ; LgMessage : String);
  end;

var
  DataModuleDatabase: TDataModuleDatabase;

implementation

uses UnitDefinations;

{$R *.dfm}

procedure TDataModuleDatabase.SaveLog(LgProcess : String ; LgType : String ; LgMessage : String);
begin
  try
    SQLQueryLog.Params.ParamByName('LogTime').AsString := DateTimeToStr(Now);
    SQLQueryLog.Params.ParamByName('LogProcess').AsString := LgProcess;
    SQLQueryLog.Params.ParamByName('LogType').AsString := LgType;
    SQLQueryLog.Params.ParamByName('LogMessage').AsString := LgMessage;
    SQLQueryLog.ExecSQL(false);
  finally
    SQLQueryLog.Close;
  end;
end;

end.
