/*
Autor: Jakub Levý
Vytvořeno pro DBA @ MFF ZS 19/20

Vytvoření databáze a tabulek, včetně relací a ostatních constraints.
Obsahuje několik nezbytných funkcí, na kterých závisí constraint nějaké tabulky.
Konkrétně se jedná o funkce:
	FUNCTION dbo.Je_Adresa_Adresou_Klubu
	FUNCTION dbo.Je_Adresa_Adresou_Utkání
	FUNCTION dbo.Je_Adresa_Využita
	FUNCTION dbo.Věk
	FUNCTION dbo.Je_Kontakt_Hráčem
	FUNCTION dbo.Je_Kontakt_Pověřenou_Osobou_Klubu
	FUNCTION dbo.Je_Kontakt_Rozhodčím
	FUNCTION dbo.Zapsal_Kontakt_Soupisku
	FUNCTION dbo.Je_Kontakt_Využit

Popis:
Cílem práce bylo vytvořit databázi pro fotbalový klub. Tj. z pohledu fotbalového klubu, nikoliv z pohledu 
fotbalové asociace, která zastřešuje všechny kluby.

Databáze eviduje jednotlivé hráče, kteří mohou být buďto členem klubu za který hrají, nebo hrát na hostování.
V případě hostování jsou uloženy informace o délce platnosti hostování, případně smlouva. 

Hráči jsou různého věku a pohlaví, v databázi jsou uloženy jednotlivé hráčské kategorie. Samozřejmností jsou
utkání, která mimo jiné obsahují soupisku hráčů, rozhodčího a sezónu, ve které se utkání odehrálo.


Nad definicí každé tabulky se nachází popis potencionálně nejasných parametrů, případný popis významu celé tabulky.
*/

CREATE DATABASE [Levý_Fotbal]
COLLATE Czech_CS_AS --CS - case sensitive, AS - accent sensitive
					--nutné, nechceme problémy s ř a ž
with 
	COMPATIBILITY_LEVEL = 140 --SQL Server 2017 jsem používal k vývoji, pravděpodobně bude fungovat i na starším
  , TRUSTWORTHY ON --nutné, pro přidání nepodepsané assembly, která obsahuje CLR funkci FileExists(string cesta)
GO

USE [Levý_Fotbal]
GO

/*
Sezóna je definovaná dvojcí datumů (Start, Konec). Netrvá déle než jeden rok a Start <= Konec.
Sloupce Start_Rok a Konec_Rok obsahují pouze rok z odpovídajícího datumu, ty jsou přítomny,
protože na ně bude vytvořen index (built-in funkce year není sargovatelná), 
více viz. trigger dbo.Validní_Sezóna (na tabulce Sezóna).
*/
CREATE TABLE dbo.Sezóna (
	Start DATE NOT NULL
  , Konec DATE NOT NULL

				--trik, aby sloupec byl not null
  , Start_Rok  AS nullif(DATEPART(YEAR,Start), 0)
  ,	Konec_Rok  AS nullif(DATEPART(YEAR,Konec), 0)

  ,	CONSTRAINT PK_Sezóna PRIMARY KEY CLUSTERED (Start) 
  , CONSTRAINT UQ_Sezóna_Konec UNIQUE NONCLUSTERED (Konec)
  , CONSTRAINT CK_Sezóna_Konec CHECK ((Start<Konec AND DATEDIFF(YEAR,Start,Konec)<=(1)))
)
GO

/*
Telefonní číslo má zvláštní tabulku, zejména kvůli mezinárodní předvolbě, kterou není nutné vyplnit.
Předpokládají se implicitně česká tel. čísla, kterých by měla být většina v DB. To je důvodem, proč
je Předvolba SPARSE NULL, namísto NULL.

Check constraints ověřují zda-li číslo je tvořené 9 číslicemi a předvolba začíná '+' následovaná 1 až 3 číslicemi.
*/
CREATE TABLE dbo.Tel (
	Id INT IDENTITY(1,1) NOT NULL
  , Předvolba NVARCHAR(4) SPARSE NULL
  ,	Číslo NVARCHAR(9) NOT NULL
  , CONSTRAINT PK_Tel PRIMARY KEY CLUSTERED (Id)
  , CONSTRAINT UQ_Tel_Číslo UNIQUE NONCLUSTERED (Číslo)
  ,	CONSTRAINT CK_Tel_Číslo CHECK ((ISNUMERIC(Číslo)=(1) AND LEN(Číslo)=(9)))
  , CONSTRAINT CK_Tel_Předvolba CHECK ((Předvolba IS NULL OR LEFT(Předvolba,(1))='+' 
								    AND ISNUMERIC(SUBSTRING(Předvolba,(1),LEN(Předvolba)-(1)))=(1)))
)
GO

/*
Standardní kontaktní informace, které si chceme uložit o jednotlivé osobě v DB.

Využit
	- Bit značící jestli má kontakt nějaký hlubší význam, než jen data (rozhodčí, hráč, zapisovatel soupisek, správce klubu)
	- Výchozí chování je, že při smazání významu kontaktu pomocí procedůry (dbo.Smaž_Hráče, ...) se nesmažou kontaktní data
	- Pro vyčištění nevyužitých kontaktů je připravena procedůra dbo.Smaž_Nevyužité_Kontakty, která tento sloupec využívá
	- Bohužel nejde vytvořit index na sloupec, pro jehož spočítání se musí udělat select do DB 
	  (podívat se jestli existuje nějaká role ke kontaktu) a tedy dbo.Smaž_Nevyužité_Kontakty vždy provede clustered index scan

CK_Kontakt_Email
	- jednoduché "ověření" emailu

CK_Kontakt_Email_Tel_Id_Req
	- vyžadujeme znalost tel. čísla nebo emailu (nebo obou) o každém kontaktu.

CK_Kontakt_Jméno_Přijmení
	- Jednoduchá kontrola jména a příjmení
	- Příjmení nevyžaduje jako druhý znak z [a-ž], příjmení O'Connell to nesplňuje
	- Nepředpokládám, že někdo bude vkládat jméno ヤクブ・レヴィ一 nebo ještě hůře 田中・高橋
	- Mimo jiné, v případě jmen nenapsaných latinkou by bylo rozumné nastavit COLLATE na Czech_CS_AS_KS_WS
*/
CREATE TABLE dbo.Kontakt (
   	Id INT IDENTITY(1,1) NOT NULL
  ,	Jméno NVARCHAR(30) NOT NULL
  ,	Příjmení NVARCHAR(30) NOT NULL
  ,	Email NVARCHAR(50) NULL
  ,	Tel_Id INT NULL
--, Využit AS nullif(dbo.Je_Kontakt_Využit(Id), 0) přidáno níže, až po definici funkce
  , CONSTRAINT PK_Kontakt PRIMARY KEY CLUSTERED (Id) 
  , CONSTRAINT CK_Kontakt_Email CHECK ((Email LIKE '%_@__%.__%'))
  , CONSTRAINT CK_Kontakt_Email_Tel_Id_Req CHECK ((Email IS NOT NULL OR Tel_Id IS NOT NULL))
  , CONSTRAINT CK_Kontakt_Jméno_Přijmení CHECK ((Jméno LIKE '[A-Ž][a-ž]%[a-ž]' AND Příjmení LIKE '[A-Ž]%[a-ž]'))
  , CONSTRAINT FK_Kontakt_Tel FOREIGN KEY(Tel_Id) REFERENCES dbo.Tel (Id)
) 
GO

/* 
Každý klub (viz tabulka následující po dbo.Adresa) má asociovanou právě jednu adresu.

Využita
	- Obdobný případ jako u sloupce Kontakt(Využit)
	- Bit značící jestli je Adresa adresou klubu
	- Výchozí chování je, že při smazání klubu procedůrou dbo.Smaž_Klub se nesmaže adresa v DB.
	- Pro vyčištění neyužitých adres je připravena procedůra dbo.Smaž_Nevyužité_Adresy, která tento sloupec využívá
	- Bohužel nejde vytvořit index na sloupec, pro jehož spočítání se musí udělat select do DB 
	  (podívat se jestli k adrese existuje klub) a tedy dbo.Smaž_Nevyužité_Adresy vždy provede clustered index scan

CK_* jsou opět jednoduché kontroly vstupních dat.

CK_Adresa_Č_p
	- Buďto číslice nebo třeba i '18/20a'
*/
CREATE TABLE dbo.Adresa (
	Id INT IDENTITY(1,1) NOT NULL
  ,	Ulice NVARCHAR(30) NOT NULL
  ,	Č_p NVARCHAR(10) NOT NULL
  ,	Město NVARCHAR(30) NOT NULL
  ,	Psč NVARCHAR(5) NOT NULL
--, Využita AS isnull(dbo.Je_Adresa_Využita(Id), 0) přidáno níže, až po definici funkce
  , CONSTRAINT PK_Adresa PRIMARY KEY CLUSTERED (Id) 
  ,	CONSTRAINT CK_Adresa_Č_p CHECK ((ISNUMERIC(Č_p)=(1) OR Č_p LIKE '%_/_%'))
  ,	CONSTRAINT CK_Adresa_Město CHECK (Město LIKE '[A-Ž]%[a-ž]')
  , CONSTRAINT CK_Adresa_Psč CHECK (Psč LIKE '[1-9][0-9][0-9][0-9][0-9]')
  , CONSTRAINT CK_Adresa_Ulice CHECK (Ulice LIKE '[A-Ž]%[a-ž]')
) 
GO

/*
Klub má jednoznačně danou adresu a název a může mít definovaného správce (Pověřená_Osoba_Id).
*/
CREATE TABLE dbo.Klub (
	Id INT IDENTITY(1,1) NOT NULL
  ,	Název NVARCHAR(50) NOT NULL
  ,	Adresa_Id INT NOT NULL
  ,	Pověřená_Osoba_Id INT NULL
  , CONSTRAINT PK_Klub PRIMARY KEY CLUSTERED (Id)
  , CONSTRAINT UQ_Klub_Adresa_Id UNIQUE NONCLUSTERED (Adresa_Id)
  , CONSTRAINT UQ_Klub_Název UNIQUE NONCLUSTERED (Název) 
  , CONSTRAINT FK_Klub_Adresa FOREIGN KEY(Adresa_Id) REFERENCES dbo.Adresa (Id)
  , CONSTRAINT FK_Klub_Kontakt FOREIGN KEY(Pověřená_Osoba_Id) REFERENCES dbo.Kontakt (Id)
  , CONSTRAINT CK_Klub_Název CHECK ((Název LIKE '[A-Ž]%[a-ž]'))
) 
GO
/*
Záznam v této tabulce znamená, že daný kontakt může "odpískat" utkání.

UQ_Rozhodčí
	- Jeden kontakt může být nejvýše 1x rozhodčím.
*/
CREATE TABLE dbo.Rozhodčí (
	Id INT IDENTITY(1,1) NOT NULL
  ,	Kontakt_Id INT NOT NULL
  , CONSTRAINT PK_Rozhodčí PRIMARY KEY CLUSTERED (Id) 
  , CONSTRAINT UQ_Rozhodčí UNIQUE NONCLUSTERED (Kontakt_Id) 
  , CONSTRAINT FK_Rozhodčí_Kontakt FOREIGN KEY(Kontakt_Id) REFERENCES dbo.Kontakt (Id)
) 
GO

/*
Soupiska hráčů.
Spojení soupisky a hráčů bude následovat v tabulce Hráč_Soupiska

Ačkoliv je NULL hodnota povolena u zapisovatele soupisky, tak předpokládáme, že bude spíše výjimkou,
když nebudeme vědět, kdo zapsal soupisku. Proto není Zapsal_Id definován jako SPARSE NULL.
*/
CREATE TABLE dbo.Soupiska (
	Id INT IDENTITY(1,1) NOT NULL
  ,	Zapsal_Id INT NULL
  ,	CONSTRAINT PK_Soupiska PRIMARY KEY CLUSTERED (Id) 
  , CONSTRAINT FK_Soupiska_Kontakt FOREIGN KEY(Zapsal_Id) REFERENCES dbo.Kontakt (Id)
) 
GO

/*
Definuje jednotlivou hráčskou kategorii, která může nastoupit na fotbalové utkání.

Název
	- 'Mladší žáci', 'Starší dorostenky', 'Starší přípravka'

Muži
	- Předpokládáme 2 pohlaví
	- 1 ~ mužská kategorie
	- 0 ~ ženská kategorie
	- Nutné vědět
		- Mladší žáci jsou chlapci
		- Starší dorostenky jsou dívky
		- Starší přípravka mohou být chlapci i dívky

CK_Délka_Zápasu_Minut
	- Obsahuje všechny standardní délky fotbalových zápasů
*/
CREATE TABLE dbo.Ml_Kategorie (
	Název NVARCHAR(20) NOT NULL
  ,	Muži BIT NOT NULL
  ,	Délka_Zápasu_Minut INT NOT NULL
  , CONSTRAINT PK_Ml_Kategorie PRIMARY KEY CLUSTERED (Název, Muži) 
  , CONSTRAINT CK_Délka_Zápasu_Minut CHECK ((Délka_Zápasu_Minut=(90) OR Délka_Zápasu_Minut=(80) 
										 OR Délka_Zápasu_Minut=(70) OR Délka_Zápasu_Minut=(60)
										 OR Délka_Zápasu_Minut=(40) OR Délka_Zápasu_Minut=(30))) 
) 
GO

/*
Vzhledem k tomu, že se jedná o databázi z pohledu fotbalového klubu ukládáme v tabulce Utkání pouze 
soupeře (Soupeř_Id) proti kterému utkání proběhlo. Dále Soupiska_Id identifikuje moji nasazenou soupisku, 
o soupisce soupeře nic nevíme.

Góly_My
	- Počet vstřelených gólu na konci utkání naším týmem

Góly_Soupeř
	- Počet vstřelených gólu na konci utkání soupeřem

Góly_My_Poločas
	- Počet vstřelených gólu naším týmem o poločase

Góly_Soupeř_Poločas
	- Počet vstřelených gólů soupeřem o poločase

Konečný stav utkání je nutnou podmínkou pro přidání nového utkání do DB. Stav v poločase není třeba uvádět.

Místo_Konání_Id
	- Adresa, kde se utkání odehrálo
	- Např. pro zjištění, zda-li se jednalo o utkání doma nebo venku

Ml_Kategorie_Název, Ml_Kategorie_Muži
	- Identifikace hráčské kategorie utkání
	- Při přidání utkání se kontroluje, zda hráči na soupisce spadají pod tuto kategorii 
	  viz trigger dbo.Validní_Soupiska ON dbo.Utkání

Seźona_Start
	- Identifikace sezóny, ve které se utkání odehrálo

Soupiska_Id
	- Soupiska mého klubu 

CK_Utkání_Omezení_Gólu
	- Gólů v zápase nemůže padnout záporné množství, zároveň se však může jednat pouze o maximálně dvojciferné číslo

CK_Utkání_Vztah_Góly_Góly_Poločas
	- Gólů v poločase nemohlo padnout více než gólu na konci utkání
*/
CREATE TABLE dbo.Utkání (
	Id INT IDENTITY(1,1) NOT NULL
  ,	Góly_My INT NOT NULL
  ,	Góly_Soupeř INT NOT NULL
  ,	Góly_My_Poločas INT NULL
  ,	Góly_Soupeř_Poločas INT NULL
  ,	Soupeř_Id INT NOT NULL
  ,	Místo_Konání_Id INT NOT NULL
  ,	Ml_Kategorie_Název NVARCHAR(20) NOT NULL
  ,	Ml_Kategorie_Muži BIT NOT NULL
  ,	Sezóna_Start DATE NOT NULL
  ,	Rozhodčí_Id INT NOT NULL
  ,	Soupiska_Id INT NOT NULL
  , CONSTRAINT PK_Utkání PRIMARY KEY CLUSTERED (Id) 
  , CONSTRAINT FK_Utkání_Adresa FOREIGN KEY(Místo_Konání_Id) REFERENCES dbo.Adresa (Id)
  , CONSTRAINT FK_Utkání_Klub FOREIGN KEY(Soupeř_Id) REFERENCES dbo.Klub (Id)
  , CONSTRAINT FK_Utkání_Ml_Kategorie FOREIGN KEY(Ml_Kategorie_Název, Ml_Kategorie_Muži) REFERENCES dbo.Ml_Kategorie (Název, Muži)
  , CONSTRAINT FK_Utkání_Rozhodčí FOREIGN KEY(Rozhodčí_Id) REFERENCES dbo.Rozhodčí (Id)
  , CONSTRAINT FK_Utkání_Sezóna FOREIGN KEY(Sezóna_Start) REFERENCES dbo.Sezóna (Start)
  , CONSTRAINT FK_Utkání_Soupiska FOREIGN KEY(Soupiska_Id) REFERENCES dbo.Soupiska (Id)
  ,	CONSTRAINT CK_Utkání_Omezení_Gólu CHECK ((Góly_My>=(0) AND Góly_My<=(99) AND Góly_My_Poločas>=(0)
										  AND Góly_My_Poločas<=(99) AND Góly_Soupeř>=(0) AND Góly_Soupeř<=(99) 
										  AND Góly_Soupeř_Poločas>=(0) AND Góly_Soupeř_Poločas<=(99)))

  , CONSTRAINT CK_Utkání_Vztah_Góly_Góly_Poločas CHECK ((Góly_My>=Góly_My_Poločas AND Góly_Soupeř>=Góly_Soupeř_Poločas))
)
GO

/*
Následující tabulka Hráč vyžaduje, aby věk hráče byl mezi 5 až 99
	- Od 5 let může být hráč registrován a spadá pod mladší přípravku
*/
--Vrátí věk podle parametru @d_nar ~ Datum narození
CREATE FUNCTION dbo.Věk (@d_nar DATE)
RETURNS INT
WITH SCHEMABINDING
AS
BEGIN
	DECLARE @retval INT
		SELECT @retval = FLOOR(DATEDIFF(DAY, @d_nar, GETDATE()) / 365.25)
	RETURN @retval
END
GO

/*
Reg_Id
	- FAČR registrační číslo hráče
	- Složené pouze z číslic
	- Př. 7230511

Muž
	- 1 ~ mužské pohlaví
	- 0 ~ ženské pohlaví
*/
CREATE TABLE dbo.Hráč (
	Reg_Id NVARCHAR(7) NOT NULL
  ,	D_Narození DATE NOT NULL
  ,	Muž BIT NOT NULL
  ,	Kontakt_Id INT NOT NULL
  , CONSTRAINT PK_Hráč PRIMARY KEY CLUSTERED (Reg_Id) 
  , CONSTRAINT UQ_Hráč_Kontakt_Id UNIQUE NONCLUSTERED (Kontakt_Id)
  , CONSTRAINT FK_Hráč_Kontakt FOREIGN KEY(Kontakt_Id) REFERENCES dbo.Kontakt (Id)
  ,	CONSTRAINT CK_Hráč_D_Narození CHECK ((dbo.Věk(D_Narození)>=(5) AND dbo.Věk(D_Narození)<=(99)))
  , CONSTRAINT CK_Hráč_Reg_Id CHECK ((ISNUMERIC(Reg_Id)=(1) AND LEN(Reg_Id)>=(6)))
)
GO

/*
Spojovací tabulka hráče a soupisky.
Hráč na soupisce má číslo dresu (Číslo) a může být pouze náhradníkem.

CK_Hráč_Soupiska
	- Validní číslo dresu je od 1 do 99.
*/
CREATE TABLE dbo.Hráč_Soupiska (
	Hráč_Reg_Id NVARCHAR(7) NOT NULL
  ,	Soupiska_Id INT NOT NULL
  ,	Číslo INT NOT NULL
  ,	Náhradník BIT NOT NULL
  , CONSTRAINT PK_Hráč_Soupiska PRIMARY KEY CLUSTERED (Hráč_Reg_Id ASC, Soupiska_Id ASC) 
  , CONSTRAINT FK_Hráč_Soupiska_Hráč FOREIGN KEY(Hráč_Reg_Id) REFERENCES dbo.Hráč (Reg_Id)
  , CONSTRAINT FK_Hráč_Soupiska_Soupiska FOREIGN KEY(Soupiska_Id) REFERENCES dbo.Soupiska (Id) ON DELETE CASCADE
  , CONSTRAINT CK_Hráč_Soupiska CHECK ((Číslo>(0) AND Číslo<(100)))
)
GO

/*
Informace o hostování hráče

Kontrakt_Id
	- Unikátní identifikátor smlouvy
	- Př. 7128792ACX

Od, Do
	- Vymezuje platnost hostovací smlouvy

Cena_Za_Sezónu
	- Smluvená částka / sezóna

Smlouva
	- binární soubor (kopie smlouvy)
	- Není ideální mít v DB kupu binárních souborů, předpokládá se, že často bude smlouva nedodána a proto SPARSE NULL

Členství_Id
	- Cizí klíč, vazba na tabulku Klub
	- Odkazuje na klub, který je vlastníkem hráče

CK_Od_Do
	- Předpokládáme, že smlouva nemůže být podepsána na více než 5 let
	- Od < Do - smlouva musí někdy platit a začátek platnosti < konec platnosti

*/
CREATE TABLE dbo.Hostování (
	Kontrakt_Id NVARCHAR(15) NOT NULL
  ,	Od DATE NOT NULL
  ,	Do DATE NOT NULL
  ,	Cena_Za_Sezónu MONEY NOT NULL
  ,	Smlouva VARBINARY(MAX) SPARSE NULL
  ,	Hráč_Reg_Id NVARCHAR(7) NOT NULL
  ,	Členství_Id INT NOT NULL
  , CONSTRAINT PK_Hostování PRIMARY KEY CLUSTERED (Kontrakt_Id ASC) 
  , CONSTRAINT FK_Hostování_Hráč FOREIGN KEY(Hráč_Reg_Id) REFERENCES dbo.Hráč (Reg_Id)
  , CONSTRAINT FK_Hostování_Klub FOREIGN KEY(Členství_Id) REFERENCES dbo.Klub (Id)
  , CONSTRAINT CK_Od_Do CHECK ((DATEDIFF(YEAR,Od,Do)<=(5) AND Od<Do))
)
GO

--Následuje několik funkcí, které umožní přidání sloupce Adresa(Využita)

--Vrátí 1 pokud existuje Klub s hodnotou Adresa_Id = @adresa_id
--Jinak 0
CREATE FUNCTION dbo.Je_Adresa_Adresou_Klubu(@adresa_id INT)
RETURNS BIT
WITH SCHEMABINDING
AS
BEGIN
	DECLARE @klub_id INT;
	SELECT TOP 1 @klub_id = Id FROM dbo.Klub WHERE Adresa_Id = @adresa_id
	IF @klub_id IS NOT NULL 
		RETURN 1

	RETURN 0
END
GO

--Vrátí 1 pokud existuje Utkání s hodnotou Místo_Konání_Id = @adresa_id
--Jinak 0
CREATE FUNCTION dbo.Je_Adresa_Adresou_Utkání(@adresa_id INT)
RETURNS BIT
WITH SCHEMABINDING
AS
BEGIN
	DECLARE @utkani_id INT
	SELECT TOP 1 @utkani_id = Id FROM dbo.Utkání WHERE Místo_Konání_Id = @adresa_id
	IF @utkani_id IS NOT NULL
		RETURN 1

	RETURN 0
END
GO

--Vrátí 1 pokud existuje klub sídlící na @adresa_id nebo existuje utkání, které se odehrálo na @adresa_id
--Jinak 0
CREATE FUNCTION dbo.Je_Adresa_Využita(@adresa_id INT)
RETURNS BIT
WITH SCHEMABINDING
AS
BEGIN
	RETURN dbo.Je_Adresa_Adresou_Klubu(@adresa_id) | dbo.Je_Adresa_Adresou_Utkání(@adresa_id)
END
GO

ALTER TABLE Adresa
ADD Využita AS 
--trik, aby sloupec byl not null
isnull(dbo.Je_Adresa_Využita(Id), 0)
GO

--Následuje několik funkcí, které umožní přidání sloupce Kontakt(Využit)

--Vrátí 1 pokud je Kontakt s Id = @kontakt_id hráčem
--Jinak 0
CREATE FUNCTION dbo.Je_Kontakt_Hráčem(@kontakt_id INT)
RETURNS BIT
WITH SCHEMABINDING
AS
BEGIN
	DECLARE @reg_id NVARCHAR(7)
	SELECT TOP 1 @reg_id = Reg_Id FROM dbo.Hráč WHERE Kontakt_Id = @kontakt_id
	IF @reg_id IS NOT NULL
		RETURN 1

	RETURN 0
END
GO

--Vrátí 1 pokud existuje Kontakt s Id = @kontakt_id, který je pověřenou osobou (správcem) nějakého klubu
--Jinak 0
CREATE FUNCTION dbo.Je_Kontakt_Pověřenou_Osobou_Klubu(@kontakt_id INT)
RETURNS BIT 
WITH SCHEMABINDING
AS
BEGIN
	DECLARE @klub_id INT

	SELECT TOP 1 @klub_id = Id FROM dbo.Klub WHERE Pověřená_Osoba_Id = @kontakt_id
	IF @klub_id IS NOT NULL
		RETURN 1

	RETURN 0
END
GO

--Vrátí 1 pokud je Kontakt s Id = @kontakt_id rozhodčím
--Jinak 0
CREATE FUNCTION dbo.Je_Kontakt_Rozhodčím(@kontakt_id INT)
RETURNS BIT
WITH SCHEMABINDING
AS
BEGIN
	DECLARE @rozhodci_id INT

	SELECT TOP 1 @rozhodci_id = Id FROM dbo.Rozhodčí WHERE Kontakt_Id = @kontakt_id
	IF @rozhodci_id IS NOT NULL
		RETURN 1

	RETURN 0
END
GO

--Vrátí 1 pokud Kontakt s Id = @kontakt_id zapsal nějakou soupisku
--Jinak 0
CREATE FUNCTION dbo.Zapsal_Kontakt_Soupisku(@kontakt_id INT)
RETURNS BIT
WITH SCHEMABINDING
AS
BEGIN
	DECLARE @soupiska_id INT
	SELECT TOP 1 @soupiska_id = Id FROM dbo.Soupiska WHERE Zapsal_Id = @kontakt_id
	IF @soupiska_id IS NOT NULL
		RETURN 1

	RETURN 0
END
GO

--Vrátí 1 pokud je Kontakt alespoň jedno z následujících: hráčem, pověřenou osobou (správcem) klubu, rozhodčím, zapisovatel soupisek
--Jinak 0
CREATE FUNCTION dbo.Je_Kontakt_Využit(@kontakt_id INT)
RETURNS BIT
WITH SCHEMABINDING
AS
BEGIN
	RETURN dbo.Je_Kontakt_Hráčem(@kontakt_id) | dbo.Je_Kontakt_Pověřenou_Osobou_Klubu(@kontakt_id) 
		 | dbo.Je_Kontakt_Rozhodčím(@kontakt_id) | dbo.Zapsal_Kontakt_Soupisku(@kontakt_id)
END
GO

ALTER TABLE Kontakt
ADD Využit AS 
--trik, aby sloupec byl not null
nullif(dbo.Je_Kontakt_Využit(Id), 0)