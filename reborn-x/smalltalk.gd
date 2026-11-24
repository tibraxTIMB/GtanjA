extends RefCounted
# Original fictional dialogue; no network dependency.
const CAST = {
  "Pratesjuke Per": [
    [
      "Eg skal berre fortelja deg ein liten ting.",
      "Har du to minutt?",
      "Du kjenner vel han som bur bortanfor svingen?",
      "Dette har eg ikkje fortalt til mange.",
      "Eg hugsar då alt dette var annleis.",
      "Du må ikkje gå før eg kjem til poenget."
    ],
    [
      "Det byrja med ein plenklippar.",
      "Så kom svogeren med ein tilhengjar.",
      "Det var på ein tysdag, trur eg.",
      "Kommunen hadde visst eit møte.",
      "Eg måtte ringja tre telefonar.",
      "Ingen hadde rett dimensjon på bolten."
    ],
    [
      "Men det er ei anna historie.",
      "No kjem eg snart til poenget.",
      "Vent litt, eg gløymde byrjinga.",
      "Det får me ta over ein kaffi.",
      "Du har vel ikkje dårleg tid?"
    ]
  ],
  "Kvist-Kari": [
    [
      "Kan du ta med litt kvist?",
      "Eg har rydda hagen.",
      "Så flott tilhengjar du har!",
      "Eg skulle berre klippa ein busk.",
      "Du er vel på veg til BIR?"
    ],
    [
      "Det vart visst tre lass.",
      "Naboen kom med motorsaga.",
      "Eg fann ein gammal kompostbinge.",
      "Det ligg litt jord under kvisten.",
      "Eg har sortert nesten alt."
    ],
    [
      "Du får ein kaffi etterpå.",
      "Eg skal hjelpa deg å lasta.",
      "Ikkje sei det til mannen min.",
      "Me tek resten neste helg.",
      "Hugs å sikra lasset."
    ]
  ],
  "Betrevitar-Bjarte": [
    [
      "Du køyrer feil.",
      "Eg ville gjort det annleis.",
      "Det der er ikkje optimalt.",
      "Har du rekna på kuletrykket?",
      "Eg har sett ein video om dette."
    ],
    [
      "Det handlar om vinklar.",
      "Du må tenkja på tyngdepunktet.",
      "Eg har eit rekneark heime.",
      "Ein kompis av meg har fagbrev.",
      "Det er elementær mekanikk."
    ],
    [
      "Men du bestemmer sjølv.",
      "Eg sa det berre.",
      "Du kjem til å hugsa dette.",
      "Eg kan visa deg ein gong.",
      "Ikkje kom til meg etterpå."
    ]
  ],
  "Sladre-Sissel": [
    [
      "Har du høyrt det siste?",
      "Eg seier ikkje kven som sa det.",
      "Dette blir mellom oss.",
      "Eg såg noko interessant i går.",
      "Du veit vel kven som har kjøpt ny hengar?"
    ],
    [
      "Det stod ein bil utanfor garasjen.",
      "Nokon hadde bestilt tre konteinarar.",
      "Det var visst eit møte på kaien.",
      "Eg såg Gunnar ved butikken.",
      "Kaffien var ikkje eingong kald."
    ],
    [
      "Men eg blandar meg ikkje.",
      "Ikkje nemn namnet mitt.",
      "No har eg sagt for mykje.",
      "Det er sikkert heilt uskuldig.",
      "Eg får vel høyra meir i morgon."
    ]
  ],
  "Traktor-Tor": [
    [
      "Fin dag for traktoren.",
      "Du skulle hatt større hjul.",
      "Eg har køyrt denne vegen i førti år.",
      "Har du sett vêrmeldinga?",
      "Det er godt med litt diesel."
    ],
    [
      "Det er vått på bøen.",
      "Eg må flytta ein rundball.",
      "Den gamle traktoren starta på første forsøk.",
      "Det ligg grus i svingen.",
      "Eg har ein bolt som passar."
    ],
    [
      "Me får ta det roleg.",
      "Du kjem fram til slutt.",
      "Eg skal sleppa deg forbi.",
      "Hels dei på BIR.",
      "No må eg heim til fjøset."
    ]
  ],
  "BIR-Berit": [
    [
      "Kva har du på lasset?",
      "Velkomen til miljøparken.",
      "Har du sortert på førehand?",
      "Stopp ved rett konteinar.",
      "Hugs at me stengjer."
    ],
    [
      "Kvist skal ikkje blandast med stein.",
      "Me må halda køyrevegen fri.",
      "Farleg avfall skal leverast separat.",
      "Sjekk skilta før du lossar.",
      "Du må sikra lasset før du køyrer."
    ],
    [
      "Spør heller ein gong for mykje.",
      "Takk for at du sorterer.",
      "Det gjekk fint denne gongen.",
      "Me har sett verre.",
      "God tur heim."
    ]
  ],
  "Vaffel-Vigdis": [
    [
      "Vil du ha ei vaffel?",
      "Kaffien er klar.",
      "Du ser svolten ut.",
      "Eg har laga ny røre.",
      "Tanja fortener ein pause."
    ],
    [
      "Brunosten er på bordet.",
      "Eg fann det gamle vaffeljernet.",
      "Per har allereie ete tre.",
      "Det regnar sidelengs ute.",
      "Eg har spart den siste til deg."
    ],
    [
      "Du får ta med ei til turen.",
      "Ikkje søl i bilen.",
      "Me snakkast etter BIR.",
      "Kaffi først, rygging etterpå.",
      "Det ordnar seg."
    ]
  ],
  "Regulerings-Rolf": [
    [
      "Er dette i samsvar med planen?",
      "Me må vurdera heilskapen.",
      "Eg har eit kart du bør sjå.",
      "Dette krev ei nærare avklaring.",
      "Har du vurdert alternativ plassering?"
    ],
    [
      "Det er eit spørsmål om arealbruk.",
      "Me må sjå på trafikktryggleiken.",
      "Det kan vera eit rekkjefølgjekrav.",
      "Kartgrunnlaget må kvalitetssikrast.",
      "Me må sikra god tilkomst."
    ],
    [
      "Eg kjem tilbake med eit notat.",
      "Dette er ikkje eit endeleg vedtak.",
      "Me tek det i neste møte.",
      "Det må vurderast konkret.",
      "Eg noterer innspelet."
    ]
  ],
  "Gunnar Gaupen": [
    [
      "Er det Tanja som kjem der?",
      "Du kallar det der ein tilhengjar?",
      "Eg har allereie levert to lass.",
      "Skal me sjå kven som kjem først?",
      "Du treng vel hjelp til å rygga?"
    ],
    [
      "Gaupen min står klar.",
      "Eg har øvd på den svingen.",
      "Eg treng ikkje tre forsøk.",
      "Det er ikkje storleiken det kjem an på.",
      "Eg såg deg i spegelen."
    ],
    [
      "Me får sjå på BIR.",
      "Ikkje køyr deg fast.",
      "Eg ventar ved mål.",
      "Dette blir interessant.",
      "Du får ein ny sjanse."
    ]
  ],
  "Tommy Tysse": [
    [
      "Sjå på dei felgane!",
      "Eg har polert hengaren.",
      "Har du sett dei nye lysa?",
      "Dette er premium, veit du.",
      "Eg køyrer berre med stil."
    ],
    [
      "Eg har matchande ventilhettar.",
      "Lakksjiktet er heilt perfekt.",
      "Eg tok eit bilete ved fjorden.",
      "Eg har investert i nye stroppar.",
      "Det er detaljane som tel."
    ],
    [
      "Ikkje sprut gjørme på meg.",
      "Me tek eit bilete seinare.",
      "Du får låna poleringskluten.",
      "Stilpoeng til meg.",
      "Eg må finna ein tørr parkeringsplass."
    ]
  ],
  "Trine Tredal": [
    [
      "Har du sjekka lista?",
      "Eg har målt alt to gonger.",
      "Du manglar eit punkt.",
      "Me bør planleggja ruta.",
      "Eg har sortert etter kategori."
    ],
    [
      "Stroppane ligg i rett rekkjefølgje.",
      "Eg har merka alle kassane.",
      "Eg har lagt inn fem minutt reserve.",
      "Eg kontrollerte lysa før avreise.",
      "Alt har sin faste plass."
    ],
    [
      "No kan me starta.",
      "Ta ein siste kontroll.",
      "Det er betre å vera førebudd.",
      "Eg kryssar av for gjennomført.",
      "Dette vart nesten perfekt."
    ]
  ]
}

var rng := RandomNumberGenerator.new()
var recent: Dictionary = {}

func conversation(speaker: String) -> Array[String]:
	var result: Array[String] = []
	if not CAST.has(speaker):
		return result
	var parts: Array = CAST[speaker]
	var history: Array = recent.get(speaker, [])
	var signature := ""
	for attempt in range(20):
		result.clear()
		for pool in parts:
			result.append(str(pool[rng.randi_range(0,pool.size()-1)]))
		signature = "|".join(result)
		if not history.has(signature):
			break
	history.append(signature)
	if history.size()>40:
		history.pop_front()
	recent[speaker] = history
	return result
