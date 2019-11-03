/*
Autor: Jakub Levý
Vytvořeno pro DBA @ MFF ZS 19/20

V případech kdy z názvu parametru není jasný jeho význam se nachází nad definicí funkce stručný popis.
*/

USE Levý_Fotbal 
GO

-- Zdrojový kód v souboru: FileExists.cs
CREATE ASSEMBLY CLR
FROM 0x4D5A90000300000004000000FFFF0000B800000000000000400000000000000000000000000000000000000000000000000000000000000000000000800000000E1FBA0E00B409CD21B8014CCD21546869732070726F6772616D2063616E6E6F742062652072756E20696E20444F53206D6F64652E0D0D0A2400000000000000504500004C010300B50CA35D0000000000000000E00022200B013000000600000006000000000000BE2500000020000000400000000000100020000000020000040000000000000006000000000000000080000000020000000000000300608500001000001000000000100000100000000000001000000000000000000000006C2500004F000000004000009002000000000000000000000000000000000000006000000C000000342400001C0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000200000080000000000000000000000082000004800000000000000000000002E74657874000000C4050000002000000006000000020000000000000000000000000000200000602E7273726300000090020000004000000004000000080000000000000000000000000000400000402E72656C6F6300000C0000000060000000020000000C00000000000000000000000000004000004200000000000000000000000000000000A025000000000000480000000200050084200000B00300000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000133001001D00000001000011000F00FE16080000016F0500000A280600000A280700000A0A2B00062A2202280800000A002A000042534A4201000100000000000C00000076342E302E33303331390000000005006C00000048010000237E0000B40100007C01000023537472696E67730000000030030000040000002355530034030000100000002347554944000000440300006C00000023426C6F620000000000000002000001471502000900000000FA013300160000010000000900000002000000020000000100000008000000040000000100000001000000020000000000B50001000000000006005B00030106007B00030106003200F0000F002301000006006701BD000A004600CF000A00C40032010A009900320106002D000A000000000001000000000001000100010010004701000015000100010050200000000096005C012D0001007920000000008618EA000600020000000100AC000900EA0001001100EA0006001900EA000A003100EA0006002900A300150049006001190039006E011E002900EA0006002000230065002E000B0034002E0013003D002E001B005C00100004800000000000000000000000000000000014000000040000000000000000000000240024000000000004000000000000000000000024001800000000000000003C4D6F64756C653E0053797374656D2E494F00434C520053797374656D2E44617461006D73636F726C69620046696C650044656275676761626C654174747269627574650053716C46756E6374696F6E41747472696275746500436F6D70696C6174696F6E52656C61786174696F6E734174747269627574650052756E74696D65436F6D7061746962696C6974794174747269627574650053716C537472696E6700546F537472696E670066696C655061746800434C522E646C6C0053797374656D0053716C426F6F6C65616E004D6963726F736F66742E53716C5365727665722E536572766572002E63746F720053797374656D2E446961676E6F73746963730053797374656D2E52756E74696D652E436F6D70696C6572536572766963657300446562756767696E674D6F6465730053797374656D2E446174612E53716C54797065730055736572446566696E656446756E6374696F6E730046696C65457869737473004F626A656374006F705F496D706C69636974000000000000006AEB512F2AD2AF44B029EDA06C202E9200042001010803200001052001011111040701111D0320000E040001020E050001111D0208B77A5C561934E089060001111D11210801000800000000001E01000100540216577261704E6F6E457863657074696F6E5468726F7773010801000701000000000401000000000000000000B50CA35D00000000020000001C0100005024000050060000525344539A0A1DA8C8B31D41B0A4FF60E0949DC001000000433A5C55736572735C6A616B75625C446F63756D656E74735C56697375616C2053747564696F20323031395C50726F6A656374735C434C525C434C525C6F626A5C44656275675C434C522E7064620000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000942500000000000000000000AE250000002000000000000000000000000000000000000000000000A0250000000000000000000000005F436F72446C6C4D61696E006D73636F7265652E646C6C0000000000FF250020001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100100000001800008000000000000000000000000000000100010000003000008000000000000000000000000000000100000000004800000058400000340200000000000000000000340234000000560053005F00560045005200530049004F004E005F0049004E0046004F0000000000BD04EFFE00000100000000000000000000000000000000003F000000000000000400000002000000000000000000000000000000440000000100560061007200460069006C00650049006E0066006F00000000002400040000005400720061006E0073006C006100740069006F006E00000000000000B00494010000010053007400720069006E006700460069006C00650049006E0066006F0000007001000001003000300030003000300034006200300000002C0002000100460069006C0065004400650073006300720069007000740069006F006E000000000020000000300008000100460069006C006500560065007200730069006F006E000000000030002E0030002E0030002E003000000030000800010049006E007400650072006E0061006C004E0061006D006500000043004C0052002E0064006C006C0000002800020001004C006500670061006C0043006F0070007900720069006700680074000000200000003800080001004F0072006900670069006E0061006C00460069006C0065006E0061006D006500000043004C0052002E0064006C006C000000340008000100500072006F006400750063007400560065007200730069006F006E00000030002E0030002E0030002E003000000038000800010041007300730065006D0062006C0079002000560065007200730069006F006E00000030002E0030002E0030002E0030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000000C000000C03500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
WITH PERMISSION_SET = UNSAFE
GO

--Vrátí 1 pokud existuje soubor s cestou @cesta
--Jinak 0
CREATE FUNCTION dbo.Soubor_Existuje(@cesta nvarchar(max))
RETURNS bit WITH EXECUTE AS CALLER
AS 
EXTERNAL NAME CLR.UserDefinedFunctions.FileExists
GO

--Vrátí sezónu, která teď je aktuální (podle aktuálního času)
CREATE function dbo.Aktuální_Sezóna()
returns date
with schemabinding
as
begin
	declare @curr_date date
	declare @sezona_start date
	set @curr_date = GETDATE()
	select top 1 @sezona_start = Start from dbo.Sezóna where Start <= @curr_date and Konec >= @curr_date
	if @sezona_start is null
		return (cast('Aktuálně není žádná sezóna. Zkuste explicitně zadat sezónu.' as date))

	return @sezona_start
end
GO

--Podle adresy, kde se odehrálo utkání a klubu, proti kterému utkání bylo vrátí
--textový řetězec 'Venku' značící, že v utkání jsme byli hosté, nebo 'Doma' značící, že jsme byli domácí
CREATE function dbo.Doma_Venku(@adresa_id int, @klub_id int)
returns nvarchar(5)
with schemabinding
as
begin
	declare @k_adresa_id int
	select @k_adresa_id = Adresa_Id from dbo.Klub where Id = @klub_id
	if @k_adresa_id = @adresa_id
		return 'Venku'

	return 'Doma'
end
GO

--Vrátí odpovídající textovou reprezentaci pohlaví
CREATE function dbo.Bit_Pohlaví(@muz bit)
returns nvarchar(4)
with schemabinding
as 
begin
	if @muz = 1
		return 'Muži'
	return 'Ženy'
end
GO


--Vrátí mládežnickou kategorii formátovanou jako textový řetězec
--@nazev ~ název ml. kategorie, př. 'starší žákyně'
--@pohlavi = 1 ~ mužské
--@pohlavi = 0 ~ ženské
--Parametr @pohlavi je nepovinný
--protože u mladších žáků víme, že se jedná o chlapce, ale u starší přípravky nevíme zda-li jde o chlapce či dívky
CREATE function dbo.Ml_Kategorie_Formátované(@nazev nvarchar(20), @pohlavi bit = null)
returns nvarchar(25)
with schemabinding
as
begin
	declare @n nvarchar(20)
	declare @p nvarchar(4)
	set @n = lower(@nazev)

	if @n = 'starší přípravka' or @n = 'mladší přípravka'
	begin
		if @pohlavi is null
			return cast('Nelze určit pohlaví ml. skupiny bez explicitního uvedení' as int)

		set @p = lower(dbo.Bit_Pohlaví(@pohlavi))
		return @nazev + ' (' + @p + ')'
	end
	return @nazev
end
GO

--Vrátí 1 pokud má hráč s @reg_id podle aktuálního času platné hostování
--Vrátí 0 jinak
CREATE function dbo.Má_Platné_Hostování(@reg_id nvarchar(7))
returns bit 
with schemabinding
as
begin
	declare @kontrakt_id nvarchar(15)
	declare @datum date
	set @datum = GETDATE()
	select top 1 @kontrakt_id = Kontrakt_Id from dbo.Hostování where Hráč_Reg_Id = @reg_id and Od <= @datum and Do > @datum
	if @kontrakt_id is not null
		return 1

	return 0
end
GO

--Pro @reg_id hráče vrátí počet utkání, ve kterém hráč nastoupil (v základu i jako náhradník)
CREATE function dbo.Počet_Odehraných_Utkání(@reg_id nvarchar(7))
returns int
with schemabinding
as
begin
	declare @ret int

	select @ret = COUNT(Hráč_Reg_Id) from dbo.Hráč_Soupiska
	join dbo.Utkání on Utkání.Soupiska_Id = Hráč_Soupiska.Soupiska_Id
	where Hráč_Reg_Id = @reg_id

	return @ret
end
GO


--Pro @reg_id hráče vrátí počet utkání, ve kterém hráč nastoupil jako náhradník
CREATE function dbo.Počet_Odehraných_Utkání_Náhradník(@reg_id nvarchar(7))
returns int
with schemabinding
as
begin
	declare @ret int

	select @ret = COUNT(Hráč_Reg_Id) from dbo.Hráč_Soupiska
	join dbo.Utkání on Utkání.Soupiska_Id = Hráč_Soupiska.Soupiska_Id
	where Hráč_Reg_Id = @reg_id and Náhradník = 1

	return @ret
end
GO

--Pro @reg_id hráče vrátí počet utkání, ve kterém hráč nastoupil v základní sestavě
CREATE function dbo.Počet_Odehraných_Utkání_V_Základu(@reg_id nvarchar(7))
returns int
with schemabinding
as
begin
	declare @ret int

	select @ret = COUNT(Hráč_Reg_Id) from dbo.Hráč_Soupiska
	join dbo.Utkání on Utkání.Soupiska_Id = Hráč_Soupiska.Soupiska_Id
	where Hráč_Reg_Id = @reg_id and Náhradník = 0

	return @ret
end
GO

--Vrátí 1, pokud existuje nějaký klub, který sídlí na @adresa_id
--Jinak 0
CREATE function dbo.Sídlí_Klub(@adresa_id int)
returns bit
with schemabinding
as
begin
	declare @klub_id int
	select @klub_id = Id from dbo.Klub where Adresa_Id = @adresa_id
	if @klub_id is not null
		return 1

	return 0
end
GO

--Vrátí počet lidí, kteří jsou zapsáni na soupisce s Id = @soupiska_id
CREATE function dbo.Soupiska_Počet_Lidí(@soupiska_id int)
returns int
with schemabinding
as
begin
	declare @ret int
	select @ret = COUNT(*) from dbo.Hráč_Soupiska where Soupiska_Id = @soupiska_id
	return @ret
end
GO

--Vrátí předvolbu + tel. číslo pro dané id tel. čísla (@tel_id)
--Pokud předvolba tel. čísla je NULL tak implicitně předpokládáme +420 (českou předvolbu)
CREATE function dbo.Tel_Číslo(@tel_id int)
returns nvarchar(13)
with schemabinding
as
begin
	declare @predvolba nvarchar(4)
	declare @cislo nvarchar(9)
	select @predvolba = Předvolba, @cislo = Číslo from dbo.Tel where Id = @tel_id

	if @predvolba is null 
		return '+420' + @cislo
	return @predvolba + @cislo
end
GO

--Pro reg_id hráče (@hrac_id) vrátí odpovídající textovou reprezentace ml. kategorie
CREATE function dbo.Urči_Ml_Kategorii (@hrac_id nvarchar(7))
returns nvarchar(20)
with schemabinding
as
begin
	declare @retval nvarchar
	declare @vek int
	declare @d_nar date
	declare @muz bit

	select @d_nar = D_Narození, @muz = Muž from dbo.Hráč where Reg_Id = @hrac_id

	set @vek = dbo.Věk(@d_nar)

	if @vek >= 5 and @vek <= 8
	begin
		return 'Mladší přípravka'
	end

	if @vek >= 9 and @vek <= 10
	begin
		return 'Starší přípravka'
	end

	if @muz = 1
	begin
		if @vek >= 11 and @vek <= 12
			return 'Mladší žáci'

		if @vek >= 13 and @vek <= 14
			return 'Starší žáci'

		if @vek >= 15 and @vek <= 16
			return 'Mladší dorost'

		if @vek >= 17 and @vek <= 18
			return 'Starší dorost'

		return 'Muži'
	end
	else
	begin
		if @vek >= 11 and @vek <= 12
			return 'Mladší žákyně'

		if @vek >= 13 and @vek <= 14
			return 'Starší žákyně'

		if @vek >= 15 and @vek <= 16
			return 'Mladší dorostenky'

		if @vek >= 17 and @vek <= 18
			return 'Starší dorostenky'
		return 'Ženy'
	end
	return 'ERROR' -- sem se nikdy nedostaneme
end
GO

--Pro reg_id (@hrac_id) hráče vrátí dvojci (název, pohlaví) ml. kategorie, do které patří
CREATE function dbo.Urči_Ml_Kategorii_Pohlaví(@hrac_id nvarchar(7))
returns @kategorie table
(
	Název nvarchar(20) not null,
	Pohlaví bit not null
)
with schemabinding
as
begin
	declare @vek int
	declare @d_nar date
	declare @muz bit

	select @d_nar = D_Narození, @muz = Muž from dbo.Hráč where Reg_Id = @hrac_id

	set @vek = dbo.Věk(@d_nar)

	if @muz = 1
	begin
		if @vek >= 5 and @vek <= 8
		begin
			insert @kategorie
			select 'Mladší přípravka', 1
		end

		else if @vek >= 9 and @vek <= 10
		begin
			insert @kategorie
			select 'Starší přípravka', 1
		end
		else if @vek >= 11 and @vek <= 12
		begin
			insert @kategorie
			select 'Mladší žáci', 1
		end

		else if @vek >= 13 and @vek <= 14
		begin
			insert @kategorie
			select 'Starší žáci', 1
		end

		else if @vek >= 15 and @vek <= 16
		begin
			insert @kategorie
			select 'Mladší dorost', 1
		end

		else if @vek >= 17 and @vek <= 18
		begin
			insert @kategorie
			select 'Starší dorost', 1
		end
		else
		begin
			insert @kategorie
			select 'Muži', 1
		end
	end
	else
	begin
		if @vek >= 5 and @vek <= 8
		begin
			insert @kategorie
			select 'Mladší přípravka', 0
		end

		else if @vek >= 9 and @vek <= 10
		begin
			insert @kategorie
			select 'Starší přípravka', 0
		end
		else if @vek >= 11 and @vek <= 12
		begin
			insert @kategorie
			select 'Mladší žákyně', 0
		end

		else if @vek >= 13 and @vek <= 14
		begin
			insert @kategorie
			select 'Starší žákyně', 0
		end

		else if @vek >= 15 and @vek <= 16
		begin
			insert @kategorie
			select 'Mladší dorostenky', 0
		end

		else if @vek >= 17 and @vek <= 18
		begin
			insert @kategorie
			select 'Starší dorostenky', 0
		end
		else
		begin
			insert @kategorie
			select 'Ženy', 0
		end
	end
	return
end
GO

--Hráč, který nemá záznam o hostování v tabulce Hostování, je považován za majetek klubu, za který hraje
--@reg_id ~ registrační číslo hráče
--Vrací 1 pokud vlastním hráče
--Jinak 0
CREATE function dbo.Vlastním_Hráče(@reg_id nvarchar(7))
returns bit
with schemabinding
as
begin
	declare @kontrakt_id nvarchar(15)
	select top 1 @kontrakt_id = Kontrakt_Id from dbo.Hostování where Hráč_Reg_Id = @reg_id
	if @kontrakt_id is null
		return 1
	
	return 0
end
GO



--Vrátí pěkné formátované skóre v textovém řetězci
--Př. výstupu: '3 : 2 (0 : 2)'
CREATE function dbo.Skóre(@goly_my int, @goly_souper int, @goly_my_polocas int = null, @goly_souper_polocas int = null)
returns nvarchar(20)
with schemabinding
as
begin
	if @goly_my_polocas is null or @goly_souper_polocas is null
		return cast(@goly_my as nvarchar(2)) + ' : ' + cast(@goly_souper as nvarchar(2))

	return cast(@goly_my as nvarchar(2)) + ' : ' + cast(@goly_souper as nvarchar(2)) + ' (' + cast(@goly_my_polocas as nvarchar(2)) + ' : ' + cast(@goly_souper_polocas as nvarchar(2)) + ')' 
end
GO

--U většiny kategorií je možné z názvu zjistit pohlaví dané skupiny
--Př. Starší žáci je mužská kategorie
--Existují však kategorie, u kterých to nejde jako např. mladší přípravka (může se jednat o chlapce i dívky)
--V tomto případě dojde k výjimce
--@kategorie ~ název mládežnické kategorie
CREATE function dbo.Ml_Kategorie_Pohlaví(@kategorie nvarchar(20))
returns bit
with schemabinding
as
begin
	declare @kat nvarchar(20)
	set @kat = lower(@kategorie)
	if @kat = 'mladší dorost' or @kat = 'mladší žáci' or @kat = 'starší dorost' or @kat = 'starší žáci' or @kat = 'muži'
		return 1
	else if @kat = 'mladší dorostenky' or @kat = 'mladší žákyně' or @kat = 'starší dorostenky' 
		 or @kat = 'starší žákyně' or @kat = 'ženy'
		return 0

	return CAST('Nejde zjistit pohlaví skupiny ' + @kategorie as bit)
end
GO

--Převod z textové reprezentace pohlaví na bit
--@pohlavi ~ textová reprezentace pohlaví
CREATE function dbo.Pohlaví_Bit(@pohlavi nvarchar(6))
returns bit
with schemabinding
as
begin
	declare @p_lower nvarchar(6)
	set @p_lower = lower(@pohlavi)

	if @p_lower = 'm' or @p_lower = 'muž' or @p_lower = 'male' or @p_lower = 'muz' or @p_lower = 'mužské' 
	or @p_lower = 'muzske' or @p_lower = 'muzi' or @p_lower = 'muži' or @p_lower = 'mužske' or @p_lower = 'muzské'
		return 1

	else if @p_lower = 'f' or @p_lower = 'female' or @p_lower = 'ž' or @p_lower = 'z' or @p_lower = 'žena' 
	     or @p_lower = 'zena' or @p_lower = 'zeny' or @p_lower = 'ženy' or @p_lower = 'ženské' 
		 or @p_lower = 'zenske' or @p_lower = 'ženske' or @p_lower = 'zenské'
		return 0

	return cast('Neplatné pohlaví' as int)
end
