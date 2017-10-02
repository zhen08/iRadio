unit UnitDefinations;

interface

const
  SAVEPACKET    = False;
  DEBUG         = True;
  VOICEDATASIZE = 194;
  TEXTDATASIZE  = 63;

  MAXKILLTIME   = 10;
  MAXUSER       = 10;

  FT_IDLE       = 0;
  FT_LOGON      = 1;
  FT_LOGONACK   = 101;
  FT_LOGOFF     = 2;
  FT_LOGOFFACK  = 102;
  FT_CALL       = 3;
  FT_CALLACK    = 103;
  FT_HANGUP     = 4;
  FT_HANGUPACK  = 104;
  FT_POLL       = 5;
  FT_POLLACK    = 105;
  FT_VOICENUL   = 6;
  FT_VOICENULACK= 106;
  FT_VOICE      = 7;
  FT_VOICEACK   = 107;
  FT_TEXT       = 8;
  FT_TEXTACK    = 108;
  FT_FILE       = 9;
  FT_FILEACK    = 109;
  FT_MAKEMEETING= 10;
  FT_MKMTINGACK = 110;
  FT_JOINMEETING= 11;
  FT_JNMTINGACK = 111;
  FT_QUITMEETING= 12;
  FT_QTMTINGACK = 112;
  FT_SYSMSG     = 13;
  FT_SYSMSGACK  = 113;
  FT_BROADCAST  = 14;
  FT_BROADCSTACK= 114;
  FT_REGIST     = 15;
  FT_REGISTACK  = 115;

  ACK_OK        = 0;
  ACK_NOUSER    = 1;
  ACK_PASSERR   = 2;
  ACK_USRBUSY   = 3;
  ACK_USROFFLINE= 4;
  ACK_REJECT    = 5;
  ACK_NOTINCALL = 7;
  ACK_DUPUSER   = 8;
  ACK_ERR       = 255;

  ST_IDLE       = 0;
  ST_LOGINGON   = 1;
  ST_FREE       = 2;
  ST_CALLING    = 3;
  ST_BUSY       = 4;
  ST_HANGING    = 5;
  ST_LOGINGOFF  = 6;
  ST_REGISTING  = 7;
  
type
  TPollUserData = record
    UserName      : array [0..19] of char;
    UserNumber    : integer;
    UserStatus    : integer;
  end;

  TPacketGeneral = record
    FrameType     : byte;
    SN            : integer;
    DestNumber    : integer;
    DestIP        : array [0..15] of char;
    DestPort      : integer;
    SourceNumber  : integer;
    SourceIP      : array [0..15] of char;
    SourcePort    : integer;
    UserName      : array [0..19] of char;
    UserPassword  : array [0..19] of char;
    MeetingID     : integer;
    Checksum      : integer;
  end;

  TPacketAck = record
    FrameType     : byte;
    SN            : integer;
    DestNumber    : integer;
    DestIP        : array [0..15] of char;
    DestPort      : integer;
    SourceNumber  : integer;
    SourceIP      : array [0..15] of char;
    SourcePort    : integer;
    MeetingID     : integer;
    AckSN         : integer;
    AckCode       : integer;
    Checksum      : integer;
  end;

  TPacketPoll = record
    FrameType     : byte;
    SN            : integer;
    DestNumber    : integer;
    SourceNumber  : integer;
    UserList      : array [0..MAXUSER] of TPollUserData;
    Checksum      : integer;
  end;

  TPacketVoice = record
    FrameType     : byte;
    SN            : integer;
    DestNumber    : integer;
    SourceNumber  : integer;
    TimeStamp     : TDateTime;
    VoiceData     : array [0..VOICEDATASIZE] of byte;
    Checksum      : integer;
  end;

  TPacketText = record
    FrameType     : byte;
    SN            : integer;
    DestNumber    : integer;
    SourceNumber  : integer;
    TimeStamp     : TDateTime;
    TextData      : array [0..TEXTDATASIZE] of char;
    Checksum      : integer;
  end;



implementation

end.
