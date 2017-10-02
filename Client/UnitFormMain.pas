unit UnitFormMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, Registry,
  ImgList, Menus, ComCtrls, ToolWin, Dialogs, Buttons, StdCtrls, ExtCtrls;

type

  TFormMain = class(TForm)
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    Exit1: TMenuItem;
    Opration1: TMenuItem;
    Help1: TMenuItem;
    About1: TMenuItem;
    Logon1: TMenuItem;
    Logoff1: TMenuItem;
    N1: TMenuItem;
    Call1: TMenuItem;
    Hangup1: TMenuItem;
    StatusBar: TStatusBar;
    TreeView: TTreeView;
    ToolBar1: TToolBar;
    ImageList1: TImageList;
    ToolButton1: TToolButton;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    ToolButton4: TToolButton;
    ToolButton5: TToolButton;
    ToolButton6: TToolButton;
    ToolButton7: TToolButton;
    ChangeUser1: TMenuItem;
    N2: TMenuItem;
    Options1: TMenuItem;
    ViaServer1: TMenuItem;
    Register1: TMenuItem;
    Panel1: TPanel;
    RichEditBroadcast: TRichEdit;
    Panel2: TPanel;
    EditBroadCast: TEdit;
    Button1: TButton;
    procedure Exit1Click(Sender: TObject);
    procedure Logon1Click(Sender: TObject);
    procedure Logoff1Click(Sender: TObject);
    procedure Call1Click(Sender: TObject);
    procedure Hangup1Click(Sender: TObject);
    procedure TreeViewMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure About1Click(Sender: TObject);
    procedure ChangeUser1Click(Sender: TObject);
    procedure Register1Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure RefreshTreeView;
  end;

var
  FormMain: TFormMain;

implementation

uses UnitDataModuleSignal, UnitDefinations, UnitFormCall, UnitAboutBox,
  UnitDialogUserInfo;

{$R *.dfm}

procedure TFormMain.Exit1Click(Sender: TObject);
begin
  Close;
end;

procedure TFormMain.Logon1Click(Sender: TObject);
begin
  DataModuleSignal.Logon;
end;

procedure TFormMain.Logoff1Click(Sender: TObject);
begin
  DataModuleSignal.Logoff;
end;

procedure TFormMain.Call1Click(Sender: TObject);
var
  i,ii : integer;
begin
  try
    for i := 0 to TreeView.Items.Count-1 do begin
      if TreeView.Items[i].Selected then begin
        if Pos(Trim(DataModuleSignal.UserName),TreeView.Items[i].Text)=0 then
          for ii := 0 to MAXUSER do begin
            if Pos(Trim(DataModuleSignal.OnlineUser[ii].UserName),TreeView.Items[i].Text)>0 then begin
              DataModuleSignal.Call(DataModuleSignal.OnlineUser[ii].UserNumber,DataModuleSignal.OnlineUser[ii].UserName);
              exit;
            end;
          end;
      end;
    end;
  finally
  end;
end;

procedure TFormMain.Hangup1Click(Sender: TObject);
begin
  DataModuleSignal.Hangup(DataModuleSignal.DestNumber);
end;

procedure TFormMain.RefreshTreeView;
var
  i,ii : integer;
  NeedDelete : Boolean;
  NeedAdd : Boolean;
begin
  try
    i := 0;
    while i < TreeView.Items.Count do begin
      NeedDelete := True;
      for ii := 0 to MAXUSER do begin
        if DataModuleSignal.OnlineUser[ii].UserNumber <> 0 then begin
          if Pos(Trim(DataModuleSignal.OnlineUser[ii].UserName),TreeView.Items[i].Text) > 0 then begin
            NeedDelete := False;
            if DataModuleSignal.OnlineUser[ii].UserStatus = ST_FREE then begin
              TreeView.Items[i].ImageIndex := 1;
            end else begin
              TreeView.Items[i].ImageIndex := 5;
            end;
          end;
        end;
      end;
      if NeedDelete then begin
        TreeView.Items[i].Delete;
      end else begin
        Inc(i);
      end;
    end;
    for ii := 0 to MAXUSER do begin
      NeedAdd := True;
      if DataModuleSignal.OnlineUser[ii].UserNumber <> 0 then begin
        i := 0;
        while i < TreeView.Items.Count do begin
          if Pos(Trim(DataModuleSignal.OnlineUser[ii].UserName),TreeView.Items[i].Text) > 0 then begin
            NeedAdd := False;
          end;
          Inc(i);
        end;
        if NeedAdd then begin
          TreeView.Items.Add(nil,Trim(DataModuleSignal.OnlineUser[ii].UserName));
          if DataModuleSignal.OnlineUser[ii].UserStatus = ST_FREE then begin
            TreeView.Items[TreeView.Items.Count-1].ImageIndex := 1;
          end else begin
            TreeView.Items[TreeView.Items.Count-1].ImageIndex := 5;
          end;
        end;
      end;
    end;
  finally  
  end;
end;

procedure TFormMain.TreeViewMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
//var
//  i : integer;
begin
{  try
    with Sender as TTreeView do begin
      for i := 0 to MAXUSER do begin
        if Pos(Trim(DataModuleSignal.OnlineUser[i].UserName),GetNodeAt(X,Y).Text)>0 then begin
          if Trim(DataModuleSignal.OnlineUser[i].UserName) <> Trim(DataModuleSignal.UserName) then
            DataModuleSignal.Call(DataModuleSignal.OnlineUser[i].UserNumber,DataModuleSignal.OnlineUser[i].UserName);
          exit;
        end;
      end;
    end;
  finally
  end;}
end;

procedure TFormMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  DataModuleSignal.Logoff;
end;

procedure TFormMain.About1Click(Sender: TObject);
begin
  Application.CreateForm(TAboutBox, AboutBox);
  AboutBox.ShowModal;
end;

procedure TFormMain.ChangeUser1Click(Sender: TObject);
var
  iRadioRegistry : TRegistry;
begin
  iRadioRegistry := TRegistry.Create;
  try
    iRadioRegistry.RootKey := HKEY_CURRENT_USER;
    if iRadioRegistry.OpenKey('\Software\BD4JI\iRadio\',True) then begin
      Application.CreateForm(TDialogUserInfo, DialogUserInfo);
      DialogUserInfo.ShowModal;
      DialogUserInfo.Free;
      if Trim(DataModuleSignal.UserName) <> '' then begin
        iRadioRegistry.WriteString('UserName',DataModuleSignal.UserName);
        iRadioRegistry.WriteString('Password',DataModuleSignal.Password);
        FormMain.Caption := 'iRadio - ' + Trim(DataModuleSignal.UserName);
      end else begin
      end;
    end;
  finally
    iRadioRegistry.Free;
  end;

end;

procedure TFormMain.Register1Click(Sender: TObject);
begin
  Application.CreateForm(TDialogUserInfo, DialogUserInfo);
  DialogUserInfo.ShowModal;
  DialogUserInfo.Free;
  DataModuleSignal.UserRegist;
end;

procedure TFormMain.Button1Click(Sender: TObject);
begin
  DataModuleSignal.BroadcastText(Trim(DataModuleSignal.UserName)+'-->'+EditBroadcast.Text);
  EditBroadcast.Text := '';
end;

end.
