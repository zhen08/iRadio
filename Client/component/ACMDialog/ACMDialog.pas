unit ACMDialog;

interface

uses
  msacm,mmsystem,Windows, SysUtils, Classes, Controls, Dialogs;

type
  TACMDialog = class(TComponent)
  private
    { Private declarations }
  protected
    { Protected declarations }
  public
    function OpenDialog:pointer;
    { Public declarations }
  published
    { Published declarations }
  end;
var
fc:TACMFORMATCHOOSEA;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Milos', [TACMDialog]);
end;

function TACMDialog.OpenDialog:Pointer;
var maxsizeformat,res:longint;
begin
  if fc.pwfx = nil then
  begin
   acmMetrics(0, ACM_METRIC_MAX_SIZE_FORMAT, MaxSizeFormat);
   fc.cbStruct := sizeof(fc);
   fc.cbWfx := MaxSizeFormat;
   getmem(fc.pwfx, MaxSizeFormat);  
   fc.pwfx.wFormatTag :=$31;   //WAVE_FORMAT_GSM610; set default format to GSM6.10
   fc.pwfx.nChannels := 1;     //mono
   fc.pwfx.nSamplesPerSec := 8000;  
   fc.pwfx.nAvgBytesPerSec:= 8000; { for buffer estimation }
   fc.pwfx.nBlockAlign:=1;      { block size of data }
   fc.pwfx.wbitspersample := 8;
  end;

  fc.fdwStyle:=ACMFORMATCHOOSE_STYLEF_INITTOWFXSTRUCT;  //use the pwfx(waveformatex structure) as default
  res:=acmFormatChoose(fc); //display the ACM dialog box
  result:=nil;
  if res=MMSYSERR_NOERROR then result:=fc.pwfx; //return the pointer to waveformatex structure

end;

end.
