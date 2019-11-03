/*
Autor: Jakub Levý
Vytvořeno pro DBA @ MFF ZS 19/20
*/

USE Levý_Fotbal 
GO

--Dvě různá hostování jednoho hráče musí mít prázdný průnik
CREATE trigger dbo.Validní_Hostování on dbo.Hostování 
after insert, update
as
begin
	select h1.Hráč_Reg_Id from inserted h1
	cross apply (
		select Kontrakt_Id,Od,Do,Hráč_Reg_Id from Hostování h2
		where h1.Hráč_Reg_Id = h2.Hráč_Reg_Id and h1.Kontrakt_Id <> h2.Kontrakt_Id and h1.Od <= h2.Do and h1.Do >= h2.Od
	) h2
	
	if @@ROWCOUNT > 0
	begin
		raiserror('Dvě hostování mají neprázdný průnik', 15, 15)
		rollback
	end
end
GO

CREATE trigger dbo.Kontrola_Soupisky on dbo.Hráč_Soupiska
AFTER insert, update
as
begin
    -- Kontrola duplicitních čísel dresů jednotlivých hráčů.
	select Soupiska_Id from Hráč_Soupiska
	where Soupiska_Id IN (select Soupiska_Id from inserted)
	group by Soupiska_Id, Číslo
	having COUNT(*) > 1

	if @@ROWCOUNT > 0
	begin
		raiserror('Duplicitní číslo dresu', 15, 15)
        rollback
	end

	-- Kontrola maximálního počtu náhradníků (7)
	select Soupiska_Id from Hráč_Soupiska
	where Náhradník = 1 and Soupiska_Id in (select Soupiska_Id from inserted)
	group by Soupiska_Id
	having count(*) > 7

	if @@ROWCOUNT > 0
	begin
		raiserror('Dosaženo maximálního počtu náhradníků', 15, 15)
		rollback
	end

	-- Kontrola maximálního počtu hráčů na soupisce (18)
	-- Tím zkontroluji, že mám max. 11 hráčů v základu.
	select Soupiska_Id from Hráč_Soupiska
	where Soupiska_Id in (select Soupiska_Id from inserted)
	group by Soupiska_Id
	having COUNT(*) > 18

	if @@ROWCOUNT > 0
	begin
		raiserror('Soupiska již obsahuje maximální počet hráčů', 15, 15)
		rollback
	end

	--Kontrola výskytu hráčů jedné kategorie (věk, pohlaví)
	select subQ.Soupiska_Id from (
		select Soupiska_Id, dbo.Urči_Ml_Kategorii(Hráč_Reg_Id) as 'Kategorie' from Hráč_Soupiska 
		where Soupiska_Id in (select Soupiska_Id from inserted)
		group by Soupiska_Id, dbo.Urči_Ml_Kategorii(Hráč_Reg_Id)
		) subQ
	group by subQ.Soupiska_Id
	having COUNT(*) > 1

	if @@ROWCOUNT > 0
	begin
		raiserror('Pokus o přidání hráče z jiné kategorie', 15, 15)
		rollback
	end
end
GO

CREATE trigger dbo.Kontrola_Využití_Soupisky on dbo.Hráč_Soupiska
after delete, update
as
begin
    --Pokud již existuje fotbalové utkání využívající soupisku, nemůžeme ji změnit na neplatnou - tj.
    --soupisku, kde je 6 a méně hráčů.

	select hs.Soupiska_Id from Hráč_Soupiska hs
	join Utkání ON Utkání.Soupiska_Id = hs.Soupiska_Id
	where hs.Soupiska_Id in (select Soupiska_Id from deleted)
	group by hs.Soupiska_Id
	having COUNT(*) < 7
	if @@ROWCOUNT > 0 
	begin
		raiserror('Existuje utkání, které tuto soupisku obsahuje, není možné ji znevalidnit', 15, 15)
		ROLLBACK
	end
end
GO

--Klub, na jehož adrese se odehrálo utkání nemůže být smazán z DB
create trigger dbo.Kontrola_Mazání_Klubu on dbo.Klub
after delete
as
begin
	declare @vyuzito int
	select @vyuzito = COUNT(*) from Utkání where Místo_Konání_Id IN (select Adresa_Id from deleted)
	if @vyuzito > 0
	begin
		raiserror('Klub, na jehož adrese se odehrálo utkání nemůže být smazán z DB',15,15)
		rollback
	end
end
GO

--Součástí kontaktních informací je i telefonní číslo ve zvláštní tabulce (oddělená předvolba a číslo)
--Pokud smažeme záznam kontatních informací chceme je odstranit všechny včetně tel. čísla
--To přesně má na starosti tento trigger
CREATE trigger dbo.Smaž_Tel on dbo.Kontakt
after delete
as
begin
	delete from Tel where Id IN (select Tel_Id from deleted)
end
GO

--Pokud při updatu Kontaktu dojde ke změně tel. čísla, staré se smaže z DB
CREATE   trigger dbo.Smaž_Tel_Pokud_Změněn on dbo.Kontakt 
after update
as
begin
	delete from Tel where Id IN ( 
		select kon_s.Tel_Id from inserted kon_n
		cross apply (
			select kon_s.Id, kon_s.Tel_Id from deleted kon_s
			where kon_n.Id = kon_s.Id and kon_n.Tel_Id <> kon_s.Tel_Id
		) kon_s
	)
end
GO

--V jednom roce může začínat a končit nejvýše jedna sezóna
CREATE trigger dbo.Validní_Sezóna on dbo.Sezóna
after insert, update
as
begin
	select Start_Rok from Sezóna where Start not in (select Start from inserted) and Start_Rok in (select Start_Rok from inserted)

	--pomalejsi, neni sargovatelne
	--select year(Start) from Sezóna group by year(Start) having Count(*) > 1
	if @@ROWCOUNT > 0
	begin
		raiserror('Vložená sezóna začíná v roce, kdy začíná i jiná', 15, 15)
		rollback
	end

	select Konec_Rok from Sezóna where Start not in (select Start from inserted) and Konec_Rok in (select Konec_Rok from inserted)

	--pomalejsi, neni sargovatelne
	--select year(Konec) from Sezóna group by year(Konec) having Count(*) > 1
	if @@ROWCOUNT > 0
	begin
		raiserror('Vložená sezóna končí v roce, kdy končí i jiná', 15, 15)
		rollback
	end
end
GO

CREATE trigger dbo.Validní_Soupiska ON dbo.Utkání
after insert, update
as 
begin
	-- Kontrola, zda-li soupiska obsahuje minimální počet hráčů na fotbalové utkání.
	select hs.Soupiska_Id from inserted u
	join Hráč_Soupiska hs ON u.Soupiska_Id = hs.Soupiska_Id
	group by hs.Soupiska_Id
	having COUNT(*) < 7

	if @@ROWCOUNT > 0
	begin
		raiserror('Soupiska neobsahuje minimální počet hráčů', 15, 15)
		rollback
	end

	-- Kontrola, zda-li je přiřazována správná kategorie hráčů na utkání
	-- = Mladší žáci hrají utkání pro mladší žáky
	select u.Id from inserted u 
	join Hráč_Soupiska hs ON hs.Soupiska_Id = u.Soupiska_Id
	cross apply (
		select info.Název, info.Pohlaví from dbo.Urči_Ml_Kategorii_Pohlaví(hs.Hráč_Reg_Id) info
		where u.Ml_Kategorie_Název <> info.Název or u.Ml_Kategorie_Muži <> info.Pohlaví
	) info
	

	if @@ROWCOUNT > 0
	begin
		raiserror('Utkání je pro jinou kategorii, než je soupiska', 15, 15)
		rollback
	end

	--Kontrola zda-li na adrese, kde se utkání koná sídlí nějaký klub
	select u.Místo_Konání_Id from inserted u
	where dbo.Sídlí_Klub(u.Místo_Konání_Id) = 0

	if @@ROWCOUNT > 0
	begin
		raiserror('Utkání se nemůže odehrát na adrese, kde nesídlí žádný klub', 15, 15)
		rollback
	end
end