<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:output method="html" indent="yes" encoding="UTF-8"/>
	
	<!-- Hlavní šablona -->
	<xsl:template match="/">
		<xsl:text disable-output-escaping="yes">&lt;!DOCTYPE html&gt;</xsl:text>
		<xsl:element name="html">
			<xsl:attribute name="lang">cs</xsl:attribute>
			<head>
				<title>Fotbalová asociace</title>
				<style>
				.umt {
				   color: red;
				}
				.zvt {
				   color: blue;
				}
				table {
				  border-collapse: collapse;
				}

				table, th, td {
				  border: 1px solid black;
				}
			</style>
			</head>
			<body>
				<h2>Seznam osob</h2>
				<table>
					<tbody>
						<tr>
							<th>Jméno</th>
							<th>Příjmení</th>
							<th>Email</th>
							<th>Email (XML)</th>
							<th>Tel. č</th>
						</tr>
						<xsl:apply-templates select="football/people/person"/>
					</tbody>
				</table>
				<h2>Seznam klubů</h2>
				<table>
					<tbody>
						<tr>
							<th>Název</th>
							<th>Motto</th>
							<th>Adresa</th>
							<th>Adresa (XML)</th>
							<th>Majetek</th>
						</tr>
						<xsl:apply-templates select="football/clubs/club"/>
					</tbody>
				</table>
				<h2>Seznam stadionů</h2>
				<i>
					<xsl:element name="span">
						<xsl:attribute name="class">umt</xsl:attribute>
						<xsl:text>Červená</xsl:text>
					</xsl:element> - umělá tráva</i>
				<br/>
				<i>
					<xsl:element name="span">
						<xsl:attribute name="class">zvt</xsl:attribute>
						<xsl:text>Modrá</xsl:text>
					</xsl:element> - živý trávník</i>
				<ul>
					<xsl:apply-templates select="football/stadions/stadion"/>
				</ul>
				
				<h2>Seznam hráčů</h2>
				<table>
					<tbody>
						<tr>
							<th>Reg. č.</th>
							<th>Jméno</th>
							<th>Přijmení</th>
							<th>Pohlaví</th>
							<th>Členství</th>
							<th>Kategorie</th>
						</tr>
						<xsl:apply-templates select="football/players/player"/>
					</tbody>
				</table>
			</body>
		</xsl:element>
	</xsl:template>
	
	<!-- Vnitřek tabulky obsahující seznam osob -->
	<xsl:template match="football/people/person">
		<tr>
			<td> <!-- křestní jméno -->
				<xsl:value-of select="first-name"/>
			</td>
			<td> <!-- příjmení -->
				<xsl:value-of select="last-name"/>
			</td>
			<td> <!-- emailové adresy oddělené čárkou -->
				<xsl:for-each select="contact/email">
					<xsl:choose>
						<xsl:when test="position() != last()">
							<xsl:value-of select="."/>, 
				</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="."/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:for-each>
			</td>
			
			<td><xmp> <!-- emailové adresy v XML -->
				<xsl:for-each select="contact/email">
				<xsl:copy>
					<xsl:apply-templates/>
				</xsl:copy>
				</xsl:for-each>
				</xmp>
			</td>
			
			<td> <!-- telefonní čísla oddělená čárkou -->
				<xsl:for-each select="contact/telephone">
					<xsl:choose>
						<xsl:when test="position() != last()">
							<xsl:value-of select="prefix"/>
							<xsl:value-of select="suffix"/>, 
				</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="prefix"/>
							<xsl:value-of select="suffix"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:for-each>
			</td>
		</tr>
	</xsl:template>
	
	<!-- Tradičním způsobem formátovaná adresa, např. Náměstí 320, 549 32 Velké Pořičí -->
	<xsl:template name="address">
		<xsl:value-of select="address/street"/>
		<xsl:text> </xsl:text>
		<xsl:value-of select="address/number"/>
		<xsl:text>, </xsl:text>
		<xsl:value-of select="address/postcode"/>
		<xsl:text> </xsl:text>
		<xsl:value-of select="address/town"/>
	</xsl:template>
	
	<!-- Vnitřek tabulky obsahující seznam klubů -->
	<xsl:template match="football/clubs/club">
		<tr>
			<td> <!-- jméno klubu -->
				<xsl:value-of select="name"/>
			</td>
			
			<td> 
				<xsl:value-of select="motto"/>
				<xsl:if test="motto/@since"> <!-- pokud motto klubu obsahuje atribut, od kdy je mottem klubu -->
					<i>(již od roku <xsl:value-of select="motto/@since"/>)</i>
				</xsl:if>
			</td>
			<td> <!-- tradičně formátovaná adresa -->
				<xsl:call-template name="address"/>
			</td>
			<td>
				<xmp> <!-- adresa v XML -->
					<xsl:copy-of select="address"/> 
				</xmp> 
			</td>
			<td>
				<ul> <!-- majetek klubu -->
					<xsl:apply-templates select="possessions"/>
				</ul>
			</td>
		</tr>
	</xsl:template>
	
	<!-- Vypíše název povrchu terénu, např. umělá tráva -->
	<xsl:template match="football/stadions/surfaces/surface">
		<xsl:value-of select="."/>
	</xsl:template>
	
	<!-- Vypíše stadion do tabulky klubů jako majetek klubu, 
		 např. Stadion 
                 ◦ Povrch: umělý trávník
				 ◦ Adresa: Příkopy 1186, 547 01 Náchod -->
	<xsl:template match="football/stadions/stadion" mode="ownedStadion">
		<xsl:variable name="surfaceId" select="@surface"/>
Stadion
<ul>
			<li>
				<strong>Povrch: </strong>
				<xsl:apply-templates select="../surfaces/surface[@id = $surfaceId]"/>
			</li>
			<li>
				<strong>Adresa: </strong>
				<xsl:call-template name="address"/>
			</li>
		</ul>
	</xsl:template>
	
	<!-- Tag possessions obsahuje mixed content
		 Tato šablona zpracovává tag owned-stadion, který se uvnitř possessions může vyskytnout -->
	<xsl:template match="football/clubs/club/possessions/owned-stadion">
		<xsl:variable name="stadionId" select="@refId"/>
		<li>
			<xsl:apply-templates select="../../../../stadions/stadion[@id = $stadionId]" mode="ownedStadion"/>
		</li>
	</xsl:template>
	
	<!-- Tag possessions obsahuje mixed content
		 Tato šablona zpracovává ostatní syrová textová data -->
	<xsl:template match="football/clubs/club/possessions/text()">
		<xsl:if test="string-length(normalize-space(.)) > 0">
			<li>
				<xsl:value-of select="."/>
			</li>
		</xsl:if>
	</xsl:template>
	
	<!-- Seznam všech stadionů, podle barvy textu se určuje povrch stadionu -->
<xsl:template match="football/stadions/stadion">
	<xsl:variable name="surfaceId" select="@surface"/>
	<xsl:variable name="surfaceType" select="../surfaces/surface[@id = $surfaceId]"/>
	<xsl:if test="$surfaceType = 'umělý trávník'">
		<li class="umt"><xsl:call-template name="address"/></li>
	</xsl:if>
	
	<xsl:if test="$surfaceType = 'živý trávník'">
		<li class="zvt"><xsl:call-template name="address"/></li>
	</xsl:if>
</xsl:template>

<!-- Vstupní parameter je id osoby,
	 Výstupem je křestní jmeno a přijmení do tabulky, 
     např. <td>Jan</td>
		   <td>Novák</td> -->
<xsl:template name="playersName">
	<xsl:param name="personId" select="person"/>
	<td><xsl:value-of select="/football/people/person[@id = $personId]/first-name"/></td>
	<td><xsl:value-of select="/football/people/person[@id = $personId]/last-name"/></td>
</xsl:template>

<!-- Vstupní parameter je id pohlaví,
	 Výstupem je jeho textová reprezentace
     např. pro m -> mužské
		   pro f -> ženské -->
<xsl:template name="gender">
	<xsl:param name="genderId" select="gender"/>
	<xsl:value-of select="/football/players/genders/gender[@id = $genderId]"/>
</xsl:template>

<!-- Vstupní parameter je id klubu,
	 Výstupem je jeho název
     např. pro cl1 -> SK Babí, z.s. -->
<xsl:template name="membership">
	<xsl:param name="clubId" select="club"/>
	<xsl:value-of select="/football/clubs/club[@id = $clubId]/name"/>
</xsl:template>

<!-- Vstupní parameter je id hráčské kategorie,
	 Výstupem je její název
     např. pro cat11 -> žáci mladší -->
<xsl:template name="category">
	<xsl:param name="categoryId" select="category"/>
	<xsl:value-of select="//category[@id = $categoryId][not(category)]/string-join((ancestor::category/text(), text()), ' ')"/>
</xsl:template>

<!-- Vnitřek tabulky obsahující seznam hráčů -->
<xsl:template match="football/players/player">
<tr>
	<td> <!-- Reg. číslo -->
		<xsl:value-of select="reg-num"/>
	</td>
	
	<xsl:call-template name="playersName"> <!-- Křestní jméno a příjmení -->
		<xsl:with-param name="personId" select="@person"/>
	</xsl:call-template>
	
	<td><xsl:call-template name="gender"> <!-- Pohlaví -->
		<xsl:with-param name="genderId" select="@gender"/>
	</xsl:call-template></td>
	
	<td><xsl:call-template name="membership"> <!-- Jméno klubu, jehož je hráč(ka) členem -->
		<xsl:with-param name="clubId" select="@club"/>
	</xsl:call-template>
	</td>
	
	<td><xsl:call-template name="category"> <!-- Hráčská kategorie, pod kterou hráč(ka) spadá -->
		<xsl:with-param name="categoryId" select="@category"/>
	</xsl:call-template>
	</td>
</tr>
</xsl:template>
</xsl:stylesheet>
