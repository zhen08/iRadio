object DataModuleDatabase: TDataModuleDatabase
  OldCreateOrder = False
  Left = 517
  Top = 120
  Height = 164
  Width = 254
  object SQLConnectionDatabase: TSQLConnection
    ConnectionName = 'MSSQLConnection'
    DriverName = 'MSSQL'
    GetDriverFunc = 'getSQLDriverMSSQL'
    LibraryName = 'dbexpmss.dll'
    LoginPrompt = False
    Params.Strings = (
      'DriverName=MSSQL'
      'HostName=localhost'
      'DataBase=iRadio'
      'User_Name=sa'
      'Password=thanksgiving'
      'BlobSize=-1'
      'ErrorResourceFile='
      'LocaleCode=0000'
      'MSSQL TransIsolation=ReadCommited'
      'OS Authentication=True')
    VendorLib = 'oledb'
    Connected = True
    Left = 32
    Top = 16
  end
  object SQLQueryUserInfo: TSQLQuery
    MaxBlobSize = -1
    Params = <>
    SQL.Strings = (
      'select * from iRadioUserInfo')
    SQLConnection = SQLConnectionDatabase
    Left = 160
    Top = 16
  end
  object SQLQueryLog: TSQLQuery
    MaxBlobSize = -1
    Params = <
      item
        DataType = ftDateTime
        Name = 'LogTime'
        ParamType = ptInput
        Value = 0d
      end
      item
        DataType = ftString
        Name = 'LogProcess'
        ParamType = ptInput
        Value = ''
      end
      item
        DataType = ftString
        Name = 'LogType'
        ParamType = ptInput
        Value = ''
      end
      item
        DataType = ftString
        Name = 'LogMessage'
        ParamType = ptInput
        Value = ''
      end>
    SQL.Strings = (
      
        'INSERT INTO iRadioLog ("LogTime","LogProcess","LogType","LogMess' +
        'age") VALUES(:LogTime,:LogProcess,:LogType,:LogMessage)')
    SQLConnection = SQLConnectionDatabase
    Left = 32
    Top = 72
  end
  object SQLQueryOnlineUser: TSQLQuery
    MaxBlobSize = -1
    Params = <
      item
        DataType = ftUnknown
        Name = 'UserNumber'
        ParamType = ptUnknown
      end
      item
        DataType = ftUnknown
        Name = 'UserIP'
        ParamType = ptUnknown
      end
      item
        DataType = ftUnknown
        Name = 'UserPort'
        ParamType = ptUnknown
      end
      item
        DataType = ftUnknown
        Name = 'UserStatus'
        ParamType = ptUnknown
      end
      item
        DataType = ftUnknown
        Name = 'MeetingID'
        ParamType = ptUnknown
      end
      item
        DataType = ftUnknown
        Name = 'KillTimer'
        ParamType = ptUnknown
      end
      item
        DataType = ftUnknown
        Name = 'UserNumber'
        ParamType = ptUnknown
      end
      item
        DataType = ftUnknown
        Name = 'UserNumber'
        ParamType = ptUnknown
      end
      item
        DataType = ftUnknown
        Name = 'UserIP'
        ParamType = ptUnknown
      end
      item
        DataType = ftUnknown
        Name = 'UserPort'
        ParamType = ptUnknown
      end
      item
        DataType = ftUnknown
        Name = 'UserStatus'
        ParamType = ptUnknown
      end
      item
        DataType = ftUnknown
        Name = 'MeetingID'
        ParamType = ptUnknown
      end
      item
        DataType = ftUnknown
        Name = 'KillTimer'
        ParamType = ptUnknown
      end>
    SQL.Strings = (
      
        'if(select count(*) from iRadioOnlineUser where "UserNumber" = :U' +
        'serNumber) > 0 begin'
      
        '  update iRadioOnlineUser set "UserIP" = :UserIP , "UserPort" = ' +
        ':UserPort , "UserStatus" = :UserStatus , "MeetingID" = :MeetingI' +
        'D , "KillTimer" = :KillTimer where "UserNumber" = :UserNumber'
      'end else begin'
      
        '  insert into iRadioOnlineUser ("UserNumber" , "UserIP" , "UserP' +
        'ort" , "UserStatus" , "MeetingID" , "KillTimer") values (:UserNu' +
        'mber , :UserIP , :UserPort , :UserStatus , :MeetingID , :KillTim' +
        'er)'
      'end')
    SQLConnection = SQLConnectionDatabase
    Left = 160
    Top = 72
  end
end
