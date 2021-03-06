/****** Object:  Database iRadio    Script Date: 2003-5-19 0:39:18 ******/
IF EXISTS (SELECT name FROM master.dbo.sysdatabases WHERE name = N'iRadio')
	DROP DATABASE [iRadio]
GO

CREATE DATABASE [iRadio]  ON (NAME = N'iRadio_Data', FILENAME = N'D:\Program Files\Microsoft SQL Server\MSSQL\data\iRadio_Data.MDF' , SIZE = 10, FILEGROWTH = 10%) LOG ON (NAME = N'iRadio_Log', FILENAME = N'D:\Program Files\Microsoft SQL Server\MSSQL\data\iRadio_Log.LDF' , SIZE = 1, FILEGROWTH = 10%)
 COLLATE Chinese_PRC_BIN
GO

exec sp_dboption N'iRadio', N'autoclose', N'false'
GO

exec sp_dboption N'iRadio', N'bulkcopy', N'false'
GO

exec sp_dboption N'iRadio', N'trunc. log', N'false'
GO

exec sp_dboption N'iRadio', N'torn page detection', N'true'
GO

exec sp_dboption N'iRadio', N'read only', N'false'
GO

exec sp_dboption N'iRadio', N'dbo use', N'false'
GO

exec sp_dboption N'iRadio', N'single', N'false'
GO

exec sp_dboption N'iRadio', N'autoshrink', N'false'
GO

exec sp_dboption N'iRadio', N'ANSI null default', N'false'
GO

exec sp_dboption N'iRadio', N'recursive triggers', N'false'
GO

exec sp_dboption N'iRadio', N'ANSI nulls', N'false'
GO

exec sp_dboption N'iRadio', N'concat null yields null', N'false'
GO

exec sp_dboption N'iRadio', N'cursor close on commit', N'false'
GO

exec sp_dboption N'iRadio', N'default to local cursor', N'false'
GO

exec sp_dboption N'iRadio', N'quoted identifier', N'false'
GO

exec sp_dboption N'iRadio', N'ANSI warnings', N'false'
GO

exec sp_dboption N'iRadio', N'auto create statistics', N'true'
GO

exec sp_dboption N'iRadio', N'auto update statistics', N'true'
GO

if( ( (@@microsoftversion / power(2, 24) = 8) and (@@microsoftversion & 0xffff >= 724) ) or ( (@@microsoftversion / power(2, 24) = 7) and (@@microsoftversion & 0xffff >= 1082) ) )
	exec sp_dboption N'iRadio', N'db chaining', N'false'
GO

use [iRadio]
GO

/****** Object:  Table [dbo].[iRadioLog]    Script Date: 2003-5-19 0:39:21 ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[iRadioLog]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[iRadioLog]
GO

/****** Object:  Table [dbo].[iRadioOnlineUser]    Script Date: 2003-5-19 0:39:21 ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[iRadioOnlineUser]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[iRadioOnlineUser]
GO

/****** Object:  Table [dbo].[iRadioUserInfo]    Script Date: 2003-5-19 0:39:21 ******/
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[iRadioUserInfo]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[iRadioUserInfo]
GO

/****** Object:  User BUILTIN\Administrators    Script Date: 2003-5-19 0:39:18 ******/
if not exists (select * from dbo.sysusers where name = N'BUILTIN\Administrators' and uid < 16382)
	EXEC sp_grantdbaccess N'BUILTIN\Administrators', N'BUILTIN\Administrators'
GO

/****** Object:  User dbo    Script Date: 2003-5-19 0:39:18 ******/
/****** Object:  Table [dbo].[iRadioLog]    Script Date: 2003-5-19 0:39:22 ******/
CREATE TABLE [dbo].[iRadioLog] (
	[SN] [int] IDENTITY (1, 1) NOT NULL ,
	[LogTime] [datetime] NOT NULL ,
	[LogProcess] [char] (30) COLLATE Chinese_PRC_BIN NOT NULL ,
	[LogType] [char] (16) COLLATE Chinese_PRC_BIN NOT NULL ,
	[LogMessage] [text] COLLATE Chinese_PRC_BIN NOT NULL 
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Table [dbo].[iRadioOnlineUser]    Script Date: 2003-5-19 0:39:25 ******/
CREATE TABLE [dbo].[iRadioOnlineUser] (
	[UserNumber] [int] NOT NULL ,
	[UserName] [char] (20) COLLATE Chinese_PRC_BIN NOT NULL ,
	[UserIP] [char] (16) COLLATE Chinese_PRC_BIN NOT NULL ,
	[UserPort] [int] NOT NULL ,
	[UserStatus] [int] NOT NULL ,
	[MeetingID] [int] NOT NULL ,
	[KillTimer] [int] NOT NULL 
) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[iRadioUserInfo]    Script Date: 2003-5-19 0:39:25 ******/
CREATE TABLE [dbo].[iRadioUserInfo] (
	[UserNumber] [int] NOT NULL ,
	[UserName] [char] (20) COLLATE Chinese_PRC_BIN NOT NULL ,
	[Password] [char] (20) COLLATE Chinese_PRC_BIN NOT NULL ,
	[LastLogonTime] [datetime] NULL ,
	[LastLogoffTime] [datetime] NULL ,
	[LastIP] [char] (16) COLLATE Chinese_PRC_BIN NULL ,
	[LastPort] [int] NULL 
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[iRadioLog] WITH NOCHECK ADD 
	CONSTRAINT [PK_iRadioLog] PRIMARY KEY  CLUSTERED 
	(
		[SN]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[iRadioOnlineUser] WITH NOCHECK ADD 
	CONSTRAINT [PK_OnlineUser] PRIMARY KEY  CLUSTERED 
	(
		[UserNumber]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[iRadioUserInfo] WITH NOCHECK ADD 
	CONSTRAINT [PK_UserInfo] PRIMARY KEY  CLUSTERED 
	(
		[UserNumber]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[iRadioOnlineUser] ADD 
	CONSTRAINT [DF_iRadioOnlineUser_KillTimer] DEFAULT (0) FOR [KillTimer]
GO

ALTER TABLE [dbo].[iRadioUserInfo] ADD 
	CONSTRAINT [DF_iRadioUserInfo_LastLogonTime] DEFAULT (0) FOR [LastLogonTime],
	CONSTRAINT [DF_iRadioUserInfo_LastLogoffTime] DEFAULT (0) FOR [LastLogoffTime]
GO

GRANT  REFERENCES ,  SELECT ,  UPDATE ,  INSERT ,  DELETE  ON [dbo].[iRadioLog]  TO [public]
GO

