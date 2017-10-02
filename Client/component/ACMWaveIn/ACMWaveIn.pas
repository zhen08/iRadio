unit ACMWaveIn;

interface

uses
  msacm,Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs, mmsystem;

type
  TOnData = procedure(data:pointer;size:longint) of object;
  TACMWaveIn = class(TWinControl)
   private
    FOnData:TOnData;
    procedure WaveInCallback (var msg:TMessage);message MM_WIM_DATA;
    { Private declarations }
   protected
    procedure TWMPaint(var msg:TWMPaint); message WM_PAINT;

   { Protected declarations }
   public
    constructor Create(AOwner:TComponent);override;
    procedure Open(format:PWaveFormatEx);
    procedure Close;
    { Public declarations }
    published
     property OnData:TOnData read FOnData write FOnData ;
    { Published declarations }
    end;
var
  closed:boolean;
  sizebuf:integer;
  HWaveIn1:PHWaveIn;
procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Milos', [TACMWaveIn]);
end;

procedure TACMWaveIn.TWMPaint(var msg: TWMPaint);   //display icon
var
  icon: HIcon;
  dc: HDC;
begin
  if csDesigning in ComponentState then
  begin
    icon := LoadIcon(HInstance,MAKEINTRESOURCE('TACMWAVEIN'));
    dc := GetDC(Handle);
    DrawIcon(dc,0,0,icon);
    Width := 32;
    Height := 32;
    ReleaseDC(Handle,dc);
    FreeResource(icon);
  end;
 ValidateRect(Handle,nil);
end;


constructor TACMWaveIn.Create(AOwner:TComponent);
begin
 inherited create(AOwner);
 width:=32;
 height:=32;
end;

procedure TACMWaveIn.WaveInCallback(var msg:TMessage);  //this is called when is buffer full 
var
   Header:PWaveHdr;
   i,bytesrecorded:integer;
   data:PChar;
begin

     {block has been recorded}
     Header:=PWaveHdr(msg.lparam);
     if closed=false then
     begin
     i:=waveInUnPrepareHeader(HWaveIn1^,Header,sizeof(TWavehdr));
     if i<>0 then showmessage('In Un Prepare error');
     bytesrecorded:=header.dwbytesrecorded;
     getmem(data,bytesrecorded); //allocate memory
     move(header.lpdata^,data^,bytesrecorded); //copy data
     if assigned(FOnData) then
     begin
      FOnData(data,bytesrecorded);
     end;

          Freemem(data); //free memory
          {reuse a old memory block}

          header.dwbufferlength:=sizebuf;
          header.dwbytesrecorded:=0;
          header.dwUser:=0;
          header.dwflags:=0;
          header.dwloops:=0;

         {prepare the old block}
          i:=waveInPrepareHeader(HWaveIn1^,Header,sizeof(TWavehdr));

          if i<>0 then showmessage('In Prepare error');

          {add it to the buffer}
          i:=waveInAddBuffer(HWaveIn1^,Header,sizeof(TWaveHdr));
          if i<>0 then showmessage('Add buffer error');
         end
         else
         begin //free buffers if closed
          dispose(header.lpdata);
          dispose(header);
         end;
end;

procedure TACMWaveIn.Open(format:PWaveFormatEx);
var
   WaveFormat:PWaveFormatEx;
   Header:PWaveHdr;
   memBlock:PChar;
   i,j,maxsizeformat:integer;
begin
if (hwavein1=nil) and (format<>nil) then
  begin
     acmMetrics(0, ACM_METRIC_MAX_SIZE_FORMAT,MaxSizeFormat);
     getmem(WaveFormat, MaxSizeFormat);
     move(format^,waveformat^,maxsizeformat);
     sizebuf := 128;
     HWaveIn1:=new(PHWaveIn);
     // create record handle with waveformatex structure
     i:=WaveInOpen(HWaveIn1,0,waveformat,handle,0,CALLBACK_WINDOW or WAVE_MAPPED);
     if i<>0 then
     begin
      showmessage('Problem creating record handle' + inttostr(i));
      exit;
     end;
     closed:=false;
     {need to add some buffers to the recording queue}
     {in case the messages that blocks have been recorded}
     {are delayed}
     for j:= 1 to 3 do
     begin
          {make a new block}
          Header:=new(PWaveHdr);
          memBlock:=new(PChar);
          getmem(memblock,sizebuf); //allocate memory
          Header:=new(PwaveHdr);
          header.lpdata:=memBlock;
          header.dwbufferlength:=sizebuf;
          header.dwbytesrecorded:=0;
          header.dwUser:=0;
          header.dwflags:=0;
          header.dwloops:=0;
          {prepare the new block}
          i:=waveInPrepareHeader(HWaveIn1^,Header,sizeof(TWavehdr));
          if i<>0 then showmessage('In Prepare error');

          {add it to the buffer}
          i:=waveInAddBuffer(HWaveIn1^,Header,sizeof(TWaveHdr));

          if i<>0 then showmessage('Add buffer error');


     end; {of loop}

     {finally start recording}
     i:=waveInStart(HwaveIn1^);
     if i<>0 then showmessage('Start error');
  end;
end;

procedure TACMWaveIn.Close;
begin
 if HWaveIn1 <> nil then
 begin
  closed:=true;
  WaveInReset(HWaveIn1^);
  WaveInClose(HWaveIn1^);
  dispose(HWaveIn1);
  HWaveIn1:=nil;
 end;
end;

end.
