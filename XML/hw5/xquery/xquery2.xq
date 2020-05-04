(:
INTEGRATION, FUNCTION

Hráč:
<player person="per2" category="cat11" gender="m" club="cl1">
			<reg-num format="old">594220</reg-num>
</player>

obsahuje v atributech mnoho cizích klíčů.

Tento dotaz transformuje tohoto hráče data do podoby:

<player>
	<reg-num>594220</reg-num>
	<person>...</person>
	<category>žáci mladší</category>
	<gender>mužské</gender>
	<club>...</club>
</player>


:)
xquery version "3.0" encoding "UTF-8";
declare copy-namespaces no-preserve, inherit;

declare function local:copyWithoutAttributes($parent as element()) 
as element() {
   element { node-name($parent) } {
      for $child in $parent/node()
      return
      if ($child instance of element()) then 
		local:copyWithoutAttributes($child)
	  else 
		$child
      }
};

declare function local:transformClub($parent as element())
as element() {
	if(node-name($parent) = xs:QName('owned-stadion')) then
		local:transformStadion($parent)
	else
		element { node-name($parent) } {
		  for $child in $parent/node()
		  return
		  if ($child instance of element()) then 
			local:transformClub($child)
		  else 
			$child
		}
};

declare function local:transformStadion($ownedStadion as element())
as element() {
    let $file := doc('../data.xml')
	let $st := $file/football/stadions/stadion[@id = $ownedStadion/@refId]
	return
	<stadion> {
		<surface> { data($file/football/stadions/surfaces/surface[@id = $st/@surface]) } </surface>,
		$st/address,
		<price> {data($st/price)} </price>
	}
	</stadion>
};


let $file := doc('../data.xml')
for $p in $file/football/players/player
let $person := $file/football/people/person[@id = $p/@person]
return
element player {
	$p/reg-num,
	local:copyWithoutAttributes($person),
	element category { $file//category[not(category)][@id = $p/@category]/string-join((ancestor::category/text(), text()), ' ') },
	local:copyWithoutAttributes($p/../genders/gender[@id = $p/@gender]),
	local:transformClub($file/football/clubs/club[@id = $p/@club])
}