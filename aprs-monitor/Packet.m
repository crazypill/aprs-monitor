//
//  Packet.m
//
//  Created by Alex Lelievre on 8/11/20.
//  Copyright © 2020 Far Out Labs, LLC. All rights reserved.
//

#import "Packet.h"
#import "RemoteTNC.h"


#define kWindMask (kWxDataFlag_wind | kWxDataFlag_windDir | kWxDataFlag_gust)


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
    
    [encoder encodeObject:_call      forKey:@"call"];
    [encoder encodeObject:_address   forKey:@"address"];
    [encoder encodeObject:_info      forKey:@"info"];
    [encoder encodeObject:_type      forKey:@"type"];
    [encoder encodeObject:_symbol    forKey:@"symbol"];
    [encoder encodeObject:_comment   forKey:@"comment"];
    [encoder encodeObject:_weather   forKey:@"weather"];
    [encoder encodeObject:_timeStamp forKey:@"timeStamp"];
}


- (id)initWithCoder:(NSCoder*)decoder
{
    if( self = [super init] )
    {
        _flags                = [decoder decodeInt32ForKey:@"flags"];
        _coordinate.latitude  = [decoder decodeFloatForKey:@"latitude"];
        _coordinate.longitude = [decoder decodeFloatForKey:@"longitude"];

        _call      = [decoder decodeObjectForKey:@"call"];
        _address   = [decoder decodeObjectForKey:@"address"];
        _info      = [decoder decodeObjectForKey:@"info"];
        _type      = [decoder decodeObjectForKey:@"type"];
        _symbol    = [decoder decodeObjectForKey:@"symbol"];
        _comment   = [decoder decodeObjectForKey:@"comment"];
        _weather   = [decoder decodeObjectForKey:@"weather"];
        _timeStamp = [decoder decodeObjectForKey:@"timeStamp"];
    }
    return self;
}


- (id)copyWithZone:(NSZone*)zone
{
    Packet* pkt = [[self class] allocWithZone:zone];

    pkt.coordinate = _coordinate;
    pkt.flags      = _flags;
    pkt.call       = [_call copyWithZone:zone];
    pkt.address    = [_address copyWithZone:zone];
    pkt.info       = [_info copyWithZone:zone];
    pkt.type       = [_type copyWithZone:zone];
    pkt.symbol     = [_symbol copyWithZone:zone];
    pkt.comment    = [_comment copyWithZone:zone];
    pkt.weather    = [_weather copyWithZone:zone];
    pkt.timeStamp  = [_timeStamp copyWithZone:zone];
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

    char           addrs[AX25_MAX_ADDRS*AX25_MAX_ADDR_LEN] = {};    // Like source>dest,digi,...,digi:
    unsigned char* pinfo = NULL;

    ax25_format_addrs( packet, addrs );

    int info_len = ax25_get_info( packet, &pinfo );
    if( info_len )
    {
        NSLog( @"%s%s\n", addrs, pinfo );

        decode_aprs_t decode_state = {};
        decode_aprs( &decode_state, packet, true );
        
        // http://www.aprs.org/symbols/symbols-new.txt
        us.call    = [NSString stringWithUTF8String:decode_state.g_src];
        us.address = [NSString stringWithUTF8String:addrs];
        us.type    = [NSString stringWithUTF8String:decode_state.g_msg_type];
        us.info    = [NSString stringWithUTF8String:(const char*)pinfo];
        us.comment = [NSString stringWithUTF8String:decode_state.g_comment];
        us.symbol  = [NSString stringWithFormat:@"%c%c",decode_state.g_symbol_table,decode_state.g_symbol_code];
        
        // ok let's do some transcribing...
        if( (decode_state.g_flags & kDataFlag_Latitude) && (decode_state.g_flags & kDataFlag_Longitude) )
        {
            us.coordinate = CLLocationCoordinate2DMake( decode_state.g_lat, decode_state.g_lon );
            us.flags |= kPacketFlag_CoordinatesValid;
        }
        
        // I like to think about these strings as short summary strings...  until we add custom views, this works nicely.
        if( (decode_state.g_flags & kDataFlag_Course) && (decode_state.g_flags & kDataFlag_Speed) && decode_state.g_speed_mph != 0 )
        {
            us.flags |= kPacketFlag_CourseSpeed;
            us.course = [NSString stringWithFormat:@"Course: %.0f°  Speed: %.0f mph", decode_state.g_course, decode_state.g_speed_mph];
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
    
   if( _course.length )
       return _course;
    
    NSString* typeDebug = [NSString stringWithFormat:@"%@-%@",  _type, _address];
    return _comment.length ? _comment : typeDebug;
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
