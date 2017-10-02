unit UnitServiceiServer;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, SvcMgr, Dialogs,
  Sockets, ExtCtrls, IdBaseComponent, IdComponent, IdUDPBase, IdUDPServer,
  IdAntiFreezeBase, IdAntiFreeze, IdSocketHandle, IdTimeUDPServer,
  IdTCPServer, IdTimeServer;

type

  TServiceiServer = class(TService)
    TimerPoll: TTimer;
    UDP: TIdUDPServer;
    IdTimeServer: TIdTimeServer;
    procedure ServiceStart(Sender: TService; var Started: Boolean);
    procedure ServiceStop(Sender: TService; var Stopped: Boolean);
    procedure ServicePause(Sender: TService; var Paused: Boolean);
    procedure UDPUDPRead(Sender: TObject; AData: TStream; ABinding: TIdSocketHandle);
    procedure TimerPollTimer(Sender: TObject);
  private
    { Private declarations }
    SendSN : integer;
    LocalIP    : array [0..15] of char;
    LocalPort  : integer;
    function GetSN : integer;
  public
    function GetServiceController: TServiceController; override;
    { Public declarations }
  end;

var
  ServiceiServer: TServiceiServer;

implementation

uses UnitDataModuleDatabase, UnitDefinations;

{$R *.DFM}

procedure ServiceController(CtrlCode: DWord); stdcall;
begin
  ServiceiServer.Controller(CtrlCode);
end;

function TServiceiServer.GetServiceController: TServiceController;
begin
  Result := ServiceController;
end;

function TServiceiServer.GetSN : integer;
begin
  GetSN := SendSN;
  Inc(SendSN);
end;
procedure TServiceiServer.ServiceStart(Sender: TService;
  var Started: Boolean);
begin
  SendSN := 0;
  DataModuleDatabase.SaveLog('UnitServiceiServer','Message','iRadio Server Service started.');
end;

procedure TServiceiServer.ServiceStop(Sender: TService;
  var Stopped: Boolean);
begin
  DataModuleDatabase.SaveLog('UnitServiceiServer','Message','iRadio Server Service stoped.');
end;

procedure TServiceiServer.ServicePause(Sender: TService;
  var Paused: Boolean);
begin
  if Paused then
    DataModuleDatabase.SaveLog('UnitServiceiServer','Message','iRadio Server Service paused.');
end;

procedure TServiceiServer.UDPUDPRead(Sender: TObject; AData: TStream;
  ABinding: TIdSocketHandle);
var
  ReceivedStream : TMemoryStream;
  ReceivedString : String;
  TempByte       : byte;
  FrameType : byte;
  PacketGeneral : TPacketGeneral;
  PacketAck : TPacketAck;
  PacketVoice : TPacketVoice;
  PacketText : TPacketText;
  UserNumber : Integer;
  i : integer;
begin
  ReceivedStream := TMemoryStream.Create;
  ReceivedStream.LoadFromStream(AData);
  if SAVEPACKET then begin
    ReceivedString := '';
    for i := 0 to ReceivedStream.Size-1 do begin
      ReceivedStream.ReadBuffer(TempByte,1);
      ReceivedString := ReceivedString + IntToHex(TempByte,2) + ' ';
    end;
    DataModuleDatabase.SaveLog('UnitServiceiServer','Debug',ABinding.PeerIP + ':' + IntToStr(ABinding.PeerPort) + ' --> ' + ReceivedString);
  end;
  ReceivedStream.Seek(0,0);
  ReceivedStream.ReadBuffer(FrameType,1);
  case FrameType of

//---------------------------------------------------------------------------------------------------------------------------------------------------
  FT_REGIST: begin
    if ReceivedStream.Size <> Sizeof(PacketGeneral) then begin
      DataModuleDatabase.SaveLog('UnitServiceiServer','Error','Incorrected length Regist packet received.');
      ReceivedStream.Free;
      exit;
    end;
    ReceivedStream.Seek(0,0);
    ReceivedStream.ReadBuffer(PacketGeneral,ReceivedStream.Size);
    ReceivedStream.Free;
    try
      Move(PacketGeneral.DestIP,LocalIP,16);
      LocalPort := PacketGeneral.DestPort;

      PacketAck.FrameType := FT_REGISTACK;
      PacketAck.SN := GetSN;

      PacketAck.SourceNumber := 0;
      Move(LocalIP,PacketAck.SourceIP,16);
      PacketAck.SourcePort := LocalPort;

      Move(ABinding.PeerIP[1],PacketAck.DestIP,Length(ABinding.PeerIP));
      PacketAck.DestPort := ABinding.PeerPort;

      PacketAck.AckSN := PacketGeneral.SN;
      PacketAck.MeetingID := 0;
      PacketAck.Checksum := 0;
      PacketAck.AckCode := ACK_ERR;

      try
        with DataModuleDatabase.SQLQueryUserInfo do begin
          Close;
          SQL.Clear;
          SQL.Add('Select * from iRadioUserInfo where "UserName" = :UserName');
          Params.ParamByName('UserName').AsString := PacketGeneral.UserName;
          Open;
        end;
      except on E:Exception do
        DataModuleDatabase.SaveLog('UnitServiceiServer','Debug',E.Message);
      end;

      if not DataModuleDatabase.SQLQueryUserInfo.Eof then begin
          PacketAck.AckCode := ACK_DUPUSER;
      end else begin
        with DataModuleDatabase.SQLQueryUserInfo do begin
          Close;
          SQL.Clear;
          SQL.Add('insert into iRadioUserInfo ("UserName","Password") values (:UserName,:Password)');
          Params.ParamByName('UserName').AsString := PacketGeneral.UserName;
          Params.ParamByName('Password').AsString := PacketGeneral.UserPassword;
          ExecSQL(false);
        end;
        PacketAck.AckCode := ACK_OK;
        if DEBUG then DataModuleDatabase.SaveLog('UnitServiceiServer','Debug',Trim(PacketGeneral.UserName)+' Registerd OK.');
      end;
    finally
      DataModuleDatabase.SQLQueryUserInfo.Close;
      UDP.SendBuffer(ABinding.PeerIP,ABinding.PeerPort,PacketAck,Sizeof(PacketAck));
    end;
  end;

//---------------------------------------------------------------------------------------------------------------------------------------------------
  FT_LOGON: begin
    if ReceivedStream.Size <> Sizeof(PacketGeneral) then begin
      DataModuleDatabase.SaveLog('UnitServiceiServer','Error','Incorrected length Logon packet received.');
      ReceivedStream.Free;
      exit;
    end;
    ReceivedStream.Seek(0,0);
    ReceivedStream.ReadBuffer(PacketGeneral,ReceivedStream.Size);
    ReceivedStream.Free;
    try
      Move(PacketGeneral.DestIP,LocalIP,16);
      LocalPort := PacketGeneral.DestPort;

      PacketAck.FrameType := FT_LOGONACK;
      PacketAck.SN := GetSN;

      PacketAck.SourceNumber := 0;
      Move(LocalIP,PacketAck.SourceIP,16);
      PacketAck.SourcePort := LocalPort;

      Move(ABinding.PeerIP[1],PacketAck.DestIP,Length(ABinding.PeerIP));
      PacketAck.DestPort := ABinding.PeerPort;

      PacketAck.AckSN := PacketGeneral.SN;
      PacketAck.MeetingID := 0;
      PacketAck.Checksum := 0;
      PacketAck.AckCode := ACK_ERR;

      try
        with DataModuleDatabase.SQLQueryUserInfo do begin
          Close;
          SQL.Clear;
          SQL.Add('Select * from iRadioUserInfo where "UserName" = :UserName');
          Params.ParamByName('UserName').AsString := PacketGeneral.UserName;
          Open;
        end;
      except on E:Exception do
        DataModuleDatabase.SaveLog('UnitServiceiServer','Debug',E.Message);
      end;

      if not DataModuleDatabase.SQLQueryUserInfo.Eof then begin
        if (DataModuleDatabase.SQLQueryUserInfo.FieldByName('Password').AsString = PacketGeneral.UserPassword) then begin
          UserNumber := DataModuleDatabase.SQLQueryUserInfo.FieldByName('UserNumber').AsInteger;
          PacketAck.DestNumber := UserNumber;
          PacketAck.AckCode := ACK_OK;
          try
            with DataModuleDatabase.SQLQueryUserInfo do begin
              Close;
              SQL.Clear;
              SQL.Add('update iRadioUserInfo set "LastLogonTime" = :LastLogonTime , "LastIP" = :LastIP , "LastPort" = :LastPort where "UserNumber" = :UserNumber');
              Params.ParamByName('UserNumber').AsInteger := UserNumber;
              Params.ParamByName('LastLogonTime').AsString := DateTimeToStr(Now);
              Params.ParamByName('LastIP').AsString := ABinding.PeerIP;
              Params.ParamByName('LastPort').AsInteger := ABinding.PeerPort;
              ExecSQL(false);
            end;
            with DataModuleDatabase.SQLQueryOnlineUser do begin
              Close;
              SQL.Clear;
              SQL.Add('if ((select count(*) from iRadioOnlineUser where "UserNumber" = '+IntToStr(UserNumber)+') > 0) begin ');
              SQL.Add('  update iRadioOnlineUser set "UserName" = ''' +PacketGeneral.UserName+ ''', "UserIP" = '''+ABinding.PeerIP+''' , "UserPort" = '+IntToStr(ABinding.PeerPort)+' , "UserStatus" = '+IntToStr(ST_FREE)+' , "MeetingID" = 0 , "KillTimer" = '+IntToStr(MAXKILLTIME)+' where "UserNumber" = '+IntToStr(UserNumber)+' ');
              SQL.Add('end else begin ');
              SQL.Add('  insert into iRadioOnlineUser (UserNumber , UserName, UserIP , UserPort , UserStatus , MeetingID , KillTimer) VALUES ('+IntToStr(UserNumber)+' , ''' + PacketGeneral.UserName + ''','''+ABinding.PeerIP+''' , '+IntToStr(ABinding.PeerPort)+' , '+IntToStr(ST_FREE)+' , 0 , '+IntToStr(MAXKILLTIME)+') ');
              SQL.Add('end');
              ExecSQL(false);
            end;
          except on E:Exception do
            DataModuleDatabase.SaveLog('UnitServiceiServer','Debug',E.Message);
          end;
          if DEBUG then DataModuleDatabase.SaveLog('UnitServiceiServer','Debug',Trim(PacketGeneral.UserName)+' Logon OK.');
        end else begin
          if DEBUG then DataModuleDatabase.SaveLog('UnitServiceiServer','Debug',Trim(PacketGeneral.UserName)+' Logon Password Error.');
          PacketAck.AckCode := ACK_PASSERR;
        end;
      end else begin
        if DEBUG then DataModuleDatabase.SaveLog('UnitServiceiServer','Debug',Trim(PacketGeneral.UserName)+' Trying to logon but not find in User database.');
        PacketAck.AckCode := ACK_NOUSER;
      end;
    finally
      DataModuleDatabase.SQLQueryUserInfo.Close;
      DataModuleDatabase.SQLQueryOnlineUser.Close;
      UDP.SendBuffer(ABinding.PeerIP,ABinding.PeerPort,PacketAck,Sizeof(PacketAck));
    end;
  end;

//---------------------------------------------------------------------------------------------------------------------------------------------------
  FT_LOGOFF: begin
    if ReceivedStream.Size <> Sizeof(PacketGeneral) then begin
      DataModuleDatabase.SaveLog('UnitServiceiServer','Error','Incorrected length Logon packet received.');
      ReceivedStream.Free;
      exit;
    end;
    ReceivedStream.Seek(0,0);
    ReceivedStream.ReadBuffer(PacketGeneral,ReceivedStream.Size);
    ReceivedStream.Free;
    try
      PacketAck.FrameType := FT_LOGOFFACK;
      PacketAck.SN := GetSN;

      PacketAck.SourceNumber := 0;
      Move(LocalIP,PacketAck.SourceIP,16);
      PacketAck.SourcePort := LocalPort;

      Move(ABinding.PeerIP[1],PacketAck.DestIP,Length(ABinding.PeerIP));
      PacketAck.DestPort := ABinding.PeerPort;

      PacketAck.AckSN := PacketGeneral.SN;
      PacketAck.MeetingID := 0;
      PacketAck.Checksum := 0;
      PacketAck.AckCode := ACK_ERR;

      try
        with DataModuleDatabase.SQLQueryUserInfo do begin
          Close;
          SQL.Clear;
          SQL.Add('Select * from iRadioUserInfo where "UserName" = :UserName');
          Params.ParamByName('UserName').AsString := PacketGeneral.UserName;
          Open;
        end;
      except on E:Exception do
        DataModuleDatabase.SaveLog('UnitServiceiServer','Debug',E.Message);
      end;

      if not DataModuleDatabase.SQLQueryUserInfo.Eof then begin
        if (DataModuleDatabase.SQLQueryUserInfo.FieldByName('Password').AsString = PacketGeneral.UserPassword) then begin
          UserNumber := DataModuleDatabase.SQLQueryUserInfo.FieldByName('UserNumber').AsInteger;
          PacketAck.DestNumber := UserNumber;
          PacketAck.AckCode := ACK_OK;
          try
            with DataModuleDatabase.SQLQueryUserInfo do begin
              Close;
              SQL.Clear;
              SQL.Add('update iRadioUserInfo set "LastLogoffTime" = :LastLogoffTime , "LastIP" = :LastIP , "LastPort" = :LastPort where "UserNumber" = :UserNumber');
              Params.ParamByName('UserNumber').AsInteger := UserNumber;
              Params.ParamByName('LastLogoffTime').AsString := DateTimeToStr(Now);
              Params.ParamByName('LastIP').AsString := ABinding.PeerIP;
              Params.ParamByName('LastPort').AsInteger := ABinding.PeerPort;
              ExecSQL(false);
            end;
            with DataModuleDatabase.SQLQueryOnlineUser do begin
              Close;
              SQL.Clear;
              SQL.Add('delete iRadioOnlineUser where "UserNumber" = '+IntToStr(UserNumber)+' ');
              ExecSQL(false);
            end;
          except on E:Exception do
            DataModuleDatabase.SaveLog('UnitServiceiServer','Debug',E.Message);
          end;
          if DEBUG then DataModuleDatabase.SaveLog('UnitServiceiServer','Debug',Trim(PacketGeneral.UserName)+' Logoff OK.');
        end else begin
          if DEBUG then DataModuleDatabase.SaveLog('UnitServiceiServer','Debug',Trim(PacketGeneral.UserName)+' Trying to logoff but password error.');
          PacketAck.AckCode := ACK_PASSERR;
        end;
      end else begin
        if DEBUG then DataModuleDatabase.SaveLog('UnitServiceiServer','Debug',Trim(PacketGeneral.UserName)+' Trying to logoff but not find in User database.');
        PacketAck.AckCode := ACK_NOUSER;
      end;
    finally
      DataModuleDatabase.SQLQueryUserInfo.Close;
      DataModuleDatabase.SQLQueryOnlineUser.Close;
      UDP.SendBuffer(ABinding.PeerIP,ABinding.PeerPort,PacketAck,Sizeof(PacketAck));
    end;
  end;

//---------------------------------------------------------------------------------------------------------------------------------------------------
  FT_CALL: begin
    if ReceivedStream.Size <> Sizeof(PacketGeneral) then begin
      DataModuleDatabase.SaveLog('UnitServiceiServer','Error','Incorrected length Call packet received.');
      ReceivedStream.Free;
      exit;
    end;
    ReceivedStream.Seek(0,0);
    ReceivedStream.ReadBuffer(PacketGeneral,ReceivedStream.Size);
    ReceivedStream.Free;
    try
      try
        with DataModuleDatabase.SQLQueryOnlineUser do begin
          Close;
          SQL.Clear;
          SQL.Add('Select * from iRadioOnlineUser where "UserNumber" = :UserNumber');
          Params.ParamByName('UserNumber').AsInteger := PacketGeneral.DestNumber;
          Open;
        end;
      except on E:Exception do
        DataModuleDatabase.SaveLog('UnitServiceiServer','Debug',E.Message);
      end;

      if not DataModuleDatabase.SQLQueryOnlineUser.Eof then begin
        if DataModuleDatabase.SQLQueryOnlineUser.FieldByName('UserStatus').AsInteger = ST_FREE then begin
          if DataModuleDatabase.SQLQueryOnlineUser.FieldByName('UserIP').AsString <> PacketGeneral.DestIP then begin
            Move(DataModuleDatabase.SQLQueryOnlineUser.FieldByName('UserIP').AsString[1],PacketGeneral.DestIP,Length(DataModuleDatabase.SQLQueryOnlineUser.FieldByName('UserIP').AsString))
          end;
          if DataModuleDatabase.SQLQueryOnlineUser.FieldByName('UserPort').AsInteger <> PacketGeneral.DestPort then begin
            PacketGeneral.DestPort := DataModuleDatabase.SQLQueryOnlineUser.FieldByName('UserPort').AsInteger;
          end;

          UDP.SendBuffer(PacketGeneral.DestIP,PacketGeneral.DestPort,PacketGeneral,Sizeof(PacketGeneral));

          with DataModuleDatabase.SQLQueryOnlineUser do begin
            Close;
            SQL.Clear;
            SQL.Add('update iRadioOnlineUser set "UserStatus" = '+IntToStr(ST_CALLING)+' where "UserNumber" = :UserNumber');
            Params.ParamByName('UserNumber').AsInteger := PacketGeneral.SourceNumber;
            ExecSQL(false);
          end;

          if DEBUG then DataModuleDatabase.SaveLog('UnitServiceiServer','Debug',Trim(PacketGeneral.UserName)+' trying to call '+IntToStr(PacketGeneral.DestNumber));

        end else begin
          PacketAck.FrameType := FT_CALLACK;
          PacketAck.SN := GetSN;

          PacketAck.SourceNumber := 0;
          Move(LocalIP,PacketAck.SourceIP,16);
          PacketAck.SourcePort := LocalPort;

          Move(ABinding.PeerIP[1],PacketAck.DestIP,Length(ABinding.PeerIP));
          PacketAck.DestPort := ABinding.PeerPort;

          PacketAck.AckSN := PacketGeneral.SN;
          PacketAck.MeetingID := 0;
          PacketAck.Checksum := 0;
          PacketAck.AckCode := ACK_USRBUSY;
          UDP.SendBuffer(ABinding.PeerIP,ABinding.PeerPort,PacketAck,Sizeof(PacketAck));
        end;
      end else begin
        PacketAck.FrameType := FT_CALLACK;
        PacketAck.SN := GetSN;

        PacketAck.SourceNumber := 0;
        Move(LocalIP,PacketAck.SourceIP,16);
        PacketAck.SourcePort := LocalPort;

        Move(ABinding.PeerIP[1],PacketAck.DestIP,Length(ABinding.PeerIP));
        PacketAck.DestPort := ABinding.PeerPort;

        PacketAck.AckSN := PacketGeneral.SN;
        PacketAck.MeetingID := 0;
        PacketAck.Checksum := 0;
        PacketAck.AckCode := ACK_USROFFLINE;
        UDP.SendBuffer(ABinding.PeerIP,ABinding.PeerPort,PacketAck,Sizeof(PacketAck));
      end;
    finally
      DataModuleDatabase.SQLQueryUserInfo.Close;
      DataModuleDatabase.SQLQueryOnlineUser.Close;
    end;
  end;

//---------------------------------------------------------------------------------------------------------------------------------------------------
  FT_CALLACK: begin
    if ReceivedStream.Size <> Sizeof(PacketAck) then begin
      DataModuleDatabase.SaveLog('UnitServiceiServer','Error','Incorrected length CallAck packet received.');
      ReceivedStream.Free;
      exit;
    end;
    ReceivedStream.Seek(0,0);
    ReceivedStream.ReadBuffer(PacketAck,ReceivedStream.Size);
    ReceivedStream.Free;
    try
      try
        with DataModuleDatabase.SQLQueryOnlineUser do begin
          Close;
          SQL.Clear;
          SQL.Add('Select * from iRadioOnlineUser where "UserNumber" = :UserNumber');
          Params.ParamByName('UserNumber').AsInteger := PacketAck.DestNumber;
          Open;
        end;
      except on E:Exception do
        DataModuleDatabase.SaveLog('UnitServiceiServer','Debug',E.Message);
      end;

      if not DataModuleDatabase.SQLQueryOnlineUser.Eof then begin
        if DataModuleDatabase.SQLQueryOnlineUser.FieldByName('UserStatus').AsInteger = ST_CALLING then begin
          if DataModuleDatabase.SQLQueryOnlineUser.FieldByName('UserIP').AsString <> PacketAck.DestIP then begin
            Move(DataModuleDatabase.SQLQueryOnlineUser.FieldByName('UserIP').AsString[1],PacketAck.DestIP,Length(DataModuleDatabase.SQLQueryOnlineUser.FieldByName('UserIP').AsString))
          end;
          if DataModuleDatabase.SQLQueryOnlineUser.FieldByName('UserPort').AsInteger <> PacketAck.DestPort then begin
            PacketAck.DestPort := DataModuleDatabase.SQLQueryOnlineUser.FieldByName('UserPort').AsInteger;
          end;

          UDP.SendBuffer(PacketAck.DestIP,PacketAck.DestPort,PacketAck,Sizeof(PacketAck));

          with DataModuleDatabase.SQLQueryOnlineUser do begin
            Close;
            SQL.Clear;

            SQL.Add('update iRadioOnlineUser set "UserStatus" = '+IntToStr(ST_BUSY)+' where ("UserNumber" = :SourceNumber or "UserNumber" = :DestNumber)');
            Params.ParamByName('SourceNumber').AsInteger := PacketAck.SourceNumber;
            Params.ParamByName('DestNumber').AsInteger := PacketAck.DestNumber;
            ExecSQL(false);
          end;
          if DEBUG then DataModuleDatabase.SaveLog('UnitServiceiServer','Debug',IntToStr(PacketAck.SourceNumber)+' Ack call request from '+IntToStr(PacketAck.DestNumber));
        end else begin
          PacketAck.FrameType := FT_CALLACK;
          PacketAck.SN := GetSN;

          PacketAck.SourceNumber := 0;
          Move(LocalIP,PacketAck.SourceIP,16);
          PacketAck.SourcePort := LocalPort;

          Move(ABinding.PeerIP[1],PacketAck.DestIP,Length(ABinding.PeerIP));
          PacketAck.DestPort := ABinding.PeerPort;

          PacketAck.AckSN := PacketGeneral.SN;
          PacketAck.MeetingID := 0;
          PacketAck.Checksum := 0;
          PacketAck.AckCode := ACK_USRBUSY;
          UDP.SendBuffer(ABinding.PeerIP,ABinding.PeerPort,PacketAck,Sizeof(PacketAck));
        end;
      end else begin
        PacketAck.FrameType := FT_CALLACK;
        PacketAck.SN := GetSN;

        PacketAck.SourceNumber := 0;
        Move(LocalIP,PacketAck.SourceIP,16);
        PacketAck.SourcePort := LocalPort;

        Move(ABinding.PeerIP[1],PacketAck.DestIP,Length(ABinding.PeerIP));
        PacketAck.DestPort := ABinding.PeerPort;

        PacketAck.AckSN := PacketGeneral.SN;
        PacketAck.MeetingID := 0;
        PacketAck.Checksum := 0;
        PacketAck.AckCode := ACK_USROFFLINE;
        UDP.SendBuffer(ABinding.PeerIP,ABinding.PeerPort,PacketAck,Sizeof(PacketAck));
      end;
    finally
      DataModuleDatabase.SQLQueryUserInfo.Close;
      DataModuleDatabase.SQLQueryOnlineUser.Close;
    end;
  end;

//---------------------------------------------------------------------------------------------------------------------------------------------------
  FT_HANGUP: begin
    if ReceivedStream.Size <> Sizeof(PacketGeneral) then begin
      DataModuleDatabase.SaveLog('UnitServiceiServer','Error','Incorrected length Hangup packet received.');
      ReceivedStream.Free;
      exit;
    end;
    ReceivedStream.Seek(0,0);
    ReceivedStream.ReadBuffer(PacketGeneral,ReceivedStream.Size);
    ReceivedStream.Free;
    try
      try
        with DataModuleDatabase.SQLQueryOnlineUser do begin
          Close;
          SQL.Clear;
          SQL.Add('Select * from iRadioOnlineUser where "UserNumber" = :UserNumber');
          Params.ParamByName('UserNumber').AsInteger := PacketGeneral.DestNumber;
          Open;
        end;
      except on E:Exception do
        DataModuleDatabase.SaveLog('UnitServiceiServer','Debug',E.Message);
      end;

      if not DataModuleDatabase.SQLQueryOnlineUser.Eof then begin
        if DataModuleDatabase.SQLQueryOnlineUser.FieldByName('UserStatus').AsInteger = ST_BUSY then begin
          if DataModuleDatabase.SQLQueryOnlineUser.FieldByName('UserIP').AsString <> PacketGeneral.DestIP then begin
            Move(DataModuleDatabase.SQLQueryOnlineUser.FieldByName('UserIP').AsString[1],PacketGeneral.DestIP,Length(DataModuleDatabase.SQLQueryOnlineUser.FieldByName('UserIP').AsString))
          end;
          if DataModuleDatabase.SQLQueryOnlineUser.FieldByName('UserPort').AsInteger <> PacketGeneral.DestPort then begin
            PacketGeneral.DestPort := DataModuleDatabase.SQLQueryOnlineUser.FieldByName('UserPort').AsInteger;
          end;

          UDP.SendBuffer(PacketGeneral.DestIP,PacketGeneral.DestPort,PacketGeneral,Sizeof(PacketGeneral));

          with DataModuleDatabase.SQLQueryOnlineUser do begin
            Close;
            SQL.Clear;
            SQL.Add('update iRadioOnlineUser set "UserStatus" = '+IntToStr(ST_HANGING)+' where "UserNumber" = :UserNumber');
            Params.ParamByName('UserNumber').AsInteger := PacketGeneral.SourceNumber;
            ExecSQL(false);
          end;

          if DEBUG then DataModuleDatabase.SaveLog('UnitServiceiServer','Debug',Trim(PacketGeneral.UserName)+' Trying to hangup.');
        end else begin
          PacketAck.FrameType := FT_HANGUPACK;
          PacketAck.SN := GetSN;

          PacketAck.SourceNumber := 0;
          Move(LocalIP,PacketAck.SourceIP,16);
          PacketAck.SourcePort := LocalPort;

          Move(ABinding.PeerIP[1],PacketAck.DestIP,Length(ABinding.PeerIP));
          PacketAck.DestPort := ABinding.PeerPort;

          PacketAck.AckSN := PacketGeneral.SN;
          PacketAck.MeetingID := 0;
          PacketAck.Checksum := 0;
          PacketAck.AckCode := ACK_NOTINCALL;
          UDP.SendBuffer(ABinding.PeerIP,ABinding.PeerPort,PacketAck,Sizeof(PacketAck));
        end;
      end else begin
        PacketAck.FrameType := FT_HANGUPACK;
        PacketAck.SN := GetSN;

        PacketAck.SourceNumber := 0;
        Move(LocalIP,PacketAck.SourceIP,16);
        PacketAck.SourcePort := LocalPort;

        Move(ABinding.PeerIP[1],PacketAck.DestIP,Length(ABinding.PeerIP));
        PacketAck.DestPort := ABinding.PeerPort;

        PacketAck.AckSN := PacketGeneral.SN;
        PacketAck.MeetingID := 0;
        PacketAck.Checksum := 0;
        PacketAck.AckCode := ACK_USROFFLINE;
        UDP.SendBuffer(ABinding.PeerIP,ABinding.PeerPort,PacketAck,Sizeof(PacketAck));
      end;
    finally
      DataModuleDatabase.SQLQueryUserInfo.Close;
      DataModuleDatabase.SQLQueryOnlineUser.Close;
    end;
  end;

//---------------------------------------------------------------------------------------------------------------------------------------------------
  FT_HANGUPACK: begin
    if ReceivedStream.Size <> Sizeof(PacketAck) then begin
      DataModuleDatabase.SaveLog('UnitServiceiServer','Error','Incorrected length HangupAck packet received.');
      ReceivedStream.Free;
      exit;
    end;
    ReceivedStream.Seek(0,0);
    ReceivedStream.ReadBuffer(PacketAck,ReceivedStream.Size);
    ReceivedStream.Free;
    try
      try
        with DataModuleDatabase.SQLQueryOnlineUser do begin
          Close;
          SQL.Clear;
          SQL.Add('Select * from iRadioOnlineUser where "UserNumber" = :UserNumber');
          Params.ParamByName('UserNumber').AsInteger := PacketAck.DestNumber;
          Open;
        end;
      except on E:Exception do
        DataModuleDatabase.SaveLog('UnitServiceiServer','Debug',E.Message);
      end;

      if not DataModuleDatabase.SQLQueryOnlineUser.Eof then begin
        if DataModuleDatabase.SQLQueryOnlineUser.FieldByName('UserStatus').AsInteger = ST_HANGING then begin
          if DataModuleDatabase.SQLQueryOnlineUser.FieldByName('UserIP').AsString <> PacketAck.DestIP then begin
            Move(DataModuleDatabase.SQLQueryOnlineUser.FieldByName('UserIP').AsString[1],PacketAck.DestIP,Length(DataModuleDatabase.SQLQueryOnlineUser.FieldByName('UserIP').AsString))
          end;
          if DataModuleDatabase.SQLQueryOnlineUser.FieldByName('UserPort').AsInteger <> PacketAck.DestPort then begin
            PacketAck.DestPort := DataModuleDatabase.SQLQueryOnlineUser.FieldByName('UserPort').AsInteger;
          end;

          UDP.SendBuffer(PacketAck.DestIP,PacketAck.DestPort,PacketAck,Sizeof(PacketAck));

          with DataModuleDatabase.SQLQueryOnlineUser do begin
            Close;
            SQL.Clear;
            SQL.Add('update iRadioOnlineUser set "UserStatus" = '+IntToStr(ST_FREE)+' where ("UserNumber" = :SourceNumber or "UserNumber" = :DestNumber)');
            Params.ParamByName('SourceNumber').AsInteger := PacketAck.SourceNumber;
            Params.ParamByName('DestNumber').AsInteger := PacketAck.DestNumber;
            ExecSQL(false);
          end;

        end else begin
          PacketAck.FrameType := FT_HANGUPACK;
          PacketAck.SN := GetSN;

          PacketAck.SourceNumber := 0;
          Move(LocalIP,PacketAck.SourceIP,16);
          PacketAck.SourcePort := LocalPort;

          Move(ABinding.PeerIP[1],PacketAck.DestIP,Length(ABinding.PeerIP));
          PacketAck.DestPort := ABinding.PeerPort;

          PacketAck.AckSN := PacketGeneral.SN;
          PacketAck.MeetingID := 0;
          PacketAck.Checksum := 0;
          PacketAck.AckCode := ACK_ERR;
          UDP.SendBuffer(ABinding.PeerIP,ABinding.PeerPort,PacketAck,Sizeof(PacketAck));
        end;
      end else begin
        PacketAck.FrameType := FT_HANGUPACK;
        PacketAck.SN := GetSN;

        PacketAck.SourceNumber := 0;
        Move(LocalIP,PacketAck.SourceIP,16);
        PacketAck.SourcePort := LocalPort;

        Move(ABinding.PeerIP[1],PacketAck.DestIP,Length(ABinding.PeerIP));
        PacketAck.DestPort := ABinding.PeerPort;

        PacketAck.AckSN := PacketGeneral.SN;
        PacketAck.MeetingID := 0;
        PacketAck.Checksum := 0;
        PacketAck.AckCode := ACK_USROFFLINE;
        UDP.SendBuffer(ABinding.PeerIP,ABinding.PeerPort,PacketAck,Sizeof(PacketAck));
      end;
    finally
      DataModuleDatabase.SQLQueryUserInfo.Close;
      DataModuleDatabase.SQLQueryOnlineUser.Close;
    end;
  end;

//---------------------------------------------------------------------------------------------------------------------------------------------------
  FT_POLLACK: begin
    if ReceivedStream.Size <> Sizeof(PacketAck) then begin
      DataModuleDatabase.SaveLog('UnitServiceiServer','Error','Incorrected length PollAck packet received.');
      ReceivedStream.Free;
      exit;
    end;
    ReceivedStream.Seek(0,0);
    ReceivedStream.ReadBuffer(PacketAck,ReceivedStream.Size);
    ReceivedStream.Free;
    try
      with DataModuleDatabase.SQLQueryOnlineUser do begin
        Close;
        SQL.Clear;
        SQL.Add('update iRadioOnlineUser set "KillTimer" = '+IntToStr(MAXKILLTIME)+',"UserStatus" = '+IntToStr(PacketAck.AckCode)+' where "UserNumber" = '+IntToStr(PacketAck.SourceNumber)+' ');
        ExecSQL(false);
      end;
      DataModuleDatabase.SQLQueryOnlineUser.Close;
    except
      on E:Exception do begin
        DataModuleDatabase.SQLQueryOnlineUser.Close;
        DataModuleDatabase.SaveLog('UnitServiceiServer','Debug',E.Message);
      end;
    end;
  end;

//---------------------------------------------------------------------------------------------------------------------------------------------------
  FT_TEXT: begin
    if ReceivedStream.Size <> Sizeof(PacketText) then begin
      DataModuleDatabase.SaveLog('UnitServiceiServer','Error','Incorrected length text packet received.');
      ReceivedStream.Free;
      exit;
    end;

    ReceivedStream.Seek(0,0);
    ReceivedStream.ReadBuffer(PacketText,ReceivedStream.Size);
    ReceivedStream.Free;
    try
      try
        with DataModuleDatabase.SQLQueryOnlineUser do begin
          Close;
          SQL.Clear;
          SQL.Add('Select * from iRadioOnlineUser where "UserNumber" = :UserNumber');
          ParamByName('UserNumber').AsInteger := PacketText.DestNumber;
          Open;
        end;
      except on E:Exception do
        DataModuleDatabase.SaveLog('UnitServiceiServer','Debug',E.Message);
      end;

      if not DataModuleDatabase.SQLQueryOnlineUser.Eof then begin
        UDP.SendBuffer(DataModuleDatabase.SQLQueryOnlineUser.FieldByName('UserIP').AsString,DataModuleDatabase.SQLQueryOnlineUser.FieldByName('UserPort').AsInteger,PacketText,Sizeof(PacketText));
      end else begin
        PacketAck.FrameType := FT_TEXTACK;
        PacketAck.SN := GetSN;

        PacketAck.SourceNumber := 0;
        Move(LocalIP,PacketAck.SourceIP,16);
        PacketAck.SourcePort := LocalPort;

        Move(ABinding.PeerIP[1],PacketAck.DestIP,Length(ABinding.PeerIP));
        PacketAck.DestPort := ABinding.PeerPort;

        PacketAck.AckSN := PacketGeneral.SN;
        PacketAck.MeetingID := 0;
        PacketAck.Checksum := 0;
        PacketAck.AckCode := ACK_USROFFLINE;
        UDP.SendBuffer(ABinding.PeerIP,ABinding.PeerPort,PacketAck,Sizeof(PacketAck));
      end;
    finally
      DataModuleDatabase.SQLQueryOnlineUser.Close;
    end;
  end;

//---------------------------------------------------------------------------------------------------------------------------------------------------
  FT_TEXTACK: begin
    if ReceivedStream.Size <> Sizeof(PacketAck) then begin
      DataModuleDatabase.SaveLog('UnitServiceiServer','Error','Incorrected length TextAck packet received.');
      ReceivedStream.Free;
      exit;
    end;
    ReceivedStream.Seek(0,0);
    ReceivedStream.ReadBuffer(PacketAck,ReceivedStream.Size);
    ReceivedStream.Free;
    try
      try
        with DataModuleDatabase.SQLQueryOnlineUser do begin
          Close;
          SQL.Clear;
          SQL.Add('Select * from iRadioOnlineUser where "UserNumber" = :UserNumber');
          Params.ParamByName('UserNumber').AsInteger := PacketAck.DestNumber;
          Open;
        end;
      except on E:Exception do
        DataModuleDatabase.SaveLog('UnitServiceiServer','Debug',E.Message);
      end;

      if not DataModuleDatabase.SQLQueryOnlineUser.Eof then begin
        if DataModuleDatabase.SQLQueryOnlineUser.FieldByName('UserIP').AsString <> PacketAck.DestIP then begin
          Move(DataModuleDatabase.SQLQueryOnlineUser.FieldByName('UserIP').AsString[1],PacketAck.DestIP,Length(DataModuleDatabase.SQLQueryOnlineUser.FieldByName('UserIP').AsString))
        end;
        if DataModuleDatabase.SQLQueryOnlineUser.FieldByName('UserPort').AsInteger <> PacketAck.DestPort then begin
          PacketAck.DestPort := DataModuleDatabase.SQLQueryOnlineUser.FieldByName('UserPort').AsInteger;
        end;

        UDP.SendBuffer(PacketAck.DestIP,PacketAck.DestPort,PacketAck,Sizeof(PacketAck));
      end;
    finally
      DataModuleDatabase.SQLQueryOnlineUser.Close;
    end;
  end;

//---------------------------------------------------------------------------------------------------------------------------------------------------
  FT_VOICE : begin
    if ReceivedStream.Size <> Sizeof(PacketVoice) then begin
      DataModuleDatabase.SaveLog('UnitServiceiServer','Error','Incorrected length Voice packet received, Length :' + IntToStr(ReceivedStream.Size));
      ReceivedStream.Free;
      exit;
    end;

    ReceivedStream.Seek(0,0);
    ReceivedStream.ReadBuffer(PacketVoice,ReceivedStream.Size);
    ReceivedStream.Free;
    try
      try
        with DataModuleDatabase.SQLQueryOnlineUser do begin
          Close;
          SQL.Clear;
          SQL.Add('Select * from iRadioOnlineUser where "UserNumber" = :UserNumber');
          ParamByName('UserNumber').AsInteger := PacketVoice.DestNumber;
          Open;
        end;
      except on E:Exception do
        DataModuleDatabase.SaveLog('UnitServiceiServer','Debug',E.Message);
      end;

      if not DataModuleDatabase.SQLQueryOnlineUser.Eof then begin
        UDP.SendBuffer(DataModuleDatabase.SQLQueryOnlineUser.FieldByName('UserIP').AsString,DataModuleDatabase.SQLQueryOnlineUser.FieldByName('UserPort').AsInteger,PacketVoice,Sizeof(PacketVoice));
      end;
    finally
      DataModuleDatabase.SQLQueryOnlineUser.Close;
    end;
  end;

//---------------------------------------------------------------------------------------------------------------------------------------------------
  FT_BROADCAST: begin
    if ReceivedStream.Size <> Sizeof(PacketText) then begin
      DataModuleDatabase.SaveLog('UnitServiceiServer','Error','Incorrected length Broadcast packet received.');
      ReceivedStream.Free;
      exit;
    end;

    ReceivedStream.Seek(0,0);
    ReceivedStream.ReadBuffer(PacketText,ReceivedStream.Size);
    ReceivedStream.Free;
    try
      with DataModuleDatabase.SQLQueryOnlineUser do begin
        Close;
        SQL.Clear;
        SQL.Add('select * from iRadioOnlineUser');
        Open;

        while not Eof do begin
          try
            PacketText.DestNumber := FieldByName('UserNumber').AsInteger;
            UDP.SendBuffer(FieldByName('UserIP').AsString , FieldByName('UserPort').AsInteger , PacketText , SizeOf(PacketText));
            Next;
          finally
          end;
        end;
      end;
    finally
      DataModuleDatabase.SQLQueryOnlineUser.Close;
    end;
  end;

//---------------------------------------------------------------------------------------------------------------------------------------------------
  else
    DataModuleDatabase.SaveLog('UnitServiceiServer','Error','Error type packet received, type:'+ IntToStr(FrameType));
    ReceivedStream.Free;
  end;

end;

procedure TServiceiServer.TimerPollTimer(Sender: TObject);
var
  PacketPoll : TPacketPoll;
  i : integer;
  DestIP : String;
  DestPort : integer;
begin
  try
    with DataModuleDatabase.SQLQueryOnlineUser do begin
      Close;
      SQL.Clear;
      SQL.Add('select * from iRadioOnlineUser');
      Open;

      PacketPoll.FrameType := FT_POLL;
      PacketPoll.SN := GetSN;
      PacketPoll.SourceNumber := 0;

      i := 0;
      while not Eof do begin
        Move(FieldByName('UserName').AsString[1] , PacketPoll.UserList[i].UserName , Length(FieldByName('UserName').AsString));
        PacketPoll.UserList[i].UserNumber := FieldByName('UserNumber').AsInteger;
        PacketPoll.UserList[i].UserStatus := FieldByName('UserStatus').AsInteger;
        Inc(i);
        Next;
      end;
      while i <= MAXUSER do begin
        PacketPoll.UserList[i].UserNumber := 0;
        Inc(i);
      end;

      PacketPoll.Checksum := 0;

      First;
      while not Eof do begin
        PacketPoll.DestNumber := FieldByName('UserNumber').AsInteger;
        DestIP := FieldByName('UserIP').AsString;
        DestPort := FieldByName('UserPort').AsInteger;
        UDP.SendBuffer(DestIP , DestPort , PacketPoll , SizeOf(PacketPoll));
        Next;
      end;

      Close;
      SQL.Clear;
      SQL.Add('delete from iRadioOnlineUser where "KillTimer" < 1 ');
      ExecSQL(false);

      Close;
      SQL.Clear;
      SQL.Add('update iRadioOnlineUser set "KillTimer" = "KillTimer" - 1 ');
      ExecSQL(false);

    end;
    DataModuleDatabase.SQLQueryOnlineUser.Close;
  except
    on E:Exception do begin
      DataModuleDatabase.SQLQueryOnlineUser.Close;
      DataModuleDatabase.SaveLog('UnitServiceiServer','Error',E.Message);
    end;
  end;
end;

end.
