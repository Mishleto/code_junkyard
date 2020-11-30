using System;
using System.Data.SqlClient;
using System.Data.SqlTypes;
using System.Transactions;

public partial class AutonomousTran
{
    private static readonly String _logJobStartSql = String.Join(Environment.NewLine,
                                                        "INSERT into dbo.miJobLogs (JobName, ParentId, JobStatus, JobInfo)",
                                                        "OUTPUT inserted.ID",
                                                        "VALUES (@jobName, @parentId, 'STARTED', @jobInfo)");

    private static readonly String _logJobSuccessSql = String.Join(Environment.NewLine,
                                                        "UPDATE dbo.miJobLogs ",
                                                        "   set JobStatus = 'SUCCESS', ",
                                                        "       EndTime = SYSDATETIME() ",
                                                        "OUTPUT inserted.Id",
                                                        "WHERE Id = @jobId and JobStatus='STARTED'");

    private static readonly String _logJobErrorSql = String.Join(Environment.NewLine,
                                                        "UPDATE dbo.miJobLogs ", 
                                                        "   set JobStatus = 'ERROR', ",
                                                        "       EndTime = SYSDATETIME(), ",
                                                        "       ErrorInfo = @errorInfo ",
                                                        "OUTPUT inserted.Id",
                                                        "WHERE Id = @jobId and JobStatus='STARTED'");

    private static readonly String _connString = (new SqlConnectionStringBuilder {
                                                    DataSource=@"DESKTOPINHO\ARTANIS",
                                                    InitialCatalog="AW2019",
                                                    PersistSecurityInfo=true}).ConnectionString;

    [Microsoft.SqlServer.Server.SqlProcedure]
    public static SqlInt32 LogJobStart (SqlString jobName, SqlInt32 parentId, SqlString jobInfo)
    {
        var res = new SqlInt32();
        
        using (SqlCommand cmd = new SqlCommand(_logJobStartSql))
        {
            cmd.Parameters.AddWithValue("@jobName", jobName);
            cmd.Parameters.AddWithValue("@parentId", parentId);
            cmd.Parameters.AddWithValue("@jobInfo", jobInfo);
            res = (SqlInt32)ExecuteCmdScalar(cmd);
        }

        return res;
    }

    [Microsoft.SqlServer.Server.SqlProcedure]
    public static SqlInt32 LogJobSuccess(SqlInt32 jobId)
    {
        var res = new SqlInt32();

        using (var cmd = new SqlCommand(_logJobSuccessSql))
        {
            cmd.Parameters.AddWithValue("@jobId", jobId);
            res = (SqlInt32)ExecuteCmdNonQuery(cmd);
        }

        return res;
    }

    [Microsoft.SqlServer.Server.SqlProcedure]
    public static SqlInt32 LogJobError(SqlInt32 jobId, SqlString errorInfo)
    {
        var res = new SqlInt32();

        using (var cmd = new SqlCommand(_logJobErrorSql))
        {
            cmd.Parameters.AddWithValue("@jobId", jobId);
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
