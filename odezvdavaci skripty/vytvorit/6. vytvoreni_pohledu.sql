/*
Autor: Jakub Levý
Vytvořeno pro DBA @ MFF ZS 19/20

Všechny pohledy vyžadují právě 1 scan.
Pokud některý pohled provede více scanů, je to kvůli tomu, že je v DB
málo dat a query optimizeru přišlo rychlejší provést scan malé tabulku než seekovat (nebo jsou staré statistiky...).

Nevynucoval jsem seeky ( pomocí with (forceseek) ), protože v malém množství dat je často scan rychlejší než seek...
*/

USE Levý_Fotbal 
GO

--Všechny kontakty, které nejsou ani jedno z následujících: hráč, zapisovatel soupisky, rozhodčí, pověřená osoba klubu (správce)
create view dbo.Nevyužité_Kontakty
as
select Jméno, Příjmení, Email, dbo.Tel_Číslo(Tel_Id) as 'Tel. číslo' from Kontakt where dbo.Je_Kontakt_Využit(Id) = 0
GO

--Všechny adresy, které nejsou adresou klubu nebo se na ní neodehrálo žádné utkání
create view dbo.Nevyužité_Adresy
as
select Ulice, Č_p as 'Č. p.', Město, Psč from Adresa where dbo.Je_Adresa_Využita(Id) = 0
GO

--Soupisky s hráči, kteří jsou na nich zapsáni
create view dbo.Hráči_Na_Soupisce as 
select Soupiska.Id as 'Id soupisky', Soupiska.Zapsal_Id as 'Id zapisovatele', Reg_Id AS 'Reg. č.', Hráč_Kontakt.Jméno 
	 , Hráč_Kontakt.Příjmení, dbo.Ml_Kategorie_Formátované(dbo.Urči_Ml_Kategorii(Reg_Id), Muž) as 'Hráčská kat.'
     , Hráč_Kontakt.Email, dbo.Tel_Číslo(Hráč_Kontakt.Tel_Id) as 'Tel. číslo', Hráč_Soupiska.Číslo as 'Číslo dresu' 
     , Hráč_Soupiska.Náhradník 
from Soupiska
left outer join Kontakt as Zapisoval on Zapisoval.Id = Soupiska.Zapsal_Id
join Hráč_Soupiska on Hráč_Soupiska.Soupiska_Id = Soupiska.Id
join Hráč on Hráč.Reg_Id = Hráč_Soupiska.Hráč_Reg_Id
join Kontakt as Hráč_Kontakt on Hráč_Kontakt.Id = Hráč.Kontakt_Id
GO

--Soupisky s kontaktními informacemi zapisovatelů soupisek
create view dbo.Soupiska_Kontakt_Zapisovatel
as
select Jméno, Příjmení, Email, dbo.Tel_Číslo(Tel_Id) as 'Tel. č.', Soupiska.Id as 'Id soupisky'
	 , COUNT(Hráč_Soupiska.Hráč_Reg_Id) as 'Počet zapsaných' 
from Soupiska
left outer join Kontakt on Kontakt.Id = Soupiska.Zapsal_Id
join Hráč_Soupiska on Hráč_Soupiska.Soupiska_Id = Soupiska.Id
group by Jméno, Příjmení, Email, dbo.Tel_Číslo(Tel_Id), Soupiska.Id
GO

--Jednotlivé (věkové/pohlaví) kategorie s délkou utkání
create view dbo.Hráčské_Kategorie as
select dbo.Ml_Kategorie_Formátované(Název, Muži) as 'Hráčská kat.', Délka_Zápasu_Minut as 'Délka utkání (min)' from Ml_Kategorie
GO

--Všichni hráči v DB
--Lépe formátované
CREATE view dbo.Hráči
as 
select Reg_Id AS 'Reg. č.', Jméno, Příjmení, dbo.Ml_Kategorie_Formátované(dbo.Urči_Ml_Kategorii(Reg_Id), Muž) as 'Hráčská kat.' 
	  , Email, dbo.Tel_Číslo(Tel_Id) as 'Tel. číslo' 
from Hráč
join Kontakt on Kontakt.Id = Hráč.Kontakt_Id
join Tel on Tel.Id = Kontakt.Tel_Id
GO

--Všichni dostupní hráči s platným hostováním
CREATE view dbo.Hráči_Platné_Hostování
as
select [Reg. č.], Jméno, Příjmení, [Hráčská kat.], Email, [Tel. číslo], Od, Do 
	 , Cena_Za_Sezónu as 'Cena za sezónu', Název as 'Mateřský klub' 
from Hráči
join Hostování ON Hostování.Hráč_Reg_Id = [Reg. č.]
join Klub ON Klub.Id = Hostování.Členství_Id
where dbo.Má_Platné_Hostování([Reg. č.]) = 1
GO

--Všechny hráči, kteří jsou majetkem klubu, za který hrají
CREATE view dbo.Hráči_Vlastnění
as
select [Reg. č.], Jméno, Příjmení, [Hráčská kat.], Email, [Tel. číslo] from Hráči
where dbo.Vlastním_Hráče([Reg. č.]) = 1
GO

--Všichni hráči s již prošlým hostováním
 CREATE view dbo.Hráči_Prošlé_Hostování
as
select [Reg. č.], Jméno, Příjmení, [Hráčská kat.], Email, [Tel. číslo], Od, Do, Cena_Za_Sezónu as 'Cena za sezónu' from Hráči
join Hostování ON Hostování.Hráč_Reg_Id = [Reg. č.]
where dbo.Má_Platné_Hostování([Reg. č.]) = 0
GO

--Všechni hráči, kteří jsou zároveň rozhodčími
CREATE view dbo.Hráči_Zároveň_Rozhodčí
as
select Reg_Id AS 'Reg. č.', Jméno, Příjmení, dbo.Ml_Kategorie_Formátované(dbo.Urči_Ml_Kategorii(Reg_Id), Muž) as 'Hráčská kat.' 
	 , Email, dbo.Tel_Číslo(Tel_Id) as 'Tel. číslo' 
from Hráč
join Kontakt on Kontakt.Id = Hráč.Kontakt_Id
join Tel on Tel.Id = Kontakt.Tel_Id
join Rozhodčí on Rozhodčí.Kontakt_Id = Hráč.Kontakt_Id
GO

--Hráči s počtem odehraných zápasů (porovnání kolikrát v základu a kolikrát jako náhradník)
CREATE view dbo.Hráči_Počet_Odehraných_Zápasů
as
select h2.Reg_Id AS 'Reg. č.', Jméno, Příjmení 
	 , dbo.Ml_Kategorie_Formátované(dbo.Urči_Ml_Kategorii(h2.Reg_Id), h2.Muž) as 'Hráčská kat.' 
	 , Email, dbo.Tel_Číslo(Tel_Id) as 'Tel. číslo' 
     , [Počet odehraných utkání], [Z toho náhradníkem] 
	 , (([Počet odehraných utkání] - [Z toho náhradníkem]) / nullif([Počet odehraných utkání], 0)) * 100 as '% v základu' 
from (
	select Reg_Id, dbo.Počet_Odehraných_Utkání(Reg_Id) as 'Počet odehraných utkání', 
		   dbo.Počet_Odehraných_Utkání_Náhradník(Reg_Id) as 'Z toho náhradníkem' from Hráč 
	) as h1
join Hráč h2 on h2.Reg_Id = h1.Reg_Id
join Kontakt on Kontakt.Id = h2.Kontakt_Id
join Tel on Tel.Id = Kontakt.Tel_Id
GO

--Hráči s počtem odehraných zápasů v dresu s číslem...
CREATE view dbo.Hráči_Číslo
as
select [Reg. č.], Jméno, Příjmení, [Hráčská kat.], Email, [Tel. číslo] 
	 , Číslo as 'Číslo dresu', COUNT(Hráč_Soupiska.Hráč_Reg_Id) as 'Počet nást.' from Hráči
join Hráč_Soupiska on Hráč_Soupiska.Hráč_Reg_Id = [Reg. č.]
group by [Reg. č.], Jméno, Příjmení, [Hráčská kat.], Email, [Tel. číslo], Číslo
GO

--Sezóna s počtem odehraných utkání
CREATE view dbo.Sezóna_Počet_Utkání
as
select Start, Konec, COUNT(Utkání.Sezóna_Start) as 'Počet utkání' from Sezóna
left outer join Utkání ON Utkání.Sezóna_Start = Sezóna.Start
group by Start, Konec
GO

--Klub s adresou a počtem odehraných utkání
CREATE view dbo.Klub_Adresa_Počet_Utkání
as
select Klub.Název as 'Název klubu', Ulice, Č_p as 'Č. p.', Město, Psč, COUNT(Utkání.Místo_Konání_Id) as 'Počet odehraných utkání' 
from Adresa
left outer join Utkání on Utkání.Místo_Konání_Id = Adresa.Id
left outer join Klub on Klub.Adresa_Id = Adresa.Id
group by Klub.Název, Ulice, Č_p, Město, Psč
GO

--Jednotliví rozhodčí s počtem odpískaných utkání
create view dbo.Rozhodčí_Počet_Odpískaných_Utkání
as
--NULL v sloupci Místo znamená, že na dané adrese, kde se utkání odehrávalo nesídlí žádný klub
select Jméno, Příjmení, Email, dbo.Tel_Číslo(Tel_Id) as 'Tel. č.', Klub.Název as 'Místo' 
	  , COUNT(Utkání.Rozhodčí_Id) as 'Počet odpískaných utkání' 
from Rozhodčí
join Kontakt on Kontakt.Id = Rozhodčí.Kontakt_Id
left outer join Utkání on Utkání.Rozhodčí_Id = Rozhodčí.Id
left join Adresa on Adresa.Id = Utkání.Místo_Konání_Id
left outer join Klub on Klub.Adresa_Id = Adresa.Id
group by Jméno, Příjmení, Email, dbo.Tel_Číslo(Tel_Id), Klub.Název
GO

--Jednotlivé hráčské kategorie s počtem odehraných utkání
CREATE view dbo.Ml_Kategorie_Počet_Odehraných_Zápasů
as
select dbo.Ml_Kategorie_Formátované(Název, Muži) as 'Název', COUNT(Utkání.Ml_Kategorie_Název) as 'Počet odehraných utkání' 
from Ml_Kategorie
left outer join Utkání on Utkání.Ml_Kategorie_Název = Ml_Kategorie.Název and Utkání.Ml_Kategorie_Muži = Ml_Kategorie.Muži
group by dbo.Ml_Kategorie_Formátované(Název, Muži)
GO

--Zapisovatelé soupisek s počtem zapsaných soupisek
create view dbo.Kontakt_Zapisovatel_Počet_Zapsaných_Soupisek
as
select Jméno, Příjmení, Email, dbo.Tel_Číslo(Tel_Id) as 'Tel. č.', COUNT(Soupiska.Zapsal_Id) as 'Počet zapsaných soupisek' 
from Kontakt 
left outer join Soupiska ON Soupiska.Zapsal_Id = Kontakt.Id
group by Jméno, Příjmení, Email, dbo.Tel_Číslo(Tel_Id)
GO

--Adresa klubu s kontaktními informace správce klubu
CREATE view dbo.Klub_Adresa_Správce
as
select Klub.Název as 'Název klubu', Ulice, Č_p as 'Č. p.', Město, Psč, Jméno as 'Jméno správce' 
	 , Příjmení as 'Příjmení správce', Email as 'Email správce', dbo.Tel_Číslo(Tel_Id) as 'Tel. č. správce' 
from Klub
join Adresa on Adresa.Id = Klub.Adresa_Id
join Kontakt on Kontakt.Id = Klub.Pověřená_Osoba_Id
GO

--Jednotliví hráči s informacemi o jejich hostování
CREATE view dbo.Hráči_Hostování
as
select 
	[Reg. č.], Jméno, Příjmení, [Hráčská kat.], Email, [Tel. číslo], Od, Do 
  , Cena_Za_Sezónu as 'Cena za sezónu', Klub.Název as 'Mateřský klub'
from Hráči
join Hostování on Hostování.Hráč_Reg_Id = [Reg. č.]
join Klub on Klub.Id = Hostování.Členství_Id
GO

--Lepší pohled na fotbalové utkání než tabulka Utkání
--Kromě připojených tabulek podle id navíc obsahuje:
	--Formátované skóre (dbo.Skóre)
	--Doma/Venku (určeno z místa, kde se utkání odehrálo)
CREATE view dbo.Zápas as
select dbo.Skóre(Góly_My, Góly_Soupeř, Góly_My_Poločas, Góly_Soupeř_Poločas) as 'Skóre' 
	 , Název as 'Soupeř', dbo.Doma_Venku(Místo_Konání_Id, Soupeř_Id) as 'Místo',Ulice, Č_p as 'Č. p.', Město, Psč 
	 , dbo.Ml_Kategorie_Formátované(Ml_Kategorie_Název, Ml_Kategorie_Muži) as 'Hráčská kat.' 
	 , dbo.Soupiska_Počet_Lidí(Soupiska_Id) as 'Počet na soupis.'
	 , Start as 'Sez. start', Konec as 'Sez. konec', Jméno as 'Jméno rozh.', Příjmení as 'Příjmení rozh.' 
	 , Email as 'Email rozh.', dbo.Tel_Číslo(Tel_Id) as 'Tel. č. rozh.' from Utkání
join Klub on Soupeř_Id = Klub.Id
join Adresa on Adresa.Id = Utkání.Místo_Konání_Id
join Sezóna on Sezóna.Start = Utkání.Sezóna_Start
join Rozhodčí on Rozhodčí.Id = Utkání.Rozhodčí_Id
join Kontakt on Kontakt.Id = Rozhodčí.Kontakt_Id
GO