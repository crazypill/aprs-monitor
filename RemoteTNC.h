//
//  RemoteTNC.h
//  aprs-monitor
//
//  Created by Alex Lelievre on 8/9/20.
//  Copyright © 2020 Apple. All rights reserved.
//

#ifndef RemoteTNC_h
#define RemoteTNC_h

#include <stdbool.h>
#include <stdint.h>

#include "kiss_frame.h"

// define this to see incoming weather data from weather sensors...
//#define TRACE_INCOMING_WX
//#define TRACE_STATS



//#define PORT_DEVICE "/dev/cu.usbserial-0001"  // blue usb->serial adapter, use command line interface instead of changing this. this is here to remind me of the port name.
#define PORT_DEVICE   "/dev/serial0"
#define PORT_ERROR    -1
#define PROGRAM_NAME  "aprs-monitor"
#define VERSION       "100"


#define pascal2inchHg    0.0002953
#define millibar2inchHg  0.02953

#define c2f( a )           (((a) * 1.8000) + 32)
#define ms2mph( a )         ((a) * 2.23694)
#define inHg2millibars( a ) ((a) * 33.8639)

// https://www.daculaweather.com/stuff/CWOP_Guide.pdf has all the intervals, etc...
#define kTelemDelaySecs     15  // 15 seconds after weather tx - used to stagger messages so they don't pile up on each other
#define kStatusDelaySecs    30

#define kTempLowBar         -60.0f
#define kTempHighBar        130.0f
#define kTempTemporalLimit  35.0f // °F -- !!@ these are supposed to be over an hour but we only really keep about 10 minutes of data
#define kHumidityLowBar     0
#define kHumidityHighBar    100
#define kWindLowBar         0
#define kWindHighBar        100
#define kWindTemporalLimit  17.39130 // this is 20 knots in mph -- !!@ see note above about temporal being 10 minutes instead of hour.


//-----------------------------------------------------------------------------------------------------------------------------

// for debugging otherwise we spend a lifetime waiting for data to debug with...
#define kSendInterval_debug    30
#define kParamsInterval_debug  60
#define kStatusInterval_debug  60

#define kTempPeriod_debug    15
#define kIntTempPeriod_debug 15
#define kWindPeriod_debug    20
#define kGustPeriod_debug    30
#define kBaroPeriod_debug    15
#define kHumiPeriod_debug    15
#define kAirPeriod_debug     15

#define kSendInterval    60 * 5        // 5 minutes
#define kParamsInterval  60 * 60 * 2   // every two hours
#define kStatusInterval  60 * 10 + 15  // every ten minutes + 15 seconds offset

#define kTempPeriod    60 * 5   // 5 minute average
#define kIntTempPeriod 60 * 5   // 5 minute average
#define kWindPeriod    60 * 2   // 2 minute average
#define kGustPeriod    60 * 10  // 10 minute max wind gust
#define kBaroPeriod    60       // low for the minute period
#define kHumiPeriod    60
#define kAirPeriod     60

//-----------------------------------------------------------------------------------------------------------------------------


#define kLongestInterval kGustPeriod

#ifdef TRACE_INCOMING_WX
#define trace printf
#else
#define trace nullprint
#endif

#ifdef TRACE_STATS
#define stats printf
#else
#define stats nullprint
#endif

#ifndef BUFSIZE
#define BUFSIZE 1025
#endif

#define AX25_MAX_ADDRS 10    /* Destination, Source, 8 digipeaters. */
#define AX25_MAX_INFO_LEN 2048    /* Maximum size for APRS. */
#define AX25_MAX_PACKET_LEN ( AX25_MAX_ADDRS * 7 + 2 + 3 + AX25_MAX_INFO_LEN)


int  init_socket_layer( frame_callback callback );
bool debug_mode( void );
void log_error( const char* format, ... );
void log_unix_error( const char* prefix );


#endif /* RemoteTNC_h */


// EOF
