object FormCall: TFormCall
  Left = 427
  Top = 246
  Width = 345
  Height = 260
  Caption = 'Call'
  Color = clBtnFace
  Font.Charset = GB2312_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = #23435#20307
  Font.Style = []
  Menu = MainMenu1
  OldCreateOrder = False
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object StatusBar: TStatusBar
    Left = 0
    Top = 195
    Width = 337
    Height = 19
    Panels = <
      item
        Width = 50
      end
      item
        Width = 50
      end
      item
        Width = 50
      end>
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 337
    Height = 160
    Align = alClient
    TabOrder = 1
    object RichEditDisplay: TRichEdit
      Left = 1
      Top = 1
      Width = 335
      Height = 158
      Align = alClient
      Font.Charset = GB2312_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = #23435#20307
      Font.Style = []
      ImeName = #20013#25991' ('#31616#20307') - '#24494#36719#25340#38899
      ParentFont = False
      ReadOnly = True
      ScrollBars = ssVertical
      TabOrder = 0
    end
    object ACMWaveOut: TACMWaveOut
      Left = 248
      Top = 1000
      Width = 32
      Height = 32
    end
    object ACMWaveIn: TACMWaveIn
      Left = 184
      Top = 1000
      Width = 32
      Height = 32
      OnData = ACMWaveInData
    end
  end
  object Panel2: TPanel
    Left = 0
    Top = 160
    Width = 337
    Height = 35
    Align = alBottom
    TabOrder = 2
    object EditSendText: TEdit
      Left = 8
      Top = 8
      Width = 249
      Height = 21
      ImeName = #20013#25991' ('#31616#20307') - '#24494#36719#25340#38899
      TabOrder = 0
    end
    object ButtonSend: TButton
      Left = 264
      Top = 6
      Width = 65
      Height = 25
      Caption = 'Send'
      Default = True
      TabOrder = 1
      OnClick = ButtonSendClick
    end
  end
  object MainMenu1: TMainMenu
    Left = 96
    Top = 32
    object File1: TMenuItem
      Caption = 'File'
      object Save1: TMenuItem
        Caption = 'Save'
        OnClick = Save1Click
      end
    end
    object Operation1: TMenuItem
      Caption = 'Operation'
      object Hangup1: TMenuItem
        Caption = 'Hangup'
        OnClick = Hangup1Click
      end
    end
  end
  object ACMDialog: TACMDialog
    Left = 184
    Top = 40
  end
  object SaveDialog: TSaveDialog
    DefaultExt = 'txt'
    Filter = 'Log File|*.txt'
    Left = 32
    Top = 16
  end
end
