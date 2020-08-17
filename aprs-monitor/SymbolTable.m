//
//  SymbolTable.m
//  aprs-monitor
//
//  Created by Alex Lelievre on 8/12/20.
//  Copyright © 2020 Apple. All rights reserved.
//

#include "SymbolTable.h"


#define kEmojiSize 32
#define kNGry      0.7f
#define kAlpha     0.7f


static const SymbolEntry s_symbol_table[] =
{
//     /- ???
    
    { @"/0", @"Circle with 0 overlay",  @"⓿",             1, 1,    0.00f,    0.00f,    0.00f, kAlpha },
    { @"/1", @"Circle with 1 overlay",  @"❶",             1, 1,  96/255.,  49/255.,   5/255., kAlpha },
    { @"/2", @"Circle with 2 overlay",  @"❷",             1, 1, 199/255.,    0.00f,  18/255., kAlpha },
    { @"/3", @"Circle with 3 overlay",  @"❸",             1, 1, 247/255., 132/255.,  82/255., kAlpha },
    { @"/4", @"Circle with 4 overlay",  @"❹",             1, 1, 252/255., 255/255.,  34/255., kAlpha },
    { @"/5", @"Circle with 5 overlay",  @"❺",             1, 1,  45/255., 211/255.,  13/255., kAlpha },
    { @"/6", @"Circle with 6 overlay",  @"❻",             1, 1,  37/255.,    0.00f, 205/255., kAlpha },
    { @"/7", @"Circle with 7 overlay",  @"❼",             1, 1, 248/255.,    0.00f, 157/255., kAlpha },
    { @"/8", @"Circle with 8 overlay",  @"🎱",            0, 1,  93/255.,  93/255., 148/255., kAlpha },
    { @"/9", @"Circle with 9 overlay",  @"❾",             1, 1,    1.00f,    1.00f,    1.00f, kAlpha },

    { @"/'", @"Campground (Portable ops)",  @"🏕",        0, 1, kNGry, kNGry, kNGry, kAlpha },

//     /= MU  RAILROAD ENGINE

//     /? MW  SERVER for Files
//     /@ MX  HC FUTURE predict (dot)
//     /A PA  Aid Station
//     /B PB  BBS or PBBS
    { @"/C", @"Canoe",                  @"🛶",             0, 1, kNGry, kNGry, kNGry, kAlpha },
//     /D PD
    { @"/E", @"Eyeball",                @"👀",             0, 1, kNGry, kNGry, kNGry, kAlpha },
//     /F PF  Farm Vehicle (tractor)
//     /G PG  Grid Square (6 digit)
//     /H PH  HOTEL (blue bed symbol)
//     /I PI  TcpIp on air network stn
//     /J PJ
    { @"/K", @"School",                @"🏫",             0, 1, kNGry, kNGry, kNGry, kAlpha },
    { @"/L", @"PC user",               @"🖥",             0, 1, kNGry, kNGry, kNGry, kAlpha },
    { @"/M", @"MacAPRS",               @"🍏",             0, 1, kNGry, kNGry, kNGry, kAlpha },
//     /N PN  NTS Station
    { @"/O", @"Balloon",               @"🎈",             0, 1, kNGry, kNGry, kNGry, kAlpha },

//     /Q PQ  TBD
    { @"/R",  @"Recreational Vehicle", @"🚙",             0, 1, kNGry, kNGry, kNGry, kAlpha },      // !!@ need better icon
//     /S PS  SHUTTLE
//     /T PT  SSTV

    { @"/V", @"ATV",                   @"🏍",             0, 1, kNGry, kNGry, kNGry, kAlpha },
//     /W PW  National WX Service Site
    { @"/X", @"Helicopter",            @"🚁",             0, 1, kNGry, kNGry, kNGry, kAlpha },
//     /Y PY  YACHT (sail)   (SSID-5)
    { @"/Y", @"Yacht",                 @"🛥",             0, 1, kNGry, kNGry, kNGry, kAlpha },
//     /Z PZ  WinAPRS

//     /\ HT  TRIANGLE(DF station)

    { @"/:", @"Fire",                  @"flame",         0, 0, 1.00f, 0.00f, 0.00f, kAlpha },
    { @"/<", @"Motorcycle",            @"🏍",            0, 1, kNGry, kNGry, kNGry, kAlpha },
    { @"/>", @"Car",                   @"🚗",            0, 1, kNGry, kNGry, kNGry, kAlpha },
    { @"/P", @"Police",                @"🚓",            0, 1, kNGry, kNGry, kNGry, kAlpha },
    { @"/U", @"Bus",                   @"🚌",            0, 1, kNGry, kNGry, kNGry, kAlpha },
    { @"/[", @"Person",                @"🏃‍♂️",            0, 1, kNGry, kNGry, kNGry, kAlpha },
    { @"/]", @"Post Office",           @"📨",            0, 1, kNGry, kNGry, kNGry, kAlpha },
    { @"/^", @"Large Aircraft",        @"✈️",            0, 1, kNGry, kNGry, kNGry, kAlpha },
    { @"/_", @"Weather Station",       @"thermometer",   0, 0, 0.00f, 0.00f, 1.00f, 0.6f },
    { @"/`", @"Dish Antenna",          @"📡",            0, 1, kNGry, kNGry, kNGry, kAlpha },
    { @"/a", @"Ambulance",             @"🚑",            0, 1, kNGry, kNGry, kNGry, kAlpha },
    { @"/b", @"Bike",                  @"🚲",            0, 1, kNGry, kNGry, kNGry, kAlpha },
//  { @"/c", @"Incident Command Post", @"",              0, 0, kNGry, kNGry, kNGry, kAlpha },
    { @"/d", @"Fire dept",             @"🚒",            0, 1, kNGry, kNGry, kNGry, kAlpha },
    { @"/e", @"Horse",                 @"🐎",            0, 1, kNGry, kNGry, kNGry, kAlpha },
    { @"/f", @"Fire truck",            @"🚒",            0, 1, kNGry, kNGry, kNGry, kAlpha },
//  { @"/g", @"Glider",                @"",              0, 0, kNGry, kNGry, kNGry, kAlpha },
    { @"/h", @"Hospital",              @"🏥",            0, 1, kNGry, kNGry, kNGry, kAlpha },
//  { @"/i", @"Islands on the air",    @"",              0, 0, kNGry, kNGry, kNGry, kAlpha },
    { @"/j", @"Jeep",                  @"🛺",            0, 1, kNGry, kNGry, kNGry, kAlpha },
    { @"/k", @"Truck",                 @"🚚",            0, 1, kNGry, kNGry, kNGry, kAlpha },
    { @"/l", @"Laptop",                @"💻",            0, 1, kNGry, kNGry, kNGry, kAlpha },
//  { @"/m", @"Mic-E Repeater",        @"",              0, 0, kNGry, kNGry, kNGry, kAlpha },
    { @"/n", @"Node",                  @"⦿",             1, 1, 0.84f, 0.84f, 0.84f, kAlpha },
//  { @"/o", @"EOC",                   @"",              0, 0, kNGry, kNGry, kNGry, kAlpha },
    { @"/p", @"Rover (dog)",           @"🐶",            0, 1, kNGry, kNGry, kNGry, kAlpha },
//  { @"/q", @"Grid Square",           @"",              0, 0, kNGry, kNGry, kNGry, kAlpha },
    { @"/r", @"Repeater",              @"",              0, 0, kNGry, kNGry, kNGry, kAlpha },
    { @"/s", @"Power Boat",            @"🚤",            0, 1, kNGry, kNGry, kNGry, kAlpha },
//  { @"/t", @"Truck Stop",            @"",              0, 0, kNGry, kNGry, kNGry, kAlpha },
    { @"/u", @"Tractor trailer",       @"🚚",            0, 1, kNGry, kNGry, kNGry, kAlpha },
    { @"/v", @"Van",                   @"🚐",            0, 1, kNGry, kNGry, kNGry, kAlpha },
    { @"/w", @"Water station",         @"🚰",            0, 1, kNGry, kNGry, kNGry, kAlpha },
//  { @"/x", @"xAPRS (Unix)",          @"",              0, 0, kNGry, kNGry, kNGry, kAlpha },
    { @"/y", @"YAGI @ QTH"       ,     @"🏠",            0, 1, kNGry, kNGry, kNGry, kAlpha },
//  { @"/z", @"",                      @"",              0, 0, kNGry, kNGry, kNGry, kAlpha },
//  { @"/{", @"",                      @"",              0, 0, kNGry, kNGry, kNGry, kAlpha },
//  { @"/|", @"TNC Stream Switch",     @"",              0, 0, kNGry, kNGry, kNGry, kAlpha },
//  { @"/}", @"",                      @"",              0, 0, kNGry, kNGry, kNGry, kAlpha },
//  { @"/~", @"TNC Stream Switch",     @"",              0, 0, kNGry, kNGry, kNGry, kAlpha },

//    /" BC  reserved  (was rain)
//    /( BI  Mobile Satellite Station
//    /) BJ  Wheelchair (handicapped)
//    /* BK  SnowMobile
    { @"/+", @"Red Cross",             @"＋",            1, 1, 1.00f, 0.00f, 0.00f, kAlpha },   // red
//    /, BM  Boy Scouts
//    /. BO  X
    { @"/.", @"X",                     @"❌",            0, 1, kNGry, kNGry, kNGry, kAlpha },
    { @"//", @"Red Dot",               @"●",             1, 1, 1.00f, 0.00f, 0.00f, kAlpha },   // red

     
     
    // alt table
//     \!  OBO EMERGENCY (and overlays)
//     \"  OC  reserved
//     \#  OD# OVERLAY DIGI (green star)
//     \$  OEO Bank or ATM  (green box)
//     \%  OFO Power Plant with overlay
//     \&  OG# I=Igte R=RX T=1hopTX 2=2hopTX
//     \'  OHO Crash (& now Incident sites)
//     \(  OIO CLOUDY (other clouds w ovrly)
//     \)  OJO Firenet MEO, MODIS Earth Obs.
//     \*  OK  AVAIL (SNOW moved to ` ovly S)
//     \+  OL  Church
//     \,  OM  Girl Scouts
//     \-  ONO House (H=HF) (O = Op Present)
//     \.  OO  Ambiguous (Big Question mark)
//     \/  OP  Waypoint Destination
    { @"\\/", @"Waypoint Destination",         @"・",            1, 1, 162/255., 86/255., 55/255., kAlpha },  // brown
//
//     \0  A0# CIRCLE (IRLP/Echolink/WIRES)
//     \1  A1  AVAIL
//     \2  A2  AVAIL
//     \3  A3  AVAIL
//     \4  A4  AVAIL
//     \5  A5  AVAIL
//     \6  A6  AVAIL
//     \7  A7  AVAIL
//     \8  A8O 802.11 or other network node
//     \9  A9  Gas Station (blue pump)
//     \:  NR  AVAIL (Hail ==> ` ovly H)
//     \;  NSO Park/Picnic + overlay events
//     \<  NTO ADVISORY (one WX flag)
//     \=  NUO avail. symbol overlay group
//     \>  NV# OVERLAYED CARs & Vehicles
//     \?  NW  INFO Kiosk  (Blue box with ?)
//     \@  NX  HURICANE/Trop-Storm
//     \A  AA# overlayBOX DTMF & RFID & XO
//     \B  AB  AVAIL (BlwngSnow ==> E ovly B
//     \C  AC  Coast Guard
//     \D ADO  DEPOTS (Drizzle ==> ' ovly D)
//     \E  AE  Smoke (& other vis codes)
//     \F  AF  AVAIL (FrzngRain ==> `F)
//     \G  AG  AVAIL (Snow Shwr ==> I ovly S)
//     \H  AHO \Haze (& Overlay Hazards)
//     \I  AI  Rain Shower
//     \J  AJ  AVAIL (Lightening ==> I ovly L)
//     \K  AK  Kenwood HT (W)
    { @"\\K", @"Kenwood HT",         @"W",            1, 1, 0.70f, 0.00f, 0.00f, kAlpha },

//     \L  AL  Lighthouse
//     \M  AMO MARS (A=Army,N=Navy,F=AF)
//     \N  AN  Navigation Buoy
//     \O  AO  Overlay Balloon (Rocket = \O)
//     \P  AP  Parking
    { @"\\P", @"Parking",            @"🅿️",           0, 1, kNGry, kNGry, kNGry, kAlpha },
//     \Q  AQ  QUAKE
//     \R  ARO Restaurant
//     \S  AS  Satellite/Pacsat
//     \T  AT  Thunderstorm
//     \U  AU  SUNNY
//     \V  AV  VORTAC Nav Aid
//     \W  AW# # NWS site (NWS options)
//     \X  AX  Pharmacy Rx (Apothicary)
//     \Y  AYO Radios and devices
//     \Z  AZ  AVAIL
//     \[  DSO W.Cloud (& humans w Ovrly)
//     \\  DTO New overlayable GPS symbol
//     \]  DU  AVAIL
//     \^  DV# other Aircraft ovrlys (2014)
//     \_  DW# # WX site (green digi)
//     \`  DX  Rain (all types w ovrly)
//
//     \a  SA#O ARRL,ARES,WinLINK,Dstar, etc
//     \b  SB  AVAIL(Blwng Dst/Snd => E ovly)
//     \c  SC#O CD triangle RACES/SATERN/etc
//     \d  SD  DX spot by callsign
//     \e  SE  Sleet (& future ovrly codes)
//     \f  SF  Funnel Cloud
//     \g  SG  Gale Flags
    { @"\\h", @"Store. or HAMFST",                       @"🛒",           0, 1, 0.40f, 0.10f, 0.10f,  kAlpha },
//     \i  SI# BOX or points of Interest
//     \j  SJ  WorkZone (Steam Shovel)
    { @"\\k", @"Special Vehicle SUV,ATV,4x4",            @"🚙",           0, 1, kNGry, kNGry, kNGry, kAlpha },
    { @"3k",  @"Special Vehicle with 3 overlay",         @"🚙",           0, 1, kNGry, kNGry, kNGry, kAlpha },      // !!@ handle overlays!
//     \l  SL  Areas      (box,circles,etc)
//     \m  SM  Value Sign (3 digit display)
//     \n  SN# OVERLAY TRIANGLE
    { @"\\o", @"small circle",                           @"◉",            1, 1, 0.70f, 0.00f, 0.00f, kAlpha },

    //     \o  SO  small circle
//     \p  SP  AVAIL (PrtlyCldy => ( ovly P
//     \q  SQ  AVAIL
//     \r  SR  Restrooms
//     \s  SS# OVERLAY SHIP/boats
//     \t  ST  Tornado
//     \u  SU# OVERLAYED TRUCK
    { @"\\u",  @"Overlayed Truck",                      @"🚛",           0, 1, kNGry, kNGry, kNGry, kAlpha },      // !!@ handle overlays!
//     \v  SV# OVERLAYED Van
//     \w  SWO Flooding (Avalanches/Slides)
//     \x  SX  Wreck or Obstruction ->X<-
    { @"\\y",  @"Skywarn",                              @"⚡️",           0, 1, kNGry, kNGry, kNGry, kAlpha },
//     \z  SZ# OVERLAYED Shelter
//     \{  Q1  AVAIL? (Fog ==> E ovly F)
//     \|  Q2  TNC Stream Switch
//     \}  Q3  AVAIL? (maybe)
//     \~  Q4  TNC Stream Switch
//
//
//
//    ADVISORIES: #<  (new expansion possibilities)
//    /< = motorcycle
//    \< = Advisory (single gale flag)
//
//    AIRCRAFT
//    /^ = LARGE Aircraft
//    \^ = top-view originally intended to point in direction of flight
//    A^ = Autonomous (2015)
//    D^ = Drone   (new may 2014)
//    E^ = Electric aircraft (2015)
//    H^ = Hovercraft    (new may 2014)
//    J^ = JET     (new may 2014)
//    M^ = Missle   (new may 2014)
//    P^ = Prop (new Aug 2014)
//    R^ = Remotely Piloted (new 2015)
//    S^ = Solar Powered  (new 2015)
//    V^ = Vertical takeoff   (new may 2014)
//    X^ = Experimental (new Aug 2014)
//
//    ATM Machine or CURRENCY:  #$
//    /$ = original primary Phone
//    \$ = Bank or ATM (generic)
//    U$ = US dollars
//    L$ = Brittish Pound
//    Y$ = Japanese Yen
//
//    ARRL or DIAMOND: #a
//    /a = Ambulance
//    Aa = ARES
//    Da = DSTAR (had been ARES Dutch)
//    Ga = RSGB Radio Society of Great Brittan
//    Ra = RACES
//    Sa = SATERN Salvation Army
//    Wa = WinLink
//    Ya = C4FM Yaesu repeaters
//
//    BALLOONS and lighter than air #O (All new Oct 2015)
//    /O = Original Balloon (think Ham balloon)
//    \O = ROCKET (amateur)(2007)
//    BO = Blimp           (2015)
//    MO = Manned Balloon  (2015)
//    TO = Teathered       (2015)
//    CO = Constant Pressure - Long duration (2015)
//    RO = Rocket bearing Balloon (Rockoon)  (2015)
//    WO = World-round balloon (2018)
//
//    BOX SYMBOL: #A (and other system inputted symbols)
//    /A = Aid station
//    \A = numbered box
//    9A = Mobile DTMF user
//    7A = HT DTMF user
//    HA = House DTMF user
//    EA = Echolink DTMF report
//    IA = IRLP DTMF report
//    RA = RFID report
//    AA = AllStar DTMF report
//    DA = D-Star report
//    XA = OLPC Laptop XO
//    etc
//
//    BUILDINGS: #h
//    /h = Hospital
//    \h = Ham Store       ** <= now used for HAMFESTS
//    Ch = Club (ham radio)
//    Eh = Electronics Store
//    Fh = HamFest (new Aug 2014)
//    Hh = Hardware Store etc..
//
//    CARS: #> (Vehicles)
//    /> = normal car (side view)
//    \> = Top view and symbol POINTS in direction of travel - !!@
    { @"\\>", @"Top View Car",                   @"🚘",        0, 1, kNGry, kNGry, kNGry, kAlpha },

//    #> = Reserve overlays 1-9 for numbered cars (new Aug 2014)
//    B> = Battery (was E for electric)
//    E> = Ethanol (was electric)
//    F> = Fuelcell or hydrogen
//    H> = Homemade
//    P> = Plugin-hybrid
//    S> = Solar powered
//    T> = Tesla  (temporary)
//    V> = GM Volt (temporary)
//
//    CIVIL DEFENSE or TRIANGLE: #c
//    /c = Incident Command Post
//    \c = Civil Defense
//    Dc = Decontamination (new Aug 2014)
//    Rc = RACES
//    Sc = SATERN mobile canteen
//
//    DEPOT
//    /D = was originally undefined
//    \D = was drizzle (moved to ' ovlyD)
//    AD = Airport  (new Aug 2014)
//    FD = Ferry Landing (new Aug 2014)
//    HD = Heloport (new Aug 2014)
//    RD = Rail Depot  (new Aug 2014)
//    BD = Bus Depot (new Aug 2014)
//    LD = LIght Rail or Subway (new Aug 2014)
//    SD = Seaport Depot (new Aug 2014)
//
//    DIGIPEATERS - green
    { @"/#", @"Generic digipeater",         @"✸",            1, 1, 0.00f, 0.80f, 0.00f, kAlpha },
    { @"1#", @"WIDE1-1 digipeater",         @"✸",            1, 1, 0.00f, 0.80f, 0.00f, kAlpha },
    { @"A#", @"Alternate input",            @"✸",            1, 1, 0.00f, 0.80f, 0.00f, kAlpha },
    { @"E#", @"Emergency powered",          @"✸",            1, 1, 0.00f, 0.80f, 0.00f, kAlpha },
    { @"I#", @"I-gate equipped digipeater", @"✸",            1, 1, 0.00f, 0.80f, 0.00f, kAlpha },
    { @"L#", @"WIDEn-N with path length",   @"✸",            1, 1, 0.00f, 0.80f, 0.00f, kAlpha },
    { @"P#", @"PacComm",                    @"✸",            1, 1, 0.00f, 0.80f, 0.00f, kAlpha },
    { @"S#", @"SSn-N digipeater",           @"✸",            1, 1, 0.00f, 0.80f, 0.00f, kAlpha },
    { @"X#", @"eXperimental digipeater",    @"✸",            1, 1, 0.00f, 0.80f, 0.00f, kAlpha },
    { @"V#", @"Viscous",                    @"✸",            1, 1, 0.00f, 0.80f, 0.00f, kAlpha },
    { @"W#", @"WIDEn-N",                    @"✸",            1, 1, 0.00f, 0.80f, 0.00f, kAlpha },
    { @"N#", @"Digipeater with N overlay",  @"✸",            1, 1, 0.00f, 0.80f, 0.00f, kAlpha },     // !!@ add support for overlay letters and numbers
    { @"T#", @"Digipeater with 1 overlay",  @"✸",            1, 1, 0.00f, 0.80f, 0.00f, kAlpha },     // !!@ add support for overlay letters and numbers


//    EMERGENCY: #!
//    /! = Police/Sheriff, etc
//    \! = Emergency!
//    E! = ELT or EPIRB  (new Aug 2014)
//    V! = Volcanic Eruption or Lava  (new Aug 2014)
//
//    EYEBALL (EVENT) and VISIBILITY  #E
//    /E = Eyeball for special live events
//    \E = (existing smoke) the symbol with no overlay
//    HE = (H overlay) Haze
//    SE = (S overlay) Smoke
//    BE = (B overlay) Blowing Snow         was \B
//    DE = (D overlay) blowing Dust or sand was \b
//    FE = (F overlay) Fog                  was \{
//
//    GATEWAYS: #& - black
    { @"/&", @"HF Gateway",                           @"♦︎",            1, 1, 0.00f, 0.00f, 0.00f, kAlpha },
    { @"I&", @"Igate Generic",                        @"♦︎",            1, 1, 0.00f, 0.00f, 0.00f, kAlpha },
    { @"R&", @"Receive only IGate",                   @"♦︎",            1, 1, 0.00f, 0.00f, 0.00f, kAlpha },
    { @"P&", @"PSKmail node",                         @"♦︎",            1, 1, 0.00f, 0.00f, 0.00f, kAlpha },
    { @"T&", @"TX igate with path set to 1 hop only", @"♦︎",            1, 1, 0.00f, 0.00f, 0.00f, kAlpha },
    { @"W&", @"WIRES-X as opposed to W0 for WiresII", @"♦︎",            1, 1, 0.00f, 0.00f, 0.00f, kAlpha },
    { @"2&", @"TX igate with path set to 2 hops",     @"♦︎",            1, 1, 0.00f, 0.00f, 0.00f, kAlpha },
    
    { @"&&", @"Winlink Gateway",                      @"♦︎",            1, 1, 232/255., 0.00f, 23/255., kAlpha }, // need overlay W
    { @"Ba", @"BPQ32 IGate",                          @"♦︎",            1, 1, 232/255., 0.00f, 23/255., kAlpha }, // need overlay B

//    GPS devices: #\
//    /\ = Triangle DF primary symbol
//    \\ = was undefined alternate symbol
//    A\ = Avmap G5      * <= Recommend special symbol
//
//    HAZARDS: #H
//    /H = hotel
//    \H = Haze
//    MH = Methane Hazard (new Apr 2017)
//    RH = Radiation detector (new mar 2011)
//    WH = Hazardous Waste
//    XH = Skull&Crossbones
//
//    HUMAN SYMBOL: #[
//    /[ = Human
//    \[ = Wall Cloud (the original definition)
//    B[ = Baby on board (stroller, pram etc)
//    S[ = Skier      * <= Recommend Special Symbol
//    R[ = Runner
//    H[ = Hiker
//
//    HOUSE: #-
    { @"/-",  @"House",     @"🏠",            0, 1, kNGry, kNGry, kNGry, kAlpha },
    { @"\\-", @"HF",        @"🏠",            0, 1, kNGry, kNGry, kNGry, kAlpha },  // need house with antenna !!@
//    5- = 50 Hz if non standard
//    6- = 60 Hz if non standard
//    B- = Battery or off grid
//    C- = Combined alternatives
//    E- = Emergency power (grid down)
//    G- = Geothermal
//    H- = Hydro powered
//    O- = Operator Present
//    S- = Solar Power
//    W- = Wind power
//
//    INCIDENT SITES: #'
//    /' = Small Aircraft (original primary symbol)
//    \' = Airplane Crash Site  <= the original alternate deifinition
//    A' = Automobile crash site
//    H' = Hazardous incident
//    M' = Multi-Vehicle crash site
//    P' = Pileup
//    T' = Truck wreck
//
//    NUMBERED CIRCLES: #0
//    A0 = Allstar Node (A0)
//    E0 = Echolink Node (E0)
//    I0 = IRLP repeater (I0)
//    S0 = Staging Area  (S0)
//    V0 = Echolink and IRLP (VOIP)
//    W0 = WIRES (Yaesu VOIP)
//
//    NETWORK NODES: #8
//    88 = 802.11 network node (88)
//    G8 = 802.11G  (G8)
//
//    PORTABLE SYMBOL: #;
//    /; = Portable operation (tent)
//    \; = Park or Picnic
//    F; = Field Day
//    I; = Islands on the air
//    S; = Summits on the air
//    W; = WOTA
//
//    POWER or ENERGY: #%
//    /% = DX cluster  <= the original primary table definition
//    C% = Coal
//    E% = Emergency  (new Aug 2014)
//    G% = Geothermal
//    H% = Hydroelectric
//    N% = Nuclear
//    P% = Portable (new Aug 2014)
//    R% = Renewable (hydrogen etc fuels)
//    S% = Solar
//    T% = Turbine
//    W% = Wind
//
//    RAIL Symbols: #=
//    /= = generic train (use steam engine shape for quick recognition)
//    \= = tbd    (use same symbol for now)
//    B= = Bus-rail/trolley/streetcar/guiderail
//    C= = Commuter
//    D= = Diesel
//    E= = Electric
//    F= = Freight
//    G= = Gondola
//    H= = High Speed Rail (& Hyperloop?)
//    I= = Inclined Rail
//    L= = eLevated
//    M= = Monorail
//    P= = Passenger
//    S= = Steam
//    T= = Terminal (station)
//    U= = sUbway (& Hyperloop?)
//    X= = eXcursion
//
//
//    RESTAURANTS: #R
//    \R = Restaurant (generic)
//    7R = 7/11
//    KR = KFC
//    MR = McDonalds
//    TR = Taco Bell
//
//    RADIOS and APRS DEVICES: #Y
//    /Y = Yacht  <= the original primary symbol
//    \Y =        <= the original alternate was undefined
//    AY = Alinco
//    BY = Byonics
//    IY = Icom
//    KY = Kenwood       * <= Recommend special symbol
//    YY = Yaesu/Standard* <= Recommend special symbol
    { @"YY", @"Yaesu/Standard",  @"📻",            0, 1, kNGry, kNGry, kNGry, kAlpha },  // need walkie talkie icon !!@
//
//
//    SPECIAL VEHICLES: #k
//    /k = truck
//    \k = SUV
//    4k = 4x4
//    Ak = ATV (all terrain vehicle)
//
//    SHELTERS: #z
//    /z = was available
//    \z = overlayed shelter
//    Cz = Clinic (new Aug 2014)
//    Ez = Emergency Power
//    Gz = Government building  (new Aug 2014)
//    Mz = Morgue (new Aug 2014)
//    Tz = Triage (new Aug 2014)
//
//    SHIPS: #s
//    /s = Power boat (ship) side view
//    \s = Overlay Boat (Top view)
//    6s = Shipwreck ("deep6") (new Aug 2014)
//    Bs = Pleasure Boat
//    Cs = Cargo
//    Ds = Diving
//    Es = Emergency or Medical transport
//    Fs = Fishing
//    Hs = High-speed Craft
//    Js = Jet Ski
//    Ls = Law enforcement
//    Ms = Miltary
//    Os = Oil Rig
//    Ps = Pilot Boat (new Aug 2014)
//    Qs = Torpedo
//    Ss = Search and Rescue
//    Ts = Tug (new Aug 2014)
//    Us = Underwater ops or submarine
//    Ws = Wing-in-Ground effect (or Hovercraft)
//    Xs = Passenger (paX)(ferry)
//    Ys = Sailing (large ship)
//
//    TRUCKS: #u
//    /u = Truck (18 wheeler)
//    \u = truck with overlay
//    Bu = Buldozer/construction/Backhoe  (new Aug 2014)
//    Gu = Gas
//    Pu = Plow or SnowPlow (new Aug 2014)
//    Tu = Tanker
//    Cu = Chlorine Tanker
//    Hu = Hazardous
//
//    WATER #w
//    /w = Water Station or other H2O
//    \w = flooding (or Avalanche/slides)
//    Aw = Avalanche
//    Gw = Green Flood Gauge
//    Mw = Mud slide
//    Nw = Normal flood gauge (blue)
//    Rw = Red flood gauge
//    Sw = Snow Blockage
//    Yw = Yellow flood gauge
    
    // leave last
    { nil, nil, nil, 0, 0.00f, 0.00f, 0.00f, 0.00f }
};


NSString* getGlyphForSymbol( NSString* symbol )
{
    const SymbolEntry* entry = s_symbol_table;
    
    while( entry->symbol )
    {
        if( [entry->symbol isEqualToString:symbol] )
            return entry->glyph;
        
        entry++;
    }
    
    return nil;
}


const SymbolEntry* getSymbolEntry( NSString* symbol )
{
    const SymbolEntry* entry = s_symbol_table;
    
    while( entry->symbol )
    {
        if( [entry->symbol isEqualToString:symbol] )
            return entry;
        
        entry++;
    }
    
    NSLog( @"getSymbolEntry: couldn't find symbol for: %@\n", symbol );
    return nil;
}



UIImage* emojiToImage( NSString* emoji )
{
    CGRect bounds = CGRectMake( 0.0f, 0.0f, kEmojiSize, kEmojiSize );
    UIGraphicsBeginImageContextWithOptions( bounds.size, false, 0.0f );
    [emoji drawInRect:bounds withAttributes:@{ NSFontAttributeName : [UIFont systemFontOfSize:kEmojiSize - 2] }];
    UIImage* emojiImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return emojiImage;
}
