extends RefCounted
const FOLLOWUPS = {
  "Pratesjuke Per": [
    "Du må høyra resten før du går.",
    "Eg har ikkje eingong kome til delen med onkelen.",
    "Det var akkurat slik det byrja sist òg.",
    "Eg kan teikna det på ein serviett.",
    "Kvar var eg no?"
  ],
  "Kvist-Kari": [
    "Berre ein liten grein til.",
    "Eg lovar at dette er siste lasset.",
    "Du skulle sett hekken før eg byrja.",
    "Komposten har fått sitt eige postnummer.",
    "Eg har funne fram hanskane."
  ],
  "Betrevitar-Bjarte": [
    "Eg har laga ein tabell over rygginga di.",
    "Det er ikkje kritikk, det er kvalitetssikring.",
    "Eg kunne forklart det med ein trekant.",
    "Du må ikkje forveksla teori med praksis.",
    "Eg har faktisk med måleband."
  ],
  "Sladre-Sissel": [
    "Eg har ikkje sagt noko, men alle veit det.",
    "Det går fortare enn fiber her i bygda.",
    "Eg såg berre det eg såg.",
    "Det er ikkje sladder dersom det handlar om ein hengar.",
    "Me får venta på neste episode."
  ],
  "Traktor-Tor": [
    "Ein god traktor treng ikkje app.",
    "Eg har kaffi på termos.",
    "Den bakken tek eg på låggir.",
    "Det er betre med møk på støvlane enn rust på akslingen.",
    "Eg har ein gamal skiftenøkkel i lomma."
  ],
  "BIR-Berit": [
    "Her er det sortering, ikkje bingo.",
    "Les skiltet før du opnar lemmen.",
    "Det er ikkje eg som har blanda lasset.",
    "Du får spørja før du tippar.",
    "Godt jobba med den sorteringa."
  ],
  "Vaffel-Vigdis": [
    "Eg har både syltetøy og brunost.",
    "Det er lov å ta ein pause.",
    "Vaffeljernet har høgare driftstid enn traktoren.",
    "Eg har ein kopp med namnet ditt på.",
    "Ta med ein serviett."
  ],
  "Regulerings-Rolf": [
    "Me må skilja mellom føremål og faktisk bruk.",
    "Eg har lagt inn ein merknad i margen.",
    "Dette er eit prinsipielt spørsmål om parkeringsareal.",
    "Me må avklara om hengaren er mellombels plassert.",
    "Eg føreslår ei synfaring."
  ],
  "Gunnar Gaupen": [
    "Eg har plass til ein pall meir enn deg.",
    "Det er resultatet som tel.",
    "Du kan få låna målebandet mitt.",
    "Eg skal ikkje undervurdera Tanja igjen.",
    "Neste gong vinn eg."
  ],
  "Tommy Tysse": [
    "Eg har eigen mikrofiberklut til kvar felg.",
    "Det er ikkje skit, det er patina.",
    "Eg parkerer helst med utsikt.",
    "Eg vurderer krom på støttehjulet.",
    "Den hengaren fortener eit eige fotoalbum."
  ],
  "Trine Tredal": [
    "Eg har laminert sjekklista.",
    "Me manglar berre signaturen.",
    "Eg har ein reserveplan for reserveplanen.",
    "Eg har kontrollert at kontrollen er kontrollert.",
    "Det er eit system i dette."
  ]
}
const OPTIONS = {
  "hurry": [
    "Eg må rekkja BIR.",
    "Me får snakkast seinare.",
    "Eg har eit lass som ventar."
  ],
  "listen": [
    "Fortel vidare.",
    "Kva skjedde så?",
    "Det må du forklara."
  ],
  "exit": [
    "Ha det godt!",
    "Me tek resten ein annan dag.",
    "No må eg vidare."
  ]
}
const REPLIES = {
  "hurry": [
    "Greitt, eg skal ikkje halda deg att.",
    "Då får me ta resten seinare.",
    "Lukke til med turen."
  ],
  "listen": [
    "Ja, no skal du høyra.",
    "Det er nettopp det som er poenget.",
    "Eg har meir på hjartet."
  ],
  "exit": [
    "Me snakkast!",
    "God tur vidare.",
    "Hels Tanja."
  ]
}
var engine = preload("res://smalltalk.gd").new()
var rng := RandomNumberGenerator.new()
var encounters: Dictionary = {}
var active := ""
var turns := 0

func begin(speaker: String) -> Dictionary:
	if not FOLLOWUPS.has(speaker):
		return {}
	active = speaker
	turns = 0
	encounters[speaker] = int(encounters.get(speaker,0))+1
	return {"speaker":speaker,"lines":engine.conversation(speaker),"options":OPTIONS,"visits":encounters[speaker]}

func respond(choice: String) -> Dictionary:
	if active.is_empty() or not OPTIONS.has(choice):
		return {}
	turns += 1
	var speaker := active
	var lines: Array[String] = []
	var done := choice != "listen" or turns >= 5
	if choice == "listen":
		var pool: Array = FOLLOWUPS[speaker]
		lines.append(str(pool[rng.randi_range(0,pool.size()-1)]))
	var responses: Array = REPLIES["exit" if done and choice == "listen" else choice]
	lines.append(str(responses[rng.randi_range(0,responses.size()-1)]))
	if done:
		active = ""
	return {"speaker":speaker,"lines":lines,"done":done,"turns":turns}
