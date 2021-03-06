//
//  Packet.m
//
//  Created by Alex Lelievre on 8/11/20.
//  Copyright © 2020 Far Out Labs, LLC. All rights reserved.
//

#import "Packet.h"
#import "RemoteTNC.h"

#ifdef DEBUG
#define DEBUG_LOG_PACKET
#endif


// eventually this will be hooked up to routines that can be called that set this from settings or prefs. !!@
static bool s_displayC    = false;
static bool s_displayMmHg = false;
// also add m/s option for wind speeds


@implementation Packet


-(void)encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeObject:_timeStamp forKey:@"timeStamp"];
    
    // encode packet data as binary blob
    if( _raw )
        [encoder encodeObject:_raw forKey:@"raw"];
}


- (id)initWithCoder:(NSCoder*)decoder
{
    if( self = [super init] )
    {
        _raw         = [decoder decodeObjectForKey:@"raw"];
        _timeStamp   = [decoder decodeObjectForKey:@"timeStamp"];
        
        [self configurePacketFromData:_raw];
    }
    return self;
}


- (id)copyWithZone:(NSZone*)zone
{
    Packet* pkt = [[self class] allocWithZone:zone];

    [pkt configurePacketFromData:_raw];
    pkt.timeStamp = [_timeStamp copyWithZone:zone];
    return pkt;
}


+ (NSString*)string:(NSString*)string byTrimmingTrailingCharactersInSet:(NSCharacterSet*)characterSet
{
    NSRange rangeOfLastWantedCharacter = [string rangeOfCharacterFromSet:[characterSet invertedSet] options:NSBackwardsSearch];
    if( rangeOfLastWantedCharacter.location == NSNotFound )
        return @"";
    
    return [string substringToIndex:rangeOfLastWantedCharacter.location + 1]; // non-inclusive
}


+ (NSString*)stringByTrimmingTrailingWhitespaceAndNewlineCharacters:(NSString*)string
{
    return [Packet string:string byTrimmingTrailingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}



+ (_Nullable id)initWithData:(NSData*)data
{
    if( !data )
        return nil;

    Packet* us = [[Packet alloc] init];
    if( !us )
        return nil;
    
    [us configurePacketFromData:data];
    return us;
}


- (bool)configurePacketFromData:(NSData*)data
{
    if( !data )
        return false;
    
    unsigned char* msg    = (unsigned char*)[data bytes];
    int            length = (int)data.length;
    alevel_t       alevel;

    memset( &alevel, 0, sizeof( alevel ) );
    packet_t packet = ax25_from_frame( msg, length, alevel );
    if( packet == NULL )
    {
        NSLog( @"invalid data frame from TNC\n" );
        return false;
    }

    unsigned char* pinfo = NULL;
    int info_len = ax25_get_info( packet, &pinfo );
    if( info_len )
    {
        char addrs[AX25_MAX_ADDRS * AX25_MAX_ADDR_LEN] = {};    // Like source>dest,digi,...,digi:
        ax25_format_addrs( packet, addrs );

#ifdef DEBUG_LOG_PACKET
        NSLog( @"%s%s\n", addrs, pinfo );
#endif
        decode_aprs_t decode_state = {};
        decode_aprs( &decode_state, packet, true );
        
        char dest[AX25_MAX_ADDR_LEN] = {};
        ax25_get_addr_with_ssid( packet, AX25_DESTINATION, dest );
        
        // http://www.aprs.org/symbols/symbols-new.txt
        _call        = [NSString stringWithUTF8String:decode_state.g_src];
        _address     = [NSString stringWithUTF8String:addrs];
        _destination = [NSString stringWithUTF8String:dest];
        _type        = [NSString stringWithUTF8String:decode_state.g_msg_type];
        _info        = [NSString stringWithUTF8String:(const char*)pinfo];
        _symbol      = [NSString stringWithFormat:@"%c%c",decode_state.g_symbol_table,decode_state.g_symbol_code];
        _raw         = data;

        if( (decode_state.g_flags & kDataFlag_Comment) && strlen( decode_state.g_comment ) )
            _comment = [NSString stringWithUTF8String:decode_state.g_comment];
        
        addrs[0] = 0;   // clear buffer lazy way
        ax25_format_via_path( packet, addrs, sizeof( addrs ) );
        _path = [NSString stringWithUTF8String:addrs];
        
        // ok let's do some transcribing...
        if( (decode_state.g_flags & kDataFlag_Latitude) && (decode_state.g_flags & kDataFlag_Longitude) )
        {
            _coordinate = CLLocationCoordinate2DMake( decode_state.g_lat, decode_state.g_lon );
            _flags |= (kPacketFlag_Latitude | kPacketFlag_Longitude);
        }
        
        if( decode_state.g_flags & kDataFlag_Course )
        {
            _flags |= kPacketFlag_Course;
            _course = decode_state.g_course;
        }

        if( decode_state.g_flags & kDataFlag_Speed )
        {
            _flags |= kPacketFlag_Speed;
            _speed  = decode_state.g_speed_mph;
        }
        
        if( decode_state.g_flags & kDataFlag_Altitude )
        {
            _flags |= kPacketFlag_Altitude;
            _altitude = decode_state.g_altitude_ft;
        }

        if( decode_state.g_flags & kDataFlag_Power )
        {
            _flags |= kPacketFlag_Power;
            _power = decode_state.g_power;
        }

        if( decode_state.g_flags & kDataFlag_Height )
        {
            _flags |= kPacketFlag_Height;
            _height = decode_state.g_height;
        }

        if( decode_state.g_flags & kDataFlag_Gain )
        {
            _flags |= kPacketFlag_Gain;
            _gain = decode_state.g_gain;
        }

        if( decode_state.g_flags & kDataFlag_Range )
        {
            _flags |= kPacketFlag_Range;
            _range = decode_state.g_range;
        }

        if( decode_state.g_wxdata.wxflags )
        {
            // just outright copy the entire wx record
            _wx = malloc( sizeof( wx_data ) );
            if( _wx )
            {
                memcpy( _wx, &decode_state.g_wxdata, sizeof( wx_data ) );
                _flags |= kPacketFlag_Weather;
            }
            
            _weather = [Packet makeWeatherString:&decode_state.g_wxdata];
        }
    }

    ax25_delete( packet );
    return true;
}



- (_Nullable id)init
{
    self = [super init];
    if( self )
        self.timeStamp = [NSDate now];
    return self;
}


- (void)dealloc
{
    if( _wx )
        free( _wx );
}


- (NSString*)title
{
    return _call;
}


- (NSString*)subtitle
{
    const char* compass[] = { "N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW" };

    if( _weather.length )
        return _weather;

    if( (_flags & kPacketFlag_Course) && (_flags & kPacketFlag_Speed) && _speed != 0.0f )
    {
        int dir = (int)(_course / 22.5f); // truncate
        return [NSString stringWithFormat:@"Course: %.0f° %s  Speed: %.0f mph",  _course, compass[dir], _speed];
    }
    
    // just return comment, course isn't important when you aren't moving...
    if( (_flags & kPacketFlag_Course) && _comment.length )
        return _comment;

    // perhaps course & altitude
    if( (_flags & kPacketFlag_Altitude) && (_flags & kPacketFlag_Course) )
    {
        int dir = (int)(_course / 22.5f); // truncate
        return [NSString stringWithFormat:@"Course: %.0f° %s  Altitude: %.0f ft", _course, compass[dir], _altitude];
    }
    
    // perhaps altitude and comment
    if( (_flags & kPacketFlag_Altitude) && _comment.length )
        return [NSString stringWithFormat:@"Altitude: %.0f feet  %@", _altitude, _comment];
    
    // solo stuff
    if( _flags & kPacketFlag_Course )
    {
        int dir = (int)(_course / 22.5f); // truncate
        return [NSString stringWithFormat:@"Course: %.0f° %s", _course, compass[dir]];
    }
    
    if( _flags & kPacketFlag_Speed && _speed != 0.0f && _comment.length )
        return [NSString stringWithFormat:@"Speed: %.0f mph  %@", _speed, _comment];

    if( _flags & kPacketFlag_Speed && _speed != 0.0f )
        return [NSString stringWithFormat:@"Speed: %.0f mph", _speed];

    if( (_flags & kPacketFlag_Altitude) )
        return [NSString stringWithFormat:@"Altitude: %.0f feet", _altitude];

    return _comment.length ? _comment : _path;
}


// this is the short string used when we don't have rain data, etc...  it's just a short string...
+ (NSString*)makeWeatherString:(wx_data*)wxdata
{
    // form weather string in the order we want
    NSString* wx = [[NSString alloc] init];
    if( wxdata->wxflags & kWxDataFlag_temp )
    {
        if( s_displayC )
            wx = [wx stringByAppendingFormat:@"🌡%.0f°C ", f2c( wxdata->tempF )];
        else
            wx = [wx stringByAppendingFormat:@"🌡%.0f°F ", wxdata->tempF];
    }
    
    if( wxdata->wxflags & kWxDataFlag_humidity )
        wx = [wx stringByAppendingFormat:@"💧%.2d%% ", wxdata->humidity];
    
    if( wxdata->wxflags & kWxDataFlag_pressure )
    {
        if( s_displayMmHg )
            wx = [wx stringByAppendingFormat:@"🔻%.0f mmHg ", wxdata->pressure];
        else
            wx = [wx stringByAppendingFormat:@"🔻%.2f InHg ", wxdata->pressure * millibar2inchHg];
    }

    return [Packet stringByTrimmingTrailingWhitespaceAndNewlineCharacters:wx];
}


- (UIImage* _Nullable)getWindIndicatorIcon:(CGRect)imageBounds
{
    // see if we have any weather info
    if( !(_flags & kPacketFlag_Weather) || !_wx )
        return nil;
    
    // if we have no wind flags at all, we should bail and use the default icon instead (rather than draw empty circles)
    if( !(_wx->wxflags & kWindMask) )
        return nil;
    
    UIGraphicsBeginImageContextWithOptions( imageBounds.size, false, 0.0f );
    CGContextRef myContext = UIGraphicsGetCurrentContext();
    CGContextClearRect( myContext, imageBounds );
    
    // create HSV color so we can make the spectrum rainbow colored
    CGColorRef cgColor = NULL;

    CGFloat xCenter = imageBounds.size.width  * 0.5f;
    CGFloat yCenter = imageBounds.size.height * 0.5f;
    CGFloat r       = imageBounds.size.height * 0.5f;
    
    // this code used to draw a rainbow which is why it draws slivers instead of a shape.  !!@ fix this
    CGFloat oversampling   = 4.0f;
    CGFloat centerDiameter = imageBounds.size.width * 0.76f;
    CGRect  circleRect     = CGRectMake( xCenter - (centerDiameter * 0.5f), yCenter - (centerDiameter * 0.5f), centerDiameter, centerDiameter );
    CGRect  clipRect       = CGRectInset( imageBounds, 1, 1 );

    CGContextSaveGState( myContext );
    CGContextSetBlendMode( myContext, kCGBlendModeOverlay );

    if( _wx->wxflags & kWxDataFlag_windDir )
    {
        int indicatorWidth = 12; // in degrees
        int windDirection = _wx->windDirection;
        
        [[[UIColor redColor] colorWithAlphaComponent:0.01] setStroke];

        for( int i = 0; i < indicatorWidth * oversampling; i++ )
        {
            // convert from math to compass orientation
            int degrees = 90 + (360 - windDirection);
            // offset the marker so that it is centered about its target
            int offset = (i + (degrees * oversampling)) - ((indicatorWidth * oversampling) / 2);

            // convert from degrees to radians
            CGFloat rs = r * sin( (offset / oversampling) * M_PI / 180.0f );
            CGFloat rc = r * cos( (offset / oversampling) * M_PI / 180.0f );
            CGFloat x  = xCenter + rc;
            CGFloat y  = yCenter - rs;

            CGContextBeginPath( myContext );
            CGContextMoveToPoint( myContext, xCenter, yCenter );
            CGContextAddLineToPoint( myContext, x, y );
            CGContextStrokePath( myContext );
        }

        // fill in the middle part with white alpha - this (if it worked) would make the red more consistent (right now it's less transparent near the center) !!@
//        [[UIColor colorWithWhite:1.0f alpha:0.6f] setFill];
//        CGContextBeginPath( myContext );
//        CGContextAddEllipseInRect( myContext, clipRect );
//        CGContextFillPath( myContext );
        
        // clip to the inside of that double line
        CGContextBeginPath( myContext );
        CGContextAddEllipseInRect( myContext, clipRect );
        CGContextAddEllipseInRect( myContext, circleRect );
        CGContextEOClip( myContext );
        
        // we color over the line so much that a 0.05 alpha will look almost opaque
        [[[UIColor redColor] colorWithAlphaComponent:0.05] setStroke];

        // re-draw the end bit so it's darker
        for( int i = 0; i < indicatorWidth * oversampling; i++ )
        {
            // convert from math to compass orientation
            int degrees = 90 + (360 - windDirection);
            // offset the marker so that it is centered about its target
            int offset = (i + (degrees * oversampling)) - ((indicatorWidth * oversampling) / 2);

            // convert from degrees to radians
            CGFloat rs = r * sin( (offset / oversampling) * M_PI / 180.0f );
            CGFloat rc = r * cos( (offset / oversampling) * M_PI / 180.0f );
            CGFloat x  = xCenter + rc;
            CGFloat y  = yCenter - rs;

            CGContextBeginPath( myContext );
            CGContextMoveToPoint( myContext, xCenter, yCenter );
            CGContextAddLineToPoint( myContext, x, y );
            CGContextStrokePath( myContext );
        }
        CGContextResetClip( myContext );
    }
    
    // draw double outline
    centerDiameter = imageBounds.size.width * 0.75f;
    circleRect     = CGRectMake( xCenter - (centerDiameter * 0.5f), yCenter - (centerDiameter * 0.5f), centerDiameter, centerDiameter );
    clipRect       = CGRectInset( imageBounds, 0.5, 0.5 );
    
    CGContextBeginPath( myContext );
    CGContextAddEllipseInRect( myContext, clipRect );
    CGContextAddEllipseInRect( myContext, circleRect );
    cgColor = [UIColor grayColor].CGColor;
    CGContextSetStrokeColorWithColor( myContext, cgColor );
    CGContextStrokePath( myContext );

    NSMutableParagraphStyle* paragraph = [[NSMutableParagraphStyle alloc] init];
    paragraph.alignment = NSTextAlignmentCenter;
    
    // draw the text in the center
    centerDiameter = 18;
    CGFloat fontSize = 8;
    CGFloat padding  = 2;
    CGRect  textRect = CGRectMake( xCenter - (centerDiameter * 0.5f), yCenter - (centerDiameter * 0.55f), centerDiameter, fontSize + padding );

    if( _wx->wxflags & kWxDataFlag_wind )
    {
        [[NSString stringWithFormat:@"%0.f", _wx->windSpeedMph] drawInRect:textRect withAttributes:@{
            NSFontAttributeName : [UIFont systemFontOfSize:8],
            NSParagraphStyleAttributeName : paragraph,
            NSForegroundColorAttributeName : [UIColor labelColor]
        }];
    }
    
    if( _wx->wxflags & kWxDataFlag_gust )
    {
        textRect.origin.y += fontSize + padding;
        [[NSString stringWithFormat:@"%0.f", _wx->windGustMph] drawInRect:textRect withAttributes:@{
            NSFontAttributeName : [UIFont systemFontOfSize:8],
            NSParagraphStyleAttributeName : paragraph,
            NSForegroundColorAttributeName : [UIColor secondaryLabelColor]
        }];
    }
    
    CGContextRestoreGState( myContext );

    UIImage* resultImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return resultImage;
}


@end
