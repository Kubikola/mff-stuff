(:
XHTML, FUNCTION
Tabulka jednotlivých klubů vlastnící stadiony alespoň za 7000 obsahující:
	- název
	- motto
	- adresu 
	- majetek (stadiony, ostatní majetek)
		- mixed content rozdělěn na text a tagy (odkazující se na stadiony)

Výstup: https://i.imgur.com/EsU3PFI.png
	(navíc byly pro přehlednost aplikovány CSS styly, nejsou součástí výstupu)
	table {
	  font-family: arial, sans-serif;
	  border-collapse: collapse;
	  width: 100%;
	}
	td, th {
	  border: 1px solid #dddddd;
	  text-align: left;
	  padding: 8px;
	}
	
	tr:nth-child(even) {
	  background-color: #dddddd;
	}

:)
xquery version "3.0" encoding "UTF-8";
declare function local:outputMotto($motto as item()?) 
as xs:string {
	if($motto) then
		if($motto/@since) then
			concat(data($motto), ' (mottem již od roku ', $motto/@since, ')')
		else
			data($motto)
	else 
	'Nemá žádné motto.'
};

declare function local:outputAddress($address as item()) 
as xs:string {
	concat($address/street, ' ', $address/number, ', ', $address/postcode, ' ', $address/town)
};

declare function local:outputPossessions($possessions as item()) 
as item()* {
	let $stadions := $possessions/owned-stadion
	let $text := $possessions/text()[normalize-space()]
	return
	if(string-length($text) > 0) then ( 
		element td { $text },
		element td { local:outputOwnedStadions($stadions) }  
	)
	else (
		element td { '' },
		element td { local:outputOwnedStadions($stadions) }
	)
};

declare function local:outputOwnedStadions($stadions as item()*)
as item()* {	
	for $ownedStadion in $stadions
	let $file := doc('../data.xml')
	let $st := $file/football/stadions/stadion[@id = $ownedStadion/@refId]
	let $outAddr := local:outputAddress($st/address)
	let $outSurface := data($file/football/stadions/surfaces/surface[@id = $st/@surface])
	return 
	element ul { 
		element li { concat('Stadion s Id = ', $ownedStadion/@refId) },
		element li {
			element ul {
				element li { concat('Adresa: ', $outAddr) },
				element li { concat('Povrch: ', $outSurface) },
				element li { concat('Cena: ', data($st/price)) }
			}
		}
	}
};

element table {
	element tr {
		element th { 'Název' },
		element th { 'Motto' },
		element th { 'Adresa' },
		element th { 
			attribute colspan { '2' },
			'Vlastněný majetek' 
		}
	},
	let $file := doc('../data.xml')
	for $club in $file/football/clubs/club
	let $name := $club/name
	let $ownedS := $file/football/stadions/stadion[@id = $club/possessions/owned-stadion/@refId]
	where sum($ownedS/price) > 7000
	order by $name ascending
	return 
	element tr {
		element td { data($club/name) },
		element td { local:outputMotto($club/motto) },
		element td { local:outputAddress($club/address) },
		local:outputPossessions($club/possessions)
	}
}