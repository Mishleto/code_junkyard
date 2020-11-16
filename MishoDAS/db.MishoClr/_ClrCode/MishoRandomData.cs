using System;
using System.Collections;
using System.Collections.Generic;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;

public partial class MishoRandomData
{
    private static readonly Random _RandomSize = new Random();
    private static readonly Random _random = new Random();
    private static readonly String _CommonCharList = @"!@#$%^&*()_-+=|\ ~`0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
    private static readonly String _AlphanumCharList = @"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
    private static readonly String _AplhaCharList = @"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";


    [SqlFunction]
    public static SqlInt32 GetInt32(SqlInt32 minVal, SqlInt32 maxVal) 
    {
        if (minVal.IsNull)
            minVal = SqlInt32.MinValue;
        if (maxVal.IsNull)
            maxVal = SqlInt32.MaxValue;

        if (minVal > maxVal)
            return SqlInt32.Null;
        if (minVal == maxVal)
            return minVal;

        int res;

        lock (_random)
        {
            res = _random.Next(minVal.Value, maxVal.Value);
        }

        return (SqlInt32)res;
    }

    [return: SqlFacet(MaxSize = -1)]
    public static SqlString GetString(int sMaxSize, int IsFixed=0)
    {
        return (SqlString)GenerateRandomString(sMaxSize, IsFixed, _CommonCharList);
    }

    [return: SqlFacet(MaxSize = -1)]
    public static SqlString GetAlphaString(int sMaxSize, int IsFixed = 0)
    {
        return (SqlString)GenerateRandomString(sMaxSize, IsFixed, _AplhaCharList);
    }

    [return: SqlFacet(MaxSize = -1)]
    public static SqlString GetAlphanumString(int sMaxSize, int IsFixed = 0)
    {
        return (SqlString)GenerateRandomString(sMaxSize, IsFixed, _AlphanumCharList);
    }

    [SqlFunction(
        DataAccess = DataAccessKind.None,
        SystemDataAccess = SystemDataAccessKind.None,
        FillRowMethodName = "FillRandomInts", TableDefinition = "RndVal INT")]
    public static IEnumerable GetIntTable(int rowsCount, int minVal, int maxVal)
    {
        var res = new List<int>();
        if (rowsCount < 1)
            return res;
        if (minVal >= maxVal)
            return res;

        lock (_random)
        { 
            for (int i=0; i< rowsCount; i++)
            {
                res.Add(_random.Next(minVal, maxVal));
            }
        }

        return res;
    }

    private static void FillRandomInts(Object obj, out SqlInt32 RndVal)
    {
        RndVal = (int)obj;
    }

    private static string GenerateRandomString(int sMaxSize, int IsFixed, string charPool)
    {
        if (IsFixed == 0)
        {
            lock (_RandomSize)
            {
                sMaxSize = _RandomSize.Next(1, sMaxSize);
            }
        }

        char[] Ret = new char[sMaxSize];

        for (int i = 0; i < sMaxSize; i++)
        {
            lock (_random)
            {
                Ret[i] = charPool[_random.Next(charPool.Length)];
            }
        }

        return new string(Ret);
    }
}

public enum RandomStringType
{
    Alpha,
    AlphaNumeric,
    CommonChars
}
