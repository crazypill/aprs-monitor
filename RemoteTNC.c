//
//  RemoteTNC.c
//  aprs-monitor
//
//  Created by Alex Lelievre on 8/9/20.
//  Copyright © 2020 Far Out Labs. All rights reserved.
//

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdarg.h>

#include <strings.h>
#include <string.h>
#include <errno.h>
#include <fcntl.h>
#include <sys/termios.h>
#include <unistd.h>
#include <time.h>
#include <math.h>
#include <assert.h>
#include <netdb.h>
#include <getopt.h>
#include <signal.h>

#include "RemoteTNC.h"

#include "wx_thread.h"
#include "aprs-wx.h"
#include "aprs-is.h"

#include "ax25_pad.h"
#include "kiss_frame.h"


// don't use old history if it's too far away from now...
#define TIME_OUT_OLD_DATA

//#define TRACE_STATS
//#define TRACE_AIR_STATS
//#define TRACE_INSERTS
//#define TRACE_AVERAGES

#define kCallSign "K6LOT-13"
#define kPasscode "8347"
#define kWidePath "WIDE2-1"
#define kIGPath   "TCPIP*"

#define kHistoryTimeout        60 * 2  // 2 minutes (to restart the app before the history rots)
#define kMaxNumberOfRecords    200     // 10 minutes (600 seconds) we need 600 / 5 sec = 120 wxrecords minimum.  Let's round up to 200.
#define kMaxQueueItems         32
#define kLogRollInterval       60 * 60 * 24   // (roll the log daily)
#define kWxWideInterval        60 * 15        // send our weather out to WIDE2-1 every quarter hour

typedef struct
{
    frame_callback  callback;
    status_callback status;
} ReadThreadInfo;


static time_t s_last_log_roll  = 0;

static bool s_debug = true;

static const char* s_logFilePath = NULL;
static FILE*       s_logFile     = NULL;


static const char* s_port_device  = PORT_DEVICE;
//static const char* s_kiss_server  = "localhost";
static const char* s_kiss_server  = "aprs.local";
static uint16_t    s_kiss_port    = 8001;
static uint8_t     s_num_retries  = 10;
static bool        s_test_mode    = false;

static wx_thread_t  s_read_thread = 0;
static sig_atomic_t s_read_thread_quit = 0;
static sig_atomic_t s_queue_busy = 0;
static sig_atomic_t s_queue_num  = 0;
static const char*  s_queue[kMaxQueueItems] = {};        // these are packets waiting to be dispatched

//static sig_atomic_t s_error_bucket_busy = 0;
//static sig_atomic_t s_error_bucket_num  = 0;
//static const char*  s_error_bucket[kMaxQueueItems] = {};  // these are packets that failed to send after already being queued for later send.  These will get requeued later...

static wx_thread_return_t sendToRadio_thread_entry( void* args );
static wx_thread_return_t sendToRadioWIDE_thread_entry( void* args );
static wx_thread_return_t sendPacket_thread_entry( void* args );
static wx_thread_return_t tnc_read_thread( void* args );

static int  connectToDireWolf( void );
static int  sendToRadio( const char* p, bool wide );    // wide = send out to WIDE2-1 instead of TCPIP*
static int  send_to_kiss_tnc( int chan, int cmd, char *data, int dlen );
static int  read_from_kiss_tnc( int server_sock, frame_callback callback );

static void        queue_packet( const char* packetData );
static const char* queue_get_next_packet( void );

static void        queue_error_packet( const char* packetData );
//static const char* error_bucket_get_next_packet( void );


#pragma mark -

int getErrno( int result )
{
    int err;
    
    err = 0;
    if (result < 0) {
        err = errno;
        assert(err != 0);
    }
    return err;
}


int ignoreSIGPIPE()
{
    int err;
    struct sigaction signalState;
    
    err = sigaction( SIGPIPE, NULL, &signalState );
    err = getErrno( err );
    if( err == 0 )
    {
        signalState.sa_handler = SIG_IGN;
        err = sigaction( SIGPIPE, &signalState, NULL );
        err = getErrno( err );
    }
    
    return err;
}


void signalHandler( int sig )
{
    switch( sig )
    {
        case SIGHUP:
            break;
            
        case SIGINT:
            if( s_logFile )
                fclose( s_logFile );
            exit( EXIT_SUCCESS );
            break;
            
        case SIGTERM:
            if( s_logFile )
                fclose( s_logFile );
            exit( EXIT_SUCCESS );
            break;

        default:
            assert( false );
            break;
    }
}



#pragma mark -

void nullprint( const char* format, ... )
{
    
}


char* copy_string( const char* stringToCopy )
{
    if( !stringToCopy )
        return NULL;
    
    size_t bufSize = strlen( stringToCopy ) + 1;
    char* newString = (char*)malloc( bufSize );
    if( newString )
    {
        strcpy( newString, stringToCopy );
        newString[bufSize - 1] = '\0';
    }
    return newString;
}


void buffer_input_flush()
{
    int c;
     // This will eat up all other characters
    while( (c = getchar()) != EOF && c != '\n' )
        ;
}


void printTime( int printNewline )
{
    time_t t = time( NULL );
    struct tm tm = *localtime(&t);
    if( printNewline )
        printf("%d-%02d-%02d %02d:%02d:%02d\n", tm.tm_year + 1900, tm.tm_mon + 1, tm.tm_mday, tm.tm_hour, tm.tm_min, tm.tm_sec);
    else
        printf("%d-%02d-%02d %02d:%02d:%02d", tm.tm_year + 1900, tm.tm_mon + 1, tm.tm_mday, tm.tm_hour, tm.tm_min, tm.tm_sec);
}


void printTimePlus5()
{
  time_t t = time( NULL );
  struct tm tm = *localtime(&t);
  printf("%d-%02d-%02d %02d:%02d:%02d\n", tm.tm_year + 1900, tm.tm_mon + 1, tm.tm_mday, tm.tm_hour, tm.tm_min + 5, tm.tm_sec);
}



time_t timeGetTimeSec()
{
    time_t rawtime = 0;
    return time( &rawtime );
}


uint8_t imax( uint8_t a, uint8_t b )
{
    return a > b ? a : b;
}


uint8_t imin( uint8_t a, uint8_t b )
{
    return a < b ? a : b;
}




#pragma mark -



uint8_t update_crc( uint8_t res, uint8_t val )
{
    for( int i = 0; i < 8; i++ )
    {
        uint8_t tmp = (uint8_t)((res ^ val) & 0x80);
        res <<= 1;
        if( 0 != tmp )
            res ^= 0x31;
        val <<= 1;
    }
    return res;
}


uint8_t calculate_crc( uint8_t* data, uint8_t len )
{
    uint8_t res = 0;
    for( int j = 0; j < len; j++ )
    {
        uint8_t val = data[j];
        res = update_crc( res, val );
    }
    return res;
}



#pragma mark -
         
void log_error( const char* format, ... )
{
    char buf[2048] = {0};
    va_list vaList;
    va_start( vaList, format );
    vsprintf( buf, format, vaList );
    va_end( vaList );
    
    time_t t = time(NULL);
    struct tm tm = *localtime(&t);
    
    if( s_logFile )
    {
        fprintf( s_logFile, "%d-%02d-%02d %02d:%02d:%02d: %s", tm.tm_year + 1900, tm.tm_mon + 1, tm.tm_mday, tm.tm_hour, tm.tm_min, tm.tm_sec, buf );
        fflush( s_logFile );
    }
    
    // print to debug as well...
    if( s_debug )
        printf( "%d-%02d-%02d %02d:%02d:%02d: %s", tm.tm_year + 1900, tm.tm_mon + 1, tm.tm_mday, tm.tm_hour, tm.tm_min, tm.tm_sec, buf );
    
    if( s_logFile && (timeGetTimeSec() > (s_last_log_roll + kLogRollInterval)) )
    {
        fclose( s_logFile );
        
        char* buffer = malloc( strlen( s_logFilePath ) + 10 );   // 8 date/time characters, a '.', and null byte
        if( buffer )
        {
            time_t t = time( NULL );
            struct tm tm = *localtime( &t );
            sprintf( buffer, "%s.%d%02d%02d", s_logFilePath, tm.tm_year + 1900, tm.tm_mon + 1, tm.tm_mday );
            
            // rename it
            if( rename( s_logFilePath, buffer ) != 0 )
                perror( "rename" );
            
            // now reopen new file and carry on
            s_logFile = fopen( s_logFilePath, "a" );
            free( buffer );
        }
        s_last_log_roll = timeGetTimeSec();
    }
}


void log_unix_error( const char* prefix )
{
    char buffer[512] = {0};
    strerror_r( errno, buffer, sizeof( buffer ) );
    
    char finalBuffer[1024] = {0};
    strcat( finalBuffer, prefix );
    strcat( finalBuffer, buffer );
    strcat( finalBuffer, "\n" );
    log_error( finalBuffer );
}



#pragma mark -

int init_socket_layer( frame_callback callback, status_callback status )
{
    if( s_read_thread )
        return EXIT_FAILURE;
    
    int err = ignoreSIGPIPE();
    if( err == 0 )
    {
        signal( SIGINT,  signalHandler );
        signal( SIGTERM, signalHandler );
        signal( SIGHUP,  signalHandler );
    }

    s_last_log_roll = timeGetTimeSec();
    if( s_logFilePath && !s_logFile )
    {
        s_logFile = fopen( s_logFilePath, "a" );
        if( !s_logFile )
            log_error( "  failed to open log file: %s\n", s_logFilePath );
        if( s_debug )
        {
            printf( "logging errors to: %s\n", s_logFilePath );
            
            time_t t = time(NULL);
            struct tm tm = *localtime(&t);
            
            if( s_logFile )
                fprintf( s_logFile, "%d-%02d-%02d %02d:%02d:%02d: %s, version %s -- kiss: %s:%d\n", tm.tm_year + 1900, tm.tm_mon + 1, tm.tm_mday, tm.tm_hour, tm.tm_min, tm.tm_sec, PROGRAM_NAME, VERSION, s_kiss_server, s_kiss_port );
        }
    }

        
    ReadThreadInfo* info = (ReadThreadInfo*)malloc( sizeof( ReadThreadInfo ) );
    if( !info )
        return EXIT_FAILURE;
    
    info->callback = callback;
    info->status   = status;

    s_read_thread_quit = false;
    s_read_thread = wx_create_thread_detached( tnc_read_thread, info );
    return EXIT_SUCCESS;
}


int shutdown_socket_layer()
{
    if( !s_read_thread )
        return EXIT_FAILURE;

    s_read_thread_quit = true;
    
    // wait for thread to exit? -- !!@ need timeout
    while( s_read_thread )
        sleep( 1 );
    
    return EXIT_SUCCESS;
}


#pragma mark -


wx_thread_return_t sendPacket_thread_entry( void* args )
{
    int         err          = 0;
    bool        success      = false;
    const char* packetToSend = (const char*)args;
    if( !packetToSend )
        wx_thread_return();

    if( s_test_mode )
    {
        log_error( "packet that would be sent: %s\n", packetToSend );
//        queue_packet( packetToSend );
//        success = true;
    }
    else
    {
        for( int i = 0; i < s_num_retries; i++ )
        {
            // send packet to APRS-IS directly...  oh btw, if you use this code, please get your own callsign and passcode!  PLEASE
            err = sendPacket( "noam.aprs2.net", 10152, kCallSign, kPasscode, packetToSend );
            if( err == 0 )
            {
                log_error( "sent:   %s\n", packetToSend );
                success = true;
                break;
            }
            
            // check for authentication error case and don't retry in that case, just queue the packet for the next server that accepts us
            if( err == -2 )
                break;

            log_error( "retry (%d/%d): (%d) %s\n", i + 1, s_num_retries, err, packetToSend );
        }
        
        if( !success )
        {
            // for packets that failed to send, we queue them up for the next time we send data
            queue_packet( packetToSend );
        }
    }
    
    free( (void*)packetToSend );
    
    // for the initial send, the code is super aggressive but for the packet queue, it's less so
    // we also don't want to try sending when we just got an error, so make sure we didn't just have a failure...
    if( success && !s_queue_busy  )
    {
        // see if there are any packets we should try sending
        const char* queued = NULL;
        do
        {
            queued = queue_get_next_packet();
            if( queued )
            {
                if( s_test_mode )
                    log_error( "queued packet that would be sent: %s\n", queued );
                else
                {
                    err = sendPacket( "noam.aprs2.net", 10152, kCallSign, kPasscode, queued );
                    if( err == 0 )
                        log_error( "resent: %s\n", queued );
                    else
                    {
                        // the idea behind this queue is it is sent to the main queue once it's empty on the next invocation
                        queue_error_packet( queued );
                    }
                    sleep( 1 ); // wait a second between each packet
                }
                free( (void*)queued );
            }
        } while( queued );
    }
    
    // !!@ need code to spill error queue into delayed queue !
    //
    wx_thread_return();
}


wx_thread_return_t sendToRadio_thread_entry( void* args )
{
    char* packetToSend = (char*)args;
    if( !packetToSend )
        wx_thread_return();
    
    // also send a packet to Direwolf running locally to hit the radio path...
    int err = sendToRadio( packetToSend, false );
    if( err != 0 )
        log_error( "failed to radio path, error: %d...\n", err );
    
    free( packetToSend );
    wx_thread_return();
}


wx_thread_return_t sendToRadioWIDE_thread_entry( void* args )
{
    char* packetToSend = (char*)args;
    if( !packetToSend )
        wx_thread_return();
    
    // also send a packet to Direwolf running locally to hit the radio path...
    int err = sendToRadio( packetToSend, true );
    if( err != 0 )
        log_error( "failed to WIDE radio path, error: %d...\n", err );
    
    free( packetToSend );
    wx_thread_return();
}




wx_thread_return_t tnc_read_thread( void* args )
{
    if( s_debug )
        printf( "%s, version %s, kiss: %s:%d, read thread started.\n", PROGRAM_NAME, VERSION, s_kiss_server, s_kiss_port );

    int server_sock = -1;
    ReadThreadInfo* info = (ReadThreadInfo*)args;
    if( !info )
    {
        log_error( "tnc_read_thread: have no data ref...\n" );
        goto exit_gracefully;
    }

    // connect to direwolf and send data
    server_sock = connectToDireWolf();
    if( server_sock < 0 )
    {
        log_error( "can't connect to direwolf...\n" );
        goto exit_gracefully;
    }

    if( info->status )
        info->status( true );

    while( !s_read_thread_quit )
        read_from_kiss_tnc( server_sock, info->callback );

exit_gracefully:
    shutdown( server_sock, 2 );
    close( server_sock );
    
    if( info && info->status )
        info->status( false );
    
    free( info );
    
    if( s_debug )
        printf( "tnc_read_thread thread done.\n" );
    
    s_read_thread = 0;
    wx_thread_return();
}

#pragma mark -


int sendToRadio( const char* p, bool wide )
{
    int result = 0;
    
    // do a bit of mangling to get the WIDE2-1 in there... figure out how much extra space we need...
    char buffer[1024] = {}; // note: largest allowable packet is 256
    if( wide )
    {
        strcpy( buffer, p );
        
        // find the TCPIP bit
        char* f = strstr( buffer, kIGPath );
        if( f )
        {
            // stomp over it -- note, this most likely stomped on part of the message if the two paths weren't the same length
            strcpy( f, kWidePath );
            
            size_t igPathLen   = strlen( kIGPath );
            size_t widePathLen = strlen( kWidePath );
             
            if( igPathLen != widePathLen )
            {
                // fix up the remaining part of the string... we know the offset of the tcpip string and the size of it, so offset the input string to get the remaining bit
                size_t offset = f - buffer;   // this points to TCPIP*
                offset += igPathLen;  // now points at message data
                f += widePathLen;
                
                // use that offset in the original packet to find message data to add to this fixed up message
                strcpy( f, &p[offset] );
            }
        }
        // if something went wrong, the original string was already copied to the buffer
    }
    else
    {
        strcpy( buffer, p );
    }

    if( s_test_mode )
    {
        log_error( "packet that would be sent to radio[%d]: %s\n", wide, p );
        return result;
    }

    // Parse the "TNC2 monitor format" and convert to AX.25 frame.
    unsigned char frame_data[AX25_MAX_PACKET_LEN];
    packet_t pp = ax25_from_text( buffer, 1 );
    if( pp != NULL )
    {
        int frame_len = ax25_pack( pp, frame_data );
        result = send_to_kiss_tnc( 0, KISS_CMD_DATA_FRAME, (char*)frame_data, frame_len );
        ax25_delete( pp );
    }
    else
    {
        log_error( "ERROR! Could not convert to AX.25 frame: %s\n", p );
        return -1;
    }
    return result;
}



/*-------------------------------------------------------------------
 *
 * Name:        send_to_kiss_tnc
 *
 * Purpose:     Encapsulate the data/command, into a KISS frame, and send to the TNC.
 *
 * Inputs:    chan    - channel number.
 *
 *        cmd    - KISS_CMD_DATA_FRAME, KISS_CMD_SET_HARDWARE, etc.
 *
 *        data    - Information for KISS frame.
 *
 *        dlen    - Number of bytes in data.
 *
 * Description:    Encapsulate as KISS frame and send to TNC.
 *
 *--------------------------------------------------------------------*/

int send_to_kiss_tnc( int chan, int cmd, char* data, int dlen )
{
    unsigned char temp[1000];
    unsigned char kissed[2000];
    int klen;
    int err = 0;

    if( chan < 0 || chan > 15 ) {
      log_error( "invalid channel %d - must be in range 0 to 15.\n", chan );
      chan = 0;
    }
    if( cmd < 0 || cmd > 15 ) {
      log_error( "invalid command %d - must be in range 0 to 15.\n", cmd );
      cmd = 0;
    }
    if( dlen < 0 || dlen > (int)(sizeof( temp ) - 1) ) {
      log_error( "invalid data length %d - must be in range 0 to %d.\n", dlen, (int)(sizeof( temp ) - 1) );
      dlen = sizeof( temp ) - 1;
    }

    temp[0] = (chan << 4) | cmd;
    memcpy( temp + 1, data, dlen );

    klen = kiss_encapsulate( temp, dlen + 1, kissed );
    
    // connect to direwolf and send data
    int server_sock = connectToDireWolf();
    if( server_sock < 0 )
    {
        log_error( "can't connect to direwolf...\n" );
        err = -1;
        goto exit_gracefully;
    }
    
    ssize_t rc = send( server_sock, (char*)kissed, klen, 0 );
    if( rc != klen )
    {
        log_error( "error writing KISS frame to socket.\n" );
        err = -1;
    }

exit_gracefully:
    shutdown( server_sock, 2 );
    close( server_sock );
    return err;
}


void callback( const char* data, int length )
{
    log_error( "callback: %d\n", length );
}


int read_from_kiss_tnc( int server_sock, frame_callback callback )
{
    uint8_t raw_buffer[BUFSIZE] = {};
    ssize_t bytesRead = recv( server_sock, raw_buffer, BUFSIZE, 0 );
    
    if( bytesRead > 0 )
    {
        kiss_frame_t kstate;
        memset( &kstate, 0, sizeof( kstate ) );

        for( int j = 0; j < bytesRead; j++ )
        {
          // Feed in one byte at a time.
          // kiss_process_msg is called when a complete frame has been accumulated.

          // When verbose is specified, we get debug output like this:
          //
          // <<< Data frame from KISS client application, port 0, total length = 46
          // 000:  c0 00 82 a0 88 ae 62 6a e0 ae 84 64 9e a6 b4 ff  ......bj...d....
          // ...
          // It says "from KISS client application" because it was written
          // on the assumption it was being used in only one direction.
          // Not worried enough about it to do anything at this time.
          kiss_rec_byte( &kstate, raw_buffer[j], false, 0, NULL, callback );
        }
    }
    
//    int err = 0;
//    if( bytesRead > 0 )
//    {
//        uint8_t unwrapped[AX25_MAX_PACKET_LEN] = {};
//        int len = kiss_unwrap( raw_buffer, (int)bytesRead, unwrapped );
//
//        if( !len )
//            log_error( "err: \n" );
//        else
//        {
//            char packetFormat = UNCOMPRESSED_PACKET;
//
//            // reuse raw_buffer now
//            printAPRSPacket( (APRSPacket*)&unwrapped, (char*)raw_buffer, packetFormat, 0, false );
////            ax25_safe_print( (char*)unwrapped, len, false );
//            log_error( "%s\n", raw_buffer );
//        }
//    }
    return 0;
}





// returns fd to use to communicate with
int connectToDireWolf( void )
{
    int              error              = 0;
    char             foundValidServerIP = 0;
    struct addrinfo* result             = NULL;
    struct addrinfo* results;
    int              socket_desc        = -1;

    error = getaddrinfo( s_kiss_server, NULL, NULL, &results );
    if( error != 0 )
    {
        if( error == EAI_SYSTEM )
        {
            log_unix_error( "connectToDireWolf:getaddrinfo: " );
        }
        else
        {
            log_error( "error in getaddrinfo: %s\n", s_kiss_server );
        }
        return error;
    }

    for( result = results; result != NULL; result = result->ai_next )
    {
        /* For readability later: */
        struct sockaddr* const addressinfo = result->ai_addr;

        socket_desc = socket( addressinfo->sa_family, SOCK_STREAM, IPPROTO_TCP );
        if( socket_desc < 0 )
        {
            log_unix_error( "connectToDireWolf:socket: " );
            continue; /* for loop */
        }

        /* Assign the port number. */
        switch (addressinfo->sa_family)
        {
            case AF_INET:
                ((struct sockaddr_in*)addressinfo)->sin_port   = htons( s_kiss_port );
                break;
            case AF_INET6:
                ((struct sockaddr_in6*)addressinfo)->sin6_port = htons( s_kiss_port );
                break;
        }

        if( connect( socket_desc, addressinfo, result->ai_addrlen ) >= 0 )
        {
            foundValidServerIP = 1;
            break; /* for loop */
        }
        else
        {
//            log_unix_error( "connectToDireWolf:connect: " );
            shutdown( socket_desc, 2 );
            close( socket_desc );
        }
    }
    freeaddrinfo( results );
    if( foundValidServerIP == 0 )
    {
        log_error( "connectToDireWolf: could not connect to the server.\n" );
        if( error )
            return error;
        else
            return -1;
    }

    return socket_desc;
}


#pragma mark -

// !!@ can probably make only one set of code but with parameterized queue info
void queue_packet( const char* packetData )
{
    if( s_queue_num >= kMaxQueueItems )
    {
        log_error( "queue is full, dropping: %s\n", packetData );
        return;
    }
    
    s_queue_busy = true;
    const char* entry = copy_string( packetData );
    s_queue[s_queue_num++] = entry;
    s_queue_busy = false;
    log_error( "queued: %s\n", packetData );
}


void queue_error_packet( const char* packetData )
{
//    if( s_error_bucket_num >= kMaxQueueItems )
//    {
//        log_error( "error queue is full, dropping: %s\n", packetData );
//        return;
//    }
    
    // avoid a memory leak until this is completely implemented... right now we don't have any direct evidence that we need this code at all
    log_error( "error bucket: dropping packet: %s\n", packetData );
    
//    s_error_bucket_busy = true;
//    const char* entry = copy_string( packetData );
//    s_error_bucket[s_error_bucket_num++] = entry;
//    s_error_bucket_busy = false;
//    log_error( "error queued: %s\n", entry );
}


const char* queue_get_next_packet( void )
{
    if( !s_queue_num )
        return NULL;

    if( s_queue_busy )
    {
        printf( "queue_get_next_packet queue busy!\n" );
        return NULL;
    }
    
    s_queue_busy = true;
    const char* result = s_queue[0];
    
    --s_queue_num;
    if( s_queue_num < 0 )
    {
        printf( "queue_get_next_packet underflow!\n" );
        s_queue_num = 0;
    }
    
    // now shift the entire list
    size_t queueSize = kMaxQueueItems;
    memmove( &s_queue[0], &s_queue[1], queueSize * sizeof( const char* ) );
    s_queue[queueSize] = NULL; // last item needs to be nulled out to be safe
    s_queue_busy = false;
    return result;
}

/*
const char* error_bucket_get_next_packet( void )
{
    if( !s_error_bucket_num || s_error_bucket_busy )
    {
        printf( "error_bucket_get_next_packet queue busy!\n" );
        return NULL;
    }

    if( !s_error_bucket_num || s_error_bucket_busy )
    {
        printf( "error_bucket_get_next_packet queue busy!\n" );
        return NULL;
    }
    
    s_error_bucket_busy = true;
    const char* result = s_error_bucket[0];
    
    --s_error_bucket_num;
    if( s_error_bucket_num < 0 )
    {
        printf( "error_bucket_get_next_packet underflow!\n" );
        s_error_bucket_num = 0;
    }

    // now shift the entire list
    size_t queueSize = kMaxQueueItems;
    memmove( &s_error_bucket[0], &s_error_bucket[1], queueSize * sizeof( const char* ) );
    s_error_bucket[queueSize] = NULL; // last item needs to be nulled out to be safe
    s_error_bucket_busy = false;
    return result;
}
*/
