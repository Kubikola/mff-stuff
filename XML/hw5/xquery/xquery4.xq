(:
INTEGRATION, FUNCTION

Vrátí informace o telefonních prefixech

Výstup:
+420 +421 +15
Celkově 3 různé prefixy se vyskytují

Nejmenší prefix: +15
Největší prefix: +421


:)
xquery version "3.0" encoding "UTF-8";

declare function local:convertToDigits($prefixes as xs:string*)
as xs:integer* {
	for $prefix in $prefixes
	return xs:integer(substring($prefix, 2, string-length($prefix) - 1))
};

let $prefixes := doc('../data.xml')/football/people/person/contact/telephone/prefix
let $uniquePrefixes := distinct-values($prefixes)
let $digits := local:convertToDigits(data($uniquePrefixes))

let $maxDigit := max($digits)
let $minDigit := min($digits)

return concat(string-join(data($uniquePrefixes), ' '), '&#10;', 'Celkově ', count($uniquePrefixes), ' různé prefixy se vyskytují', '&#10;&#10;', 'Nejmenší prefix(y): +', $minDigit, '&#10;', 'Největší prefix(y): +', $maxDigit, '&#10;', '(Vzhledem k standardnímu uspořádání přirozených čísel)')


