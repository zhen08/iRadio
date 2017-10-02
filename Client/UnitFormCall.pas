unit UnitFormCall;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, ExtCtrls, Menus, ACMWaveOut, ACMWaveIn,
  MMSystem, MSAcm, ACMDialog;

type
  TACMWaveFormat = packed record
    case integer of
      0 : (Format : TWaveFormatEx);
      1 : (RawData : Array[0..128] of byte);
  end;

  TFormCall = class(TForm)
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    Save1: TMenuItem;
    Operation1: TMenuItem;
    Hangup1: TMenuItem;
    StatusBar: TStatusBar;
    Panel1: TPanel;
    Panel2: TPanel;
    EditSendText: TEdit;
    ButtonSend: TButton;
    RichEditDisplay: TRichEdit;
    ACMWaveOut: TACMWaveOut;
    ACMDialog: TACMDialog;
    ACMWaveIn: TACMWaveIn;
    SaveDialog: TSaveDialog;
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure ButtonSendClick(Sender: TObject);
    procedure ACMWaveInData(data: Pointer; size: Integer);
    procedure Hangup1Click(Sender: TObject);
    procedure Save1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure AddDisplayMessage(Sender : String ; Msg : String);
    procedure Play(Data: Pointer; Size: Integer);
  end;

var
  FormCall: TFormCall;

implementation

uses UnitFormMain, UnitDataModuleSignal, UnitDefinations ;

{$R *.dfm}

procedure TFormCall.FormCreate(Sender: TObject);
var
  SoundFormat : ^TACMWaveFormat;
begin
  GetMem(SoundFormat,SizeOf(TACMWaveFormat));

  SoundFormat^.Format.wFormatTag := 49;
  SoundFormat^.Format.nChannels := 1;
  SoundFormat^.Format.nSamplesPerSec := 8000;
  SoundFormat^.Format.nAvgBytesPerSec := 1625;
  SoundFormat^.Format.nBlockAlign := 65;
  SoundFormat^.Format.wBitsPerSample := 0;
  SoundFormat^.Format.cbSize := 2;

  SoundFormat^.RawData[18] := 64;
  SoundFormat^.RawData[19] := 1;
  ACMWaveOut.Open(Pointer(SoundFormat));
  ACMWaveIn.Open(Pointer(SoundFormat));
end;

procedure TFormCall.AddDisplayMessage(Sender : String ; Msg : String);
begin
  RichEditDisplay.Lines.Add(Trim(Sender)+'-->'+Trim(Msg));
end;

procedure TFormCall.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  ACMWaveIn.Close;
  ACMWaveOut.Close;
  FormMain.Hangup1Click(Sender);
  CanClose := False;
end;

procedure TFormCall.ButtonSendClick(Sender: TObject);
begin
  DataModuleSignal.SendText(EditSendText.Text);
  AddDisplayMessage(DataModuleSignal.UserName,EditSendText.Text);
  EditSendText.Text := '';
end;

procedure TFormCall.Play(Data: Pointer; Size: Integer);
begin
  FormCall.ACMWaveOut.PlayBack(Data,Size);
end;

procedure TFormCall.ACMWaveInData(data: Pointer; size: Integer);
begin
//  ACMWaveOut.PlayBack(Data,Size);
  DataModuleSignal.SendVoice(data,size);
end;

procedure TFormCall.Hangup1Click(Sender: TObject);
begin
  FormMain.Hangup1Click(Sender);
end;

procedure TFormCall.Save1Click(Sender: TObject);
begin
  if SaveDialog.Execute then begin
    RichEditDisplay.Lines.SaveToFile(SaveDialog.FileName);
  end;
end;

end.
