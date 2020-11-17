using System;
using System.Data;
using System.Data.SqlClient;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;

public partial class StringProcessor
{
    [Microsoft.SqlServer.Server.SqlFunction]
    [return: SqlFacet(MaxSize = -1)]
    public static SqlString Capitalize(SqlString input)
    {
        // Put your code here
        return new SqlString (char.ToUpper(input.Value[0]) + input.Value.Substring(1).ToLower());
    }
}
