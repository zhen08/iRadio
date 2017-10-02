unit UnitDataModuleSignal;

interface

uses
  SysUtils, Classes, Sockets, IdBaseComponent, IdAntiFreezeBase, Forms, Windows, Registry,
  IdAntiFreeze, ExtCtrls, IdComponent, IdUDPBase, IdUDPServer, IdSocketHandle,UnitDefinations,
  IdUDPClient, IdTCPConnection, IdTCPClient, IdTime;

type
  TDataModuleSignal = class(TDataModule)
    TimerTimeout: TTimer;
    UDP: TIdUDPServer;
    IdTime: TIdTime;
    TimerPoll: TTimer;
    procedure DataModuleCreate(Sender: TObject);
    procedure UDPUDPRead(Sender: TObject; AData: TStream;
      ABinding: TIdSocketHandle);
    procedure DataModuleDestroy(Sender: TObject);
    procedure TimerTimeoutTimer(Sender: TObject);
    procedure TimerPollTimer(Sender: TObject);
  private
    { Private declarations }
    ServerIP   : array [0..15] of char;
    ServerPort : integer;
    LocalIP    : array [0..15] of char;
    LocalPort  : integer;

    DestName   : array [0..20] of char;
    DestIP     : array [0..15] of char;
    DestPort   : integer;
    UserNumber : integer;
    Status     : integer;
    SendSN     : integer;
    TimerCount : integer;
    LastVoiceSN: integer;
    ServerPoll : integer;
    function GetSN : integer;

  public
    { Public declarations }
    DestNumber : integer;
    UserName   : array [0..19] of char;
    Password   : array [0..19] of char;
    OnlineUser : array [0..MAXUSER] of TPollUserData;
    TimeOffset : TDateTime;
    procedure UserRegist;
    procedure SaveLog(LgProcess : String ; LgType : String ; LgMessage : String);
    procedure ChangeStatus(St : integer);
    procedure SetServer(SvrIP : String; SvrPort : integer);
    procedure Logon;
    procedure Logoff;
    procedure Call(DstNumber : integer ; DstName : String);
    procedure Hangup(DestNumber : integer);
    procedure SendText(Txt : String);
    procedure BroadcastText(Txt : String);
    procedure SendVoice(Vdata : Pointer ; Sz : integer);
  end;

var
  DataModuleSignal: TDataModuleSignal;

implementation

uses UnitFormMain, UnitFormCall, UnitDialogUserInfo;

{$R *.dfm}

procedure TDataModuleSignal.SaveLog(LgProcess : String ; LgType : String ; LgMessage : String);
var
  LogFile : TextFile;
begin
  AssignFile(LogFile,'iRadio.Log');
  try
    Append(LogFile);
  except
    Rewrite(LogFile);
    Writeln(LogFile,'iRadio Client Software version 2.0');
  end;
  Writeln(LogFile,DateTimeToStr(Now) , '-->' , LgProcess , ' ' , LgType , ' ' , LgMessage);
  Close(LogFile);
end;

procedure TDataModuleSignal.ChangeStatus(St : integer);
begin
  Status := St;
  case Status of
  ST_IDLE : begin
    with FormMain do begin
      Logon1.Enabled := True;
      Logoff1.Enabled := False;
      Call1.Enabled := False;
      Hangup1.Enabled := False;
      ToolButton1.Enabled := True;
      ToolButton2.Enabled := False;
      ToolButton4.Enabled := False;
      ToolButton5.Enabled := False;
      FormMain.TreeView.Items.Clear;
    end;
    FormMain.StatusBar.Panels[1].Text := 'IDLE';
    if Debug then SaveLog('UnitDataModuleSignal','Debug','Change into ST_IDLE');
  end;
  ST_REGISTING : begin
    FormMain.StatusBar.Panels[1].Text := 'REGISTING';
    TimerTimeout.Enabled := True;
    with FormMain do begin
      Logon1.Enabled := False;
      Logoff1.Enabled := False;
      Call1.Enabled := False;
      Hangup1.Enabled := False;
      ToolButton1.Enabled := False;
      ToolButton2.Enabled := False;
      ToolButton4.Enabled := False;
      ToolButton5.Enabled := False;
    end;
    if Debug then SaveLog('UnitDataModuleSignal','Debug','Change into ST_REGISTING');
  end;
  ST_LOGINGON : begin
    FormMain.StatusBar.Panels[1].Text := 'LOGINGON';
    TimerTimeout.Enabled := True;
    with FormMain do begin
      Logon1.Enabled := False;
      Logoff1.Enabled := False;
      Call1.Enabled := False;
      Hangup1.Enabled := False;
      ToolButton1.Enabled := False;
      ToolButton2.Enabled := False;
      ToolButton4.Enabled := False;
      ToolButton5.Enabled := False;
    end;
    if Debug then SaveLog('UnitDataModuleSignal','Debug','Change into ST_LOGINGON');
  end;
  ST_FREE : begin
    if FormCall <> nil then begin
      FormCall.Close;
      FormCall.Free;
      FormCall := nil;
    end;
    FormMain.StatusBar.Panels[1].Text := 'FREE';
    with FormMain do begin
      Logon1.Enabled := False;
      Logoff1.Enabled := True;
      Call1.Enabled := True;
      Hangup1.Enabled := False;
      ToolButton1.Enabled := False;
      ToolButton2.Enabled := True;
      ToolButton4.Enabled := True;
      ToolButton5.Enabled := False;
    end;
    try
      IdTime.Host := ServerIP;
      IdTime.Port := 7373;
      TimeOffset := IdTime.DateTime - Now;
    except on E:Exception do
      SaveLog('UnitDataModuleSignal','Error','Sync time error :' + E.Message);
    end;
    if Debug then SaveLog('UnitDataModuleSignal','Debug','Change into ST_FREE');
  end;
  ST_CALLING : begin
    FormMain.StatusBar.Panels[1].Text := 'CALLING';
    TimerTimeout.Enabled := True;
    with FormMain do begin
      Logon1.Enabled := False;
      Logoff1.Enabled := False;
      Call1.Enabled := False;
      Hangup1.Enabled := False;
      ToolButton1.Enabled := False;
      ToolButton2.Enabled := False;
      ToolButton4.Enabled := False;
      ToolButton5.Enabled := False;
    end;
    if Debug then SaveLog('UnitDataModuleSignal','Debug','Change into ST_CALLING');
  end;
  ST_BUSY : begin
    LastVoiceSN := 0;
    FormMain.StatusBar.Panels[1].Text := 'BUSY';
    Application.CreateForm(TFormCall, FormCall);
    FormCall.Show;
    with FormMain do begin
      Logon1.Enabled := False;
      Logoff1.Enabled := False;
      Call1.Enabled := False;
      Hangup1.Enabled := True;
      ToolButton1.Enabled := False;
      ToolButton2.Enabled := False;
      ToolButton4.Enabled := False;
      ToolButton5.Enabled := True;
    end;
    if Debug then SaveLog('UnitDataModuleSignal','Debug','Change into ST_BUSY');
  end;
  ST_HANGING : begin
    FormCall.Close;
    FormCall.Free;
    FormCall := nil;
    FormMain.StatusBar.Panels[1].Text := 'HANGING';
    TimerTimeout.Enabled := True;
    with FormMain do begin
      Logon1.Enabled := False;
      Logoff1.Enabled := False;
      Call1.Enabled := False;
      Hangup1.Enabled := False;
      ToolButton1.Enabled := False;
      ToolButton2.Enabled := False;
      ToolButton4.Enabled := False;
      ToolButton5.Enabled := False;
    end;
    if Debug then SaveLog('UnitDataModuleSignal','Debug','Change into ST_HANGING');
  end;
  ST_LOGINGOFF : begin
    FormMain.StatusBar.Panels[1].Text := 'LOGINGOFF';
    TimerTimeout.Enabled := True;
    with FormMain do begin
      Logon1.Enabled := False;
      Logoff1.Enabled := False;
      Call1.Enabled := False;
      Hangup1.Enabled := False;
      ToolButton1.Enabled := False;
      ToolButton2.Enabled := False;
      ToolButton4.Enabled := False;
      ToolButton5.Enabled := False;
    end;
    if Debug then SaveLog('UnitDataModuleSignal','Debug','Change into ST_LOGINGOFF');
  end;
  else
    FormMain.StatusBar.Panels[1].Text := 'ERROR';
    ChangeStatus(ST_IDLE);
    with FormMain do begin
      Logon1.Enabled := True;
      Logoff1.Enabled := False;
      Call1.Enabled := False;
      Hangup1.Enabled := False;
      ToolButton1.Enabled := True;
      ToolButton2.Enabled := False;
      ToolButton4.Enabled := False;
      ToolButton5.Enabled := False;
    end;
    SaveLog('UnitDataModuleSignal','Error','Trying to change into a undefined status : ' + IntToStr(Status));
  end;
end;

procedure TDataModuleSignal.TimerTimeoutTimer(Sender: TObject);
begin
  Inc(TimerCount);
  case Status of
  ST_REGISTING : begin
    if TimerCount = 2 then begin
      ChangeStatus(ST_IDLE);
      if Debug then SaveLog('UnitDataModuleSignal','Debug','Registing Timeout.');
      TimerCount := 0;
      TimerTimeout.Enabled := False;
    end else begin
    end;
  end;
  ST_LOGINGON : begin
    if TimerCount = 10 then begin
      ChangeStatus(ST_IDLE);
      if Debug then SaveLog('UnitDataModuleSignal','Debug','Logon Timeout.');
      TimerCount := 0;
      TimerTimeout.Enabled := False;
    end else begin
      Logon;
    end;
  end;
  ST_LOGINGOFF : begin
    if TimerCount = 10 then begin
      ChangeStatus(ST_IDLE);
      if Debug then SaveLog('UnitDataModuleSignal','Debug','Logoff Timeout.');
      TimerCount := 0;
      TimerTimeout.Enabled := False;
    end else begin
      Logoff;
    end;
  end;
  ST_CALLING : begin
    if TimerCount = 30 then begin
      ChangeStatus(ST_FREE);
      if Debug then SaveLog('UnitDataModuleSignal','Debug','Call Timeout.');
      TimerCount := 0;
      TimerTimeout.Enabled := False;
    end else begin
    end;
  end;
  ST_HANGING : begin
    if TimerCount = 30 then begin
      ChangeStatus(ST_FREE);
      if Debug then SaveLog('UnitDataModuleSignal','Debug','Hangup Timeout.');
      TimerCount := 0;
      TimerTimeout.Enabled := False;
    end else begin
    end;
  end;
  else
  end;
end;

procedure TDataModuleSignal.DataModuleCreate(Sender: TObject);
var
  iRadioRegistry : TRegistry;
begin
  LocalIP := '0.0.0.0';
  LocalPort := 8873;
  iRadioRegistry := TRegistry.Create;
  try
    iRadioRegistry.RootKey := HKEY_CURRENT_USER;
    if iRadioRegistry.OpenKey('\Software\BD4JI\iRadio\',True) then begin
      try
        UserNumber := iRadioRegistry.ReadInteger('UserNumber');
        Move(iRadioRegistry.ReadString('UserName')[1],UserName,20);
        Move(iRadioRegistry.ReadString('Password')[1],Password,20);
        Move(iRadioRegistry.ReadString('ServerIP')[1],ServerIP,16);
        ServerPort := iRadioRegistry.ReadInteger('ServerPort');
      except
        ServerIP := 'leao.vicp.net';
        ServerPort := 7388;
        UserName := '';
        Password := '';
        if Trim(UserName) <> '' then begin
          iRadioRegistry.WriteInteger('UserNumber',UserNumber);
          iRadioRegistry.WriteString('UserName',UserName);
          iRadioRegistry.WriteString('Password',Password);
          iRadioRegistry.WriteString('ServerIP',ServerIP);
          iRadioRegistry.WriteInteger('ServerPort',ServerPort);
        end else begin
          exit;
        end;
      end;
    end;
  finally
    iRadioRegistry.Free;
  end;

  ChangeStatus(ST_IDLE);
end;

procedure TDataModuleSignal.DataModuleDestroy(Sender: TObject);
var
  iRadioRegistry : TRegistry;
begin
  iRadioRegistry := TRegistry.Create;
  try
    iRadioRegistry.RootKey := HKEY_CURRENT_USER;
    if iRadioRegistry.OpenKey('\Software\BD4JI\iRadio\',True) then
    begin
      iRadioRegistry.WriteInteger('UserNumber',UserNumber);
      iRadioRegistry.WriteString('UserName',UserName);
      iRadioRegistry.WriteString('Password',Password);
    end;
  finally
    iRadioRegistry.Free;
  end;

end;

procedure TDataModuleSignal.SetServer(SvrIP : String; SvrPort : integer);
begin
  Move(SvrIP[1],ServerIP,Length(SvrIP));
  ServerPort := SvrPort;
end;

function TDataModuleSignal.GetSN : integer;
begin
  GetSN := SendSN;
  Inc(SendSN);
end;

procedure TDataModuleSignal.UserRegist;
var
  PacketRegist : TPacketGeneral;
begin
  if Status = ST_IDLE then begin
    PacketRegist.FrameType := FT_REGIST;
    PacketRegist.SN := GetSN;
    Move(ServerIP,PacketRegist.DestIP,16);
    PacketRegist.DestPort := ServerPort;
    Move(LocalIP,PacketRegist.SourceIP,16);
    PacketRegist.SourcePort := LocalPort;

    Move(UserName[0],PacketRegist.UserName,20);
    Move(Password[0],PacketRegist.UserPassword,20);
    try
      UDP.SendBuffer(ServerIP,ServerPort,PacketRegist,sizeof(PacketRegist));
      ChangeStatus(ST_REGISTING);
    except
      on E:Exception do begin
        SaveLog('UnitDataModuleSignal','Error','UDP Socket error : ' + E.Message);
        ChangeStatus(ST_IDLE);
      end;
    end;
  end;
end;

procedure TDataModuleSignal.Logon;
var
  PacketLogon : TPacketGeneral;
begin
  if Status = ST_IDLE then begin
    if Trim(UserName) = '' then begin
      Application.CreateForm(TDialogUserInfo, DialogUserInfo);
      DialogUserInfo.ShowModal;
      DialogUserInfo.Free;
      if Trim(UserName) = '' then begin
        exit;
      end;
    end;
    PacketLogon.FrameType := FT_LOGON;
    PacketLogon.SN := GetSN;
    Move(ServerIP,PacketLogon.DestIP,16);
    PacketLogon.DestPort := ServerPort;
    Move(LocalIP,PacketLogon.SourceIP,16);
    PacketLogon.SourcePort := LocalPort;

    Move(UserName[0],PacketLogon.UserName,20);
    Move(Password[0],PacketLogon.UserPassword,20);
    try
      UDP.SendBuffer(ServerIP,ServerPort,PacketLogon,sizeof(PacketLogon));
      ChangeStatus(ST_LOGINGON);
    except on E:Exception do
      SaveLog('UnitDataModuleSignal','Error','UDP Socket error : ' + E.Message);
    end;
  end;
end;

procedure TDataModuleSignal.Logoff;
var
  PacketLogon : TPacketGeneral;
begin
  if Status <> ST_IDLE then begin
    PacketLogon.FrameType := FT_LOGOFF;
    PacketLogon.SN := GetSN;
    Move(ServerIP,PacketLogon.DestIP,16);
    PacketLogon.DestPort := ServerPort;
    Move(LocalIP,PacketLogon.SourceIP,16);
    PacketLogon.SourcePort := LocalPort;

    Move(UserName[0],PacketLogon.UserName,20);
    Move(Password[0],PacketLogon.UserPassword,20);
    try
      UDP.SendBuffer(ServerIP,ServerPort,PacketLogon,sizeof(PacketLogon));
      ChangeStatus(ST_LOGINGOFF);
    except on E:Exception do
      SaveLog('UnitDataModuleSignal','Error','UDP Socket error : ' + E.Message);
    end;
  end;
end;

procedure TDataModuleSignal.Call(DstNumber : integer ; DstName : String);
var
  PacketLogon : TPacketGeneral;
begin
  DestNumber := DstNumber;
  Move(DstName[1],DestName,Length(DstName));

  if Status = ST_FREE then begin
    PacketLogon.FrameType := FT_CALL;
    PacketLogon.SN := GetSN;

    PacketLogon.DestNumber := DstNumber;
    Move(ServerIP,PacketLogon.DestIP,16);
    PacketLogon.DestPort := ServerPort;

    PacketLogon.SourceNumber := UserNumber;
    Move(LocalIP,PacketLogon.SourceIP,16);
    PacketLogon.SourcePort := LocalPort;

    Move(UserName[0],PacketLogon.UserName,20);
    Move(Password[0],PacketLogon.UserPassword,20);
    try
      UDP.SendBuffer(ServerIP,ServerPort,PacketLogon,sizeof(PacketLogon));
      ChangeStatus(ST_CALLING);
    except on E:Exception do
      SaveLog('UnitDataModuleSignal','Error','UDP Socket error : ' + E.Message);
    end;
  end;
end;

procedure TDataModuleSignal.Hangup(DestNumber : integer);
var
  PacketLogon : TPacketGeneral;
begin
  if Status = ST_BUSY then begin
    PacketLogon.FrameType := FT_HANGUP;
    PacketLogon.SN := GetSN;

    PacketLogon.DestNumber := DestNumber;
    Move(ServerIP,PacketLogon.DestIP,16);
    PacketLogon.DestPort := ServerPort;

    PacketLogon.SourceNumber := UserNumber;
    Move(LocalIP,PacketLogon.SourceIP,16);
    PacketLogon.SourcePort := LocalPort;

    Move(UserName[0],PacketLogon.UserName,20);
    Move(Password[0],PacketLogon.UserPassword,20);
    try
      UDP.SendBuffer(ServerIP,ServerPort,PacketLogon,sizeof(PacketLogon));
      ChangeStatus(ST_HANGING);
    except on E:Exception do
      SaveLog('UnitDataModuleSignal','Error','UDP Socket error : ' + E.Message);
    end;
  end;
end;

procedure TDataModuleSignal.SendText(Txt : String);
var
  PacketText : TPacketText;
  i : integer;
begin
  if Status = ST_BUSY then begin
    PacketText.FrameType := FT_TEXT;
    PacketText.SN := GetSN;

    PacketText.DestNumber := DestNumber;

    PacketText.SourceNumber := UserNumber;

    PacketText.TimeStamp := Now + TimeOffset;

    Move(Txt[1],PacketText.TextData,Length(Txt));
    for i := Length(Txt) to TEXTDATASIZE do PacketText.TextData[i] := ' ';
    PacketText.Checksum := 0;
    try
      UDP.SendBuffer(ServerIP,ServerPort,PacketText,sizeof(PacketText));
    except on E:Exception do
      SaveLog('UnitDataModuleSignal','Error','UDP Socket error : ' + E.Message);
    end;
  end;
end;

procedure TDataModuleSignal.BroadcastText(Txt : String);
var
  PacketText : TPacketText;
  i : integer;
begin
  if Status <> ST_IDLE then begin
    PacketText.FrameType := FT_BROADCAST;
    PacketText.SN := GetSN;

    PacketText.DestNumber := 0;

    PacketText.SourceNumber := UserNumber;

    PacketText.TimeStamp := Now + TimeOffset;

    Move(Txt[1],PacketText.TextData,Length(Txt));
    for i := Length(Txt) to TEXTDATASIZE do PacketText.TextData[i] := ' ';
    PacketText.Checksum := 0;
    try
      UDP.SendBuffer(ServerIP,ServerPort,PacketText,sizeof(PacketText));
    except on E:Exception do
      SaveLog('UnitDataModuleSignal','Error','UDP Socket error : ' + E.Message);
    end;
  end;
end;

procedure TDataModuleSignal.SendVoice(Vdata : Pointer ; Sz : integer);
var
  PacketVoice : TPacketVoice;
begin
  if Status = ST_BUSY then begin
    if Sz <> VOICEDATASIZE+1 then begin
      SaveLog('UnitDataModuleSignal','Error','Incorrect size voice buffer data trying to be send, size :'+IntToStr(Sz));
      exit;
    end;

    PacketVoice.FrameType := FT_VOICE;
    PacketVoice.SN := GetSN;

    PacketVoice.DestNumber := DestNumber;
    PacketVoice.SourceNumber := UserNumber;

    PacketVoice.TimeStamp := Now + TimeOffset;

    Move(Vdata^,PacketVoice.VoiceData,Sz);
    try
      if FormMain.ViaServer1.Checked then begin
        UDP.SendBuffer(ServerIP,ServerPort,PacketVoice, SizeOf(PacketVoice));
      end else begin
        UDP.SendBuffer(DestIP,DestPort,PacketVoice, SizeOf(PacketVoice));
      end;
    except on E:Exception do
      SaveLog('UnitDataModuleSignal','Error','UDP Socket error : ' + E.Message);
    end;
  end;
end;

procedure TDataModuleSignal.UDPUDPRead(Sender: TObject; AData: TStream;
  ABinding: TIdSocketHandle);
var
  ReceivedStream : TMemoryStream;
  ReceivedString : String;
  TempByte       : byte;
  FrameType : byte;
  PacketGeneral : TPacketGeneral;
  PacketAck : TPacketAck;
  PacketPoll : TPacketPoll;
  PacketVoice : TPacketVoice;
  PacketText : TPacketText;
  i : integer;
  DestNotOnline : Boolean;
  VoiceDelay : TDateTime;
begin

  ReceivedStream := TMemoryStream.Create;
  ReceivedStream.LoadFromStream(AData);
  if SAVEPACKET then begin
    ReceivedString := '';
    for i := 0 to ReceivedStream.Size-1 do begin
      ReceivedStream.ReadBuffer(TempByte,1);
      ReceivedString := ReceivedString + IntToHex(TempByte,2) + ' ';
    end;
    SaveLog('UnitDataModuleSignal','Debug',ABinding.PeerIP + ':' + IntToStr(ABinding.PeerPort) + ' --> ' + ReceivedString);
  end;
  ReceivedStream.Seek(0,0);
  ReceivedStream.ReadBuffer(FrameType,1);
  case FrameType of

//---------------------------------------------------------------------------------------------------------------------------------------------------
  FT_REGISTACK: begin
    if Status <> ST_REGISTING then begin
      SaveLog('UnitDataModuleSignal','Error','Unexpected RegistAck packet received.');
      ReceivedStream.Free;
      exit;
    end;

    if ReceivedStream.Size <> Sizeof(PacketAck) then begin
      SaveLog('UnitDataModuleSignal','Error','Incorrected length RegistAck packet received.');
      ReceivedStream.Free;
      exit;
    end;

    ReceivedStream.Seek(0,0);
    ReceivedStream.ReadBuffer(PacketAck,ReceivedStream.Size);
    ReceivedStream.Free;

    Move(ABinding.PeerIP[1],ServerIP,Length(ABinding.PeerIP));
    for i := Length(ABinding.PeerIP) to 15 do begin
      ServerIP[i] := ' ';
    end;

    case PacketAck.AckCode of
    ACK_OK : begin
      ChangeStatus(ST_IDLE);
      UserNumber := PacketAck.DestNumber;
      Move(PacketAck.DestIP,LocalIP,16);
      LocalPort := PacketAck.DestPort;
      FormMain.StatusBar.Panels[0].Text := 'Offline';
      Application.MessageBox('Regist OK!','Hi',MB_OK);
    end;
    ACK_DUPUSER : begin
      ChangeStatus(ST_IDLE);
      SaveLog('UnitDataModuleSignal','Error','This username has been registered by another user.');
      Application.MessageBox('This username has been registered by another user!' , 'Error');
    end;
    ACK_ERR : begin
      ChangeStatus(ST_IDLE);
      SaveLog('UnitDataModuleSignal','Error','Server Error.');
      Application.MessageBox('Server Error!' , 'Error');
    end;
    else
      SaveLog('UnitDataModuleSignal','Error','Error AckCode LogonAck packet received, AckCode : ' + IntToStr(PacketAck.AckCode));
    end;
  end;

//---------------------------------------------------------------------------------------------------------------------------------------------------
  FT_LOGONACK: begin
    if Status <> ST_LOGINGON then begin
      SaveLog('UnitDataModuleSignal','Error','Unexpected LogonAck packet received.');
      ReceivedStream.Free;
      exit;
    end;

    if ReceivedStream.Size <> Sizeof(PacketAck) then begin
      SaveLog('UnitDataModuleSignal','Error','Incorrected length LogonAck packet received.');
      ReceivedStream.Free;
      exit;
    end;

    ReceivedStream.Seek(0,0);
    ReceivedStream.ReadBuffer(PacketAck,ReceivedStream.Size);
    ReceivedStream.Free;
{
    Move(ABinding.PeerIP[1],ServerIP,Length(ABinding.PeerIP));
    for i := Length(ABinding.PeerIP) to 15 do begin
      ServerIP[i] := ' ';
    end;
 }
    case PacketAck.AckCode of
    ACK_OK : begin
      ChangeStatus(ST_FREE);
      UserNumber := PacketAck.DestNumber;
      Move(PacketAck.DestIP,LocalIP,16);
      LocalPort := PacketAck.DestPort;

      FormMain.Caption := 'iRadio - ' + Trim(UserName);
      FormMain.StatusBar.Panels[0].Text := 'Online';
    end;
    ACK_NOUSER : begin
      ChangeStatus(ST_IDLE);
      SaveLog('UnitDataModuleSignal','Error','Not a registered user.');
      Application.MessageBox('Not a registered user!' , 'Error');
    end;
    ACK_PASSERR : begin
      ChangeStatus(ST_IDLE);
      SaveLog('UnitDataModuleSignal','Error','Password Error.');
      Application.MessageBox('Password Error!' , 'Error');
    end;
    ACK_ERR : begin
      ChangeStatus(ST_IDLE);
      SaveLog('UnitDataModuleSignal','Error','Server Error.');
      Application.MessageBox('Server Error!' , 'Error');
    end;
    else
      SaveLog('UnitDataModuleSignal','Error','Error AckCode LogonAck packet received, AckCode : ' + IntToStr(PacketAck.AckCode));
    end;
  end;

//---------------------------------------------------------------------------------------------------------------------------------------------------
  FT_LOGOFFACK: begin
    if Status <> ST_LOGINGOFF then begin
      SaveLog('UnitDataModuleSignal','Error','Unexpected LogoffAck packet received.');
      ReceivedStream.Free;
      exit;
    end;

    if ReceivedStream.Size <> Sizeof(PacketAck) then begin
      SaveLog('UnitDataModuleSignal','Error','Incorrected length LogoffAck packet received.');
      ReceivedStream.Free;
      exit;
    end;

    ReceivedStream.Seek(0,0);
    ReceivedStream.ReadBuffer(PacketAck,ReceivedStream.Size);
    ReceivedStream.Free;

    case PacketAck.AckCode of
    ACK_OK : begin
      ChangeStatus(ST_IDLE);

      FormMain.Caption := 'iRadio';
      FormMain.StatusBar.Panels[0].Text := 'Offline';
    end;
    ACK_NOUSER : begin
      ChangeStatus(ST_IDLE);
      SaveLog('UnitDataModuleSignal','Error','Not a registered user.');
      Application.MessageBox('Not a registered user!' , 'Error');
    end;
    ACK_PASSERR : begin
      ChangeStatus(ST_IDLE);
      SaveLog('UnitDataModuleSignal','Error','Password Error.');
      Application.MessageBox('Password Error!' , 'Error');
    end;
    ACK_ERR : begin
      ChangeStatus(ST_IDLE);
      SaveLog('UnitDataModuleSignal','Error','Server Error.');
      Application.MessageBox('Server Error!' , 'Error');
    end;
    else
      SaveLog('UnitDataModuleSignal','Error','Error AckCode LogoffAck packet received, AckCode : ' + IntToStr(PacketAck.AckCode));
    end;
  end;

//---------------------------------------------------------------------------------------------------------------------------------------------------
  FT_CALL : begin
    if ReceivedStream.Size <> Sizeof(PacketGeneral) then begin
      SaveLog('UnitDataModuleSignal','Error','Incorrected length Call packet received.');
      ReceivedStream.Free;
      exit;
    end;

    ReceivedStream.Seek(0,0);
    ReceivedStream.ReadBuffer(PacketGeneral,ReceivedStream.Size);
    ReceivedStream.Free;
    if Status <> ST_FREE then begin
      if Debug then SaveLog('UnitDataModuleSignal','Debug','Called in busy status.');
      with PacketAck do begin
        FrameType := FT_CALLACK;
        SN := GetSN;
        DestNumber := PacketGeneral.SourceNumber;
        Move(PacketGeneral.SourceIP,DestIP,16);
        DestPort := PacketGeneral.SourcePort;
        SourceNumber := UserNumber;
        Move(LocalIP,SourceIP,16);
        SourcePort := LocalPort;
        AckSN := PacketGeneral.SN;
        AckCode := ACK_REJECT;
        Checksum := 0;
      end;
      try
        UDP.SendBuffer(ServerIP,ServerPort,PacketAck,SizeOf(PacketAck));
      except on E:Exception do
        SaveLog('UnitDataModuleSignal','Error','UDP Socket error : ' + E.Message);
      end;
    end else begin
      if Application.MessageBox(Pchar(Trim(PacketGeneral.UserName)+' Calling you.') , 'Hi' , MB_YESNO) = ID_YES then begin
        DestNumber := PacketGeneral.SourceNumber;
        Move(PacketGeneral.UserName,DestName,20);
        Move(PacketGeneral.SourceIP,DestIP,16);
        DestPort := PacketGeneral.SourcePort;
        with PacketAck do begin
          FrameType := FT_CALLACK;
          SN := GetSN;
          DestNumber := PacketGeneral.SourceNumber;
          Move(PacketGeneral.SourceIP,DestIP,16);
          DestPort := PacketGeneral.SourcePort;
          SourceNumber := UserNumber;
          Move(LocalIP,SourceIP,16);
          SourcePort := LocalPort;
          AckSN := PacketGeneral.SN;
          AckCode := ACK_OK;
          Checksum := 0;
        end;
        try
          UDP.SendBuffer(ServerIP,ServerPort,PacketAck,SizeOf(PacketAck));
        except on E:Exception do
          SaveLog('UnitDataModuleSignal','Error','UDP Socket error : ' + E.Message);
        end;
        ChangeStatus(ST_BUSY);
        if Debug then SaveLog('UnitDataModuleSignal','Debug','Accept call from '+ PacketGeneral.UserName);
      end else begin
        if Debug then SaveLog('UnitDataModuleSignal','Debug','Reject call from '+ PacketGeneral.UserName);
        with PacketAck do begin
          FrameType := FT_CALLACK;
          SN := GetSN;
          DestNumber := PacketGeneral.SourceNumber;
          Move(PacketGeneral.SourceIP,DestIP,16);
          DestPort := PacketGeneral.SourcePort;
          SourceNumber := UserNumber;
          Move(LocalIP,SourceIP,16);
          SourcePort := LocalPort;
          AckSN := PacketGeneral.SN;
          AckCode := ACK_REJECT;
          Checksum := 0;
        end;
        try
          UDP.SendBuffer(ServerIP,ServerPort,PacketAck,SizeOf(PacketAck));
        except on E:Exception do
          SaveLog('UnitDataModuleSignal','Error','UDP Socket error : ' + E.Message);
        end;
      end;
    end;
  end;

//---------------------------------------------------------------------------------------------------------------------------------------------------
  FT_CALLACK: begin
    if Status <> ST_CALLING then begin
      SaveLog('UnitDataModuleSignal','Error','Unexpected CallAck packet received.');
      ReceivedStream.Free;
      exit;
    end;

    if ReceivedStream.Size <> Sizeof(PacketAck) then begin
      SaveLog('UnitDataModuleSignal','Error','Incorrected length CallAck packet received.');
      ReceivedStream.Free;
      exit;
    end;

    ReceivedStream.Seek(0,0);
    ReceivedStream.ReadBuffer(PacketAck,ReceivedStream.Size);
    ReceivedStream.Free;
    case PacketAck.AckCode of
    ACK_OK : begin
      ChangeStatus(ST_BUSY);

      Move(PacketAck.SourceIP,DestIP,16);;
      DestPort := PacketAck.SourcePort;
      FormMain.StatusBar.Panels[0].Text := 'Connected';
      if Debug then SaveLog('UnitDataModuleSignal','Debug','Call Connected.');
    end;
    ACK_REJECT : begin
      ChangeStatus(ST_FREE);
      Application.MessageBox('Call Recected.!' , 'Hi');
      if Debug then SaveLog('UnitDataModuleSignal','Debug','Call Recected.');
    end;
    ACK_USROFFLINE : begin
      ChangeStatus(ST_FREE);
      Application.MessageBox('User is now offline.!' , 'Hi');
      if Debug then SaveLog('UnitDataModuleSignal','Debug','User is now offline.');
    end;

    ACK_ERR : begin
      ChangeStatus(ST_IDLE);
      SaveLog('UnitDataModuleSignal','Error','Server Error.');
      Application.MessageBox('Server Error!' , 'Error');
    end;
    else
      SaveLog('UnitDataModuleSignal','Error','Error AckCode LogoffAck packet received, AckCode : ' + IntToStr(PacketAck.AckCode));
    end;
  end;

//---------------------------------------------------------------------------------------------------------------------------------------------------
  FT_HANGUP : begin
    if ReceivedStream.Size <> Sizeof(PacketGeneral) then begin
      SaveLog('UnitDataModuleSignal','Error','Incorrected length Hangup packet received.');
      ReceivedStream.Free;
      exit;
    end;

    ReceivedStream.Seek(0,0);
    ReceivedStream.ReadBuffer(PacketGeneral,ReceivedStream.Size);
    ReceivedStream.Free;
    if Status <> ST_BUSY then begin
      if Debug then SaveLog('UnitDataModuleSignal','Debug','Be Hanged but not in busy status.');
      with PacketAck do begin
        FrameType := FT_HANGUPACK;
        SN := GetSN;
        DestNumber := PacketGeneral.SourceNumber;
        Move(PacketGeneral.SourceIP,DestIP,16);
        DestPort := PacketGeneral.SourcePort;
        SourceNumber := UserNumber;
        Move(LocalIP,SourceIP,16);
        SourcePort := LocalPort;
        AckSN := PacketGeneral.SN;
        AckCode := ACK_REJECT;
        Checksum := 0;
      end;
      try
        UDP.SendBuffer(ServerIP,ServerPort,PacketAck,SizeOf(PacketAck));
      except on E:Exception do
        SaveLog('UnitDataModuleSignal','Error','UDP Socket error : ' + E.Message);
      end;
    end else begin
      Application.MessageBox(Pchar(Trim(PacketGeneral.UserName)+' Hangup.') , 'Hi' , MB_OK);
      DestNumber := PacketGeneral.SourceNumber;
      Move(PacketGeneral.SourceIP,DestIP,16);
      DestPort := PacketGeneral.SourcePort;
      with PacketAck do begin
        FrameType := FT_HANGUPACK;
        SN := GetSN;
        DestNumber := PacketGeneral.SourceNumber;
        Move(PacketGeneral.SourceIP,DestIP,16);
        DestPort := PacketGeneral.SourcePort;
        SourceNumber := UserNumber;
        Move(LocalIP,SourceIP,16);
        SourcePort := LocalPort;
        AckSN := PacketGeneral.SN;
        AckCode := ACK_OK;
        Checksum := 0;
      end;
      try
        UDP.SendBuffer(ServerIP,ServerPort,PacketAck,SizeOf(PacketAck));
      except on E:Exception do
        SaveLog('UnitDataModuleSignal','Error','UDP Socket error : ' + E.Message);
      end;
      ChangeStatus(ST_HANGING);
      ChangeStatus(ST_FREE);
      if Debug then SaveLog('UnitDataModuleSignal','Debug','Accept Hangup from '+ PacketGeneral.UserName);
    end;
  end;

//---------------------------------------------------------------------------------------------------------------------------------------------------
  FT_HANGUPACK : begin
    if ReceivedStream.Size <> Sizeof(PacketAck) then begin
      SaveLog('UnitDataModuleSignal','Error','Incorrected length HangupAck packet received.');
      ReceivedStream.Free;
      exit;
    end;

    ReceivedStream.Seek(0,0);
    ReceivedStream.ReadBuffer(PacketAck,ReceivedStream.Size);
    ReceivedStream.Free;
    if Status <> ST_HANGING then begin
      if Debug then SaveLog('UnitDataModuleSignal','Debug','Be Hanged but not in busy status.');
    end else begin
      if PacketAck.AckCode <> ACK_OK then begin
        if Debug then SaveLog('UnitDataModuleSignal','Debug','Error HangupAck AckCode received :' + IntToStr(PacketAck.AckCode));
      end else begin
        ChangeStatus(ST_FREE);
      end;
    end;
  end;

//---------------------------------------------------------------------------------------------------------------------------------------------------
  FT_POLL : begin
    if ReceivedStream.Size <> Sizeof(PacketPoll) then begin
      SaveLog('UnitDataModuleSignal','Error','Incorrected length Poll packet received.');
      ReceivedStream.Free;
      exit;
    end;

    if Status = ST_IDLE then begin
      ReceivedStream.Free;
      ReceivedStream.Free;
      exit;
    end;

    ReceivedStream.Seek(0,0);
    ReceivedStream.ReadBuffer(PacketPoll,ReceivedStream.Size);
    ReceivedStream.Free;
    Move(PacketPoll.UserList,OnlineUser,SizeOf(OnlineUser));
    if ((Status = ST_CALLING) or (Status = ST_HANGING) or (Status = ST_BUSY)) then begin
      DestNotOnline := True;
      for i := 0 to MAXUSER do begin
        if DestNumber = PacketPoll.UserList[i].UserNumber then begin
          DestNotOnline := False;
        end;
      end;
      if DestNotOnline then begin
        Application.MessageBox(Pchar(Trim(DestName)+' Offline.') , 'Hi' , MB_OK);
        ChangeStatus(ST_FREE);
      end;
    end;
    
    FormMain.RefreshTreeView;

    with PacketAck do begin
      FrameType := FT_POLLACK;
      SN := GetSN;
      DestNumber := 0;
      Move(ServerIP,DestIP,16);
      DestPort := ServerPort;

      SourceNumber := UserNumber;
      Move(LocalIP,SourceIP,16);
      SourcePort := LocalPort;
      MeetingID := 0;
      AckSN := PacketPoll.SN;
      AckCode := Status;
      CheckSum := 0;
    end;
    try
      UDP.SendBuffer(ServerIP,ServerPort,PacketAck,SizeOf(PacketAck));
      ServerPoll := 0;
    except on E:Exception do
      SaveLog('UnitDataModuleSignal','Error','UDP Socket error : ' + E.Message);
    end;
  end;

//---------------------------------------------------------------------------------------------------------------------------------------------------
  FT_TEXT : begin
    if ReceivedStream.Size <> Sizeof(PacketText) then begin
      SaveLog('UnitDataModuleSignal','Error','Incorrected length Text packet received.');
      ReceivedStream.Free;
      exit;
    end;

    ReceivedStream.Seek(0,0);
    ReceivedStream.ReadBuffer(PacketText,ReceivedStream.Size);
    ReceivedStream.Free;
    if FormCall <> nil then FormCall.AddDisplayMessage(DestName,PacketText.TextData);
    with PacketAck do begin
      FrameType := FT_TEXTACK;
      SN := GetSN;
      DestNumber := PacketText.SourceNumber;
      Move(ServerIP,DestIP,16);
      DestPort := ServerPort;

      SourceNumber := UserNumber;
      Move(LocalIP,SourceIP,16);
      SourcePort := LocalPort;
      MeetingID := 0;
      AckSN := PacketPoll.SN;
      AckCode := ACK_OK;
      CheckSum := 0;
    end;
    try
      UDP.SendBuffer(ServerIP,ServerPort,PacketAck,SizeOf(PacketAck));
    except on E:Exception do
      SaveLog('UnitDataModuleSignal','Error','UDP Socket error : ' + E.Message);
    end;
  end;

//---------------------------------------------------------------------------------------------------------------------------------------------------
  FT_TEXTACK : begin
    if ReceivedStream.Size <> Sizeof(PacketAck) then begin
      SaveLog('UnitDataModuleSignal','Error','Incorrected length TextAck packet received.');
      ReceivedStream.Free;
      exit;
    end;

    ReceivedStream.Seek(0,0);
    ReceivedStream.ReadBuffer(PacketAck,ReceivedStream.Size);
    ReceivedStream.Free;
  end;

//---------------------------------------------------------------------------------------------------------------------------------------------------
  FT_VOICE : begin
    if ReceivedStream.Size <> Sizeof(PacketVoice) then begin
      SaveLog('UnitDataModuleSignal','Error','Incorrected length Voice packet received.');
      ReceivedStream.Free;
      exit;
    end;

    ReceivedStream.Seek(0,0);
    ReceivedStream.ReadBuffer(PacketVoice,ReceivedStream.Size);
    ReceivedStream.Free;
    if FormCall <> nil then begin
      if (PacketVoice.SN > LastVoiceSN) then begin
        VoiceDelay := PacketVoice.TimeStamp - Now - TimeOffset;
        if (VoiceDelay * 24 * 60 * 60 <= 5) then begin
          FormCall.StatusBar.Panels[2].Text := FormatDateTime('"Voice Delay : "z"ms"',VoiceDelay);
          FormCall.Play(@PacketVoice.VoiceData,SizeOf(PacketVoice.VoiceData));
        end;
        LastVoiceSN := PacketVoice.SN;
      end;
    end;
  end;

//---------------------------------------------------------------------------------------------------------------------------------------------------
  FT_BROADCAST : begin
    if ReceivedStream.Size <> Sizeof(PacketText) then begin
      SaveLog('UnitDataModuleSignal','Error','Incorrected length Broadcast packet received.');
      ReceivedStream.Free;
      exit;
    end;

    ReceivedStream.Seek(0,0);
    ReceivedStream.ReadBuffer(PacketText,ReceivedStream.Size);
    ReceivedStream.Free;
    FormMain.RichEditBroadcast.Lines.Add(Trim(PacketText.TextData));
  end;

//---------------------------------------------------------------------------------------------------------------------------------------------------
  else
    ReceivedStream.Free;
    SaveLog('UnitDataModuleSignal','Error','Error type packet received, type:'+ IntToStr(FrameType));
  end;
end;

procedure TDataModuleSignal.TimerPollTimer(Sender: TObject);
begin
  if Status <> ST_IDLE then begin
    if ServerPoll > 30 then begin
      ChangeStatus(ST_IDLE);
      ServerPoll := 0;
    end else begin
      Inc(ServerPoll);
    end;
  end else begin
    ServerPoll := 0;
  end;
end;

end.
