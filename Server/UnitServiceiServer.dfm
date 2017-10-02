object ServiceiServer: TServiceiServer
  OldCreateOrder = False
  DisplayName = 'iRadio Server'
  Interactive = True
  OnPause = ServicePause
  OnStart = ServiceStart
  OnStop = ServiceStop
  Left = 192
  Top = 107
  Height = 150
  Width = 215
  object TimerPoll: TTimer
    Interval = 2000
    OnTimer = TimerPollTimer
    Left = 88
    Top = 56
  end
  object UDP: TIdUDPServer
    Active = True
    BufferSize = 65536
    BroadcastEnabled = True
    Bindings = <
      item
        IP = '0.0.0.0'
        Port = 7388
      end>
    DefaultPort = 7388
    OnUDPRead = UDPUDPRead
    Left = 144
    Top = 56
  end
  object IdTimeServer: TIdTimeServer
    Active = True
    Bindings = <
      item
        IP = '0.0.0.0'
        Port = 7373
      end>
    CommandHandlers = <>
    DefaultPort = 7373
    Greeting.NumericCode = 0
    MaxConnectionReply.NumericCode = 0
    ReplyExceptionCode = 0
    ReplyTexts = <>
    ReplyUnknownCommand.NumericCode = 0
    BaseDate = 2.000000000000000000
    Left = 32
    Top = 56
  end
end
