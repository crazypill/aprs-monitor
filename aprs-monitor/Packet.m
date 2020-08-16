//
//  Packet.m
//
//  Created by Alex Lelievre on 8/11/20.
//  Copyright © 2020 Far Out Labs, LLC. All rights reserved.
//

#import "Packet.h"
#import "RemoteTNC.h"




// eventually this will be hooked up to routines that can be called that set this from settings or prefs. !!@
static bool s_displayC    = false;
static bool s_displayMmHg = false;
// also add m/s option for wind speeds


@implementation Packet


-(void)encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeInt32:_flags                forKey:@"flags"];
    [encoder encodeFloat:_coordinate.latitude  forKey:@"latitude"];
    [encoder encodeFloat:_coordinate.longitude forKey:@"longitude"];
    
    [encoder encodeObject:_call        forKey:@"call"];
    [encoder encodeObject:_address     forKey:@"address"];
    [encoder encodeObject:_destination forKey:@"destination"];
    [encoder encodeObject:_path        forKey:@"path"];
    [encoder encodeObject:_info        forKey:@"info"];
    [encoder encodeObject:_type        forKey:@"type"];
    [encoder encodeObject:_symbol      forKey:@"symbol"];
    [encoder encodeObject:_comment     forKey:@"comment"];
    [encoder encodeObject:_weather     forKey:@"weather"];  // this can be generated by the wxdata, might be best to remove !!@
    [encoder encodeObject:_course      forKey:@"course"];
    [encoder encodeObject:_speed       forKey:@"speed"];
    [encoder encodeObject:_timeStamp   forKey:@"timeStamp"];
    
    // encode wx data as binary blob
    if( _wx )
        [encoder encodeObject:[NSData dataWithBytes:_wx length:sizeof( wx_data )] forKey:@"wxdata"];
}


- (id)initWithCoder:(NSCoder*)decoder
{
    if( self = [super init] )
    {
        // !!@ add missing items
        _flags                = [decoder decodeInt32ForKey:@"flags"];
        _coordinate.latitude  = [decoder decodeFloatForKey:@"latitude"];
        _coordinate.longitude = [decoder decodeFloatForKey:@"longitude"];

        _call        = [decoder decodeObjectForKey:@"call"];
        _address     = [decoder decodeObjectForKey:@"address"];
        _destination = [decoder decodeObjectForKey:@"destination"];
        _path        = [decoder decodeObjectForKey:@"path"];
        _info        = [decoder decodeObjectForKey:@"info"];
        _type        = [decoder decodeObjectForKey:@"type"];
        _symbol      = [decoder decodeObjectForKey:@"symbol"];
        _comment     = [decoder decodeObjectForKey:@"comment"];
        _weather     = [decoder decodeObjectForKey:@"weather"];
        _course      = [decoder decodeObjectForKey:@"course"];
        _speed       = [decoder decodeObjectForKey:@"speed"];
        _timeStamp   = [decoder decodeObjectForKey:@"timeStamp"];

        NSData* wxdata = [decoder decodeObjectForKey:@"wxdata"];
        if( wxdata )
        {
            _wx = malloc( wxdata.length );
            if( _wx )
                memcpy( _wx, wxdata.bytes, wxdata.length );
        }
    }
    return self;
}


- (id)copyWithZone:(NSZone*)zone
{
    Packet* pkt = [[self class] allocWithZone:zone];

    pkt.coordinate  = _coordinate;
    pkt.flags       = _flags;
    pkt.call        = [_call copyWithZone:zone];
    pkt.address     = [_address copyWithZone:zone];
    pkt.destination = [_destination copyWithZone:zone];
    pkt.path        = [_path copyWithZone:zone];
    pkt.info        = [_info copyWithZone:zone];
    pkt.type        = [_type copyWithZone:zone];
    pkt.symbol      = [_symbol copyWithZone:zone];
    pkt.comment     = [_comment copyWithZone:zone];
    pkt.weather     = [_weather copyWithZone:zone];
    pkt.course      = [_course copyWithZone:zone];
    pkt.speed       = [_speed copyWithZone:zone];
    pkt.timeStamp   = [_timeStamp copyWithZone:zone];
    
    if( _wx )
    {
        pkt.wx = malloc( sizeof( wx_data ) );
        if( pkt.wx )
            memcpy( pkt.wx, _wx, sizeof( wx_data ) );
    }
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




+ (_Nullable id)initWithPacket_t:(packet_t)packet
{
    Packet* us = [[Packet alloc] init];
    if( !us )
        return nil;

    unsigned char* pinfo = NULL;


    int info_len = ax25_get_info( packet, &pinfo );
    if( info_len )
    {
        char addrs[AX25_MAX_ADDRS*AX25_MAX_ADDR_LEN] = {};    // Like source>dest,digi,...,digi:
        ax25_format_addrs( packet, addrs );
        NSLog( @"%s%s\n", addrs, pinfo );
        
        decode_aprs_t decode_state = {};
        decode_aprs( &decode_state, packet, true );
        
        char dest[AX25_MAX_ADDR_LEN] = {};
        ax25_get_addr_with_ssid( packet, AX25_DESTINATION, dest );
        
        // http://www.aprs.org/symbols/symbols-new.txt
        us.call        = [NSString stringWithUTF8String:decode_state.g_src];
        us.address     = [NSString stringWithUTF8String:addrs];
        us.destination = [NSString stringWithUTF8String:dest];
        us.type        = [NSString stringWithUTF8String:decode_state.g_msg_type];
        us.info        = [NSString stringWithUTF8String:(const char*)pinfo];
        us.symbol      = [NSString stringWithFormat:@"%c%c",decode_state.g_symbol_table,decode_state.g_symbol_code];

        if( (decode_state.g_flags & kDataFlag_Comment) && strlen( decode_state.g_comment ) )
            us.comment = [NSString stringWithUTF8String:decode_state.g_comment];
        
        addrs[0] = 0;   // clear buffer lazy way
        ax25_format_via_path( packet, addrs, sizeof( addrs ) );
        us.path = [NSString stringWithUTF8String:addrs];
        
        // ok let's do some transcribing...
        if( (decode_state.g_flags & kDataFlag_Latitude) && (decode_state.g_flags & kDataFlag_Longitude) )
        {
            us.coordinate = CLLocationCoordinate2DMake( decode_state.g_lat, decode_state.g_lon );
            us.flags |= (kPacketFlag_Latitude | kPacketFlag_Longitude);
        }
        
        // I like to think about these strings as short summary strings...  until we add custom views, this works nicely.
        if( (decode_state.g_flags & kDataFlag_Course) && (decode_state.g_flags & kDataFlag_Speed) && decode_state.g_speed_mph != 0 )
        {
            us.flags |= (kPacketFlag_Course | kPacketFlag_Speed);
            us.course = [NSString stringWithFormat:@"Course: %.0f°",   decode_state.g_course];
            us.speed  = [NSString stringWithFormat:@"Speed: %.0f mph", decode_state.g_speed_mph];
        }
        
        if( decode_state.g_wxdata.wxflags )
        {
            // just outright copy the entire wx record
            us.wx = malloc( sizeof( wx_data ) );
            if( us.wx )
            {
                memcpy( us.wx, &decode_state.g_wxdata, sizeof( wx_data ) );
                us.flags |= kPacketFlag_Weather;
            }
            
            us.weather = [Packet makeWeatherString:&decode_state.g_wxdata];
        }
    }
    
    return us;
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
    if( _weather.length )
        return _weather;

    if( _course.length && _speed.length )
        return [NSString stringWithFormat:@"%@   %@",  _course, _speed];

    if( _course.length )
       return _course;

    if( _speed.length )
        return _speed;

//    NSString* typeDebug = [NSString stringWithFormat:@"%@-%@",  _type, _path];
//    return _comment.length ? _comment : typeDebug;

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
