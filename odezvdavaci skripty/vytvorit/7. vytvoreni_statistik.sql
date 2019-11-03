/*
Autor: Jakub Levý
Vytvořeno pro DBA @ MFF ZS 19/20

Statistiky, které pokud bychom je nevytvořili my, a měli povolené 'Auto Create Statistics' tak si je MSSQL sám vytvoří.
Hodí se query optimizeru pro dotazy, které jsou obsaženy ve funkcích, procedůrách a triggerech.
*/

USE Levý_Fotbal 
GO

create statistics STAT_Adresa_Ulice on Adresa(Ulice) with fullscan
create statistics STAT_Adresa_Č_p on Adresa(Č_p) with fullscan
create statistics STAT_Adresa_Město on Adresa(Město) with fullscan
create statistics STAT_Adresa_Psč on Adresa(Psč) with fullscan

create statistics STAT_Hostování_Od on Hostování(Od) with fullscan
create statistics STAT_Hostování_Do on Hostování(Do) with fullscan
create statistics STAT_Hostování_Cena_Za_Sezónu on Hostování(Cena_Za_Sezónu) with fullscan

create statistics STAT_Hráč_Muž on Hráč(Muž) with fullscan

create statistics STAT_Hráč_Soupiska_Číslo on Hráč_Soupiska(Číslo) with fullscan
create statistics STAT_Hráč_Soupiska_Náhradník on Hráč_Soupiska(Náhradník) with fullscan

create statistics STAT_Kontakt_Jméno on Kontakt(Jméno) with fullscan
create statistics STAT_Kontakt_Příjmení on Kontakt(Příjmení) with fullscan

create statistics STAT_Ml_Kategorie_Délka_Zápasu_Minut on Ml_Kategorie(Délka_Zápasu_Minut) with fullscan

create statistics STAT_Utkání_Ml_Kategorie_Muži on Utkání(Ml_Kategorie_Muži) with fullscan
create statistics STAT_Utkání_Góly_My on Utkání(Góly_My) with fullscan
create statistics STAT_Utkání_Góly_Soupeř on Utkání(Góly_Soupeř) with fullscan
create statistics STAT_Utkání_Góly_My_Poločas on Utkání(Góly_My_Poločas) with fullscan
create statistics STAT_Utkání_Góly_Soupeř_Poločas on Utkání(Góly_Soupeř_Poločas) with fullscan