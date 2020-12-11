using System;
using System.Data.SqlClient;
using System.Data.SqlTypes;
using System.Transactions;

public partial class AutonomousTran
{
    private static readonly String _logJobStartSql = String.Join(Environment.NewLine,
                                                        "INSERT into dbo.miProcedureLogs (ProcedureName, ObjectID, ParentLogID, Status, CallerName, AdditionalInfo)",
                                                        "OUTPUT inserted.LogID",
                                                        "VALUES (@procName, @objectId, @parentLogId, 'STARTED', @callerName, @additionalInfo)");

    private static readonly String _logJobSuccessSql = String.Join(Environment.NewLine,
                                                        "UPDATE dbo.miProcedureLogs ",
                                                        "   set Status = 'SUCCESS', ",
                                                        "       EndTime = SYSDATETIME() ",
                                                        "WHERE LogID = @logId and Status='STARTED'");

    private static readonly String _logJobErrorSql = String.Join(Environment.NewLine,
                                                        "UPDATE dbo.miProcedureLogs ", 
                                                        "   set Status = 'ERROR', ",
                                                        "       EndTime = SYSDATETIME(), ",
                                                        "       ErrorInfo = @errorInfo ",
                                                        "WHERE LogID = @logId and Status='STARTED'");

    private static readonly String _connString = (new SqlConnectionStringBuilder {
                                                    DataSource=@"DESKTOPINHO\ARTANIS",
                                                    InitialCatalog="AW2019",
                                                    PersistSecurityInfo=false,
                                                    IntegratedSecurity=true}).ConnectionString;

    [Microsoft.SqlServer.Server.SqlProcedure]
    public static SqlInt32 LogProcedureStart (SqlString procName, SqlInt32 objectID, SqlString callerName, SqlInt32 parentLogID, SqlString additionalInfo)
    {
        var res = new SqlInt32();
        
        using (SqlCommand cmd = new SqlCommand(_logJobStartSql))
        {
            cmd.Parameters.AddWithValue("@procName", procName);
            cmd.Parameters.AddWithValue("@objectId", objectID);
            cmd.Parameters.AddWithValue("@parentLogId", parentLogID);
            cmd.Parameters.AddWithValue("@callerName", callerName);
            cmd.Parameters.AddWithValue("@additionalInfo", additionalInfo);
            res = (SqlInt32)ExecuteCmdScalar(cmd);
        }

        return res;
    }

    [Microsoft.SqlServer.Server.SqlProcedure]
    public static SqlInt32 LogProcedureSuccess(SqlInt32 logID)
    {
        var res = new SqlInt32();

        using (var cmd = new SqlCommand(_logJobSuccessSql))
        {
            cmd.Parameters.AddWithValue("@logId", logID);
            res = (SqlInt32)ExecuteCmdNonQuery(cmd);
        }

        return res;
    }

    [Microsoft.SqlServer.Server.SqlProcedure]
    public static SqlInt32 LogProcedureError(SqlInt32 logID, SqlString errorInfo)
    {
        var res = new SqlInt32();

        using (var cmd = new SqlCommand(_logJobErrorSql))
        {
            cmd.Parameters.AddWithValue("@logId", logID);
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
