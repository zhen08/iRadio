unit ACMIn;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ACMConvertor, MMSystem, MSACM;

type
  TACMBufferCount = 2..64;
  TBufferFullEvent = procedure(Sender : TObject; Data : Pointer; Size:longint) of object;

  EACMIn = Class(Exception);
  TACMIn = class(TComponent)
  private
    FActive                   : Boolean;
    FBufferList               : TList;
    FBufferSize               : DWord;
    FFormat                   : TACMWaveFormat;
    FNumBuffers               : TACMBufferCount;
    FWaveInHandle             : HWaveIn;
    FWindowHandle             : HWnd;
    FOnBufferFull             : TBufferFullEvent;
    procedure DoBufferFull(Header : PWaveHdr);
    procedure SetBufferSize(const Value: DWord);
    procedure SetNumBuffers(const Value: TACMBufferCount);
  protected
    function  NewHeader : PWaveHDR;
    procedure DisposeHeader(Header : PWaveHDR);
    procedure WndProc(Var Message : TMessage);
  public
    constructor Create(AOwner : TComponent); override;
    destructor Destroy; override;

    procedure Open(aFormat : TACMWaveFormat);
    procedure Close;

    procedure RaiseException(const aMessage : String; Result : Integer);

      property Active         : Boolean
        read FActive;
      property WindowHandle   : HWnd
        read FWindowHandle;
    published
      property BufferSize     : DWord
        read FBufferSize
        write SetBufferSize;
      property NumBuffers     : TACMBufferCount
        read FNumBuffers
        write SetNumBuffers;

      property OnBufferFull   : TBufferFullEvent
        read FOnBufferFull
        write FOnBufferFull;
 end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Sound', [TACMIn]);
end;

constructor TACMIn.Create(AOwner:TComponent);
begin
 inherited;
 FBufferList := TList.Create;
 FActive := False;
 FBufferSize := 8192;
 FWaveInHandle := 0;
 FWindowHandle := AllocateHWND(WndProc);
 FNumBuffers := 4;
end;

procedure TACMIn.DoBufferFull(Header : PWaveHdr);
var
   Res                        : Integer;
   BytesRecorded              : Integer;
   Data                       : Pointer;
begin
  if Active then begin
    Res := WaveInUnPrepareHeader(FWaveInHandle,Header,sizeof(TWavehdr));
    if Res <>0  then RaiseException('WaveIn-UnprepareHeader', Res);

    BytesRecorded:=header.dwBytesRecorded;

    if assigned(FOnBufferFull) then begin
      Getmem(Data, BytesRecorded);
      try
        move(header.lpData^,Data^,BytesRecorded);
        FOnBufferFull(Self, Data, BytesRecorded);
      finally
        Freemem(Data);
      end;
    end;

    header.dwbufferlength:=FBufferSize;
    header.dwBytesRecorded:=0;
    header.dwUser:=0;
    header.dwflags:=0;
    header.dwloops:=0;
    FillMemory(Header.lpData,FBufferSize,0);

    Res := WaveInPrepareHeader(FWaveInHandle,Header,sizeof(TWavehdr));
    if Res <> 0 then RaiseException('WaveIn-PrepareHeader', Res);

    Res:=WaveInAddBuffer(FWaveInHandle,Header,sizeof(TWaveHdr));
    if Res <> 0 then RaiseException('WaveInAddBuffer', Res);

   end else
    if not (csDestroying in ComponentState) then
      DisposeHeader(Header);
end;

procedure TACMIn.Open(aFormat : TACMWaveFormat);
var
  Res                         : Integer;
  J                           : Integer;
begin
  if Active then exit;
  Res := WaveInOpen(@FWaveInHandle,0,@aFormat.Format,FWindowHandle,0,CALLBACK_WINDOW or WAVE_MAPPED);
  if Res <> 0 then RaiseException('WaveIn-Open',Res);

  for j:= 1 to FNumBuffers do NewHeader;

  Res := WaveInStart(FWaveInHandle);
  if Res <> 0 then RaiseException('WaveIn-Start',Res);

  FFormat := aFormat;
  FActive := True;
end;

destructor TACMIn.Destroy;
begin
  if Active then Close;
  FBufferList.Free;
  DeAllocateHWND(FWindowHandle);
  inherited;
end;

procedure TACMIn.RaiseException(const aMessage: String; Result: Integer);
begin
  case Result of
    ACMERR_NotPossible : Raise EACMIn.Create(aMessage + ' The requested operation cannot be performed.');
    ACMERR_BUSY : Raise EACMIn.Create(aMessage + ' The conversion stream is already in use.');
    ACMERR_UNPREPARED : Raise EACMIn.Create(aMessage + ' Cannot perform this action on a header that has not been prepared.');
    MMSYSERR_InvalFlag : Raise EACMIn.Create(aMessage + ' At least one flag is invalid.');
    MMSYSERR_InvalHandle : Raise EACMIn.Create(aMessage + ' The specified handle is invalid.');
    MMSYSERR_InvalParam : Raise EACMIn.Create(aMessage + ' At least one parameter is invalid.');
    MMSYSERR_NoMem : Raise EACMIn.Create(aMessage + ' The system is unable to allocate resources.');
    MMSYSERR_NoDriver : Raise EACMIn.Create(aMessage + ' A suitable driver is not available to provide valid format selections.');
    MMSYSERR_ALLOCATED : Raise EACMIn.Create(aMessage + ' The specified resource is already in use.');
    MMSYSERR_BADDEVICEID : Raise EACMIn.Create(aMessage + ' The specified resource does not exist.');
    WAVERR_BADFORMAT : Raise EACMIn.Create(aMessage + ' Unsupported audio format.');
    WAVERR_SYNC : Raise EACMIn.Create(aMessage + ' The specified device does not support asynchronous operation.');
  else
    if Result <> 0 then
      Raise EACMIn.Create(SysUtils.Format('%s raised an unknown error (code #%d)',[aMessage,Result]));
  end;
end;

procedure TACMIn.WndProc(var Message: TMessage);
begin
  case Message.Msg of
    MM_WIM_Data: DoBufferFull(PWaveHDR(Message.LParam));
  end;

end;

procedure TACMIn.Close;
var
  X                           : Integer;
begin
  if not Active then Exit;
  FActive := False;
  WaveInReset(FWaveInHandle);
  WaveInClose(FWaveInHandle);
  FWaveInHandle := 0;
  For X:=FBufferList.Count-1 downto 0 do DisposeHeader(PWaveHDR(FBufferList[X]));
end;

procedure TACMIn.SetBufferSize(const Value: DWord);
begin
  if Active then exit;
  FBufferSize := Value;
end;

function TACMIn.NewHeader: PWaveHDR;
var
  Res                         : Integer;
begin
  Getmem(Result, SizeOf(TWaveHDR));
  FBufferList.Add(Result);
  with Result^ do begin
    Getmem(lpData,FBufferSize);
    dwBufferLength := FBufferSize;
    dwBytesRecorded := 0;
    dwFlags := 0;
    dwLoops := 0;
    Res := WaveInPrepareHeader(FWaveInHandle,Result,sizeof(TWaveHDR));
    if Res <> 0 then RaiseException('WaveIn-PrepareHeader',Res);

    Res := WaveInAddBuffer(FWaveInHandle,Result,SizeOf(TWaveHDR));
    if Res <> 0 then RaiseException('WaveIn-AddBuffer',Res);
  end;
end;

procedure TACMIn.SetNumBuffers(const Value: TACMBufferCount);
begin
  if Active then exit;
  FNumBuffers := Value;
end;

procedure TACMIn.DisposeHeader(Header: PWaveHDR);
var
  X                           : Integer;
begin
  X := FBufferList.IndexOf(Header);
  if X < 0 then exit;
  Freemem(header.lpData);
  Freemem(header);
  FBufferList.Delete(X);
end;

end.
