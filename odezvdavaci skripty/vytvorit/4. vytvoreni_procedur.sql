/*
Autor: Jakub Levý
Vytvořeno pro DBA @ MFF ZS 19/20

V případech kdy z názvu parametru není jasný jeho význam se nachází nad definicí procedury stručný popis.
*/

USE Levý_Fotbal 
GO


--Vrátí všechny hráče s hostováním, jejichž mateřským klubem je @mat_klub_nazev
--Př. exec Hostování_Mateřský_Klub 'FC Náchod'
--Vyžaduje 1x clustered index scan, protože vrací celou tabulku
CREATE procedure dbo.Hostování_Mateřský_Klub(@mat_klub_nazev nvarchar(50))
as
begin
	select 
		h.Reg_Id AS 'Reg. č.', k.Jméno, k.Příjmení, 
		dbo.Ml_Kategorie_Formátované(dbo.Urči_Ml_Kategorii(h.Reg_Id), h.Muž) as 'Hráčská kat.', 
		k.Email, dbo.Tel_Číslo(k.Tel_Id) as 'Tel. číslo', 
		host.Od, host.Do, host.Cena_Za_Sezónu as 'Cena za sezónu', kl.Název as 'Mateřský klub' 
	from Klub kl
	join Hostování host on host.Členství_Id = kl.Id 
	join Hráč h on h.Reg_Id = host.Hráč_Reg_Id
	join Kontakt k on k.Id = h.Kontakt_Id
	where kl.Název = @mat_klub_nazev
end
GO

--Vrátí jednotlivé hráče podle zadané mládežnické kategorie
--@kategorie ~ název ml. kategorie
--@pohlavi ~ textová reprezentace pohlaví
--Př. 
  --exec Hráči_Podle_Kategorie 'Starší dorost'
  --exec Hráči_Podle_Kategorie 'Starší přípravka', 'mužské'
  --exec Hráči_Podle_Kategorie 'Starší přípravka', 'z'
--Vyžaduje 1x clustered index scan, protože vrací celou tabulku
CREATE procedure dbo.Hráči_Podle_Kategorie(@kategorie nvarchar(20), @pohlavi nvarchar(6) = null)
as
begin
	declare @err nvarchar(70)
	declare @p_b bit
	if @pohlavi is null
	begin
		begin try
			set @p_b = dbo.Ml_Kategorie_Pohlaví(@kategorie)
		end try
		begin catch
			select @err = concat('U kategorie ', @kategorie, ' není možné určit pohlaví implicitně')
			raiserror(@err, 15, 15)
			return
		end catch
	end
	else
		set @p_b = dbo.Pohlaví_Bit(@pohlavi)

	select 
		Reg_Id AS 'Reg. č.', Jméno, Příjmení, dbo.Ml_Kategorie_Formátované(@kategorie, @p_b) as 'Hráčská kat.', 
		Email, dbo.Tel_Číslo(Tel_Id) as 'Tel. číslo' from Hráč
	join Kontakt on Kontakt.Id = Hráč.Kontakt_Id
	join Tel on Tel.Id = Kontakt.Tel_Id
	where Muž = @p_b and lower(dbo.Urči_Ml_Kategorii(Reg_Id)) = lower(@kategorie)
end
GO

--Hráči, kteří mají nějaký záznam o hostování jsou považováni za hráče hrající na hostování.
--Hráči, kteří nemají žádný záznam o hostování jsou považováni za hráče klubu, který je vlastní.
--Tato funkce smaže všechny staré záznamy o hostování a převede hráče do vlastnictví klubu.
--V připadě, že hráč má platné hostování dojde k výjimce.
--@reg_id ~ registrační číslo hráče
CREATE procedure dbo.Koupit_Hráče(@reg_id nvarchar(7))
as
begin
	if dbo.Má_Platné_Hostování(@reg_id) = 1
	begin
		raiserror('Nemůže být zakoupen hráč, který má stále platné hostování.', 15, 15)
		return
	end
	
	delete from Hostování where Hráč_Reg_Id = @reg_id
end
GO

--Přidá novovou adresu do databáze
create procedure dbo.Přidej_Adresu(@ulice nvarchar(30), @c_p nvarchar(10), @mesto nvarchar(30)
								 , @psc nvarchar(5), @adresa_id int output)
as
begin
	insert into Adresa (Ulice, Č_p, Město, Psč) values (@ulice, @c_p, @mesto, @psc)
	set @adresa_id = SCOPE_IDENTITY()
end
GO

--Vytvoří nové hostování, 
--@smlouva_soubor_cesta reprezentuje cestu k souboru smlouvy 
create procedure dbo.Přidej_Hostování(@kontrakt_id nvarchar(15), @od date, @do date, @cena_za_sezonu money 
							   	    , @hrac_reg_id nvarchar(7), @clenstvi_id int
									, @smlouva_soubor_cesta nvarchar(max) = null)
as
begin
	declare @bin_data varbinary(max)
	declare @query nvarchar(max)		   -- sql injection check, CLR function
	if @smlouva_soubor_cesta is not null and dbo.Soubor_Existuje(@smlouva_soubor_cesta) = 1
	begin
		set @query = 
			'set @bin_data = (select * FROM OPENROWSET(BULK  ''' + @smlouva_soubor_cesta + ''', SINGLE_BLOB) as varbinary)'

		exec sp_executesql @query, N'@bin_data varbinary(MAX) OUTPUT', @bin_data = @bin_data output
		insert into Hostování (Kontrakt_Id, Od, Do, Cena_Za_Sezónu, Smlouva, Hráč_Reg_Id, Členství_Id) 
			         VALUES (@kontrakt_id, @od, @do, @cena_za_sezonu, @bin_data, @hrac_reg_id, @clenstvi_id)
	end
	else if @smlouva_soubor_cesta is null
		insert into Hostování (Kontrakt_Id, Od, Do, Cena_Za_Sezónu, Hráč_Reg_Id, Členství_Id) 
			         VALUES (@kontrakt_id, @od, @do, @cena_za_sezonu, @hrac_reg_id, @clenstvi_id)
	else
		raiserror('@smlouva_soubor_cesta neobsahuje cestu k existujícímu souboru.', 15, 15)
end
GO

CREATE procedure dbo.Přidej_Hráč_Na_Soupisku (@reg_id nvarchar(7), @soupiska_id int, @cislo_dresu int, @nahradnik bit)
as
begin
	insert into Hráč_Soupiska (Hráč_Reg_Id, Soupiska_Id, Číslo, Náhradník) 
					     VALUES (@reg_id, @soupiska_id, @cislo_dresu, @nahradnik)
end
GO

--Přidá nové kontaktní informace včetně telefoního čísla
--Email nebo telefon nebo oboje musí být vyplněno
--Př. 
-- declare @id_franty int
-- exec Přidej_Kontakt 'František', 'Vomáčka', 'frantisek.vomacka@email.cz', '775382906', @kontakt_id = @id_franty
CREATE procedure dbo.Přidej_Kontakt(@jmeno nvarchar(30), @prijmeni nvarchar(30), @email nvarchar(50) = null
								  , @tel_cislo nvarchar(9) = null, @predvolba nvarchar(4) = null, @kontakt_id int output)
as
begin
	if @tel_cislo is not null
	begin
	  declare @tel_id int
	  BEGIN TRANSACTION T
	  BEGIN TRY
		insert into Tel (Předvolba, Číslo) VALUES (@predvolba, @tel_cislo)
		set @tel_id = SCOPE_IDENTITY()
		insert into Kontakt (Jméno, Příjmení, Email, Tel_Id) VALUES (@jmeno, @prijmeni, @email, @tel_id)
		COMMIT TRANSACTION T
	 END TRY

    BEGIN CATCH
      ROLLBACK TRANSACTION T;
	  throw
    END CATCH  
   end
   else
	 --constraint zařídí, že se insert neprovede pokud email je null
     insert into Kontakt (Jméno, Příjmení, Email, Tel_Id) VALUES (@jmeno, @prijmeni, @email, NULL)


   set @kontakt_id = SCOPE_IDENTITY()
end
GO

--Přidá nového hráče včetně kontaktních informací
--Procedura selže, pokud není dodán email, tel. číslo nebo oboje
CREATE procedure dbo.Přidej_Hráče(@reg_id nvarchar(7), @jmeno nvarchar(30), @prijmeni nvarchar(30) 
							    , @pohlavi nvarchar(6), @d_nar date, @email nvarchar(50) = null 
								, @tel_cislo nvarchar(9) = null, @predvolba nvarchar(4) = null)
as
begin
	declare @pohlavi_bit bit
	set @pohlavi_bit = dbo.Pohlaví_Bit(@pohlavi)
	begin try
		begin transaction T
			declare @kontakt_id int
			exec Přidej_Kontakt @jmeno, @prijmeni, @email, @tel_cislo, @predvolba, @kontakt_id = @kontakt_id output
			insert into Hráč (Reg_Id, D_Narození, Muž, Kontakt_Id) VALUES (@reg_id, @d_nar, @pohlavi_bit, @kontakt_id)
		commit transaction T
	end try
	begin catch
		rollback transaction T;
		throw
	end catch
end
GO

--Uloží do DB nový klub včetně adresy a kontaktních informací správce klubu
create procedure dbo.Přidej_Klub(@nazev nvarchar(50)
						       , @ulice nvarchar(30), @c_p nvarchar(10), @mesto nvarchar(30), @psc nvarchar(5)
							   , @jmeno nvarchar(30) = null, @prijmeni nvarchar(30) = null, @email nvarchar(50) = null
							   , @tel_cislo nvarchar(9) = null, @predvolba nvarchar(4) = null
							   , @klub_id int output)
as
begin
	declare @tel_id int
	declare @kontakt_id int
	declare @adresa_id int

	BEGIN TRANSACTION T
	  BEGIN TRY
	  if @jmeno is not null
		exec Přidej_Kontakt @jmeno, @prijmeni, @email, @tel_cislo, @predvolba, @kontakt_id output
	  
	  exec Přidej_Adresu @ulice, @c_p, @mesto, @psc, @adresa_id output
	  insert into Klub (Název, Adresa_Id, Pověřená_Osoba_Id) VALUES (@nazev, @adresa_id, @kontakt_id)
	  set @klub_id = SCOPE_IDENTITY()
	  COMMIT TRANSACTION T
	 END TRY

    BEGIN CATCH
      ROLLBACK TRANSACTION T;
	  throw
    END CATCH 
end
GO

--Přidá nový kontakt a udělá z něho rozhodčího
CREATE procedure dbo.Přidej_Rozhodčího(@jmeno nvarchar(30), @prijmeni nvarchar(30), @email nvarchar(50) = null
									 , @tel_cislo nvarchar(9) = null, @predvolba nvarchar(4) = null, @rozhodci_id int output)
as
begin
	declare @tel_id int
	BEGIN TRANSACTION T
	BEGIN TRY
		declare @kontakt_id int
		exec Přidej_Kontakt @jmeno, @prijmeni, @email, @tel_cislo, @predvolba, @kontakt_id = @kontakt_id output
		insert into Rozhodčí (Kontakt_Id) VALUES (@kontakt_id)
		set @rozhodci_id = SCOPE_IDENTITY()
		COMMIT TRANSACTION T
  END TRY

  BEGIN CATCH
      ROLLBACK TRANSACTION T;
	  throw
  END CATCH  
end
GO

--Přidá novou sezónu
CREATE procedure dbo.Přidej_Sezónu(@zacina date, @konci date)
as
begin
	insert into Sezóna (Start, Konec) values (@zacina, @konci)
end
GO

--Přidá nové utkání do DB
--Není nutné předat sezónu jako parametr (implicitně se použije aktuální sezóna, podle systémového datumu)
--Není nutné vždy předávat pohlaví skupiny (starší žáci jsou chlapci, ale u starší přípravky to jasné není - výjimka)
CREATE procedure dbo.Přidej_Utkání(@goly_my int, @goly_souper int, @souper_id int, @misto_konani_id int
							     , @rozhodci_id int, @soupiska_id int, @ml_kategorie_nazev nvarchar(20)
							     , @ml_kategorie_muzi bit = null, @sezona_start date = null, @goly_my_polocas int = null
							     , @goly_souper_polocas int = null, @utkani_id int output)
as
begin
	if @ml_kategorie_muzi is null 
		set @ml_kategorie_muzi = dbo.Ml_Kategorie_Pohlaví(@ml_kategorie_nazev)

	if @sezona_start is null		
		begin try
			select @sezona_start = dbo.Aktuální_Sezóna()
		end try
		begin catch
			throw
		end catch

	insert into Utkání (Góly_My, Góly_Soupeř, Góly_My_Poločas, Góly_Soupeř_Poločas, Soupeř_Id, Místo_Konání_Id, Ml_Kategorie_Název, Ml_Kategorie_Muži, Sezóna_Start, Rozhodčí_Id, Soupiska_Id) 
		     VALUES (@goly_my, @goly_souper, @goly_my_polocas, @goly_souper_polocas, @souper_id, @misto_konani_id, @ml_kategorie_nazev, @ml_kategorie_muzi, @sezona_start, @rozhodci_id, @soupiska_id)

	set @utkani_id = SCOPE_IDENTITY()
end
GO

create procedure dbo.Smaž_Adresu (@adresa_id int)
as
begin
	delete from Adresa where Id = @adresa_id
end
GO

create procedure dbo.Smaž_Hostování(@kontrakt_id nvarchar(15))
as
begin
	delete from Hostování where Kontrakt_Id = @kontrakt_id
end
GO

--Smaže hráče z DB, nikoliv však jeho kontaktní informace
--Pro vyčištění přebytečných kontaktních informací viz Smaž_Nevyužité_Kontakty
--@reg_id ~ registrační číslo hráče
create procedure dbo.Smaž_Hráče(@reg_id nvarchar(7))
as
begin
	delete from Hráč where Reg_Id = @reg_id
end
GO

--@reg_id ~ registrační číslo hráče
create procedure dbo.Smaž_Hráče_Ze_Soupisky (@reg_id nvarchar(7), @soupiska_id int)
as
begin
	delete from Hráč_Soupiska where Hráč_Reg_Id = @reg_id and Soupiska_Id = @soupiska_id
end
GO

--Smaže klub z DB, nikoliv však jeho adresu
--Pro vyčištění přebytečných adres viz Smaž_Nevyužité_Adresy
CREATE procedure dbo.Smaž_Klub(@klub_id int) 
as
begin
	delete from Klub where Id = @klub_id
end
GO

--Smaže kontakt včetně telefoního čísla (trigger Smaž_Tel ON dbo.Kontakt)
create procedure dbo.Smaž_Kontakt(@kontakt_id int)
as
begin
	delete from Kontakt where Id = @kontakt_Id
end
GO

--Smaže všechny adresy, které nejsou využity ani v jednom utkání nebo na ní nesídlí klub
--Vyžaduje 1x clustered index scan
--Nejde zlepšit, protože nejde vytvořit index na computed column Adresa(Využita). 
--Pro vypočítání hodnoty tohoto sloupce se musí provést select do DB
--Na takové sloupce nejde vytvořit index
CREATE procedure dbo.Smaž_Nevyužité_Adresy
as
begin
	delete from Adresa where Využita = 0
end
GO

--Smaže všechny záznamy z tabulky Kontakt, které nejsou ani jedno z následujících:
	-- rozhodčí, hráč, zapisovatel soupisek, pověřenou osobou klubu
--Vyžaduje 1x clustered index scan
--Nejde zlepšit, protože nejde vytvořit index na computed column Kontakt(Využit). 
--Pro vypočítání hodnoty tohoto sloupce se musí provést select do DB
--Na takové sloupce nejde vytvořit index
CREATE   procedure dbo.Smaž_Nevyužité_Kontakty
as
begin
	delete from Kontakt where Využit = 0
end
GO

--Smaže rozhodčího z DB, nikoliv však jeho kontaktní informace
--Pro vyčištění přebytečných kontaktních informací viz Smaž_Nevyužité_Kontakty
create procedure dbo.Smaž_Rozhodčího (@rozhodci_id int)
as
begin
	delete from Rozhodčí where Id = @rozhodci_id
end
GO

create procedure dbo.Smaž_Sezónu(@zacina date)
as
begin
	delete from Sezóna where Start = @zacina
end
GO

--Smaže soupisku včetně záznamů hráčů, kteří na ní jsou zapsání (cascade delete)
--(Pokud soupiska již není využita pro nějaké utkání)
create procedure dbo.Smaž_Soupisku(@soupiska_id int)
as
begin
	delete from Soupiska where Id = @soupiska_id
end
GO

create procedure dbo.Smaž_Utkání(@utkani_id int)
as
begin
	delete from Utkání where Id = @utkani_id
end
GO

--Vrátí všechna utkání, která se hrála proti soupěři se jménem klubu @souper_klub_nazev
--Př. exec Utkání_Proti 'Lokomotiva Červený Kostelec'
--Vyžaduje 1x clustered index scan, protože vrací celou tabulku
CREATE procedure dbo.Utkání_Proti(@souper_klub_nazev nvarchar(50))
as
begin
	select  
	   dbo.Skóre(u.Góly_My, u.Góly_Soupeř, u.Góly_My_Poločas, u.Góly_Soupeř_Poločas) as 'Skóre', 
	   kl.Název as 'Soupeř', dbo.Doma_Venku(u.Místo_Konání_Id, u.Soupeř_Id) as 'Místo', a.Ulice, a.Č_p as 'Č. p.', a.Město, a.Psč,
	   dbo.Ml_Kategorie_Formátované(u.Ml_Kategorie_Název, u.Ml_Kategorie_Muži) as 'Hráčská kat.', 
	   dbo.Soupiska_Počet_Lidí(u.Soupiska_Id) as 'Počet na soupis.',
	   s.Start as 'Sez. start', s.Konec as 'Sez. konec', k.Jméno as 'Jméno rozh.', k.Příjmení as 'Příjmení rozh.', 
	   k.Email as 'Email rozh.', dbo.Tel_Číslo(k.Tel_Id) as 'Tel. č. rozh.'
	from Klub kl 
	join Utkání u on u.Soupeř_Id = kl.Id
	join Adresa a on a.Id = u.Místo_Konání_Id
	join Sezóna s on s.Start = u.Sezóna_Start
	join Rozhodčí r on r.Id = u.Rozhodčí_Id
	join Kontakt k on k.Id = r.Kontakt_Id
	where kl.Název = @souper_klub_nazev
end
GO

--Vytvoří novou prázdnou soupisku, kterou zapsala osoba @zapsal_kontakt_id
--Id nové soupisky se vrací v druhém parametru
CREATE procedure dbo.Vytvoř_Prázdnou_Soupisku(@zapsal_kontakt_id int = null, @soupiska_id int output)
as
begin
	insert into Soupiska (Zapsal_Id) values (@zapsal_kontakt_id)
	set @soupiska_id = SCOPE_IDENTITY()
end
