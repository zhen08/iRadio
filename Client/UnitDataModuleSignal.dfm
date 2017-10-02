object DataModuleSignal: TDataModuleSignal
  OldCreateOrder = False
  OnCreate = DataModuleCreate
  OnDestroy = DataModuleDestroy
  Left = 567
  Top = 290
  Height = 179
  Width = 245
  object TimerTimeout: TTimer
    Enabled = False
    OnTimer = TimerTimeoutTimer
    Left = 152
    Top = 88
  end
  object UDP: TIdUDPServer
    Active = True
    Bindings = <
      item
        IP = '0.0.0.0'
        Port = 8873
      end>
    DefaultPort = 8873
    OnUDPRead = UDPUDPRead
    Left = 40
    Top = 24
  end
  object IdTime: TIdTime
    MaxLineAction = maException
    ReadTimeout = 0
    BaseDate = 2.000000000000000000
    Timeout = 1000
    Left = 40
    Top = 88
  end
  object TimerPoll: TTimer
    OnTimer = TimerPollTimer
    Left = 152
    Top = 24
  end
end
