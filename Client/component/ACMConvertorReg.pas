unit ACMConvertorReg;

interface
uses
  Classes, Messages, Windows, Forms, SysUtils, Controls, MSACM, MMSystem, Dialogs,
  ACMConvertor, DesignIntf, DesignEditors;

type
  TACMConvertorEditor = class(TComponentEditor)
  private

  protected
  public
    procedure ExecuteVerb(Index: Integer); override;
    function GetVerb(Index: Integer): string; override;
    function GetVerbCount: Integer; override;
  published
  end;


procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Sound',[TACMConvertor]);
  RegisterComponentEditor(TACMConvertor, TACMConvertorEditor);
end;

{ TACMConvertorEditor }

procedure TACMConvertorEditor.ExecuteVerb(Index: Integer);
begin
  inherited;
  with TACMConvertor(Component) do
  case Index of
    0 : ChooseFormatIn(True);
    1 : ChooseFormatOut(True);
  end;
  Designer.Modified;
end;

function TACMConvertorEditor.GetVerb(Index: Integer): string;
begin
  case Index of
    0 : Result := 'Select input format...';
    1 : Result := 'Select output format...';
  end;
end;

function TACMConvertorEditor.GetVerbCount: Integer;
begin
  Result := 2;
end;

end.
 