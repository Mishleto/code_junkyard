using System;
using System.Data.SqlClient;
using System.Data.SqlTypes;
using System.Transactions;

public partial class AutonomousTran
{
    private static readonly String _logJobStartSql = String.Join(Environment.NewLine,
                                                        "INSERT into dbo.miProcedureLogs (ProcedureName, ObjectID, ParentLogID, Status, CallerName, AdditionalInfo)",
                                                        "OUTPUT inserted.ID",
                                                        "VALUES (@procName, @objectId, @parentLogId, 'STARTED', @callerName, @additionalInfo)");

    private static readonly String _logJobSuccessSql = String.Join(Environment.NewLine,
                                                        "UPDATE dbo.miProcedureLogs ",
                                                        "   set Status = 'SUCCESS', ",
                                                        "       EndTime = SYSDATETIME() ",
                                                        "OUTPUT inserted.Id",
                                                        "WHERE LogID = @logId and JobStatus='STARTED'");

    private static readonly String _logJobErrorSql = String.Join(Environment.NewLine,
                                                        "UPDATE dbo.miProcedureLogs ", 
                                                        "   set JobStatus = 'ERROR', ",
                                                        "       EndTime = SYSDATETIME(), ",
                                                        "       ErrorInfo = @errorInfo ",
                                                        "OUTPUT inserted.Id",
                                                        "WHERE LogID = @logId and JobStatus='STARTED'");

    private static readonly String _connString = (new SqlConnectionStringBuilder {
                                                    DataSource=@"DESKTOPINHO\ARTANIS",
                                                    InitialCatalog="AW2019",
                                                    PersistSecurityInfo=true}).ConnectionString;
    /*
 	    [LogID] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
	    [ProcedureName] NVARCHAR(50) NOT NULL,
	    [StartTime] DATETIME2 CONSTRAINT [DF_miJobLogs_StartTime] DEFAULT (SYSDATETIME()) NOT NULL,
	    [EndTime] DATETIME2 NULL,
	    [Status] NVARCHAR(20) NOT NULL,
	    [ElapsedMilisecs] as DATEDIFF(MILLISECOND, StartTime, EndTime),
	    [ObjectID] INT NOT NULL,
	    [ParentLogID] INT NULL,
	    [CallerName] sys.sysname DEFAULT CONVERT(sysname, CURRENT_USER) NOT NULL,
	    [AdditionalInfo] NVARCHAR(2000) NULL,
	    [ErrorInfo] NVARCHAR(2000) NULL
    */
    [Microsoft.SqlServer.Server.SqlProcedure]
    public static SqlInt32 LogJobStart (SqlString procName, SqlInt32 objectId, SqlInt32 parentLogId, SqlString callerName, SqlString additionalInfo)
    {
        var res = new SqlInt32();
        
        using (SqlCommand cmd = new SqlCommand(_logJobStartSql))
        {
            cmd.Parameters.AddWithValue("@procName", procName);
            cmd.Parameters.AddWithValue("@objectId", objectId);
            cmd.Parameters.AddWithValue("@parentLogId", parentLogId);
            cmd.Parameters.AddWithValue("@callerName", callerName);
            cmd.Parameters.AddWithValue("@additionalInfo", additionalInfo);
            res = (SqlInt32)ExecuteCmdScalar(cmd);
        }

        return res;
    }

    [Microsoft.SqlServer.Server.SqlProcedure]
    public static SqlInt32 LogJobSuccess(SqlInt32 logId)
    {
        var res = new SqlInt32();

        using (var cmd = new SqlCommand(_logJobSuccessSql))
        {
            cmd.Parameters.AddWithValue("@logId", logId);
            res = (SqlInt32)ExecuteCmdNonQuery(cmd);
        }

        return res;
    }

    [Microsoft.SqlServer.Server.SqlProcedure]
    public static SqlInt32 LogJobError(SqlInt32 logId, SqlString errorInfo)
    {
        var res = new SqlInt32();

        using (var cmd = new SqlCommand(_logJobErrorSql))
        {
            cmd.Parameters.AddWithValue("@logId", logId);
            cmd.Parameters.AddWithValue("@errorInfo", errorInfo);
            res = (SqlInt32)ExecuteCmdNonQuery(cmd);
        }

        return res;
    }

    private static int ExecuteCmdScalar(SqlCommand sqlCmd)
    {
        int res = -1;

        using (var tranScope = new TransactionScope(TransactionScopeOption.RequiresNew))
        {
            using (var sqlConn = new SqlConnection(_connString))
            {
                sqlCmd.Connection = sqlConn;
                sqlConn.Open();
                res = (int)sqlCmd.ExecuteScalar();
                sqlConn.Close();
            }
            tranScope.Complete();
        }

        return res;
    }

    private static int ExecuteCmdNonQuery(SqlCommand sqlCmd)
    {
        int res = -1;

        using (var tranScope = new TransactionScope(TransactionScopeOption.RequiresNew))
        {
            using (var sqlConn = new SqlConnection(_connString))
            {
                sqlCmd.Connection = sqlConn;
                sqlConn.Open();
                res = sqlCmd.ExecuteNonQuery();
                sqlConn.Close();
            }
            tranScope.Complete();
        }

        return res;
    }

}
