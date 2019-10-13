// Tato CLR funkce odpovídá funkci dbo.Soubor_Existuje 

using System.Data.SqlTypes;
using System.IO;

public partial class UserDefinedFunctions
{
    [Microsoft.SqlServer.Server.SqlFunction]
    public static SqlBoolean FileExists(SqlString filePath)
    {
        return File.Exists(filePath.ToString());
    }
}
