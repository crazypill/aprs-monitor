//
//  SymbolTable.m
//  aprs-monitor
//
//  Created by Alex Lelievre on 8/12/20.
//  Copyright © 2020 Apple. All rights reserved.
//

#include "SymbolTable.h"


static const SymbolEntry s_symbol_table[] =
{
//     /0 P0  # circle (obsolete)
//     /1 P1  TBD (these were numbered)
//     /2 P2  TBD (circles like pool)
//     /3 P3  TBD (balls.  But with)
//     /4 P4  TBD (overlays, we can)
//     /5 P5  TBD (put all #'s on one)
//     /6 P6  TBD (So 1-9 are available)
//     /7 P7  TBD (for new uses?)
//     /8 P8  TBD (They are often used)
//     /9 P9  TBD (as mobiles at events)

//     /; MS  Campground (Portable ops)

//     /= MU  RAILROAD ENGINE

//     /? MW  SERVER for Files
//     /@ MX  HC FUTURE predict (dot)
//     /A PA  Aid Station
//     /B PB  BBS or PBBS
//     /C PC  Canoe
//     /D PD
//     /E PE  EYEBALL (Events, etc!)
//     /F PF  Farm Vehicle (tractor)
//     /G PG  Grid Square (6 digit)
//     /H PH  HOTEL (blue bed symbol)
//     /I PI  TcpIp on air network stn
//     /J PJ
//     /K PK  School
//     /L PL  PC user (Jan 03)
//     /M PM  MacAPRS
//     /N PN  NTS Station
//     /O PO  BALLOON        (SSID-11)

//     /Q PQ  TBD
//     /R PR  REC. VEHICLE   (SSID-13)
//     /S PS  SHUTTLE
//     /T PT  SSTV

//     /V PV  ATV
//     /W PW  National WX Service Site
//     /X PX  HELO           (SSID-6)
//     /Y PY  YACHT (sail)   (SSID-5)
//     /Z PZ  WinAPRS

//     /\ HT  TRIANGLE(DF station)

    { @"/:", @"Fire",                  @"flame",         0, 1.00f, 0.00f, 0.00f },
    { @"/<", @"Motorcycle",            @"🏍",            1, 1.00f, 0.00f, 1.00f },
    { @"/>", @"Car",                   @"car",           0, 1.00f, 0.50f, 0.00f },
    { @"/P", @"Police",                @"🚓",            1, 0.00f, 0.00f, 0.50f },
    { @"/U", @"Bus",                   @"🚌",            1, 0.80f, 0.80f, 0.80f },
    { @"/[", @"Person",                @"person",        0, 0.00f, 1.00f, 1.00f },
    { @"/]", @"Post Office",           @"📨",            1, 1.00f, 1.00f, 0.00f },
    { @"/^", @"Large Aircraft",        @"airplane",      0, 1.00f, 0.00f, 0.50f },
    { @"/_", @"Weather Station",       @"thermometer",   0, 0.00f, 0.00f, 1.00f },

//    { @"/`", @"Dish Antenna",          @"", 0.00f, 1.00f, 0.00f },
//    { @"/a", @"Ambulance",             @"", 0.00f, 1.00f, 0.00f },
//    { @"/b", @"Bike",                  @"", 0.00f, 1.00f, 0.00f },
//    { @"/c", @"Incident Command Post", @"", 0.00f, 1.00f, 0.00f },
//    { @"/d", @"Fire dept",             @"", 0.00f, 1.00f, 0.00f },
//    { @"/e", @"Horse",                 @"", 0.00f, 1.00f, 0.00f },
//    { @"/f", @"Fire truck",            @"", 0.00f, 1.00f, 0.00f },
//    { @"/g", @"Glider",                @"", 0.00f, 1.00f, 0.00f },
//    { @"/h", @"Hospital",              @"", 0.00f, 1.00f, 0.00f },
//    { @"/i", @"Islands on the air",    @"", 0.00f, 1.00f, 0.00f },
//    { @"/j", @"Jeep",                  @"", 0.00f, 1.00f, 0.00f },
//    { @"/k", @"Truck",                 @"", 0.00f, 1.00f, 0.00f },
//    { @"/l", @"Laptop",                @"", 0.00f, 1.00f, 0.00f },
//    { @"/m", @"Mic-E Repeater",        @"", 0.00f, 1.00f, 0.00f },
//    { @"/n", @"Node",                  @"", 0.00f, 1.00f, 0.00f },
//    { @"/o", @"EOC",                   @"", 0.00f, 1.00f, 0.00f },
//    { @"/p", @"Rover (dog)",           @"", 0.00f, 1.00f, 0.00f },
//    { @"/q", @"Grid Square",           @"", 0.00f, 1.00f, 0.00f },
//    { @"/r", @"Repeater",              @"", 0.00f, 1.00f, 0.00f },
//    { @"/s", @"Power Boat",            @"", 0.00f, 1.00f, 0.00f },
//    { @"/t", @"Truck Stop",            @"", 0.00f, 1.00f, 0.00f },
//    { @"/u", @"Tractor trailer",       @"", 0.00f, 1.00f, 0.00f },
//    { @"/v", @"Van",                   @"", 0.00f, 1.00f, 0.00f },
//    { @"/w", @"Water station",         @"", 0.00f, 1.00f, 0.00f },
//    { @"/x", @"xAPRS (Unix)",          @"", 0.00f, 1.00f, 0.00f },
//    { @"/y", @"YAGI @ QTH",            @"", 0.00f, 1.00f, 0.00f },
//    { @"/z", @"",                      @"", 0.00f, 1.00f, 0.00f },
//    { @"/{", @"",                      @"", 0.00f, 1.00f, 0.00f },
//    { @"/|", @"TNC Stream Switch",     @"", 0.00f, 1.00f, 0.00f },
//    { @"/}", @"",                      @"", 0.00f, 1.00f, 0.00f },
//    { @"/~", @"TNC Stream Switch",     @"", 0.00f, 1.00f, 0.00f },

//    /" BC  reserved  (was rain)
//    /( BI  Mobile Satellite Station
//    /) BJ  Wheelchair (handicapped)
//    /* BK  SnowMobile
//    /+ BL  Red Cross
//    /, BM  Boy Scouts
//    /. BO  X
//    // BP  Red Dot

     
     
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
//     \L  AL  Lighthouse
//     \M  AMO MARS (A=Army,N=Navy,F=AF)
//     \N  AN  Navigation Buoy
//     \O  AO  Overlay Balloon (Rocket = \O)
//     \P  AP  Parking
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
//     \h  SHO Store. or HAMFST Hh=HAM store
//     \i  SI# BOX or points of Interest
//     \j  SJ  WorkZone (Steam Shovel)
//     \k  SKO Special Vehicle SUV,ATV,4x4
//     \l  SL  Areas      (box,circles,etc)
//     \m  SM  Value Sign (3 digit display)
//     \n  SN# OVERLAY TRIANGLE
//     \o  SO  small circle
//     \p  SP  AVAIL (PrtlyCldy => ( ovly P
//     \q  SQ  AVAIL
//     \r  SR  Restrooms
//     \s  SS# OVERLAY SHIP/boats
//     \t  ST  Tornado
//     \u  SU# OVERLAYED TRUCK
//     \v  SV# OVERLAYED Van
//     \w  SWO Flooding (Avalanches/Slides)
//     \x  SX  Wreck or Obstruction ->X<-
//     \y  SY  Skywarn
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
//    \> = Top view and symbol POINTS in direction of travel
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
//    DIGIPEATERS
//    /# - Generic digipeater
//    1# - WIDE1-1 digipeater
//    A# - Alternate input (i.e. 144.990MHz) digipeater
//    E# - Emergency powered (assumed full normal digi)
//    I# - I-gate equipped digipeater
//    L# - WIDEn-N with path length trapping
//    P# - PacComm
//    S# - SSn-N digipeater (includes WIDEn-N)
//    X# - eXperimental digipeater
//    V# - Viscous https://github.com/PhirePhly/aprx/blob/master/ViscousDigipeater.README
//    W# - WIDEn-N, SSn-N and Trapping
//
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
//    GATEWAYS: #&
//    /& = HF Gateway  <= the original primary table definition
//    I& = Igate Generic (please use more specific overlay)
//    R& = Receive only IGate (do not send msgs back to RF)
//    P& = PSKmail node
//    T& = TX igate with path set to 1 hop only)
//    W& = WIRES-X as opposed to W0 for WiresII
//    2& = TX igate with path set to 2 hops (not generally good idea)
//
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
//    /- = House
//    \- = (was HF)
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
    { nil, nil, nil, 0.00f, 0.00f, 0.00f }
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
    
    return nil;
}


#define kEmojiSize 40

UIImage* emojiToImage( NSString* emoji )
{
    CGRect bounds = CGRectMake( 0.0f, 0.0f, kEmojiSize, kEmojiSize );
    UIGraphicsBeginImageContextWithOptions( bounds.size, false, 0.0f );
    [emoji drawInRect:bounds withAttributes:@{ NSFontAttributeName : [UIFont systemFontOfSize:kEmojiSize] }];
    UIImage* emojiImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return emojiImage;
}
