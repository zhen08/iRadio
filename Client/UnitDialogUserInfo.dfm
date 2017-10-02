object DialogUserInfo: TDialogUserInfo
  Left = 245
  Top = 108
  Width = 321
  Height = 203
  Caption = 'Dialog'
  Color = clBtnFace
  Font.Charset = GB2312_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = #23435#20307
  Font.Style = []
  OldCreateOrder = True
  Position = poScreenCenter
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Bevel1: TBevel
    Left = 8
    Top = 8
    Width = 297
    Height = 121
    Shape = bsFrame
  end
  object Label1: TLabel
    Left = 36
    Top = 48
    Width = 70
    Height = 13
    Caption = 'User Name '
  end
  object Label2: TLabel
    Left = 36
    Top = 80
    Width = 63
    Height = 13
    Caption = 'Password '
  end
  object OKBtn: TButton
    Left = 79
    Top = 140
    Width = 75
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 2
    OnClick = OKBtnClick
  end
  object CancelBtn: TButton
    Left = 159
    Top = 140
    Width = 75
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 3
    OnClick = CancelBtnClick
  end
  object EditUserName: TEdit
    Left = 112
    Top = 40
    Width = 121
    Height = 21
    ImeMode = imClose
    ImeName = #20013#25991' ('#31616#20307') - '#24494#36719#25340#38899
    MaxLength = 20
    TabOrder = 0
    OnKeyPress = EditUserNameKeyPress
  end
  object EditPassword: TEdit
    Left = 112
    Top = 72
    Width = 121
    Height = 21
    ImeMode = imClose
    ImeName = #20013#25991' ('#31616#20307') - '#24494#36719#25340#38899
    MaxLength = 20
    PasswordChar = '*'
    TabOrder = 1
    OnKeyPress = EditPasswordKeyPress
  end
end
