
/* decode_aprs.h */


#ifndef DECODE_APRS_H

#define DECODE_APRS_H 1



#ifndef G_UNKNOWN
#include "latlong.h"
#endif

#ifndef AX25_MAX_ADDR_LEN
#include "ax25_pad.h"
#endif 

#ifndef APRSTT_LOC_DESC_LEN
#define APRSTT_LOC_DESC_LEN 32        /* Need at least 26 */
#endif


// Various cases of the overloaded "message."
typedef enum
{
    message_subtype_invalid = 0,
    message_subtype_message,
    message_subtype_ack,
    message_subtype_rej,
    message_subtype_telem_parm,
    message_subtype_telem_unit,
    message_subtype_telem_eqns,
    message_subtype_telem_bits,
    message_subtype_directed_query
} message_subtype_e;


enum
{
    kWxDataFlag_wind       = 1 << 0,
    kWxDataFlag_windDir    = 1 << 1,
    kWxDataFlag_gust       = 1 << 2,    // note: a bunch of my hacky code depends on these wind guys all sticking together
    kWxDataFlag_temp       = 1 << 3,
    kWxDataFlag_humidity   = 1 << 4,
    kWxDataFlag_pressure   = 1 << 5,
    kWxDataFlag_rainHr     = 1 << 6,
    kWxDataFlag_rain24     = 1 << 7,
    kWxDataFlag_rainMid    = 1 << 8,
    kWxDataFlag_rainRaw    = 1 << 9,
    kWxDataFlag_snow24     = 1 << 10,
    kWxDataFlag_luminosity = 1 << 11,
    kWxDataFlag_radiation  = 1 << 12
};


enum
{
    kDataFlag_Latitude        = 1 << 0,
    kDataFlag_Longitude       = 1 << 1,
    kDataFlag_MaidenHead      = 1 << 2,
    kDataFlag_Course          = 1 << 3,
    kDataFlag_Speed           = 1 << 4,
    kDataFlag_Power           = 1 << 5,
    kDataFlag_Height          = 1 << 6,
    kDataFlag_Gain            = 1 << 7,
    kDataFlag_Range           = 1 << 8,
    kDataFlag_Altitude        = 1 << 9,
    kDataFlag_Frequency       = 1 << 10,
    kDataFlag_Tone            = 1 << 11,
    kDataFlag_DCS             = 1 << 12,
    kDataFlag_Offset          = 1 << 13,
    kDataFlag_Footprint       = 1 << 14,
    kDataFlag_Comment         = 1 << 15
};



typedef struct
{
    uint16_t  wxflags;           // the flags tell you which fields are valid in this message
    uint8_t   humidity;          // 0 - 100
    float     tempF;             // temp in F
    float     pressure;          // pressure in millibars
    float     windDirection;     // in degrees
    float     windSpeedMph;      // mph
    float     windGustMph;       // mph
    float     rainLastHour;      // 1/100 inches
    float     rainLast24Hrs;
    float     rainSinceMidnight;
    float     rainRaw;
    float     snowLast24Hrs;
    float     luminosity;
    float     radiation;
} wx_data;



typedef struct decode_aprs_s
{
    uint16_t g_flags;                           // the flags tell you which fields are valid in this message

    int    g_quiet;                             // Suppress error messages when decoding
    
    char   g_src[AX25_MAX_ADDR_LEN];
    char   g_msg_type[60];	    	            // APRS data type.  Telemetry descriptions get pretty long

    message_subtype_e g_message_subtype;

    char   g_symbol_table;                      // The Symbol Table Identifier character selects one
    char   g_symbol_code;
    char   g_aprstt_loc[APRSTT_LOC_DESC_LEN];	// APRStt location from !DAO!

    double g_lat;                               // Location, degrees.  Negative for South or West
    double g_lon;
    char   g_maidenhead[12];                    // 4 or 6 (or 8?) character maidenhead locator
    
    char   g_name[12];                          // Object or item name. Max. 9 characters
    char   g_addressee[12];                     // Addressee for a "message."  Max. 9 characters
    char   g_message_number[8];                 // Message number.  Should be 1 - 5 characters if used

    float  g_speed_mph;                         // Speed in MPH
    float  g_course;                            // 0 = North, 90 = East, etc

    int    g_power;                             // Transmitter power in watts
    int    g_height;                            // Antenna height above average terrain, feet
    int    g_gain;                              // Antenna gain in dB.
    char   g_directivity[12];                   // Direction of max signal strength
    float  g_range;                             // Precomputed radio range in miles
    float  g_altitude_ft;                       // Feet above median sea level
    char   g_mfr[80];                           // Manufacturer or application
                
    char   g_mic_e_status[32];                  // MIC-E message

    double g_freq;                              // Frequency, MHz
    float  g_tone;                              // CTCSS tone, Hz, one fractional digit
    int    g_dcs;                               // Digital coded squelch, print as 3 octal digits
    int    g_offset;	                        // Transmit offset, kHz

    char   g_query_type[12];                    // General Query: APRS, IGATE, WX, ...
    double g_footprint_lat;                     // A general query may contain a foot print
    double g_footprint_lon;                     // Set all to G_UNKNOWN if not used
    float  g_footprint_radius;                  // Radius in miles
    char   g_query_callsign[12];                // Directed query may contain callsign

    // text versions of stuff...
    char   g_weather[500];                      // Weather.  Can get quite long. Rethink max size.
    char   g_telemetry[256];                    // Telemetry data.  Rethink max size
    char   g_comment[256];
    
    wx_data g_wxdata;   // this contains all the weather data we find...

} decode_aprs_t;





extern void decode_aprs (decode_aprs_t *A, packet_t pp, int quiet);

extern void decode_aprs_print (decode_aprs_t *A);


#endif
