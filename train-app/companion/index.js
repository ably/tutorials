import Ably from "ably/browser/static/ably-commonjs.js";
// Import the messaging module
import * as messaging from "messaging";
import { settingsStorage } from "settings";
import { geolocation } from "geolocation";

const StationsIDMapping = [
    {
      line: "metropolitan",
      stationid: "940GZZLUALD",
      station: "Aldgate Underground Station"
    },
    {
      line: "metropolitan",
      stationid: "940GZZLUAMS",
      station: "Amersham Underground Station"
    },
    {
      line: "metropolitan",
      stationid: "940GZZLUBBN",
      station: "Barbican Underground Station"
    },
    {
      line: "metropolitan",
      stationid: "940GZZLUBST",
      station: "Baker Street Underground Station"
    },
    {
      line: "metropolitan",
      stationid: "940GZZLUCAL",
      station: "Chalfont & Latimer Underground Station"
    },
    {
      line: "metropolitan",
      stationid: "940GZZLUCSM",
      station: "Chesham Underground Station"
    },
    {
      line: "metropolitan",
      stationid: "940GZZLUCXY",
      station: "Croxley Underground Station"
    },
    {
      line: "metropolitan",
      stationid: "940GZZLUCYD",
      station: "Chorleywood Underground Station"
    },
    {
      line: "metropolitan",
      stationid: "940GZZLUEAE",
      station: "Eastcote Underground Station"
    },
    {
      line: "metropolitan",
      stationid: "940GZZLUESQ",
      station: "Euston Square Underground Station"
    },
    {
      line: "metropolitan",
      stationid: "940GZZLUFCN",
      station: "Farringdon Underground Station"
    },
    {
      line: "metropolitan",
      stationid: "940GZZLUFYR",
      station: "Finchley Road Underground Station"
    },
    {
      line: "metropolitan",
      stationid: "940GZZLUGPS",
      station: "Great Portland Street Underground Station"
    },
    {
      line: "metropolitan",
      stationid: "940GZZLUHGD",
      station: "Hillingdon Underground Station"
    },
    {
      line: "metropolitan",
      stationid: "940GZZLUHOH",
      station: "Harrow-on-the-Hill Underground Station"
    },
    {
      line: "metropolitan",
      stationid: "940GZZLUICK",
      station: "Ickenham Underground Station"
    },
    {
      line: "metropolitan",
      stationid: "940GZZLUKSX",
      station: "King's Cross St. Pancras Underground Station"
    },
    {
      line: "metropolitan",
      stationid: "940GZZLULVT",
      station: "Liverpool Street Underground Station"
    },
    {
      line: "metropolitan",
      stationid: "940GZZLUMGT",
      station: "Moorgate Underground Station"
    },
    {
      line: "metropolitan",
      stationid: "940GZZLUMPK",
      station: "Moor Park Underground Station"
    },
    {
      line: "metropolitan",
      stationid: "940GZZLUNHA",
      station: "North Harrow Underground Station"
    },
    {
      line: "metropolitan",
      stationid: "940GZZLUNKP",
      station: "Northwick Park Underground Station"
    },
    {
      line: "metropolitan",
      stationid: "940GZZLUNOW",
      station: "Northwood Underground Station"
    },
    {
      line: "metropolitan",
      stationid: "940GZZLUNWH",
      station: "Northwood Hills Underground Station"
    },
    {
      line: "metropolitan",
      stationid: "940GZZLUPNR",
      station: "Pinner Underground Station"
    },
    {
      line: "metropolitan",
      stationid: "940GZZLUPRD",
      station: "Preston Road Underground Station"
    },
    {
      line: "metropolitan",
      stationid: "940GZZLURKW",
      station: "Rickmansworth Underground Station"
    },
    {
      line: "metropolitan",
      stationid: "940GZZLURSM",
      station: "Ruislip Manor Underground Station"
    },
    {
      line: "metropolitan",
      stationid: "940GZZLURSP",
      station: "Ruislip Underground Station"
    },
    {
      line: "metropolitan",
      stationid: "940GZZLURYL",
      station: "Rayners Lane Underground Station"
    },
    {
      line: "metropolitan",
      stationid: "940GZZLUUXB",
      station: "Uxbridge Underground Station"
    },
    {
      line: "metropolitan",
      stationid: "940GZZLUWAF",
      station: "Watford Underground Station"
    },
    {
      line: "metropolitan",
      stationid: "940GZZLUWHW",
      station: "West Harrow Underground Station"
    },
    {
      line: "metropolitan",
      stationid: "940GZZLUWIG",
      station: "Willesden Green Underground Station"
    },
    {
      line: "metropolitan",
      stationid: "940GZZLUWYP",
      station: "Wembley Park Underground Station"
    },
    {
      line: "central",
      stationid: "940GZZLUBKE",
      station: "Barkingside Underground Station"
    },
    {
      line: "central",
      stationid: "940GZZLUBKH",
      station: "Buckhurst Hill Underground Station"
    },
    {
      line: "central",
      stationid: "940GZZLUBLG",
      station: "Bethnal Green Underground Station"
    },
    {
      line: "central",
      stationid: "940GZZLUBND",
      station: "Bond Street Underground Station"
    },
    {
      line: "central",
      stationid: "940GZZLUBNK",
      station: "Bank Underground Station"
    },
    {
      line: "central",
      stationid: "940GZZLUCHL",
      station: "Chancery Lane Underground Station"
    },
    {
      line: "central",
      stationid: "940GZZLUCWL",
      station: "Chigwell Underground Station"
    },
    {
      line: "central",
      stationid: "940GZZLUDBN",
      station: "Debden Underground Station"
    },
    {
      line: "central",
      stationid: "940GZZLUEAN",
      station: "East Acton Underground Station"
    },
    {
      line: "central",
      stationid: "940GZZLUEBY",
      station: "Ealing Broadway Underground Station"
    },
    {
      line: "central",
      stationid: "940GZZLUEPG",
      station: "Epping Underground Station"
    },
    {
      line: "central",
      stationid: "940GZZLUFLP",
      station: "Fairlop Underground Station"
    },
    {
      line: "central",
      stationid: "940GZZLUGFD",
      station: "Greenford Underground Station"
    },
    {
      line: "central",
      stationid: "940GZZLUGGH",
      station: "Grange Hill Underground Station"
    },
    {
      line: "central",
      stationid: "940GZZLUGTH",
      station: "Gants Hill Underground Station"
    },
    {
      line: "central",
      stationid: "940GZZLUHBN",
      station: "Holborn Underground Station"
    },
    {
      line: "central",
      stationid: "940GZZLUHGR",
      station: "Hanger Lane Underground Station"
    },
    {
      line: "central",
      stationid: "940GZZLUHLT",
      station: "Hainault Underground Station"
    },
    {
      line: "central",
      stationid: "940GZZLUHPK",
      station: "Holland Park Underground Station"
    },
    {
      line: "central",
      stationid: "940GZZLULGN",
      station: "Loughton Underground Station"
    },
    {
      line: "central",
      stationid: "940GZZLULGT",
      station: "Lancaster Gate Underground Station"
    },
    {
      line: "central",
      stationid: "940GZZLULVT",
      station: "Liverpool Street Underground Station"
    },
    {
      line: "central",
      stationid: "940GZZLULYN",
      station: "Leyton Underground Station"
    },
    {
      line: "central",
      stationid: "940GZZLULYS",
      station: "Leytonstone Underground Station"
    },
    {
      line: "central",
      stationid: "940GZZLUMBA",
      station: "Marble Arch Underground Station"
    },
    {
      line: "central",
      stationid: "940GZZLUMED",
      station: "Mile End Underground Station"
    },
    {
      line: "central",
      stationid: "940GZZLUNAN",
      station: "North Acton Underground Station"
    },
    {
      line: "central",
      stationid: "940GZZLUNBP",
      station: "Newbury Park Underground Station"
    },
    {
      line: "central",
      stationid: "940GZZLUNHG",
      station: "Notting Hill Gate Underground Station"
    },
    {
      line: "central",
      stationid: "940GZZLUNHT",
      station: "Northolt Underground Station"
    },
    {
      line: "central",
      stationid: "940GZZLUOXC",
      station: "Oxford Circus Underground Station"
    },
    {
      line: "central",
      stationid: "940GZZLUPVL",
      station: "Perivale Underground Station"
    },
    {
      line: "central",
      stationid: "940GZZLUQWY",
      station: "Queensway Underground Station"
    },
    {
      line: "central",
      stationid: "940GZZLURBG",
      station: "Redbridge Underground Station"
    },
    {
      line: "central",
      stationid: "940GZZLURSG",
      station: "Ruislip Gardens Underground Station"
    },
    {
      line: "central",
      stationid: "940GZZLURVY",
      station: "Roding Valley Underground Station"
    },
    {
      line: "central",
      stationid: "940GZZLUSBC",
      station: "Shepherd's Bush (Central) Underground Station"
    },
    {
      line: "central",
      stationid: "940GZZLUSNB",
      station: "Snaresbrook Underground Station"
    },
    {
      line: "central",
      stationid: "940GZZLUSPU",
      station: "St. Paul's Underground Station"
    },
    {
      line: "central",
      stationid: "940GZZLUSRP",
      station: "South Ruislip Underground Station"
    },
    {
      line: "central",
      stationid: "940GZZLUSTD",
      station: "Stratford Underground Station"
    },
    {
      line: "central",
      stationid: "940GZZLUSWF",
      station: "South Woodford Underground Station"
    },
    {
      line: "central",
      stationid: "940GZZLUTCR",
      station: "Tottenham Court Road Underground Station"
    },
    {
      line: "central",
      stationid: "940GZZLUTHB",
      station: "Theydon Bois Underground Station"
    },
    {
      line: "central",
      stationid: "940GZZLUWCY",
      station: "White City Underground Station"
    },
    {
      line: "central",
      stationid: "940GZZLUWOF",
      station: "Woodford Underground Station"
    },
    {
      line: "central",
      stationid: "940GZZLUWRP",
      station: "West Ruislip Underground Station"
    },
    {
      line: "central",
      stationid: "940GZZLUWSD",
      station: "Wanstead Underground Station"
    },
    {
      line: "central",
      stationid: "940GZZLUWTA",
      station: "West Acton Underground Station"
    },
    {
      line: "waterloo-city",
      stationid: "940GZZLUBNK",
      station: "Bank Underground Station"
    },
    {
      line: "waterloo-city",
      stationid: "940GZZLUWLO",
      station: "Waterloo Underground Station"
    },
    {
      line: "jubilee",
      stationid: "940GZZLUBMY",
      station: "Bermondsey Underground Station"
    },
    {
      line: "jubilee",
      stationid: "940GZZLUBND",
      station: "Bond Street Underground Station"
    },
    {
      line: "jubilee",
      stationid: "940GZZLUBST",
      station: "Baker Street Underground Station"
    },
    {
      line: "jubilee",
      stationid: "940GZZLUCGT",
      station: "Canning Town Underground Station"
    },
    {
      line: "jubilee",
      stationid: "940GZZLUCPK",
      station: "Canons Park Underground Station"
    },
    {
      line: "jubilee",
      stationid: "940GZZLUCWR",
      station: "Canada Water Underground Station"
    },
    {
      line: "jubilee",
      stationid: "940GZZLUCYF",
      station: "Canary Wharf Underground Station"
    },
    {
      line: "jubilee",
      stationid: "940GZZLUDOH",
      station: "Dollis Hill Underground Station"
    },
    {
      line: "jubilee",
      stationid: "940GZZLUFYR",
      station: "Finchley Road Underground Station"
    },
    {
      line: "jubilee",
      stationid: "940GZZLUGPK",
      station: "Green Park Underground Station"
    },
    {
      line: "jubilee",
      stationid: "940GZZLUKBN",
      station: "Kilburn Underground Station"
    },
    {
      line: "jubilee",
      stationid: "940GZZLUKBY",
      station: "Kingsbury Underground Station"
    },
    {
      line: "jubilee",
      stationid: "940GZZLULNB",
      station: "London Bridge Underground Station"
    },
    {
      line: "jubilee",
      stationid: "940GZZLUNDN",
      station: "Neasden Underground Station"
    },
    {
      line: "jubilee",
      stationid: "940GZZLUNGW",
      station: "North Greenwich Underground Station"
    },
    {
      line: "jubilee",
      stationid: "940GZZLUQBY",
      station: "Queensbury Underground Station"
    },
    {
      line: "jubilee",
      stationid: "940GZZLUSJW",
      station: "St. John's Wood Underground Station"
    },
    {
      line: "jubilee",
      stationid: "940GZZLUSTD",
      station: "Stratford Underground Station"
    },
    {
      line: "jubilee",
      stationid: "940GZZLUSTM",
      station: "Stanmore Underground Station"
    },
    {
      line: "jubilee",
      stationid: "940GZZLUSWC",
      station: "Swiss Cottage Underground Station"
    },
    {
      line: "jubilee",
      stationid: "940GZZLUSWK",
      station: "Southwark Underground Station"
    },
    {
      line: "jubilee",
      stationid: "940GZZLUWHM",
      station: "West Ham Underground Station"
    },
    {
      line: "jubilee",
      stationid: "940GZZLUWHP",
      station: "West Hampstead Underground Station"
    },
    {
      line: "jubilee",
      stationid: "940GZZLUWIG",
      station: "Willesden Green Underground Station"
    },
    {
      line: "jubilee",
      stationid: "940GZZLUWLO",
      station: "Waterloo Underground Station"
    },
    {
      line: "jubilee",
      stationid: "940GZZLUWSM",
      station: "Westminster Underground Station"
    },
    {
      line: "jubilee",
      stationid: "940GZZLUWYP",
      station: "Wembley Park Underground Station"
    },
    {
      line: "victoria",
      stationid: "940GZZLUBLR",
      station: "Blackhorse Road Underground Station"
    },
    {
      line: "victoria",
      stationid: "940GZZLUBXN",
      station: "Brixton Underground Station"
    },
    {
      line: "victoria",
      stationid: "940GZZLUEUS",
      station: "Euston Underground Station"
    },
    {
      line: "victoria",
      stationid: "940GZZLUFPK",
      station: "Finsbury Park Underground Station"
    },
    {
      line: "victoria",
      stationid: "940GZZLUGPK",
      station: "Green Park Underground Station"
    },
    {
      line: "victoria",
      stationid: "940GZZLUHAI",
      station: "Highbury & Islington Underground Station"
    },
    {
      line: "victoria",
      stationid: "940GZZLUKSX",
      station: "King's Cross St. Pancras Underground Station"
    },
    {
      line: "victoria",
      stationid: "940GZZLUOXC",
      station: "Oxford Circus Underground Station"
    },
    {
      line: "victoria",
      stationid: "940GZZLUPCO",
      station: "Pimlico Underground Station"
    },
    {
      line: "victoria",
      stationid: "940GZZLUSKW",
      station: "Stockwell Underground Station"
    },
    {
      line: "victoria",
      stationid: "940GZZLUSVS",
      station: "Seven Sisters Underground Station"
    },
    {
      line: "victoria",
      stationid: "940GZZLUTMH",
      station: "Tottenham Hale Underground Station"
    },
    {
      line: "victoria",
      stationid: "940GZZLUVIC",
      station: "Victoria Underground Station"
    },
    {
      line: "victoria",
      stationid: "940GZZLUVXL",
      station: "Vauxhall Underground Station"
    },
    {
      line: "victoria",
      stationid: "940GZZLUWRR",
      station: "Warren Street Underground Station"
    },
    {
      line: "victoria",
      stationid: "940GZZLUWWL",
      station: "Walthamstow Central Underground Station"
    },
    {
      line: "bakerloo",
      stationid: "940GZZLUBST",
      station: "Baker Street Underground Station"
    },
    {
      line: "bakerloo",
      stationid: "940GZZLUCHX",
      station: "Charing Cross Underground Station"
    },
    {
      line: "bakerloo",
      stationid: "940GZZLUEAC",
      station: "Elephant & Castle Underground Station"
    },
    {
      line: "bakerloo",
      stationid: "940GZZLUEMB",
      station: "Embankment Underground Station"
    },
    {
      line: "bakerloo",
      stationid: "940GZZLUERB",
      station: "Edgware Road (Bakerloo) Underground Station"
    },
    {
      line: "bakerloo",
      stationid: "940GZZLUHAW",
      station: "Harrow & Wealdstone Underground Station"
    },
    {
      line: "bakerloo",
      stationid: "940GZZLUHSN",
      station: "Harlesden Underground Station"
    },
    {
      line: "bakerloo",
      stationid: "940GZZLUKEN",
      station: "Kenton Underground Station"
    },
    {
      line: "bakerloo",
      stationid: "940GZZLUKPK",
      station: "Kilburn Park Underground Station"
    },
    {
      line: "bakerloo",
      stationid: "940GZZLUKSL",
      station: "Kensal Green Underground Station"
    },
    {
      line: "bakerloo",
      stationid: "940GZZLULBN",
      station: "Lambeth North Underground Station"
    },
    {
      line: "bakerloo",
      stationid: "940GZZLUMVL",
      station: "Maida Vale Underground Station"
    },
    {
      line: "bakerloo",
      stationid: "940GZZLUMYB",
      station: "Marylebone Underground Station"
    },
    {
      line: "bakerloo",
      stationid: "940GZZLUNWY",
      station: "North Wembley Underground Station"
    },
    {
      line: "bakerloo",
      stationid: "940GZZLUOXC",
      station: "Oxford Circus Underground Station"
    },
    {
      line: "bakerloo",
      stationid: "940GZZLUPAC",
      station: "Paddington Underground Station"
    },
    {
      line: "bakerloo",
      stationid: "940GZZLUPCC",
      station: "Piccadilly Circus Underground Station"
    },
    {
      line: "bakerloo",
      stationid: "940GZZLUQPS",
      station: "Queen's Park Underground Station"
    },
    {
      line: "bakerloo",
      stationid: "940GZZLURGP",
      station: "Regent's Park Underground Station"
    },
    {
      line: "bakerloo",
      stationid: "940GZZLUSGP",
      station: "Stonebridge Park Underground Station"
    },
    {
      line: "bakerloo",
      stationid: "940GZZLUSKT",
      station: "South Kenton Underground Station"
    },
    {
      line: "bakerloo",
      stationid: "940GZZLUWJN",
      station: "Willesden Junction Underground Station"
    },
    {
      line: "bakerloo",
      stationid: "940GZZLUWKA",
      station: "Warwick Avenue Underground Station"
    },
    {
      line: "bakerloo",
      stationid: "940GZZLUWLO",
      station: "Waterloo Underground Station"
    },
    {
      line: "bakerloo",
      stationid: "940GZZLUWYC",
      station: "Wembley Central Underground Station"
    },
    {
      line: "hammersmith-city",
      stationid: "940GZZLUADE",
      station: "Aldgate East Underground Station"
    },
    {
      line: "hammersmith-city",
      stationid: "940GZZLUBBB",
      station: "Bromley-by-Bow Underground Station"
    },
    {
      line: "hammersmith-city",
      stationid: "940GZZLUBBN",
      station: "Barbican Underground Station"
    },
    {
      line: "hammersmith-city",
      stationid: "940GZZLUBKG",
      station: "Barking Underground Station"
    },
    {
      line: "hammersmith-city",
      stationid: "940GZZLUBST",
      station: "Baker Street Underground Station"
    },
    {
      line: "hammersmith-city",
      stationid: "940GZZLUBWR",
      station: "Bow Road Underground Station"
    },
    {
      line: "hammersmith-city",
      stationid: "940GZZLUEHM",
      station: "East Ham Underground Station"
    },
    {
      line: "hammersmith-city",
      stationid: "940GZZLUERC",
      station: "Edgware Road (Circle Line) Underground Station"
    },
    {
      line: "hammersmith-city",
      stationid: "940GZZLUESQ",
      station: "Euston Square Underground Station"
    },
    {
      line: "hammersmith-city",
      stationid: "940GZZLUFCN",
      station: "Farringdon Underground Station"
    },
    {
      line: "hammersmith-city",
      stationid: "940GZZLUGHK",
      station: "Goldhawk Road Underground Station"
    },
    {
      line: "hammersmith-city",
      stationid: "940GZZLUGPS",
      station: "Great Portland Street Underground Station"
    },
    {
      line: "hammersmith-city",
      stationid: "940GZZLUHSC",
      station: "Hammersmith (H&C Line) Underground Station"
    },
    {
      line: "hammersmith-city",
      stationid: "940GZZLUKSX",
      station: "King's Cross St. Pancras Underground Station"
    },
    {
      line: "hammersmith-city",
      stationid: "940GZZLULAD",
      station: "Ladbroke Grove Underground Station"
    },
    {
      line: "hammersmith-city",
      stationid: "940GZZLULRD",
      station: "Latimer Road Underground Station"
    },
    {
      line: "hammersmith-city",
      stationid: "940GZZLULVT",
      station: "Liverpool Street Underground Station"
    },
    {
      line: "hammersmith-city",
      stationid: "940GZZLUMED",
      station: "Mile End Underground Station"
    },
    {
      line: "hammersmith-city",
      stationid: "940GZZLUMGT",
      station: "Moorgate Underground Station"
    },
    {
      line: "hammersmith-city",
      stationid: "940GZZLUPAH",
      station: "Paddington (H&C Line)-Underground"
    },
    {
      line: "hammersmith-city",
      stationid: "940GZZLUPLW",
      station: "Plaistow Underground Station"
    },
    {
      line: "hammersmith-city",
      stationid: "940GZZLURYO",
      station: "Royal Oak Underground Station"
    },
    {
      line: "hammersmith-city",
      stationid: "940GZZLUSBM",
      station: "Shepherd's Bush Market Underground Station"
    },
    {
      line: "hammersmith-city",
      stationid: "940GZZLUSGN",
      station: "Stepney Green Underground Station"
    },
    {
      line: "hammersmith-city",
      stationid: "940GZZLUUPK",
      station: "Upton Park Underground Station"
    },
    {
      line: "hammersmith-city",
      stationid: "940GZZLUWHM",
      station: "West Ham Underground Station"
    },
    {
      line: "hammersmith-city",
      stationid: "940GZZLUWLA",
      station: "Wood Lane Underground Station"
    },
    {
      line: "hammersmith-city",
      stationid: "940GZZLUWPL",
      station: "Whitechapel Underground Station"
    },
    {
      line: "hammersmith-city",
      stationid: "940GZZLUWSP",
      station: "Westbourne Park Underground Station"
    },
    {
      line: "circle",
      stationid: "940GZZLUALD",
      station: "Aldgate Underground Station"
    },
    {
      line: "circle",
      stationid: "940GZZLUBBN",
      station: "Barbican Underground Station"
    },
    {
      line: "circle",
      stationid: "940GZZLUBKF",
      station: "Blackfriars Underground Station"
    },
    {
      line: "circle",
      stationid: "940GZZLUBST",
      station: "Baker Street Underground Station"
    },
    {
      line: "circle",
      stationid: "940GZZLUBWT",
      station: "Bayswater Underground Station"
    },
    {
      line: "circle",
      stationid: "940GZZLUCST",
      station: "Cannon Street Underground Station"
    },
    {
      line: "circle",
      stationid: "940GZZLUEMB",
      station: "Embankment Underground Station"
    },
    {
      line: "circle",
      stationid: "940GZZLUERC",
      station: "Edgware Road (Circle Line) Underground Station"
    },
    {
      line: "circle",
      stationid: "940GZZLUESQ",
      station: "Euston Square Underground Station"
    },
    {
      line: "circle",
      stationid: "940GZZLUFCN",
      station: "Farringdon Underground Station"
    },
    {
      line: "circle",
      stationid: "940GZZLUGHK",
      station: "Goldhawk Road Underground Station"
    },
    {
      line: "circle",
      stationid: "940GZZLUGPS",
      station: "Great Portland Street Underground Station"
    },
    {
      line: "circle",
      stationid: "940GZZLUGTR",
      station: "Gloucester Road Underground Station"
    },
    {
      line: "circle",
      stationid: "940GZZLUHSC",
      station: "Hammersmith (H&C Line) Underground Station"
    },
    {
      line: "circle",
      stationid: "940GZZLUHSK",
      station: "High Street Kensington Underground Station"
    },
    {
      line: "circle",
      stationid: "940GZZLUKSX",
      station: "King's Cross St. Pancras Underground Station"
    },
    {
      line: "circle",
      stationid: "940GZZLULAD",
      station: "Ladbroke Grove Underground Station"
    },
    {
      line: "circle",
      stationid: "940GZZLULRD",
      station: "Latimer Road Underground Station"
    },
    {
      line: "circle",
      stationid: "940GZZLULVT",
      station: "Liverpool Street Underground Station"
    },
    {
      line: "circle",
      stationid: "940GZZLUMGT",
      station: "Moorgate Underground Station"
    },
    {
      line: "circle",
      stationid: "940GZZLUMMT",
      station: "Monument Underground Station"
    },
    {
      line: "circle",
      stationid: "940GZZLUMSH",
      station: "Mansion House Underground Station"
    },
    {
      line: "circle",
      stationid: "940GZZLUNHG",
      station: "Notting Hill Gate Underground Station"
    },
    {
      line: "circle",
      stationid: "940GZZLUPAC",
      station: "Paddington Underground Station"
    },
    {
      line: "circle",
      stationid: "940GZZLUPAH",
      station: "Paddington (H&C Line)-Underground"
    },
    {
      line: "circle",
      stationid: "940GZZLURYO",
      station: "Royal Oak Underground Station"
    },
    {
      line: "circle",
      stationid: "940GZZLUSBM",
      station: "Shepherd's Bush Market Underground Station"
    },
    {
      line: "circle",
      stationid: "940GZZLUSJP",
      station: "St. James's Park Underground Station"
    },
    {
      line: "circle",
      stationid: "940GZZLUSKS",
      station: "South Kensington Underground Station"
    },
    {
      line: "circle",
      stationid: "940GZZLUSSQ",
      station: "Sloane Square Underground Station"
    },
    {
      line: "circle",
      stationid: "940GZZLUTMP",
      station: "Temple Underground Station"
    },
    {
      line: "circle",
      stationid: "940GZZLUTWH",
      station: "Tower Hill Underground Station"
    },
    {
      line: "circle",
      stationid: "940GZZLUVIC",
      station: "Victoria Underground Station"
    },
    {
      line: "circle",
      stationid: "940GZZLUWLA",
      station: "Wood Lane Underground Station"
    },
    {
      line: "circle",
      stationid: "940GZZLUWSM",
      station: "Westminster Underground Station"
    },
    {
      line: "circle",
      stationid: "940GZZLUWSP",
      station: "Westbourne Park Underground Station"
    },
    {
      line: "district",
      stationid: "940GZZLUACT",
      station: "Acton Town Underground Station"
    },
    {
      line: "district",
      stationid: "940GZZLUADE",
      station: "Aldgate East Underground Station"
    },
    {
      line: "district",
      stationid: "940GZZLUBBB",
      station: "Bromley-by-Bow Underground Station"
    },
    {
      line: "district",
      stationid: "940GZZLUBEC",
      station: "Becontree Underground Station"
    },
    {
      line: "district",
      stationid: "940GZZLUBKF",
      station: "Blackfriars Underground Station"
    },
    {
      line: "district",
      stationid: "940GZZLUBKG",
      station: "Barking Underground Station"
    },
    {
      line: "district",
      stationid: "940GZZLUBSC",
      station: "Barons Court Underground Station"
    },
    {
      line: "district",
      stationid: "940GZZLUBWR",
      station: "Bow Road Underground Station"
    },
    {
      line: "district",
      stationid: "940GZZLUBWT",
      station: "Bayswater Underground Station"
    },
    {
      line: "district",
      stationid: "940GZZLUCST",
      station: "Cannon Street Underground Station"
    },
    {
      line: "district",
      stationid: "940GZZLUCWP",
      station: "Chiswick Park Underground Station"
    },
    {
      line: "district",
      stationid: "940GZZLUDGE",
      station: "Dagenham East Underground Station"
    },
    {
      line: "district",
      stationid: "940GZZLUDGY",
      station: "Dagenham Heathway Underground Station"
    },
    {
      line: "district",
      stationid: "940GZZLUEBY",
      station: "Ealing Broadway Underground Station"
    },
    {
      line: "district",
      stationid: "940GZZLUECM",
      station: "Ealing Common Underground Station"
    },
    {
      line: "district",
      stationid: "940GZZLUECT",
      station: "Earl's Court Underground Station"
    },
    {
      line: "district",
      stationid: "940GZZLUEHM",
      station: "East Ham Underground Station"
    },
    {
      line: "district",
      stationid: "940GZZLUEMB",
      station: "Embankment Underground Station"
    },
    {
      line: "district",
      stationid: "940GZZLUEPK",
      station: "Elm Park Underground Station"
    },
    {
      line: "district",
      stationid: "940GZZLUEPY",
      station: "East Putney Underground Station"
    },
    {
      line: "district",
      stationid: "940GZZLUERC",
      station: "Edgware Road (Circle Line) Underground Station"
    },
    {
      line: "district",
      stationid: "940GZZLUFBY",
      station: "Fulham Broadway Underground Station"
    },
    {
      line: "district",
      stationid: "940GZZLUGBY",
      station: "Gunnersbury Underground Station"
    },
    {
      line: "district",
      stationid: "940GZZLUGTR",
      station: "Gloucester Road Underground Station"
    },
    {
      line: "district",
      stationid: "940GZZLUHCH",
      station: "Hornchurch Underground Station"
    },
    {
      line: "district",
      stationid: "940GZZLUHSD",
      station: "Hammersmith (Dist&Picc Line) Underground Station"
    },
    {
      line: "district",
      stationid: "940GZZLUHSK",
      station: "High Street Kensington Underground Station"
    },
    {
      line: "district",
      stationid: "940GZZLUKOY",
      station: "Kensington (Olympia) Underground Station"
    },
    {
      line: "district",
      stationid: "940GZZLUKWG",
      station: "Kew Gardens Underground Station"
    },
    {
      line: "district",
      stationid: "940GZZLUMED",
      station: "Mile End Underground Station"
    },
    {
      line: "district",
      stationid: "940GZZLUMMT",
      station: "Monument Underground Station"
    },
    {
      line: "district",
      stationid: "940GZZLUMSH",
      station: "Mansion House Underground Station"
    },
    {
      line: "district",
      stationid: "940GZZLUNHG",
      station: "Notting Hill Gate Underground Station"
    },
    {
      line: "district",
      stationid: "940GZZLUPAC",
      station: "Paddington Underground Station"
    },
    {
      line: "district",
      stationid: "940GZZLUPLW",
      station: "Plaistow Underground Station"
    },
    {
      line: "district",
      stationid: "940GZZLUPSG",
      station: "Parsons Green Underground Station"
    },
    {
      line: "district",
      stationid: "940GZZLUPYB",
      station: "Putney Bridge Underground Station"
    },
    {
      line: "district",
      stationid: "940GZZLURMD",
      station: "Richmond Underground Station"
    },
    {
      line: "district",
      stationid: "940GZZLURVP",
      station: "Ravenscourt Park Underground Station"
    },
    {
      line: "district",
      stationid: "940GZZLUSFB",
      station: "Stamford Brook Underground Station"
    },
    {
      line: "district",
      stationid: "940GZZLUSFS",
      station: "Southfields Underground Station"
    },
    {
      line: "district",
      stationid: "940GZZLUSGN",
      station: "Stepney Green Underground Station"
    },
    {
      line: "district",
      stationid: "940GZZLUSJP",
      station: "St. James's Park Underground Station"
    },
    {
      line: "district",
      stationid: "940GZZLUSKS",
      station: "South Kensington Underground Station"
    },
    {
      line: "district",
      stationid: "940GZZLUSSQ",
      station: "Sloane Square Underground Station"
    },
    {
      line: "district",
      stationid: "940GZZLUTMP",
      station: "Temple Underground Station"
    },
    {
      line: "district",
      stationid: "940GZZLUTNG",
      station: "Turnham Green Underground Station"
    },
    {
      line: "district",
      stationid: "940GZZLUTWH",
      station: "Tower Hill Underground Station"
    },
    {
      line: "district",
      stationid: "940GZZLUUPB",
      station: "Upminster Bridge Underground Station"
    },
    {
      line: "district",
      stationid: "940GZZLUUPK",
      station: "Upton Park Underground Station"
    },
    {
      line: "district",
      stationid: "940GZZLUUPM",
      station: "Upminster Underground Station"
    },
    {
      line: "district",
      stationid: "940GZZLUUPY",
      station: "Upney Underground Station"
    },
    {
      line: "district",
      stationid: "940GZZLUVIC",
      station: "Victoria Underground Station"
    },
    {
      line: "district",
      stationid: "940GZZLUWBN",
      station: "West Brompton Underground Station"
    },
    {
      line: "district",
      stationid: "940GZZLUWHM",
      station: "West Ham Underground Station"
    },
    {
      line: "district",
      stationid: "940GZZLUWIM",
      station: "Wimbledon Underground Station"
    },
    {
      line: "district",
      stationid: "940GZZLUWIP",
      station: "Wimbledon Park Underground Station"
    },
    {
      line: "district",
      stationid: "940GZZLUWKN",
      station: "West Kensington Underground Station"
    },
    {
      line: "district",
      stationid: "940GZZLUWPL",
      station: "Whitechapel Underground Station"
    },
    {
      line: "district",
      stationid: "940GZZLUWSM",
      station: "Westminster Underground Station"
    },
    {
      line: "piccadilly",
      stationid: "940GZZLUACT",
      station: "Acton Town Underground Station"
    },
    {
      line: "piccadilly",
      stationid: "940GZZLUALP",
      station: "Alperton Underground Station"
    },
    {
      line: "piccadilly",
      stationid: "940GZZLUASG",
      station: "Arnos Grove Underground Station"
    },
    {
      line: "piccadilly",
      stationid: "940GZZLUASL",
      station: "Arsenal Underground Station"
    },
    {
      line: "piccadilly",
      stationid: "940GZZLUBDS",
      station: "Bounds Green Underground Station"
    },
    {
      line: "piccadilly",
      stationid: "940GZZLUBOS",
      station: "Boston Manor Underground Station"
    },
    {
      line: "piccadilly",
      stationid: "940GZZLUBSC",
      station: "Barons Court Underground Station"
    },
    {
      line: "piccadilly",
      stationid: "940GZZLUCAR",
      station: "Caledonian Road Underground Station"
    },
    {
      line: "piccadilly",
      stationid: "940GZZLUCGN",
      station: "Covent Garden Underground Station"
    },
    {
      line: "piccadilly",
      stationid: "940GZZLUCKS",
      station: "Cockfosters Underground Station"
    },
    {
      line: "piccadilly",
      stationid: "940GZZLUEAE",
      station: "Eastcote Underground Station"
    },
    {
      line: "piccadilly",
      stationid: "940GZZLUECM",
      station: "Ealing Common Underground Station"
    },
    {
      line: "piccadilly",
      stationid: "940GZZLUECT",
      station: "Earl's Court Underground Station"
    },
    {
      line: "piccadilly",
      stationid: "940GZZLUFPK",
      station: "Finsbury Park Underground Station"
    },
    {
      line: "piccadilly",
      stationid: "940GZZLUGPK",
      station: "Green Park Underground Station"
    },
    {
      line: "piccadilly",
      stationid: "940GZZLUGTR",
      station: "Gloucester Road Underground Station"
    },
    {
      line: "piccadilly",
      stationid: "940GZZLUHBN",
      station: "Holborn Underground Station"
    },
    {
      line: "piccadilly",
      stationid: "940GZZLUHGD",
      station: "Hillingdon Underground Station"
    },
    {
      line: "piccadilly",
      stationid: "940GZZLUHNX",
      station: "Hatton Cross Underground Station"
    },
    {
      line: "piccadilly",
      stationid: "940GZZLUHPC",
      station: "Hyde Park Corner Underground Station"
    },
    {
      line: "piccadilly",
      stationid: "940GZZLUHR4",
      station: "Heathrow Terminal 4 Underground Station"
    },
    {
      line: "piccadilly",
      stationid: "940GZZLUHR5",
      station: "Heathrow Terminal 5 Underground Station"
    },
    {
      line: "piccadilly",
      stationid: "940GZZLUHRC",
      station: "Heathrow Terminals 2 & 3 Underground Station"
    },
    {
      line: "piccadilly",
      stationid: "940GZZLUHSD",
      station: "Hammersmith (Dist&Picc Line) Underground Station"
    },
    {
      line: "piccadilly",
      stationid: "940GZZLUHWC",
      station: "Hounslow Central Underground Station"
    },
    {
      line: "piccadilly",
      stationid: "940GZZLUHWE",
      station: "Hounslow East Underground Station"
    },
    {
      line: "piccadilly",
      stationid: "940GZZLUHWT",
      station: "Hounslow West Underground Station"
    },
    {
      line: "piccadilly",
      stationid: "940GZZLUHWY",
      station: "Holloway Road Underground Station"
    },
    {
      line: "piccadilly",
      stationid: "940GZZLUICK",
      station: "Ickenham Underground Station"
    },
    {
      line: "piccadilly",
      stationid: "940GZZLUKNB",
      station: "Knightsbridge Underground Station"
    },
    {
      line: "piccadilly",
      stationid: "940GZZLUKSX",
      station: "King's Cross St. Pancras Underground Station"
    },
    {
      line: "piccadilly",
      stationid: "940GZZLULSQ",
      station: "Leicester Square Underground Station"
    },
    {
      line: "piccadilly",
      stationid: "940GZZLUMRH",
      station: "Manor House Underground Station"
    },
    {
      line: "piccadilly",
      stationid: "940GZZLUNEN",
      station: "North Ealing Underground Station"
    },
    {
      line: "piccadilly",
      stationid: "940GZZLUNFD",
      station: "Northfields Underground Station"
    },
    {
      line: "piccadilly",
      stationid: "940GZZLUOAK",
      station: "Oakwood Underground Station"
    },
    {
      line: "piccadilly",
      stationid: "940GZZLUOSY",
      station: "Osterley Underground Station"
    },
    {
      line: "piccadilly",
      stationid: "940GZZLUPCC",
      station: "Piccadilly Circus Underground Station"
    },
    {
      line: "piccadilly",
      stationid: "940GZZLUPKR",
      station: "Park Royal Underground Station"
    },
    {
      line: "piccadilly",
      stationid: "940GZZLURSM",
      station: "Ruislip Manor Underground Station"
    },
    {
      line: "piccadilly",
      stationid: "940GZZLURSP",
      station: "Ruislip Underground Station"
    },
    {
      line: "piccadilly",
      stationid: "940GZZLURSQ",
      station: "Russell Square Underground Station"
    },
    {
      line: "piccadilly",
      stationid: "940GZZLURYL",
      station: "Rayners Lane Underground Station"
    },
    {
      line: "piccadilly",
      stationid: "940GZZLUSEA",
      station: "South Ealing Underground Station"
    },
    {
      line: "piccadilly",
      stationid: "940GZZLUSGT",
      station: "Southgate Underground Station"
    },
    {
      line: "piccadilly",
      stationid: "940GZZLUSHH",
      station: "South Harrow Underground Station"
    },
    {
      line: "piccadilly",
      stationid: "940GZZLUSKS",
      station: "South Kensington Underground Station"
    },
    {
      line: "piccadilly",
      stationid: "940GZZLUSUH",
      station: "Sudbury Hill Underground Station"
    },
    {
      line: "piccadilly",
      stationid: "940GZZLUSUT",
      station: "Sudbury Town Underground Station"
    },
    {
      line: "piccadilly",
      stationid: "940GZZLUTNG",
      station: "Turnham Green Underground Station"
    },
    {
      line: "piccadilly",
      stationid: "940GZZLUTPN",
      station: "Turnpike Lane Underground Station"
    },
    {
      line: "piccadilly",
      stationid: "940GZZLUUXB",
      station: "Uxbridge Underground Station"
    },
    {
      line: "piccadilly",
      stationid: "940GZZLUWOG",
      station: "Wood Green Underground Station"
    },
    {
      line: "northern",
      stationid: "940GZZLUACY",
      station: "Archway Underground Station"
    },
    {
      line: "northern",
      stationid: "940GZZLUAGL",
      station: "Angel Underground Station"
    },
    {
      line: "northern",
      stationid: "940GZZLUBLM",
      station: "Balham Underground Station"
    },
    {
      line: "northern",
      stationid: "940GZZLUBNK",
      station: "Bank Underground Station"
    },
    {
      line: "northern",
      stationid: "940GZZLUBOR",
      station: "Borough Underground Station"
    },
    {
      line: "northern",
      stationid: "940GZZLUBTK",
      station: "Burnt Oak Underground Station"
    },
    {
      line: "northern",
      stationid: "940GZZLUBTX",
      station: "Brent Cross Underground Station"
    },
    {
      line: "northern",
      stationid: "940GZZLUBZP",
      station: "Belsize Park Underground Station"
    },
    {
      line: "northern",
      stationid: "940GZZLUCFM",
      station: "Chalk Farm Underground Station"
    },
    {
      line: "northern",
      stationid: "940GZZLUCHX",
      station: "Charing Cross Underground Station"
    },
    {
      line: "northern",
      stationid: "940GZZLUCND",
      station: "Colindale Underground Station"
    },
    {
      line: "northern",
      stationid: "940GZZLUCPC",
      station: "Clapham Common Underground Station"
    },
    {
      line: "northern",
      stationid: "940GZZLUCPN",
      station: "Clapham North Underground Station"
    },
    {
      line: "northern",
      stationid: "940GZZLUCPS",
      station: "Clapham South Underground Station"
    },
    {
      line: "northern",
      stationid: "940GZZLUCSD",
      station: "Colliers Wood Underground Station"
    },
    {
      line: "northern",
      stationid: "940GZZLUCTN",
      station: "Camden Town Underground Station"
    },
    {
      line: "northern",
      stationid: "940GZZLUEAC",
      station: "Elephant & Castle Underground Station"
    },
    {
      line: "northern",
      stationid: "940GZZLUEFY",
      station: "East Finchley Underground Station"
    },
    {
      line: "northern",
      stationid: "940GZZLUEGW",
      station: "Edgware Underground Station"
    },
    {
      line: "northern",
      stationid: "940GZZLUEMB",
      station: "Embankment Underground Station"
    },
    {
      line: "northern",
      stationid: "940GZZLUEUS",
      station: "Euston Underground Station"
    },
    {
      line: "northern",
      stationid: "940GZZLUFYC",
      station: "Finchley Central Underground Station"
    },
    {
      line: "northern",
      stationid: "940GZZLUGDG",
      station: "Goodge Street Underground Station"
    },
    {
      line: "northern",
      stationid: "940GZZLUGGN",
      station: "Golders Green Underground Station"
    },
    {
      line: "northern",
      stationid: "940GZZLUHBT",
      station: "High Barnet Underground Station"
    },
    {
      line: "northern",
      stationid: "940GZZLUHCL",
      station: "Hendon Central Underground Station"
    },
    {
      line: "northern",
      stationid: "940GZZLUHGT",
      station: "Highgate Underground Station"
    },
    {
      line: "northern",
      stationid: "940GZZLUHTD",
      station: "Hampstead Underground Station"
    },
    {
      line: "northern",
      stationid: "940GZZLUKNG",
      station: "Kennington Underground Station"
    },
    {
      line: "northern",
      stationid: "940GZZLUKSH",
      station: "Kentish Town Underground Station"
    },
    {
      line: "northern",
      stationid: "940GZZLUKSX",
      station: "King's Cross St. Pancras Underground Station"
    },
    {
      line: "northern",
      stationid: "940GZZLULNB",
      station: "London Bridge Underground Station"
    },
    {
      line: "northern",
      stationid: "940GZZLULSQ",
      station: "Leicester Square Underground Station"
    },
    {
      line: "northern",
      stationid: "940GZZLUMDN",
      station: "Morden Underground Station"
    },
    {
      line: "northern",
      stationid: "940GZZLUMGT",
      station: "Moorgate Underground Station"
    },
    {
      line: "northern",
      stationid: "940GZZLUMHL",
      station: "Mill Hill East Underground Station"
    },
    {
      line: "northern",
      stationid: "940GZZLUMTC",
      station: "Mornington Crescent Underground Station"
    },
    {
      line: "northern",
      stationid: "940GZZLUODS",
      station: "Old Street Underground Station"
    },
    {
      line: "northern",
      stationid: "940GZZLUOVL",
      station: "Oval Underground Station"
    },
    {
      line: "northern",
      stationid: "940GZZLUSKW",
      station: "Stockwell Underground Station"
    },
    {
      line: "northern",
      stationid: "940GZZLUSWN",
      station: "South Wimbledon Underground Station"
    },
    {
      line: "northern",
      stationid: "940GZZLUTAW",
      station: "Totteridge & Whetstone Underground Station"
    },
    {
      line: "northern",
      stationid: "940GZZLUTBC",
      station: "Tooting Bec Underground Station"
    },
    {
      line: "northern",
      stationid: "940GZZLUTBY",
      station: "Tooting Broadway Underground Station"
    },
    {
      line: "northern",
      stationid: "940GZZLUTCR",
      station: "Tottenham Court Road Underground Station"
    },
    {
      line: "northern",
      stationid: "940GZZLUTFP",
      station: "Tufnell Park Underground Station"
    },
    {
      line: "northern",
      stationid: "940GZZLUWFN",
      station: "West Finchley Underground Station"
    },
    {
      line: "northern",
      stationid: "940GZZLUWLO",
      station: "Waterloo Underground Station"
    },
    {
      line: "northern",
      stationid: "940GZZLUWOP",
      station: "Woodside Park Underground Station"
    },
    {
      line: "northern",
      stationid: "940GZZLUWRR",
      station: "Warren Street Underground Station"
    }
  ];
  // Check Front of Train
  const towardsMapping = [
    {
      line: "metropolitan",
      origin: "Willesden Green Underground Station",
      towards: ["Baker Street"]
    },
    {
      line: "metropolitan",
      origin: "Finchley Road Underground Station",
      towards: ["Uxbridge", "Watford", "Baker Street", "Chesham"]
    },
    {
      line: "metropolitan",
      origin: "Farringdon Underground Station",
      towards: ["Check Front of Train"]
    },
    {
      line: "metropolitan",
      origin: "Euston Square Underground Station",
      towards: ["Check Front of Train"]
    },
    {
      line: "metropolitan",
      origin: "Barbican Underground Station",
      towards: ["Check Front of Train"]
    },
    {
      line: "metropolitan",
      origin: "Aldgate Underground Station",
      towards: ["Check Front of Train"]
    },
    {
      line: "metropolitan",
      origin: "Amersham Underground Station",
      towards: ["Amersham"]
    },
    {
      line: "circle",
      origin: "Monument Underground Station",
      towards: ["Edgware Road (Circle)", "Hammersmith"]
    },
    {
      line: "bakerloo",
      origin: "Maida Vale Underground Station",
      towards: [
        "Queen's Park",
        "Stonebridge Park",
        "Elephant and Castle",
        "Harrow and Wealdstone"
      ]
    },
    {
      line: "central",
      origin: "Leyton Underground Station",
      towards: [
        "Woodford Via Hainault",
        "Ealing Broadway",
        "West Ruislip",
        "Hainault via Newbury Park",
        "Newbury Park",
        "Loughton",
        "Epping"
      ]
    },
    {
      line: "district",
      origin: "Monument Underground Station",
      towards: [
        "Ealing Broadway",
        "Barking",
        "Wimbledon",
        "Upminster",
        "Check Front of Train",
        "Tower Hill",
        "Richmond"
      ]
    },
    {
      line: "jubilee",
      origin: "Canary Wharf Underground Station",
      towards: ["Wembley Park", "Willesden Green", "Stratford", "Stanmore"]
    },
    {
      line: "central",
      origin: "Debden Underground Station",
      towards: ["West Ruislip", "Epping"]
    },
    {
      line: "piccadilly",
      origin: "Rayners Lane Underground Station",
      towards: ["Rayners Lane", "Uxbridge", "Check Front of Train"]
    },
    {
      line: "circle",
      origin: "Gloucester Road Underground Station",
      towards: ["Edgware Road (Circle)", "Hammersmith"]
    },
    {
      line: "central",
      origin: "Tottenham Court Road Underground Station",
      towards: [
        "Woodford Via Hainault",
        "Ealing Broadway",
        "West Ruislip",
        "Hainault via Newbury Park",
        "Northolt",
        "Newbury Park",
        "Loughton",
        "White City",
        "Epping"
      ]
    },
    {
      line: "hammersmith-city",
      origin: "Hammersmith (H&C Line) Underground Station",
      towards: [
        "Barking",
        "Edgware Road (Circle)",
        "Hammersmith",
        "Check Front of Train"
      ]
    },
    {
      line: "northern",
      origin: "Kennington Underground Station",
      towards: [
        "High Barnet via CX",
        "Edgware via Bank",
        "Kennington via CX",
        "High Barnet via Bank",
        "Morden via Bank",
        "Edgware via CX"
      ]
    },
    {
      line: "circle",
      origin: "Westminster Underground Station",
      towards: ["Edgware Road (Circle)", "Hammersmith"]
    },
    {
      line: "hammersmith-city",
      origin: "West Ham Underground Station",
      towards: ["Barking", "Hammersmith"]
    },
    {
      line: "northern",
      origin: "Moorgate Underground Station",
      towards: ["Edgware via Bank", "High Barnet via Bank", "Morden via Bank"]
    },
    {
      line: "jubilee",
      origin: "Bond Street Underground Station",
      towards: ["Wembley Park", "Willesden Green", "Stratford", "Stanmore"]
    },
    {
      line: "metropolitan",
      origin: "Croxley Underground Station",
      towards: ["Watford", "Check Front of Train"]
    },
    {
      line: "northern",
      origin: "Oval Underground Station",
      towards: [
        "Morden via CX",
        "Edgware via Bank",
        "Morden via Bank",
        "High Barnet via Bank"
      ]
    },
    {
      line: "central",
      origin: "Roding Valley Underground Station",
      towards: ["Woodford Via Hainault"]
    },
    {
      line: "metropolitan",
      origin: "Chesham Underground Station",
      towards: ["Chesham", "Check Front of Train"]
    },
    {
      line: "jubilee",
      origin: "Neasden Underground Station",
      towards: ["Wembley Park", "Stratford", "Stanmore"]
    },
    {
      line: "central",
      origin: "Notting Hill Gate Underground Station",
      towards: [
        "Woodford Via Hainault",
        "Ealing Broadway",
        "West Ruislip",
        "Hainault via Newbury Park",
        "Northolt",
        "Newbury Park",
        "Loughton",
        "White City",
        "Epping"
      ]
    },
    {
      line: "circle",
      origin: "Euston Square Underground Station",
      towards: ["Edgware Road (Circle)"]
    },
    {
      line: "district",
      origin: "St. James's Park Underground Station",
      towards: [
        "Ealing Broadway",
        "Wimbledon",
        "Upminster",
        "Check Front of Train",
        "Richmond"
      ]
    },
    {
      line: "metropolitan",
      origin: "Hillingdon Underground Station",
      towards: ["Uxbridge", "Check Front of Train"]
    },
    {
      line: "northern",
      origin: "Edgware Underground Station",
      towards: [
        "Edgware via Bank",
        "Morden via Bank",
        "Kennington via CX",
        "Edgware via CX"
      ]
    },
    {
      line: "northern",
      origin: "Camden Town Underground Station",
      towards: [
        "High Barnet via CX",
        "Edgware via Bank",
        "High Barnet via Bank",
        "Morden via Bank",
        "Kennington via CX",
        "Edgware via CX"
      ]
    },
    {
      line: "central",
      origin: "Ealing Broadway Underground Station",
      towards: ["Ealing Broadway"]
    },
    {
      line: "central",
      origin: "Greenford Underground Station",
      towards: ["West Ruislip", "Northolt", "Woodford Via Hainault", "Epping"]
    },
    {
      line: "hammersmith-city",
      origin: "Whitechapel Underground Station",
      towards: ["Barking", "Hammersmith"]
    },
    {
      line: "northern",
      origin: "West Finchley Underground Station",
      towards: [
        "Kennington via CX",
        "High Barnet via CX",
        "Morden via Bank",
        "High Barnet via Bank"
      ]
    },
    {
      line: "metropolitan",
      origin: "Chalfont & Latimer Underground Station",
      towards: ["Aldgate", "Amersham", "Chesham", "Check Front of Train"]
    },
    {
      line: "hammersmith-city",
      origin: "Plaistow Underground Station",
      towards: ["Barking", "Hammersmith"]
    },
    {
      line: "northern",
      origin: "Tufnell Park Underground Station",
      towards: [
        "Kennington via CX",
        "High Barnet via CX",
        "Morden via Bank",
        "High Barnet via Bank"
      ]
    },
    {
      line: "jubilee",
      origin: "Kilburn Underground Station",
      towards: ["Wembley Park", "Willesden Green", "Stratford", "Stanmore"]
    },
    {
      line: "piccadilly",
      origin: "Eastcote Underground Station",
      towards: ["Uxbridge", "Check Front of Train"]
    },
    {
      line: "circle",
      origin: "High Street Kensington Underground Station",
      towards: ["Edgware Road (Circle)", "Hammersmith"]
    },
    {
      line: "circle",
      origin: "Barbican Underground Station",
      towards: ["Edgware Road (Circle)"]
    },
    {
      line: "metropolitan",
      origin: "Watford Underground Station",
      towards: ["Watford", "Check Front of Train"]
    },
    {
      line: "central",
      origin: "Leytonstone Underground Station",
      towards: [
        "Woodford Via Hainault",
        "Ealing Broadway",
        "West Ruislip",
        "Hainault via Newbury Park",
        "Newbury Park",
        "Loughton",
        "Epping"
      ]
    },
    {
      line: "jubilee",
      origin: "Kingsbury Underground Station",
      towards: ["Stratford", "Stanmore"]
    },
    {
      line: "district",
      origin: "Blackfriars Underground Station",
      towards: [
        "Ealing Broadway",
        "Barking",
        "Wimbledon",
        "Upminster",
        "Check Front of Train",
        "Richmond"
      ]
    },
    {
      line: "victoria",
      origin: "Vauxhall Underground Station",
      towards: ["Brixton", "Walthamstow Central"]
    },
    {
      line: "bakerloo",
      origin: "Waterloo Underground Station",
      towards: ["Queen's Park", "Elephant and Castle"]
    },
    {
      line: "bakerloo",
      origin: "Regent's Park Underground Station",
      towards: [
        "Harrow and Wealdstone",
        "Stonebridge Park",
        "Elephant and Castle",
        "Queen's Park"
      ]
    },
    {
      line: "metropolitan",
      origin: "Northwood Underground Station",
      towards: [
        "Aldgate",
        "Watford",
        "Amersham",
        "Chesham",
        "Check Front of Train"
      ]
    },
    {
      line: "piccadilly",
      origin: "Finsbury Park Underground Station",
      towards: [
        "Heathrow via T4 Loop",
        "Cockfosters",
        "Northfields",
        "Uxbridge",
        "Rayners Lane",
        "Arnos Grove",
        "Heathrow T123 + 5"
      ]
    },
    {
      line: "central",
      origin: "East Acton Underground Station",
      towards: [
        "Woodford Via Hainault",
        "Ealing Broadway",
        "West Ruislip",
        "Hainault via Newbury Park",
        "Northolt",
        "Newbury Park",
        "Epping"
      ]
    },
    {
      line: "bakerloo",
      origin: "Stonebridge Park Underground Station",
      towards: [
        "Harrow and Wealdstone",
        "Stonebridge Park",
        "Elephant and Castle"
      ]
    },
    {
      line: "bakerloo",
      origin: "Wembley Central Underground Station",
      towards: ["Harrow and Wealdstone", "Elephant and Castle"]
    },
    {
      line: "piccadilly",
      origin: "Boston Manor Underground Station",
      towards: [
        "Arnos Grove",
        "Heathrow T123 + 5",
        "Heathrow via T4 Loop",
        "Cockfosters"
      ]
    },
    {
      line: "central",
      origin: "Barkingside Underground Station",
      towards: ["Woodford Via Hainault", "Hainault via Newbury Park"]
    },
    {
      line: "metropolitan",
      origin: "Pinner Underground Station",
      towards: ["Watford", "Amersham", "Aldgate", "Check Front of Train"]
    },
    {
      line: "district",
      origin: "East Ham Underground Station",
      towards: [
        "Ealing Broadway",
        "Barking",
        "Wimbledon",
        "Upminster",
        "Richmond"
      ]
    },
    {
      line: "district",
      origin: "Parsons Green Underground Station",
      towards: ["Wimbledon", "Barking", "Edgware Road", "City (via Victoria)"]
    },
    {
      line: "piccadilly",
      origin: "Hounslow West Underground Station",
      towards: [
        "Arnos Grove",
        "Heathrow via T4 Loop",
        "Heathrow T123 + 5",
        "Cockfosters"
      ]
    },
    {
      line: "victoria",
      origin: "Tottenham Hale Underground Station",
      towards: ["Brixton", "Walthamstow Central"]
    },
    {
      line: "northern",
      origin: "Charing Cross Underground Station",
      towards: ["High Barnet via CX", "Kennington via CX", "Edgware via CX"]
    },
    {
      line: "northern",
      origin: "Clapham North Underground Station",
      towards: [
        "Morden via CX",
        "Edgware via Bank",
        "High Barnet via Bank",
        "Morden via Bank"
      ]
    },
    {
      line: "metropolitan",
      origin: "North Harrow Underground Station",
      towards: [
        "Aldgate",
        "Watford",
        "Amersham",
        "Baker Street",
        "Check Front of Train"
      ]
    },
    {
      line: "victoria",
      origin: "Walthamstow Central Underground Station",
      towards: ["Brixton", "Walthamstow Central"]
    },
    {
      line: "metropolitan",
      origin: "Ruislip Underground Station",
      towards: ["Uxbridge", "Check Front of Train"]
    },
    {
      line: "central",
      origin: "Woodford Underground Station",
      towards: [
        "Woodford Via Hainault",
        "West Ruislip",
        "Loughton",
        "Woodford",
        "Epping"
      ]
    },
    {
      line: "metropolitan",
      origin: "Ickenham Underground Station",
      towards: ["Uxbridge", "Check Front of Train"]
    },
    {
      line: "northern",
      origin: "Hampstead Underground Station",
      towards: [
        "Edgware via Bank",
        "Morden via Bank",
        "Kennington via CX",
        "Edgware via CX"
      ]
    },
    {
      line: "piccadilly",
      origin: "Arsenal Underground Station",
      towards: [
        "Heathrow via T4 Loop",
        "Cockfosters",
        "Northfields",
        "Uxbridge",
        "Arnos Grove",
        "Rayners Lane",
        "Heathrow T123 + 5"
      ]
    },
    {
      line: "metropolitan",
      origin: "Harrow-on-the-Hill Underground Station",
      towards: [
        "Aldgate",
        "Watford",
        "Uxbridge",
        "Amersham",
        "Baker Street",
        "Chesham",
        "Check Front of Train"
      ]
    },
    {
      line: "piccadilly",
      origin: "Sudbury Hill Underground Station",
      towards: ["Rayners Lane", "Uxbridge", "Cockfosters", "Check Front of Train"]
    },
    {
      line: "piccadilly",
      origin: "Southgate Underground Station",
      towards: ["Uxbridge", "Rayners Lane", "Heathrow T123 + 5", "Cockfosters"]
    },
    {
      line: "piccadilly",
      origin: "Earl's Court Underground Station",
      towards: [
        "Heathrow via T4 Loop",
        "Cockfosters",
        "Northfields",
        "Uxbridge",
        "Arnos Grove",
        "Rayners Lane",
        "Heathrow T123 + 5"
      ]
    },
    {
      line: "northern",
      origin: "Colindale Underground Station",
      towards: [
        "Kennington via CX",
        "Edgware via Bank",
        "Morden via Bank",
        "Edgware via CX"
      ]
    },
    {
      line: "piccadilly",
      origin: "Acton Town Underground Station",
      towards: [
        "Heathrow via T4 Loop",
        "Cockfosters",
        "Northfields",
        "Uxbridge",
        "Arnos Grove",
        "Rayners Lane",
        "Heathrow T123 + 5",
        "Check Front of Train"
      ]
    },
    {
      line: "jubilee",
      origin: "West Hampstead Underground Station",
      towards: ["Wembley Park", "Willesden Green", "Stratford", "Stanmore"]
    },
    {
      line: "hammersmith-city",
      origin: "Stepney Green Underground Station",
      towards: ["Hammersmith"]
    },
    {
      line: "metropolitan",
      origin: "Ruislip Manor Underground Station",
      towards: ["Uxbridge", "Check Front of Train"]
    },
    {
      line: "northern",
      origin: "Angel Underground Station",
      towards: ["Edgware via Bank", "High Barnet via Bank", "Morden via Bank"]
    },
    {
      line: "jubilee",
      origin: "Southwark Underground Station",
      towards: ["Wembley Park", "Willesden Green", "Stratford", "Stanmore"]
    },
    {
      line: "northern",
      origin: "South Wimbledon Underground Station",
      towards: [
        "Morden via CX",
        "Edgware via Bank",
        "High Barnet via Bank",
        "Morden via Bank"
      ]
    },
    {
      line: "hammersmith-city",
      origin: "Ladbroke Grove Underground Station",
      towards: [
        "Barking",
        "Edgware Road (Circle)",
        "Hammersmith",
        "Check Front of Train"
      ]
    },
    {
      line: "bakerloo",
      origin: "Harlesden Underground Station",
      towards: [
        "Harrow and Wealdstone",
        "Stonebridge Park",
        "Elephant and Castle"
      ]
    },
    {
      line: "circle",
      origin: "South Kensington Underground Station",
      towards: ["Edgware Road (Circle)", "Hammersmith"]
    },
    {
      line: "piccadilly",
      origin: "Hounslow East Underground Station",
      towards: [
        "Arnos Grove",
        "Heathrow T123 + 5",
        "Heathrow via T4 Loop",
        "Cockfosters"
      ]
    },
    {
      line: "piccadilly",
      origin: "Oakwood Underground Station",
      towards: ["Uxbridge", "Heathrow T123 + 5", "Cockfosters"]
    },
    {
      line: "bakerloo",
      origin: "North Wembley Underground Station",
      towards: ["Harrow and Wealdstone", "Elephant and Castle"]
    },
    {
      line: "district",
      origin: "Ealing Broadway Underground Station",
      towards: ["Upminster", "Ealing Broadway", "Check Front of Train"]
    },
    {
      line: "piccadilly",
      origin: "Sudbury Town Underground Station",
      towards: ["Rayners Lane", "Uxbridge", "Cockfosters", "Check Front of Train"]
    },
    {
      line: "bakerloo",
      origin: "Baker Street Underground Station",
      towards: [
        "Queen's Park",
        "Stonebridge Park",
        "Elephant and Castle",
        "Harrow and Wealdstone"
      ]
    },
    {
      line: "hammersmith-city",
      origin: "Latimer Road Underground Station",
      towards: [
        "Barking",
        "Edgware Road (Circle)",
        "Hammersmith",
        "Check Front of Train"
      ]
    },
    {
      line: "district",
      origin: "Ealing Common Underground Station",
      towards: ["Ealing Broadway"]
    },
    {
      line: "circle",
      origin: "Farringdon Underground Station",
      towards: ["Edgware Road (Circle)"]
    },
    {
      line: "bakerloo",
      origin: "Kensal Green Underground Station",
      towards: [
        "Harrow and Wealdstone",
        "Stonebridge Park",
        "Elephant and Castle"
      ]
    },
    {
      line: "district",
      origin: "Aldgate East Underground Station",
      towards: [
        "Ealing Broadway",
        "Barking",
        "Wimbledon",
        "Upminster",
        "Richmond"
      ]
    },
    {
      line: "piccadilly",
      origin: "Manor House Underground Station",
      towards: [
        "Heathrow via T4 Loop",
        "Cockfosters",
        "Northfields",
        "Uxbridge",
        "Arnos Grove",
        "Rayners Lane",
        "Heathrow T123 + 5"
      ]
    },
    {
      line: "piccadilly",
      origin: "Arnos Grove Underground Station",
      towards: [
        "Heathrow via T4 Loop",
        "Cockfosters",
        "Northfields",
        "Uxbridge",
        "Rayners Lane",
        "Arnos Grove",
        "Heathrow T123 + 5"
      ]
    },
    {
      line: "victoria",
      origin: "Pimlico Underground Station",
      towards: ["Brixton", "Walthamstow Central"]
    },
    {
      line: "northern",
      origin: "Waterloo Underground Station",
      towards: ["High Barnet via CX", "Kennington via CX", "Edgware via CX"]
    },
    {
      line: "district",
      origin: "Edgware Road (Circle Line) Underground Station",
      towards: ["Wimbledon", "Edgware Road"]
    },
    {
      line: "hammersmith-city",
      origin: "Paddington (H&C Line)-Underground",
      towards: ["Barking", "Hammersmith"]
    },
    {
      line: "northern",
      origin: "High Barnet Underground Station",
      towards: [
        "High Barnet via Bank",
        "High Barnet via CX",
        "Kennington via CX",
        "Morden via Bank"
      ]
    },
    {
      line: "central",
      origin: "South Woodford Underground Station",
      towards: ["West Ruislip", "Loughton", "Epping"]
    },
    {
      line: "central",
      origin: "St. Paul's Underground Station",
      towards: [
        "Woodford Via Hainault",
        "Ealing Broadway",
        "West Ruislip",
        "Hainault via Newbury Park",
        "Northolt",
        "Newbury Park",
        "Loughton",
        "White City",
        "Epping"
      ]
    },
    {
      line: "hammersmith-city",
      origin: "Wood Lane Underground Station",
      towards: [
        "Barking",
        "Edgware Road (Circle)",
        "Hammersmith",
        "Check Front of Train"
      ]
    },
    {
      line: "victoria",
      origin: "Euston Underground Station",
      towards: ["Brixton", "Walthamstow Central"]
    },
    {
      line: "circle",
      origin: "Moorgate Underground Station",
      towards: ["Edgware Road (Circle)"]
    },
    {
      line: "northern",
      origin: "Highgate Underground Station",
      towards: [
        "High Barnet via Bank",
        "Morden via Bank",
        "High Barnet via CX",
        "Kennington via CX"
      ]
    },
    {
      line: "piccadilly",
      origin: "Park Royal Underground Station",
      towards: ["Rayners Lane", "Uxbridge", "Cockfosters", "Check Front of Train"]
    },
    {
      line: "central",
      origin: "Wanstead Underground Station",
      towards: [
        "Woodford Via Hainault",
        "Ealing Broadway",
        "Hainault via Newbury Park",
        "Newbury Park",
        "White City"
      ]
    },
    {
      line: "central",
      origin: "Loughton Underground Station",
      towards: ["West Ruislip", "Loughton", "Epping"]
    },
    {
      line: "bakerloo",
      origin: "South Kenton Underground Station",
      towards: ["Harrow and Wealdstone", "Elephant and Castle"]
    },
    {
      line: "jubilee",
      origin: "Green Park Underground Station",
      towards: ["Wembley Park", "Willesden Green", "Stratford", "Stanmore"]
    },
    {
      line: "central",
      origin: "Holborn Underground Station",
      towards: [
        "Woodford Via Hainault",
        "Ealing Broadway",
        "West Ruislip",
        "Hainault via Newbury Park",
        "Northolt",
        "Newbury Park",
        "Loughton",
        "White City",
        "Epping"
      ]
    },
    {
      line: "piccadilly",
      origin: "South Kensington Underground Station",
      towards: [
        "Heathrow via T4 Loop",
        "Cockfosters",
        "Northfields",
        "Uxbridge",
        "Arnos Grove",
        "Rayners Lane",
        "Heathrow T123 + 5"
      ]
    },
    {
      line: "central",
      origin: "West Acton Underground Station",
      towards: ["Hainault via Newbury Park", "Ealing Broadway"]
    },
    {
      line: "central",
      origin: "Fairlop Underground Station",
      towards: ["Woodford Via Hainault", "Hainault via Newbury Park"]
    },
    {
      line: "piccadilly",
      origin: "Osterley Underground Station",
      towards: [
        "Arnos Grove",
        "Heathrow via T4 Loop",
        "Heathrow T123 + 5",
        "Cockfosters"
      ]
    },
    {
      line: "piccadilly",
      origin: "Knightsbridge Underground Station",
      towards: [
        "Heathrow via T4 Loop",
        "Cockfosters",
        "Northfields",
        "Uxbridge",
        "Rayners Lane",
        "Arnos Grove",
        "Heathrow T123 + 5"
      ]
    },
    {
      line: "piccadilly",
      origin: "South Ealing Underground Station",
      towards: [
        "Heathrow via T4 Loop",
        "Cockfosters",
        "Northfields",
        "Arnos Grove",
        "Heathrow T123 + 5"
      ]
    },
    {
      line: "central",
      origin: "North Acton Underground Station",
      towards: [
        "Woodford Via Hainault",
        "Ealing Broadway",
        "West Ruislip",
        "Hainault via Newbury Park",
        "Northolt",
        "Epping"
      ]
    },
    {
      line: "district",
      origin: "Tower Hill Underground Station",
      towards: [
        "Ealing Broadway",
        "Barking",
        "Wimbledon",
        "Upminster",
        "Tower Hill",
        "Richmond"
      ]
    },
    {
      line: "bakerloo",
      origin: "Warwick Avenue Underground Station",
      towards: [
        "Queen's Park",
        "Stonebridge Park",
        "Elephant and Castle",
        "Harrow and Wealdstone"
      ]
    },
    {
      line: "piccadilly",
      origin: "Caledonian Road Underground Station",
      towards: [
        "Heathrow via T4 Loop",
        "Cockfosters",
        "Northfields",
        "Uxbridge",
        "Rayners Lane",
        "Arnos Grove",
        "Heathrow T123 + 5"
      ]
    },
    {
      line: "hammersmith-city",
      origin: "Bromley-by-Bow Underground Station",
      towards: ["Barking", "Hammersmith"]
    },
    {
      line: "jubilee",
      origin: "Stratford Underground Station",
      towards: ["Stratford"]
    },
    {
      line: "central",
      origin: "Shepherd's Bush (Central) Underground Station",
      towards: [
        "Woodford Via Hainault",
        "Ealing Broadway",
        "West Ruislip",
        "Hainault via Newbury Park",
        "Northolt",
        "Newbury Park",
        "Loughton",
        "White City",
        "Epping"
      ]
    },
    {
      line: "central",
      origin: "Epping Underground Station",
      towards: ["West Ruislip", "Epping"]
    },
    {
      line: "piccadilly",
      origin: "North Ealing Underground Station",
      towards: ["Rayners Lane", "Uxbridge", "Cockfosters", "Check Front of Train"]
    },
    {
      line: "district",
      origin: "Barons Court Underground Station",
      towards: ["Upminster", "Ealing Broadway", "Richmond"]
    },
    {
      line: "central",
      origin: "Chancery Lane Underground Station",
      towards: [
        "Woodford Via Hainault",
        "Ealing Broadway",
        "West Ruislip",
        "Northolt",
        "Hainault via Newbury Park",
        "Newbury Park",
        "Loughton",
        "White City",
        "Epping"
      ]
    },
    {
      line: "central",
      origin: "Newbury Park Underground Station",
      towards: [
        "Hainault via Newbury Park",
        "Woodford Via Hainault",
        "Ealing Broadway",
        "Newbury Park"
      ]
    },
    {
      line: "district",
      origin: "Bromley-by-Bow Underground Station",
      towards: [
        "Ealing Broadway",
        "Barking",
        "Wimbledon",
        "Upminster",
        "Richmond"
      ]
    },
    {
      line: "bakerloo",
      origin: "Piccadilly Circus Underground Station",
      towards: ["Harrow and Wealdstone", "Elephant and Castle", "Queen's Park"]
    },
    {
      line: "district",
      origin: "Elm Park Underground Station",
      towards: ["Upminster", "Ealing Broadway", "Richmond"]
    },
    {
      line: "circle",
      origin: "Aldgate Underground Station",
      towards: ["Edgware Road (Circle)", "Hammersmith"]
    },
    {
      line: "bakerloo",
      origin: "Kilburn Park Underground Station",
      towards: [
        "Queen's Park",
        "Stonebridge Park",
        "Elephant and Castle",
        "Harrow and Wealdstone"
      ]
    },
    {
      line: "central",
      origin: "Redbridge Underground Station",
      towards: [
        "Woodford Via Hainault",
        "Ealing Broadway",
        "Hainault via Newbury Park",
        "Newbury Park",
        "White City"
      ]
    },
    {
      line: "northern",
      origin: "Burnt Oak Underground Station",
      towards: [
        "Edgware via Bank",
        "Morden via Bank",
        "Kennington via CX",
        "Edgware via CX"
      ]
    },
    {
      line: "circle",
      origin: "Great Portland Street Underground Station",
      towards: ["Edgware Road (Circle)"]
    },
    {
      line: "victoria",
      origin: "Highbury & Islington Underground Station",
      towards: ["Brixton", "Walthamstow Central"]
    },
    {
      line: "piccadilly",
      origin: "Turnham Green Underground Station",
      towards: [
        "Heathrow via T4 Loop",
        "Cockfosters",
        "Northfields",
        "Uxbridge",
        "Arnos Grove",
        "Rayners Lane",
        "Heathrow T123 + 5"
      ]
    },
    {
      line: "waterloo-city",
      origin: "Waterloo Underground Station",
      towards: ["Waterloo"]
    },
    {
      line: "northern",
      origin: "Clapham Common Underground Station",
      towards: [
        "Morden via CX",
        "Edgware via Bank",
        "High Barnet via Bank",
        "Morden via Bank"
      ]
    },
    {
      line: "northern",
      origin: "Embankment Underground Station",
      towards: ["High Barnet via CX", "Kennington via CX"]
    },
    {
      line: "district",
      origin: "Hammersmith (Dist&Picc Line) Underground Station",
      towards: [
        "Upminster",
        "Ealing Broadway",
        "Richmond",
        "Check Front of Train"
      ]
    },
    {
      line: "central",
      origin: "West Ruislip Underground Station",
      towards: ["West Ruislip", "Epping"]
    },
    {
      line: "northern",
      origin: "Golders Green Underground Station",
      towards: [
        "Edgware via Bank",
        "Morden via Bank",
        "Kennington via CX",
        "Edgware via CX"
      ]
    },
    {
      line: "victoria",
      origin: "Blackhorse Road Underground Station",
      towards: ["Walthamstow Central"]
    },
    {
      line: "northern",
      origin: "Elephant & Castle Underground Station",
      towards: ["Edgware via Bank", "High Barnet via Bank", "Morden via Bank"]
    },
    {
      line: "metropolitan",
      origin: "Moorgate Underground Station",
      towards: ["Aldgate", "Amersham", "Check Front of Train"]
    },
    {
      line: "northern",
      origin: "King's Cross St. Pancras Underground Station",
      towards: ["Edgware via Bank", "High Barnet via Bank", "Morden via Bank"]
    },
    {
      line: "district",
      origin: "Southfields Underground Station",
      towards: ["Wimbledon", "Edgware Road", "City (via Victoria)"]
    },
    {
      line: "district",
      origin: "Kew Gardens Underground Station",
      towards: ["Richmond", "Check Front of Train"]
    },
    {
      line: "piccadilly",
      origin: "Heathrow Terminals 2 & 3 Underground Station",
      towards: [
        "Arnos Grove",
        "Heathrow T123 + 5",
        "Heathrow via T4 Loop",
        "Cockfosters"
      ]
    },
    {
      line: "northern",
      origin: "East Finchley Underground Station",
      towards: [
        "High Barnet via Bank",
        "Morden via Bank",
        "High Barnet via CX",
        "Kennington via CX"
      ]
    },
    {
      line: "central",
      origin: "Snaresbrook Underground Station",
      towards: ["West Ruislip", "Loughton", "Epping"]
    },
    {
      line: "northern",
      origin: "Warren Street Underground Station",
      towards: ["High Barnet via CX", "Kennington via CX", "Edgware via CX"]
    },
    {
      line: "bakerloo",
      origin: "Lambeth North Underground Station",
      towards: ["Queen's Park", "Elephant and Castle"]
    },
    {
      line: "jubilee",
      origin: "St. John's Wood Underground Station",
      towards: ["Wembley Park", "Willesden Green", "Stratford", "Stanmore"]
    },
    {
      line: "northern",
      origin: "Goodge Street Underground Station",
      towards: ["High Barnet via CX", "Kennington via CX", "Edgware via CX"]
    },
    {
      line: "district",
      origin: "Ravenscourt Park Underground Station",
      towards: [
        "Upminster",
        "Ealing Broadway",
        "Richmond",
        "Check Front of Train"
      ]
    },
    {
      line: "northern",
      origin: "Finchley Central Underground Station",
      towards: [
        "Mill Hill East via CX",
        "High Barnet via CX",
        "Morden via Bank",
        "High Barnet via Bank",
        "Kennington via CX"
      ]
    },
    {
      line: "central",
      origin: "Ruislip Gardens Underground Station",
      towards: ["West Ruislip"]
    },
    {
      line: "piccadilly",
      origin: "Ruislip Underground Station",
      towards: ["Uxbridge", "Check Front of Train"]
    },
    {
      line: "district",
      origin: "Embankment Underground Station",
      towards: [
        "Ealing Broadway",
        "Barking",
        "Wimbledon",
        "Upminster",
        "Check Front of Train",
        "Richmond"
      ]
    },
    {
      line: "piccadilly",
      origin: "Covent Garden Underground Station",
      towards: [
        "Heathrow via T4 Loop",
        "Cockfosters",
        "Northfields",
        "Uxbridge",
        "Arnos Grove",
        "Rayners Lane",
        "Heathrow T123 + 5"
      ]
    },
    {
      line: "bakerloo",
      origin: "Marylebone Underground Station",
      towards: [
        "Queen's Park",
        "Stonebridge Park",
        "Elephant and Castle",
        "Harrow and Wealdstone"
      ]
    },
    {
      line: "piccadilly",
      origin: "Heathrow Terminal 4 Underground Station",
      towards: ["Arnos Grove", "Heathrow via T4 Loop", "Cockfosters"]
    },
    {
      line: "bakerloo",
      origin: "Embankment Underground Station",
      towards: ["Queen's Park", "Elephant and Castle"]
    },
    {
      line: "circle",
      origin: "Sloane Square Underground Station",
      towards: ["Edgware Road (Circle)", "Hammersmith"]
    },
    {
      line: "bakerloo",
      origin: "Harrow & Wealdstone Underground Station",
      towards: ["Harrow and Wealdstone", "Elephant and Castle"]
    },
    {
      line: "district",
      origin: "Gloucester Road Underground Station",
      towards: [
        "Ealing Broadway",
        "Wimbledon",
        "Upminster",
        "Check Front of Train",
        "Richmond"
      ]
    },
    {
      line: "northern",
      origin: "Euston Underground Station",
      towards: [
        "High Barnet via CX",
        "Edgware via Bank",
        "High Barnet via Bank",
        "Kennington via CX",
        "Morden via Bank",
        "Edgware via CX"
      ]
    },
    {
      line: "district",
      origin: "Stamford Brook Underground Station",
      towards: [
        "Upminster",
        "Ealing Broadway",
        "Richmond",
        "Check Front of Train"
      ]
    },
    {
      line: "metropolitan",
      origin: "Northwood Hills Underground Station",
      towards: [
        "Aldgate",
        "Watford",
        "Amersham",
        "Chesham",
        "Check Front of Train"
      ]
    },
    {
      line: "northern",
      origin: "Archway Underground Station",
      towards: [
        "Kennington via CX",
        "High Barnet via Bank",
        "High Barnet via CX",
        "Morden via Bank"
      ]
    },
    {
      line: "piccadilly",
      origin: "Ealing Common Underground Station",
      towards: ["Rayners Lane", "Uxbridge", "Cockfosters", "Check Front of Train"]
    },
    {
      line: "circle",
      origin: "Mansion House Underground Station",
      towards: ["Edgware Road (Circle)", "Hammersmith"]
    },
    {
      line: "circle",
      origin: "Blackfriars Underground Station",
      towards: ["Edgware Road (Circle)", "Hammersmith"]
    },
    {
      line: "piccadilly",
      origin: "Bounds Green Underground Station",
      towards: [
        "Heathrow via T4 Loop",
        "Cockfosters",
        "Northfields",
        "Uxbridge",
        "Arnos Grove",
        "Rayners Lane",
        "Heathrow T123 + 5"
      ]
    },
    {
      line: "circle",
      origin: "Victoria Underground Station",
      towards: ["Edgware Road (Circle)", "Hammersmith"]
    },
    {
      line: "central",
      origin: "Hainault Underground Station",
      towards: [
        "Hainault",
        "Woodford Via Hainault",
        "White City",
        "Hainault via Newbury Park"
      ]
    },
    {
      line: "hammersmith-city",
      origin: "Shepherd's Bush Market Underground Station",
      towards: [
        "Barking",
        "Edgware Road (Circle)",
        "Hammersmith",
        "Check Front of Train"
      ]
    },
    {
      line: "circle",
      origin: "Temple Underground Station",
      towards: ["Edgware Road (Circle)", "Hammersmith"]
    },
    {
      line: "victoria",
      origin: "Oxford Circus Underground Station",
      towards: ["Brixton", "Walthamstow Central"]
    },
    {
      line: "piccadilly",
      origin: "Ickenham Underground Station",
      towards: ["Uxbridge"]
    },
    {
      line: "district",
      origin: "Plaistow Underground Station",
      towards: [
        "Ealing Broadway",
        "Barking",
        "Wimbledon",
        "Upminster",
        "Richmond"
      ]
    },
    {
      line: "jubilee",
      origin: "Queensbury Underground Station",
      towards: ["Stratford", "Stanmore"]
    },
    {
      line: "metropolitan",
      origin: "Northwick Park Underground Station",
      towards: ["Watford", "Uxbridge", "Amersham"]
    },
    {
      line: "northern",
      origin: "Totteridge & Whetstone Underground Station",
      towards: [
        "High Barnet via CX",
        "High Barnet via Bank",
        "Morden via Bank",
        "Kennington via CX"
      ]
    },
    {
      line: "district",
      origin: "Stepney Green Underground Station",
      towards: ["Wimbledon", "Ealing Broadway", "Richmond"]
    },
    {
      line: "bakerloo",
      origin: "Willesden Junction Underground Station",
      towards: [
        "Harrow and Wealdstone",
        "Stonebridge Park",
        "Elephant and Castle"
      ]
    },
    {
      line: "piccadilly",
      origin: "Hatton Cross Underground Station",
      towards: [
        "Arnos Grove",
        "Heathrow via T4 Loop",
        "Heathrow T123 + 5",
        "Cockfosters"
      ]
    },
    {
      line: "piccadilly",
      origin: "Heathrow Terminal 5 Underground Station",
      towards: ["Cockfosters"]
    },
    {
      line: "metropolitan",
      origin: "Rayners Lane Underground Station",
      towards: ["Uxbridge", "Check Front of Train"]
    },
    {
      line: "northern",
      origin: "Leicester Square Underground Station",
      towards: ["High Barnet via CX", "Kennington via CX", "Edgware via CX"]
    },
    {
      line: "piccadilly",
      origin: "Hillingdon Underground Station",
      towards: ["Uxbridge"]
    },
    {
      line: "circle",
      origin: "Cannon Street Underground Station",
      towards: ["Edgware Road (Circle)", "Hammersmith"]
    },
    {
      line: "central",
      origin: "Bethnal Green Underground Station",
      towards: [
        "Woodford Via Hainault",
        "Ealing Broadway",
        "West Ruislip",
        "Hainault via Newbury Park",
        "Northolt",
        "Loughton",
        "Epping"
      ]
    },
    {
      line: "northern",
      origin: "Mornington Crescent Underground Station",
      towards: ["High Barnet via CX", "Kennington via CX", "Edgware via CX"]
    },
    {
      line: "northern",
      origin: "Clapham South Underground Station",
      towards: [
        "Morden via CX",
        "Edgware via Bank",
        "High Barnet via Bank",
        "Morden via Bank"
      ]
    },
    {
      line: "central",
      origin: "Northolt Underground Station",
      towards: ["West Ruislip", "Northolt", "Woodford Via Hainault"]
    },
    {
      line: "bakerloo",
      origin: "Edgware Road (Bakerloo) Underground Station",
      towards: [
        "Harrow and Wealdstone",
        "Stonebridge Park",
        "Elephant and Castle",
        "Queen's Park"
      ]
    },
    {
      line: "northern",
      origin: "Hendon Central Underground Station",
      towards: [
        "Kennington via CX",
        "Edgware via Bank",
        "Morden via Bank",
        "Edgware via CX"
      ]
    },
    {
      line: "jubilee",
      origin: "Swiss Cottage Underground Station",
      towards: ["Wembley Park", "Willesden Green", "Stratford", "Stanmore"]
    },
    {
      line: "northern",
      origin: "Belsize Park Underground Station",
      towards: [
        "Kennington via CX",
        "Edgware via Bank",
        "Morden via Bank",
        "Edgware via CX"
      ]
    },
    {
      line: "district",
      origin: "Upminster Bridge Underground Station",
      towards: ["Upminster", "Ealing Broadway", "Richmond"]
    },
    {
      line: "district",
      origin: "East Putney Underground Station",
      towards: ["Wimbledon", "Edgware Road", "City (via Victoria)"]
    },
    {
      line: "bakerloo",
      origin: "Queen's Park Underground Station",
      towards: [
        "Queen's Park",
        "Stonebridge Park",
        "Elephant and Castle",
        "Harrow and Wealdstone"
      ]
    },
    {
      line: "central",
      origin: "Buckhurst Hill Underground Station",
      towards: ["West Ruislip", "Loughton", "Epping"]
    },
    {
      line: "central",
      origin: "Hanger Lane Underground Station",
      towards: ["West Ruislip", "Northolt", "Woodford Via Hainault", "Epping"]
    },
    {
      line: "central",
      origin: "Perivale Underground Station",
      towards: ["West Ruislip", "Northolt", "Woodford Via Hainault", "Epping"]
    },
    {
      line: "district",
      origin: "Turnham Green Underground Station",
      towards: [
        "Upminster",
        "Ealing Broadway",
        "Richmond",
        "Check Front of Train"
      ]
    },
    {
      line: "piccadilly",
      origin: "South Harrow Underground Station",
      towards: ["Rayners Lane", "Uxbridge", "Cockfosters", "Check Front of Train"]
    },
    {
      line: "metropolitan",
      origin: "Chorleywood Underground Station",
      towards: ["Aldgate", "Amersham", "Chesham", "Check Front of Train"]
    },
    {
      line: "jubilee",
      origin: "Bermondsey Underground Station",
      towards: ["Wembley Park", "Willesden Green", "Stratford", "Stanmore"]
    },
    {
      line: "district",
      origin: "Chiswick Park Underground Station",
      towards: ["Upminster", "Ealing Broadway"]
    },
    {
      line: "piccadilly",
      origin: "Piccadilly Circus Underground Station",
      towards: [
        "Heathrow via T4 Loop",
        "Cockfosters",
        "Northfields",
        "Uxbridge",
        "Arnos Grove",
        "Rayners Lane",
        "Heathrow T123 + 5"
      ]
    },
    {
      line: "circle",
      origin: "Tower Hill Underground Station",
      towards: ["Edgware Road (Circle)", "Hammersmith"]
    },
    {
      line: "central",
      origin: "Stratford Underground Station",
      towards: [
        "Woodford Via Hainault",
        "Ealing Broadway",
        "West Ruislip",
        "Hainault via Newbury Park",
        "Loughton",
        "Epping"
      ]
    },
    {
      line: "metropolitan",
      origin: "Eastcote Underground Station",
      towards: ["Uxbridge", "Check Front of Train"]
    },
    {
      line: "piccadilly",
      origin: "Barons Court Underground Station",
      towards: [
        "Heathrow via T4 Loop",
        "Cockfosters",
        "Northfields",
        "Uxbridge",
        "Arnos Grove",
        "Rayners Lane",
        "Heathrow T123 + 5"
      ]
    },
    {
      line: "district",
      origin: "Cannon Street Underground Station",
      towards: [
        "Ealing Broadway",
        "Barking",
        "Wimbledon",
        "Upminster",
        "Check Front of Train",
        "Tower Hill",
        "Richmond"
      ]
    },
    {
      line: "bakerloo",
      origin: "Oxford Circus Underground Station",
      towards: ["Harrow and Wealdstone", "Elephant and Castle", "Queen's Park"]
    },
    {
      line: "piccadilly",
      origin: "Northfields Underground Station",
      towards: [
        "Heathrow via T4 Loop",
        "Cockfosters",
        "Northfields",
        "Arnos Grove",
        "Heathrow T123 + 5"
      ]
    },
    {
      line: "northern",
      origin: "Stockwell Underground Station",
      towards: [
        "Morden via CX",
        "Edgware via Bank",
        "High Barnet via Bank",
        "Morden via Bank"
      ]
    },
    {
      line: "district",
      origin: "Mansion House Underground Station",
      towards: [
        "Ealing Broadway",
        "Barking",
        "Wimbledon",
        "Upminster",
        "Check Front of Train",
        "Tower Hill",
        "Richmond"
      ]
    },
    {
      line: "metropolitan",
      origin: "West Harrow Underground Station",
      towards: ["Uxbridge", "Check Front of Train"]
    },
    {
      line: "hammersmith-city",
      origin: "Westbourne Park Underground Station",
      towards: [
        "Barking",
        "Edgware Road (Circle)",
        "Hammersmith",
        "Check Front of Train"
      ]
    },
    {
      line: "jubilee",
      origin: "Canning Town Underground Station",
      towards: ["Wembley Park", "Stratford", "Stanmore"]
    },
    {
      line: "metropolitan",
      origin: "Moor Park Underground Station",
      towards: [
        "Aldgate",
        "Watford",
        "Amersham",
        "Chesham",
        "Check Front of Train"
      ]
    },
    {
      line: "piccadilly",
      origin: "Holloway Road Underground Station",
      towards: [
        "Heathrow via T4 Loop",
        "Cockfosters",
        "Northfields",
        "Uxbridge",
        "Arnos Grove",
        "Rayners Lane",
        "Heathrow T123 + 5"
      ]
    },
    {
      line: "district",
      origin: "Putney Bridge Underground Station",
      towards: ["Wimbledon", "Edgware Road", "City (via Victoria)"]
    },
    {
      line: "central",
      origin: "White City Underground Station",
      towards: [
        "Woodford Via Hainault",
        "Ealing Broadway",
        "West Ruislip",
        "Hainault via Newbury Park",
        "Northolt",
        "Newbury Park",
        "White City",
        "Epping"
      ]
    },
    {
      line: "jubilee",
      origin: "Canada Water Underground Station",
      towards: ["Wembley Park", "Willesden Green", "Stratford", "Stanmore"]
    },
    {
      line: "central",
      origin: "Gants Hill Underground Station",
      towards: [
        "Woodford Via Hainault",
        "Ealing Broadway",
        "Hainault via Newbury Park",
        "Newbury Park",
        "White City"
      ]
    },
    {
      line: "district",
      origin: "Sloane Square Underground Station",
      towards: [
        "Ealing Broadway",
        "Barking",
        "Wimbledon",
        "Upminster",
        "Check Front of Train",
        "Richmond"
      ]
    },
    {
      line: "jubilee",
      origin: "London Bridge Underground Station",
      towards: ["Wembley Park", "Willesden Green", "Stratford", "Stanmore"]
    },
    {
      line: "hammersmith-city",
      origin: "King's Cross St. Pancras Underground Station",
      towards: ["Barking", "Hammersmith"]
    },
    {
      line: "jubilee",
      origin: "Baker Street Underground Station",
      towards: ["Wembley Park", "Willesden Green", "Stratford", "Stanmore"]
    },
    {
      line: "circle",
      origin: "St. James's Park Underground Station",
      towards: ["Edgware Road (Circle)", "Hammersmith"]
    },
    {
      line: "district",
      origin: "Richmond Underground Station",
      towards: ["Richmond", "Check Front of Train"]
    },
    {
      line: "bakerloo",
      origin: "Charing Cross Underground Station",
      towards: ["Harrow and Wealdstone", "Elephant and Castle", "Queen's Park"]
    },
    {
      line: "district",
      origin: "Fulham Broadway Underground Station",
      towards: ["Wimbledon", "Barking", "Edgware Road", "City (via Victoria)"]
    },
    {
      line: "hammersmith-city",
      origin: "East Ham Underground Station",
      towards: ["Barking", "Hammersmith"]
    },
    {
      line: "hammersmith-city",
      origin: "Aldgate East Underground Station",
      towards: ["Barking", "Hammersmith"]
    },
    {
      line: "district",
      origin: "Acton Town Underground Station",
      towards: ["Ealing Broadway"]
    },
    {
      line: "piccadilly",
      origin: "Cockfosters Underground Station",
      towards: [
        "Heathrow via T4 Loop",
        "Cockfosters",
        "Uxbridge",
        "Rayners Lane",
        "Heathrow T123 + 5"
      ]
    },
    {
      line: "northern",
      origin: "Borough Underground Station",
      towards: ["Edgware via Bank", "High Barnet via Bank", "Morden via Bank"]
    },
    {
      line: "district",
      origin: "Temple Underground Station",
      towards: [
        "Ealing Broadway",
        "Barking",
        "Wimbledon",
        "Upminster",
        "Check Front of Train",
        "Richmond"
      ]
    },
    {
      line: "bakerloo",
      origin: "Kenton Underground Station",
      towards: ["Harrow and Wealdstone", "Elephant and Castle"]
    },
    {
      line: "central",
      origin: "Queensway Underground Station",
      towards: [
        "Woodford Via Hainault",
        "Ealing Broadway",
        "West Ruislip",
        "Hainault via Newbury Park",
        "Northolt",
        "Newbury Park",
        "Loughton",
        "White City",
        "Epping"
      ]
    },
    {
      line: "hammersmith-city",
      origin: "Barking Underground Station",
      towards: ["Barking"]
    },
    {
      line: "circle",
      origin: "Paddington (H&C Line)-Underground",
      towards: ["Edgware Road (Circle)"]
    },
    {
      line: "piccadilly",
      origin: "Green Park Underground Station",
      towards: [
        "Heathrow via T4 Loop",
        "Cockfosters",
        "Northfields",
        "Uxbridge",
        "Arnos Grove",
        "Rayners Lane",
        "Heathrow T123 + 5"
      ]
    },
    {
      line: "northern",
      origin: "Colliers Wood Underground Station",
      towards: [
        "Morden via CX",
        "Edgware via Bank",
        "Morden via Bank",
        "High Barnet via Bank"
      ]
    },
    {
      line: "jubilee",
      origin: "Stanmore Underground Station",
      towards: ["Stratford", "Stanmore"]
    },
    {
      line: "district",
      origin: "Dagenham East Underground Station",
      towards: ["Upminster", "Ealing Broadway", "Richmond"]
    },
    {
      line: "northern",
      origin: "Mill Hill East Underground Station",
      towards: ["Mill Hill East via CX"]
    },
    {
      line: "northern",
      origin: "Chalk Farm Underground Station",
      towards: [
        "Edgware via Bank",
        "Morden via Bank",
        "Kennington via CX",
        "Edgware via CX"
      ]
    },
    {
      line: "metropolitan",
      origin: "Rickmansworth Underground Station",
      towards: ["Aldgate", "Amersham", "Chesham", "Check Front of Train"]
    },
    {
      line: "northern",
      origin: "Morden Underground Station",
      towards: [
        "Morden via CX",
        "Edgware via Bank",
        "Morden via Bank",
        "High Barnet via Bank"
      ]
    },
    {
      line: "northern",
      origin: "Tooting Bec Underground Station",
      towards: [
        "Morden via CX",
        "Edgware via Bank",
        "High Barnet via Bank",
        "Morden via Bank"
      ]
    },
    {
      line: "central",
      origin: "Lancaster Gate Underground Station",
      towards: [
        "Woodford Via Hainault",
        "Ealing Broadway",
        "West Ruislip",
        "Hainault via Newbury Park",
        "Northolt",
        "Newbury Park",
        "Loughton",
        "White City",
        "Epping"
      ]
    },
    {
      line: "victoria",
      origin: "Victoria Underground Station",
      towards: ["Brixton", "Walthamstow Central"]
    },
    {
      line: "piccadilly",
      origin: "Ruislip Manor Underground Station",
      towards: ["Uxbridge", "Check Front of Train"]
    },
    {
      line: "victoria",
      origin: "Warren Street Underground Station",
      towards: ["Brixton", "Walthamstow Central"]
    },
    {
      line: "district",
      origin: "High Street Kensington Underground Station",
      towards: ["Edgware Road"]
    },
    {
      line: "victoria",
      origin: "Stockwell Underground Station",
      towards: ["Brixton", "Walthamstow Central"]
    },
    {
      line: "northern",
      origin: "London Bridge Underground Station",
      towards: ["Edgware via Bank", "Morden via Bank", "High Barnet via Bank"]
    },
    {
      line: "district",
      origin: "Barking Underground Station",
      towards: [
        "Ealing Broadway",
        "Barking",
        "Wimbledon",
        "Upminster",
        "Check Front of Train",
        "Richmond"
      ]
    },
    {
      line: "waterloo-city",
      origin: "Bank Underground Station",
      towards: ["Waterloo", "Bank"]
    },
    {
      line: "northern",
      origin: "Kentish Town Underground Station",
      towards: [
        "Kennington via CX",
        "Morden via Bank",
        "High Barnet via CX",
        "High Barnet via Bank"
      ]
    },
    {
      line: "circle",
      origin: "Edgware Road (Circle Line) Underground Station",
      towards: ["Edgware Road (Circle)"]
    },
    {
      line: "piccadilly",
      origin: "Russell Square Underground Station",
      towards: [
        "Heathrow via T4 Loop",
        "Cockfosters",
        "Northfields",
        "Uxbridge",
        "Arnos Grove",
        "Rayners Lane",
        "Heathrow T123 + 5"
      ]
    },
    {
      line: "jubilee",
      origin: "North Greenwich Underground Station",
      towards: ["Wembley Park", "Willesden Green", "Stratford", "Stanmore"]
    },
    {
      line: "jubilee",
      origin: "Wembley Park Underground Station",
      towards: ["Wembley Park", "Stratford", "Stanmore"]
    },
    {
      line: "central",
      origin: "Holland Park Underground Station",
      towards: [
        "Woodford Via Hainault",
        "Ealing Broadway",
        "West Ruislip",
        "Hainault via Newbury Park",
        "Northolt",
        "Newbury Park",
        "Loughton",
        "White City",
        "Epping"
      ]
    },
    {
      line: "victoria",
      origin: "Seven Sisters Underground Station",
      towards: ["Brixton", "Walthamstow Central"]
    },
    {
      line: "northern",
      origin: "Balham Underground Station",
      towards: [
        "Morden via CX",
        "Edgware via Bank",
        "High Barnet via Bank",
        "Morden via Bank"
      ]
    },
    {
      line: "northern",
      origin: "Bank Underground Station",
      towards: ["Edgware via Bank", "High Barnet via Bank", "Morden via Bank"]
    },
    {
      line: "hammersmith-city",
      origin: "Royal Oak Underground Station",
      towards: [
        "Barking",
        "Edgware Road (Circle)",
        "Hammersmith",
        "Check Front of Train"
      ]
    },
    {
      line: "district",
      origin: "Hornchurch Underground Station",
      towards: ["Upminster", "Ealing Broadway", "Richmond"]
    },
    {
      line: "central",
      origin: "Marble Arch Underground Station",
      towards: [
        "Woodford Via Hainault",
        "Ealing Broadway",
        "West Ruislip",
        "Northolt",
        "Hainault via Newbury Park",
        "Newbury Park",
        "Loughton",
        "White City",
        "Epping"
      ]
    },
    {
      line: "jubilee",
      origin: "Finchley Road Underground Station",
      towards: ["Wembley Park", "Willesden Green", "Stratford", "Stanmore"]
    },
    {
      line: "jubilee",
      origin: "Willesden Green Underground Station",
      towards: ["Wembley Park", "Willesden Green", "Stratford", "Stanmore"]
    },
    {
      line: "metropolitan",
      origin: "Uxbridge Underground Station",
      towards: ["Uxbridge", "Check Front of Train"]
    },
    {
      line: "northern",
      origin: "Old Street Underground Station",
      towards: ["Edgware via Bank", "High Barnet via Bank", "Morden via Bank"]
    },
    {
      line: "piccadilly",
      origin: "Hounslow Central Underground Station",
      towards: [
        "Arnos Grove",
        "Heathrow T123 + 5",
        "Heathrow via T4 Loop",
        "Cockfosters"
      ]
    },
    {
      line: "jubilee",
      origin: "Dollis Hill Underground Station",
      towards: ["Wembley Park", "Stratford", "Stanmore"]
    },
    {
      line: "district",
      origin: "Paddington Underground Station",
      towards: ["Wimbledon", "Edgware Road"]
    },
    {
      line: "victoria",
      origin: "Brixton Underground Station",
      towards: ["Brixton", "Walthamstow Central"]
    },
    {
      line: "central",
      origin: "Liverpool Street Underground Station",
      towards: [
        "Woodford Via Hainault",
        "Ealing Broadway",
        "West Ruislip",
        "Northolt",
        "Hainault via Newbury Park",
        "Newbury Park",
        "Loughton",
        "White City",
        "Epping"
      ]
    },
    {
      line: "district",
      origin: "Gunnersbury Underground Station",
      towards: ["Richmond", "Check Front of Train"]
    },
    {
      line: "bakerloo",
      origin: "Elephant & Castle Underground Station",
      towards: ["Queen's Park", "Elephant and Castle", "Harrow and Wealdstone"]
    },
    {
      line: "jubilee",
      origin: "Canons Park Underground Station",
      towards: ["Stratford", "Stanmore"]
    },
    {
      line: "central",
      origin: "Chigwell Underground Station",
      towards: ["Woodford Via Hainault"]
    },
    {
      line: "hammersmith-city",
      origin: "Goldhawk Road Underground Station",
      towards: [
        "Barking",
        "Edgware Road (Circle)",
        "Hammersmith",
        "Check Front of Train"
      ]
    },
    {
      line: "district",
      origin: "Earl's Court Underground Station",
      towards: [
        "Ealing Broadway",
        "Edgware Road",
        "City (via Victoria)",
        "Wimbledon",
        "Upminster",
        "Check Front of Train",
        "Richmond"
      ]
    },
    {
      line: "metropolitan",
      origin: "Great Portland Street Underground Station",
      towards: ["Aldgate", "Uxbridge", "Amersham"]
    },
    {
      line: "northern",
      origin: "Tooting Broadway Underground Station",
      towards: [
        "Morden via CX",
        "Edgware via Bank",
        "High Barnet via Bank",
        "Morden via Bank"
      ]
    },
    {
      line: "northern",
      origin: "Brent Cross Underground Station",
      towards: [
        "Edgware via Bank",
        "Morden via Bank",
        "Kennington via CX",
        "Edgware via CX"
      ]
    },
    {
      line: "central",
      origin: "Bank Underground Station",
      towards: [
        "Woodford Via Hainault",
        "Ealing Broadway",
        "West Ruislip",
        "Hainault via Newbury Park",
        "Northolt",
        "Newbury Park",
        "Loughton",
        "White City",
        "Epping"
      ]
    },
    {
      line: "central",
      origin: "South Ruislip Underground Station",
      towards: ["West Ruislip"]
    },
    {
      line: "central",
      origin: "Mile End Underground Station",
      towards: [
        "Woodford Via Hainault",
        "Ealing Broadway",
        "West Ruislip",
        "Hainault via Newbury Park",
        "Loughton",
        "Epping"
      ]
    },
    {
      line: "piccadilly",
      origin: "Alperton Underground Station",
      towards: ["Rayners Lane", "Uxbridge", "Cockfosters", "Check Front of Train"]
    },
    {
      line: "metropolitan",
      origin: "Liverpool Street Underground Station",
      towards: ["Aldgate"]
    },
    {
      line: "central",
      origin: "Bond Street Underground Station",
      towards: [
        "Woodford Via Hainault",
        "Ealing Broadway",
        "West Ruislip",
        "Northolt",
        "Hainault via Newbury Park",
        "Newbury Park",
        "Loughton",
        "White City",
        "Epping"
      ]
    },
    {
      line: "piccadilly",
      origin: "Hyde Park Corner Underground Station",
      towards: [
        "Heathrow via T4 Loop",
        "Cockfosters",
        "Northfields",
        "Uxbridge",
        "Rayners Lane",
        "Arnos Grove",
        "Heathrow T123 + 5"
      ]
    },
    {
      line: "hammersmith-city",
      origin: "Edgware Road (Circle Line) Underground Station",
      towards: ["Barking", "Hammersmith", "Edgware Road", "Check Front of Train"]
    },
    {
      line: "central",
      origin: "Grange Hill Underground Station",
      towards: ["Hainault", "Woodford Via Hainault"]
    }
  ];

const ablyAPIKey = '<YOUR-API-KEY>';
var realtime = new Ably.Realtime(ablyAPIKey);
const apiKey = '<YOUR-GOOGLE-API-KEY>';
let watchID = geolocation.watchPosition(locationSuccess, locationError);
let latitude, longitude, timeToArrival, walkingTime;

function locationSuccess(position) {
  latitude = position.coords.latitude;
  longitude = position.coords.longitude;
  if (JSON.parse(settingsStorage.getItem("line")) === null) return;
  // Reading the origin station from Companion Settings
  const station = JSON.parse(settingsStorage.getItem("origin")).name; 
  if (station === "") return;

  // Replace the space with plus so that it can be passed to Google API  
  let dest = station.split(" ").join("+");  
  let googleUrl = `https://maps.googleapis.com/maps/api/distancematrix/json?origins=${latitude},${longitude}&destinations=${dest}&mode=walking&key=${apiKey}`;
  fetch(googleUrl, {
    method: "GET"
  })
    .then(function(res) {
      return res.json();
    })
    .then(function(data) {
      let myData = data;
      // Convert the time to mins
      walkingTime = Math.floor(myData.rows[0].elements[0].duration.value / 60); 
    })
    .catch(err => console.log("[FETCH]: " + err));
}

function locationError(error) {
  console.log("Error: " + error.code, "Message: " + error.message);
}

function sendMessage() {
    // Get the line, origin station & towards from Companion settings through settingsStorage
    const line = JSON.parse(settingsStorage.getItem("line")).values[0].name;
    const station = JSON.parse(settingsStorage.getItem("origin")).name;
    const towards = JSON.parse(settingsStorage.getItem("towards")).name;
  
    if (station === "" || towards === "") return
      // Get stationId for the selected line and origin station,
      // using the StationsIDMapping static data
      const stationId = StationsIDMapping.filter(function(train) {
        return train.line === line && train.station === station;
      });
 
      // We use the Ably TFL Hub, to recieve update for the given line & stationid (station & towards)   
      let channelName = `[product:ably-tfl/tube]tube:${line}:${stationId[0].stationid}:arrivals`;
      let trainChannel = realtime.channels.get(channelName);
      // Replace the space with plus so that it can be passed to Google API
      let dest = station.split(" ").join("+");
      if (latitude !== undefined && longitude !== undefined) {
        // Sending current location & station as destination to Google API to get walking time
        let googleUrl = `https://maps.googleapis.com/maps/api/distancematrix/json?origins=${latitude},${longitude}&destinations=${dest}&mode=walking&key=${apiKey}`;
        fetch(googleUrl, {
          method: "GET"
        })
          .then(function(res) {
            return res.json();
          })
          .then(function(data) {
            let myData = data;
             // Convert the time to mins
            walkingTime = Math.floor(
              myData.rows[0].elements[0].duration.value / 60
            );
          })
          .catch(err => console.log("[FETCH]: " + err));
      }
 
      // We subscribe to the messages coming on the Ably TFL Hub channel   
      trainChannel.subscribe(msg => {
        /* station update in msg */
        // Get upcoming trains for our user input of line, station and towards
        const trains = msg.data.filter(train => {
          return (
            line === train.LineId &&
            station === train.StationName &&
            towards === train.Towards &&
            Math.floor((new Date(train.ExpectedArrival) - new Date())/1000/60) >= walkingTime
          );
        });
        // Get the first upcoming train time
        let trainTime = new Date(trains[0].ExpectedArrival);
        let currentTime = new Date();
        let diff = trainTime - currentTime;
        timeToArrival = Math.floor(diff / 1000 / 60);
        // Now using the messaging module we send the data to the app 
        // Walk time, train time 
        if (
          messaging.peerSocket.readyState === messaging.peerSocket.OPEN &&
          walkingTime !== undefined
        ) {
          messaging.peerSocket.send({
            tTA: timeToArrival,
            wT: walkingTime,
            lT: (timeToArrival - walkingTime) > 30? "FAR" : (timeToArrival - walkingTime)
          });
        }
      });
 }