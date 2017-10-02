unit UnitDialogUserInfo;

interface

uses Windows, SysUtils, Classes, Graphics, Forms, Controls, StdCtrls, 
  Buttons, ExtCtrls;

type
  TDialogUserInfo = class(TForm)
    OKBtn: TButton;
    CancelBtn: TButton;
    Bevel1: TBevel;
    Label1: TLabel;
    Label2: TLabel;
    EditUserName: TEdit;
    EditPassword: TEdit;
    procedure CancelBtnClick(Sender: TObject);
    procedure OKBtnClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure EditUserNameKeyPress(Sender: TObject; var Key: Char);
    procedure EditPasswordKeyPress(Sender: TObject; var Key: Char);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  DialogUserInfo: TDialogUserInfo;

implementation

uses UnitDataModuleSignal;

{$R *.dfm}

procedure TDialogUserInfo.CancelBtnClick(Sender: TObject);
begin
  DataModuleSignal.UserName := '';
  DataModuleSignal.Password := '';
  Close;
end;

procedure TDialogUserInfo.OKBtnClick(Sender: TObject);
var
  i : integer;
begin
  Move(EditUserName.Text[1] , DataModuleSignal.UserName , Length(EditUserName.Text));
  for i := Length(EditUserName.Text) to 19 do begin
    DataModuleSignal.UserName[i] := ' ';
  end;
  Move(EditPassword.Text[1] , DataModuleSignal.Password , Length(EditPassword.Text));
  for i := Length(EditPassword.Text) to 19 do begin
    DataModuleSignal.Password[i] := ' ';
  end;
end;

procedure TDialogUserInfo.FormShow(Sender: TObject);
begin
  EditUserName.SetFocus;
end;

procedure TDialogUserInfo.EditUserNameKeyPress(Sender: TObject;
  var Key: Char);
begin
  Key := UpCase(Key);
end;

procedure TDialogUserInfo.EditPasswordKeyPress(Sender: TObject;
  var Key: Char);
begin
  Key := UpCase(Key);
end;

end.
