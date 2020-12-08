CREATE TABLE [dbo].[miProcedureLogs]
(
	[LogID] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
	[ProcedureName] NVARCHAR(50) NOT NULL,
	[StartTime] DATETIME2 CONSTRAINT [DF_miJobLogs_StartTime] DEFAULT (sysdatetime()) NOT NULL,
	[EndTime] DATETIME2 NULL,
	[Status] NVARCHAR(20) NOT NULL,
	[ElapsedMilisecs] as datediff(millisecond, StartTime, EndTime),
	[ObjectID] INT NOT NULL,
	[CallerName] sys.sysname DEFAULT user_name() NOT NULL,
	[ParentLogID] INT NULL,
	[AdditionalInfo] NVARCHAR(2000) NULL,
	[ErrorInfo] NVARCHAR(2000) NULL
);


