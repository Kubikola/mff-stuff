(:
	INTEGRATION, FUNCTION
	Vlastní každý klub, alespoň jednu další věc (mimo stadionů)?
:)

xquery version "3.0" encoding "UTF-8";

declare function local:listOfPossessions($cId as xs:string)
as xs:string* {
	for $item in doc('../data.xml')/football/clubs/club[@id = $cId]/possessions/text()[normalize-space()]
	let $strippedItem := translate($item, ' &#9;&#10;&#13;', '')
	return concat('   ', $strippedItem)
};

let $file := doc('../data.xml')
return (
if(every $club in $file/football/clubs/club satisfies (string-length($club/possessions/text()[normalize-space()]) > 0)) then
text {	
	'Každý klub vlastní alespoň jednu další věc (mimo stadionu).&#10;&#10;',
	string-join (
		for $club in $file/football/clubs/club
		return
			concat('Klub ', data($club/name), ':', '&#10;', string-join(local:listOfPossessions($club/@id), '&#10;'))
	, '&#10;&#10;')
	}
else 
text {
	'Existuje klub, který nevlastní žádnou další věc navíc (mimo stadionu).&#10;&#10;',
		string-join (
			for $club in $file/football/clubs/club[string-length(possessions/text()[normalize-space()]) = 0]
			return concat('Klub ', data($club/name))
	  , '&#10;')	
}
)
