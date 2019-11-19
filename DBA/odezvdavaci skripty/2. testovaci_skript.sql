/*
Autor: Jakub Levý
Vytvořeno pro DBA @ MFF ZS 19/20

Tento soubor obsahuje testovací demo předvádějící hlavní funkcionalitu DB.
Předpokládáme, že v DB jsou již testovací data obsažena v souboru '1. testovaci_data.sql'
*/

--Test constraints

--Constraints tabulky Adresa
--Ani jeden z následujících příkazů pro vložení neprojde přes omezení
insert into Adresa (Ulice, Č_p, Město, Psč) values ('17. listopadu','2k19', 'Praha', '10001')
insert into Adresa (Ulice, Č_p, Město, Psč) values ('$17. listopadu','2/19', 'Praha', '10001')
insert into Adresa (Ulice, Č_p, Město, Psč) values ('17. listopadu','2/19', 'Praha@', '10002')
insert into Adresa (Ulice, Č_p, Město, Psč) values ('17. listopadu','2/19', 'Praha', '00002')

--Tento příkaz projde
insert into Adresa (Ulice, Č_p, Město, Psč) values ('17. listopadu','2/19', 'Praha', '10002')

--Kontrola
select * from Adresa where Id = SCOPE_IDENTITY()

--Constraint tabulky Hostování
declare @machov int
select @machov = Id from Klub where Název = 'VEBA Machov'
--Hostování nemůže skončit dříve než začně
exec Přidej_Hostování '10A45XXX12', '2020-02-10', '2020-01-10', 5000, '1650655', @machov
--Neprošlo

--Constraints tabulky Hráč
--Uvnitř procedůry Přidej_Hráče se nachází transakce, 
--při selhání DB zůstane neupravena díky využítí transakce
--Neprojde - neplatný formát FAČR registračního čísla
exec Přidej_Hráče '1434A59', 'Milan', 'Konečný', 'mužské', '1989-11-05', 'mkonecny@email.cz', '744389520'

--Neprojde - hráči musí být alespoň pět let před registrací
exec Přidej_Hráče '1434159', 'Milan', 'Konečný', 'mužské', '2017-11-05', 'mkonecny@email.cz', '744389520'

--Constraints tabulky Hráč_Soupiska
--Neprojde - číslo dresu musí být > 0 a < 100
begin transaction
begin try
	declare @soupiska int
	exec Vytvoř_Prázdnou_Soupisku @soupiska_id = @soupiska output
	exec Přidej_Hráče_Na_Soupisku '1811787', @soupiska, @cislo_dresu = 150, @nahradnik = 0
	commit transaction
end try
begin catch
	--znovu vyhození výjimky, která nastala ve try
    declare @ErrorMessage nvarchar(max), @ErrorSeverity int, @ErrorState int;
    select @ErrorMessage = ERROR_MESSAGE() + ' Line ' + cast(ERROR_LINE() as nvarchar(5)), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();

	rollback transaction
	raiserror (@ErrorMessage, @ErrorSeverity, @ErrorState);
end catch

--Constraint tabulky Klub
--Neprojde - neplatný název klubu
exec Přidej_Klub '007Kacau007', 'Bří. Čapků', '13', 'Dolany', '30012'

--Constraints tabulky Kontakt
--Neprojde - neplatné jméno/přijmení
exec Přidej_Kontakt 'James 007', 'Bond', 'james@007.uk', '773903128', '+44'
exec Přidej_Kontakt 'James', 'Bond 007', 'james@007.uk', '773903128', '+44'

--Neprojde - email nebo tel. číslo vyžadováno
exec Přidej_Kontakt 'James', 'Bond', @predvolba = '+44'

--Toto již projde
exec Přidej_Kontakt 'James', 'Bond', @tel_cislo = '007007007', @predvolba = '+44' --UK

--Constrains tabulky Ml_Kategorie
--Neprojde - fotbalové utkání nemůže mít 100 minut
insert into Ml_Kategorie (Název, Muži, Délka_Zápasu_Minut) VALUES ('Kojenci', 1, 100)

--Constraints tabulky Sezóna
--Neprojde
exec Přidej_Sezónu '2022-10-23', '2024-01-02' --moc dlouhá sezóna
exec Přidej_Sezónu '2024-09-29', '2023-08-15' --kon < zac

--Constraints tabulky Tel
--Neprojde
exec Přidej_Kontakt 'Jaromír', 'Soukup', 'jarda@barrandov.cz', '77471Z855' --neplatné tel. číslo
exec Přidej_Kontakt 'Jaromír', 'Soukup', 'jarda@barrandov.cz', '774715855', @predvolba = '-420' --neplatná tel. předvolba

--Constraints tabulky Utkání
--Neprojde ani jeden příkaz
exec Přidej_Utkání 101, 5, 1, 1, 1, 1, 'Mladší dorost' --nemůže padnou 101 gólu ve fotbale v rámci jednoho utkání
--O poločase víc gólu než na konci utkání
exec Přidej_Utkání 5, 3, 1, 1, 1, 1, 'Starší žáci', @goly_my_polocas = 2, @goly_souper_polocas = 4 -- 5 : 3 (2 : 4) je neplatné skóre


--Test triggerů

--Trigger na tabulce Hostování
--V DB je hráč s reg. č. '1915044' s platným hostováním od '2013-03-15' do '2013-12-12'
select * from Hráči_Hostování where [Reg. č.] = '1915044'
--Pokusíme se tomuto hráči přidat další hostování, které má neprázdný průnik s již existujícím hostováním
--Příkaz neprojde
declare @c1 int
select @c1 = Id from Klub where Název = 'VEBA Machov'
exec Přidej_Hostování 'JAM1001EX25', '2013-10-27', '2014-07-17', 35000, '1915044', @c1

--Hostování, která mají prázdný průnik však projdou
declare @c2 int
select @c2 = Id from Klub where Název = 'VEBA Machov'
exec Přidej_Hostování 'JAM1001EX25', '2009-10-27', '2011-07-17', 35000, '1915044', @c2

--Přidání můžeme ověřit
select * from Hráči_Hostování where [Reg. č.] = '1915044'

--Trigger Kontrola_Využití_Soupisky na tabulce Hráč_Soupiska
--Vybereme si nějakou soupisku, která je již přiřazena k existujícímu utkání a smažeme z ní všechny hráče
--Logicky vznikne soupiska, která nemůže být přiřazena k žádnému utkání
--Následující příkazy neprojdou
declare @vyuzita_soupiska int
select top 1 @vyuzita_soupiska = Soupiska_Id from Utkání 
delete from Hráč_Soupiska where Soupiska_Id = @vyuzita_soupiska

--Trigger Kontrola_Soupisky na tabulce Hráč_Soupiska
--duplicitní dresy
declare @ns int
exec Vytvoř_Prázdnou_Soupisku @soupiska_id = @ns output
--oba hráčí mají číslo dresu 5, toto neprojde
exec Přidej_Hráče_Na_Soupisku '0001820', @ns, 5, 0
exec Přidej_Hráče_Na_Soupisku '0004530', @ns, 5, 0

--Na druhou stranu toto již projde
declare @ns2 int
exec Vytvoř_Prázdnou_Soupisku @soupiska_id = @ns2 output
--jeden hráč má číslo dresu 5 a druhý 6
exec Přidej_Hráče_Na_Soupisku '0001820', @ns2, 5, 0
exec Přidej_Hráče_Na_Soupisku '0004530', @ns2, 6, 0

--Maximální počet náhradníku (7)
--Pokusíme se přidat 8 náhradníků na novou soupisku
declare @ns3 int
exec Vytvoř_Prázdnou_Soupisku @soupiska_id = @ns3 output
exec Přidej_Hráče_Na_Soupisku '0001820', @ns3, 1, 1
exec Přidej_Hráče_Na_Soupisku '0004530', @ns3, 2, 1
exec Přidej_Hráče_Na_Soupisku '0033513', @ns3, 3, 1
exec Přidej_Hráče_Na_Soupisku '0046815', @ns3, 4, 1
exec Přidej_Hráče_Na_Soupisku '0095357', @ns3, 5, 1
exec Přidej_Hráče_Na_Soupisku '0102630', @ns3, 6, 1
exec Přidej_Hráče_Na_Soupisku '0471068', @ns3, 7, 1
exec Přidej_Hráče_Na_Soupisku '0434013', @ns3, 8, 1 --Tento již má smůlu, prošlo jich prvních 7

--Kontrola
select * from Hráči_Na_Soupisce where [Id soupisky] IN (select max(Id) from Soupiska)

--Kontrola výskytu hráčů jedné kategorie (věk, pohlaví)

--Hráč s reg. č. '0095357' spadá do kategorie Muži
--Hráč s reg. č. '1811787' spadá do kategorie Starší dorost
--Kontrola
select * from Hráči where [Reg. č.] = '0095357' or [Reg. č.] = '1811787'

--Pokusíme se je přidat na jednu soupisku (neprojde)
declare @ns4 int
exec Vytvoř_Prázdnou_Soupisku @soupiska_id = @ns4 output
exec Přidej_Hráče_Na_Soupisku '0095357', @ns4, 5, 0
exec Přidej_Hráče_Na_Soupisku '1811787', @ns4, 10, 0

--Na soupisku se přidal pouze první hráč, ten určil kategorii soupisky
select * from Hráči_Na_Soupisce where [Id soupisky] IN (select max(Id) from Soupiska)

--Kontrola maximálního počtu hráčů na soupisce (18)
--Nejprve budeme potřebovat přidat další hráče do DB
--Pokusíme se přidat > 18 hráčů novou soupisku (přesněji řečeno 20 hráčů)
exec Přidej_Hráče '3128202', 'Kamil', 'Brodský', 'mužské', '1990-10-01', 'kamil@brodak.cz', '601958933'
exec Přidej_Hráče '4328223', 'Roman', 'Loskot', 'mužské', '1993-04-22', 'roman.loskot@uhk.cz', '894453270'
exec Přidej_Hráče '5163443', 'Radek', 'Cvejn', 'mužské', '1989-07-31', 'radek.cvejn@uhk.cz', '123421343'
exec Přidej_Hráče '1299451', 'Yoshiko', 'Nagai', 'mužské', '1991-03-22', 'sekai.wa.nagai@hontoni.jp', '478439098', '+81'

declare @ns5 int
exec Vytvoř_Prázdnou_Soupisku @soupiska_id = @ns5 output
exec Přidej_Hráče_Na_Soupisku '3128202', @ns5, 1, 0
exec Přidej_Hráče_Na_Soupisku '4328223', @ns5, 2, 0
exec Přidej_Hráče_Na_Soupisku '5163443', @ns5, 3, 0
exec Přidej_Hráče_Na_Soupisku '1299451', @ns5, 4, 0
exec Přidej_Hráče_Na_Soupisku '0001820', @ns5, 5, 0
exec Přidej_Hráče_Na_Soupisku '0004530', @ns5, 6, 0
exec Přidej_Hráče_Na_Soupisku '0033513', @ns5, 7, 0
exec Přidej_Hráče_Na_Soupisku '0046815', @ns5, 8, 0
exec Přidej_Hráče_Na_Soupisku '0095357', @ns5, 9, 0
exec Přidej_Hráče_Na_Soupisku '0102630', @ns5, 10, 0
exec Přidej_Hráče_Na_Soupisku '0471068', @ns5, 11, 0
exec Přidej_Hráče_Na_Soupisku '0434013', @ns5, 12, 1
exec Přidej_Hráče_Na_Soupisku '0374901', @ns5, 13, 1
exec Přidej_Hráče_Na_Soupisku '0549405', @ns5, 14, 1
exec Přidej_Hráče_Na_Soupisku '0593646', @ns5, 15, 1
exec Přidej_Hráče_Na_Soupisku '0645778', @ns5, 16, 1
exec Přidej_Hráče_Na_Soupisku '0668429', @ns5, 17, 1
exec Přidej_Hráče_Na_Soupisku '0996668', @ns5, 18, 1
exec Přidej_Hráče_Na_Soupisku '1094895', @ns5, 19, 1 --má smůlu, na soupisku se již nevejde
exec Přidej_Hráče_Na_Soupisku '1937981', @ns5, 20, 1 --má smůlu, na soupisku se již nevejde

--Kontrola, na soupisce je 18 hráčů, poslední dva se na ní nevyskytují
select * from Hráči_Na_Soupisce where [Id soupisky] IN (select max(Id) from Soupiska)

--Kontrola, že poslední dva hráči tam opravdu nejsou
select * from Hráči_Na_Soupisce where [Id soupisky] IN (select max(Id) from Soupiska) and ([Reg. č.] = '1094895' or [Reg. č.] = '1937981')


--Trigger na tabulce Klub
--Na adrese klubu VEBA Machov se odehrály dvě utkání
select * from Klub_Adresa_Počet_Utkání where [Název klubu] = 'VEBA Machov'
--Vzhledem k tomu by z DB nemělo být možné odstranit klub VEBA Machov
--A také není, následující dotaz neprojde
delete from Klub where Název = 'VEBA Machov'
--(Error, který dostaneme nebude ten z triggeru, 
--protože klub VEBA Machov také nelze odstranit, 
--protože existuje utkání, v kterém je VEBA Machov soupeřem)
--Pokud by se však utkání odehrálo na adrese klubu, jenž není soupeřem
--v žádném utkání, pak bychom dostali error z triggeru - kód je jednoduchý
--a je zřejmé, že implementace funguje

--Trigger Smaž_Tel na tabulce Kontakt
--Pokud jsme spustili všechny předchozí příklady, které měli projít
--měli bychom v DB mít jeden neužitečný kontakt (James Bond)
select * from Nevyužité_Kontakty
--Pokud chybí, tak spustit: exec Přidej_Kontakt 'James', 'Bond', @tel_cislo = '007007007', @predvolba = '+44'
--V tabulce Tel je uloženo telefonní číslo Jamese Bonda
select * from Tel where Předvolba = '+44'
--Smažeme Jamese Bonda z DB
delete from Kontakt where Jméno = 'James' and Příjmení = 'Bond'
--Ve výpisu:
--(1 row affected)
--(1 row affected)
--Smazal se kontakt i jeho telefonní informace
select * from Tel where Předvolba = '+44'

--Trigger Smaž_Tel_Pokud_Změněn na tabulce Kontakt
--Vraťme se do původní situace, přidejme si opět Jamese Bonda do DB
exec Přidej_Kontakt 'James', 'Bond', @tel_cislo = '007007007', @predvolba = '+44'
--Opět se v tabulce Tel nachází jeho telefonní číslo
select * from Tel where Předvolba = '+44'
--Nyní se ho pokusíme změnit na nové číslo (divným způsobem, aby staré číslo zůstalo v DB)
insert into Tel (Předvolba, Číslo) VALUES ('+44', '111111111')
update Kontakt SET Tel_Id = SCOPE_IDENTITY() where Jméno = 'James' and Příjmení = 'Bond'
--Opět byli upraveny 2 řádky v DB
--Staré číslo by již nebylo vázáno na existující Kontakt a tak bylo smazáno z DB
select * from Tel where Předvolba = '+44'

--Trigger na tabulce Utkání
--Nemůžeme vytvořit utkání se soupiskou hráčů, která neobsahuje alespoň minimální počet hráčů (7)
--Vytvoříme si soupisku s jenom šesti hráči a zkusíme vytvořit utkání
declare @ns6 int
exec Vytvoř_Prázdnou_Soupisku @soupiska_id = @ns6 output
exec Přidej_Hráče_Na_Soupisku '3128202', @ns6, 1, 0
exec Přidej_Hráče_Na_Soupisku '4328223', @ns6, 2, 0
exec Přidej_Hráče_Na_Soupisku '5163443', @ns6, 3, 0
exec Přidej_Hráče_Na_Soupisku '1299451', @ns6, 4, 0
exec Přidej_Hráče_Na_Soupisku '0004530', @ns6, 5, 0
exec Přidej_Hráče_Na_Soupisku '0033513', @ns6, 6, 0
declare @r1 int
select top 1 @r1 = Id from Rozhodčí
declare @s1 int, @a1 int
select @s1 = Id, @a1 = Klub.Adresa_Id from Klub where Název = 'RSCM Rozkoš'
exec Přidej_Utkání 5, 3, @s1, @a1, @r1, @ns6, 'Muži'

--Neprošlo, zkusíme to znovu, pouze s jedním hráčem navíc
declare @sa int 
select @sa = max(Id) from Soupiska
exec Přidej_Hráče_Na_Soupisku '0996668', @sa, 7, 0
declare @r2 int
select top 1 @r2 = Id from Rozhodčí
declare @s2 int, @a2 int
select @s2 = Id, @a2 = Klub.Adresa_Id from Klub where Název = 'RSCM Rozkoš'
exec Přidej_Utkání 5, 3, @s2, @a2, @r2, @sa, 'Muži'
--Prošlo

--Kontrola
select * from Zápas where [Id zápasu] IN (select max(Id) from Utkání)

--Kategorie, pro kterou je určené utkání musí být stejné jako kategorie hráčů na soupisce
--Využijeme validní (čítající pouze 7 hráčů) soupisku z předchozího, jenom zkusíme změnit kategorii z Muži na cokoliv jiného
declare @sb int 
select @sb = max(Id) from Soupiska
declare @r3 int
select top 1 @r3 = Id from Rozhodčí
declare @s3 int, @a3 int
select @s3 = Id, @a3 = Klub.Adresa_Id from Klub where Název = 'RSCM Rozkoš'
exec Přidej_Utkání 5, 3, @s3, @a3, @r3, @sb, 'Mladší žáci'

--Neprošlo protože hráčí na soupisce spadají pod kategorii Muži, což si můžeme ověřit:
select * from Hráči_Na_Soupisce where [Id soupisky] IN (select max(Id) from Soupiska)

--Kontrola, zda-li na adrese, kde se koná utkání sídlí nějaký klub
--Utkání se jinde konat nemůže -- kde nesídlí klub není hriště :)
--Vytvoříme si novou adresu, která nebude asociována s žádným klubem a zkusíme na ní vytvořit utkání
declare @a4 int
exec Přidej_Adresu 'Národní', '23', 'Praha', '10002', @adresa_id = @a4 output
declare @sc int 
select @sc = max(Id) from Soupiska
declare @r4 int
select top 1 @r4 = Id from Rozhodčí
declare @s4 int
select @s4 = Id from Klub where Název = 'RSCM Rozkoš'
exec Přidej_Utkání 5, 3, @s4, @a4, @r4, @sc, 'Muži'
--Neprošlo

--Kontrola, zda-li hráči na soupisce mají validní hostování v sezóně utkání
--Opět využijeme předchozí soupisku, jenom jednomu hráči přidáme hostování, které již nebude
--aktuální a zkusíme přidat nové utkání
declare @sol int
select @sol = Id from Klub where Název = 'SK Solnice'
exec Přidej_Hostování 'XC25OOM1010', '2012-05-17', '2016-08-08', 50000, '3128202', @sol
declare @sd int 
select @sd = max(Id) from Soupiska
declare @r5 int
select top 1 @r5 = Id from Rozhodčí
declare @s5 int, @a5 int
select @s5 = Id, @a5 = Klub.Adresa_Id from Klub where Název = 'RSCM Rozkoš'
exec Přidej_Utkání 5, 3, @s5, @a5, @r5, @sd, 'Muži', @sezona_start = '2019-10-08'
--Neprošlo

--Test procedůr

--Hostování_Mateřský_Klub
--Přidáme si do DB dvě nové hráčky, jedné přidáme hostování z TJ Koněpůlek a druhé z SK Solnice
exec Přidej_Hráče '8742367', 'Kamila', 'Smutná', 'ženské', '2006-02-27', 'k.smutna@deckonachod.cz', '847302298'
exec Přidej_Hráče '9732367', 'Anna', 'Kutinová', 'ženské', '2006-05-13', 'anicka@kutinova.cz', '273489478'
declare @par1 int, @sol1 int
select @par1 = Id from Klub where Název = 'TJ Koněpůlky'
select @sol1 = Id from Klub where Název = 'SK Solnice'
exec Přidej_Hostování '45AA502500C', '2012-07-17', '2014-05-15', 5000, '8742367', @par1
exec Přidej_Hostování '2500X50CC12', '2018-03-21', '2021-01-12', 75000, '9732367', @sol1

--Podíváme se na hráče s hostováním pocházející z klubu TJ Koněpůlky
exec Hostování_Mateřský_Klub 'TJ Koněpůlky'
--ve výpisu je Kamila Smutná

--a SK Solnice 
exec Hostování_Mateřský_Klub 'SK Solnice'
--ve výpisu je Anna Kutinová

--Test funkcí



--Test pohledů