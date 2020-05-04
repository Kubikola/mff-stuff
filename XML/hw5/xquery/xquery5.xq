xquery version "3.0" encoding "UTF-8";

(:
JOIN

Spojí doc('../data.xml')/football/people/
a doc('../data-people.xml')/people	

do

<people>
	<person> ... </person>
</people>

:)

element people {
let $p1 :=
	let $ppl1 := doc('../data.xml')/football/people/person
	for $p in $ppl1
	return
	element person {
		attribute id { $p/@id },
		element name {
			element first { data($p/first-name) },
			element last { data($p/last-name) }
			
    	},
    	element contact {
			$p/contact/email,
			$p/contact/telephone
    	}
	}
let $p2 := 
	let $ppl2 := doc('../data-people.xml')/people/person
	for $p in $ppl2
	let $name := tokenize(data($p/name), '[ &#9;&#10;&#13;]+')
	return
	element person {
		attribute id { $p/@id },
		element name {
			element first { $name[1] },
			element second { $name[2] }
		},
	 	element contact {
			$p/email,
			$p/telephone
    	}
	}
for $person in $p1 | $p2
let $lastN := $person/name/last
let $firstN := $person/name/first
order by $lastN, $firstN ascending
return $person
}

