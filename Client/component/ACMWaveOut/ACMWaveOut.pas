unit ACMWaveOut;

interface

uses
  msacm,mmsystem,Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs;

type
  TACMWaveOut = class(TWinControl)
  private
  procedure WaveOutCallback(var msg:TMessage);message MM_WOM_DONE;
    { Private declarations }
  protected
  procedure TWMPaint(var msg:TWMPaint); message WM_PAINT;

    { Protected declarations }
  public
  constructor Create(AOwner:TComponent);override;
  //destructor Destroy;
  procedure Open(format:PWaveFormatEx);
  procedure PlayBack(data:pointer;size:longint);
  procedure Close;
    { Public declarations }
  published
    { Published declarations }
  end;
var
HWaveOut1:PHWaveOut;
closed:boolean;
procedure Register;

implementation

constructor TACMWaveOut.create(AOwner:TComponent);
begin
 inherited Create (AOWner);
 width:=32;
 height:=32;
end;

procedure TACMWaveOut.TWMPaint(var msg: TWMPaint);   //draw icon
var
  icon: HIcon;
  dc: HDC;
begin
  if csDesigning in ComponentState then
  begin
    icon := LoadIcon(HInstance,MAKEINTRESOURCE('TACMWAVEOUT'));
    dc := GetDC(Handle);
    DrawIcon(dc,0,0,icon);
    Width := 32;
    Height := 32;
    ReleaseDC(Handle,dc);
    FreeResource(icon);
  end;
 ValidateRect(Handle,nil);
end;


procedure TACMWaveOut.Open(format:PWaveFormatEx);
var
waveformat:PWaveFormatEx;
maxsizeformat,i:integer;
begin
  if (format<>nil) and (HWaveOut1=nil) then
   begin
     acmMetrics(0, ACM_METRIC_MAX_SIZE_FORMAT,MaxSizeFormat);
     getmem(WaveFormat, MaxSizeFormat);
     move(format^,waveformat^,maxsizeformat);
     HWaveOut1:=new(PHWaveOut);
     //create playing handle with waveformatex structure
     i:=WaveOutOpen(HWaveOut1,0,waveformat,handle,0,CALLBACK_WINDOW or WAVE_MAPPED);
     if i<>0 then
     begin
      showmessage('Problem creating playing handle' + inttostr(i));
      exit;
     end;
     closed:=false;
    end; 
end;

procedure TACMWaveOut.PlayBack(data:pointer;size:longint);
var
Header:PWaveHdr;
memblock:pointer;
i:integer;
begin
if HWaveOut1<>nil then
begin
 header:=new(PWaveHdr);
 memblock:=new(pointer);
 getmem(memblock,size);
 move(data^,memBlock^,size);
 header.lpdata:=memBlock;
 header.dwbufferlength:=size;
 header.dwbytesrecorded:=size;
 header.dwUser:=0;
 header.dwflags:=0;
 header.dwloops:=0;
 i:=WaveOutPrepareHeader(HWaveOut1^,header,sizeof(TWaveHdr));
 if i<> 0 then showmessage('WaveOutPrepareHeader error');
 i:=WaveOutWrite(HWaveOut1^,header,sizeof(TWaveHdr));
 if i<> 0 then showmessage('WaveOutWrite error');
end;

end;


procedure TACMWaveOut.WaveOutCallback(var msg:TMessage);
var header:PWaveHdr;
i:integer;
begin
 header:=PWaveHdr(msg.LParam);
 if closed=false then
 begin
 i:=WaveOutUnPrepareHeader(HWaveOut1^,header,sizeof(TWaveHdr));
 if i<> 0 then showmessage('WaveOutPrepareHeader error');
 end;
 dispose(Header^.lpData);
 dispose(Header);

end;

procedure TACMWaveOut.Close;
begin
 if HWaveOut1<>nil then
 begin
 closed:=TRUE;
 WaveOutReset(HWaveOut1^);
 WaveOutClose(HWaveOut1^);
 HWaveOut1:=nil;
 end;
end;

procedure Register;
begin
  RegisterComponents('Milos', [TACMWaveOut]);
end;

end.
 