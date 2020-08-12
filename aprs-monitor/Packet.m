//
//  Packet.m
//
//  Created by Alex Lelievre on 8/11/20.
//  Copyright © 2020 Far Out Labs, LLC. All rights reserved.
//

#import "Packet.h"




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


+ (_Nullable id)initWithCoordinates:(CLLocationCoordinate2D)coordinate
{
    Packet* us = [[Packet alloc] init];
    if( us )
    {
        us.coordinate = coordinate;
        us.flags |= kPacketFlag_CoordinatesValid;
    }
    
    return us;
}


+ (_Nullable id)initWithRaw:(const char*)rawstring address:(const char*)rawaddress
{
    Packet* us = [[Packet alloc] init];
    
    // this is where we would do all the parsing of the raw and stuff it into the appropriate fields...
    if( us )
        [us parse:rawstring address:rawaddress];
    
    return us;
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
        
        us.call    = [NSString stringWithUTF8String:decode_state.g_src];
        us.address = [NSString stringWithUTF8String:addrs];
        us.type    = [NSString stringWithUTF8String:decode_state.g_msg_type];
        us.info    = [NSString stringWithUTF8String:(const char*)pinfo];
        us.comment = [NSString stringWithUTF8String:decode_state.g_comment];
        us.weather = [NSString stringWithUTF8String:decode_state.g_weather];
        us.symbol  = [NSString stringWithFormat:@"%c",decode_state.g_symbol_code];
        
        // ok let's do some transcribing...
        if( decode_state.g_lat != G_UNKNOWN && decode_state.g_lon != G_UNKNOWN )
        {
            us.coordinate = CLLocationCoordinate2DMake( decode_state.g_lat, decode_state.g_lon );
            us.flags |= kPacketFlag_CoordinatesValid;
        }

           
//        A->g_symbol_table = '/';    /* Default to primary table. */
//        A->g_symbol_code = ' ';        /* What should we have for default symbol? */
//
//        A->g_speed_mph = G_UNKNOWN;
//        A->g_course = G_UNKNOWN;
//
//        A->g_power = G_UNKNOWN;
//        A->g_height = G_UNKNOWN;
//        A->g_gain = G_UNKNOWN;
//
//        A->g_range = G_UNKNOWN;
//        A->g_altitude_ft = G_UNKNOWN;
//        A->g_freq = G_UNKNOWN;
//        A->g_tone = G_UNKNOWN;
//        A->g_dcs = G_UNKNOWN;
//        A->g_offset = G_UNKNOWN;
//
//        A->g_footprint_lat = G_UNKNOWN;
//        A->g_footprint_lon = G_UNKNOWN;
//        A->g_footprint_radius = G_UNKNOWN;

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





- (NSString*)title
{
    return _call;
}


- (NSString*)subtitle
{
    if( _weather.length )
        return _weather;

    return [NSString stringWithFormat:@"%@ -> %@",  _type, _comment.length ? _comment : _address];
}


- (CLLocationDegrees)convertToDegrees:(NSString*)aprsPosition
{
    if( !aprsPosition )
        return 0.0;
    
    int degrees = 0;
    int minutes = 0;
    float hundredthsMinutes = 0;
    
    // check for latitude vs longitude
    if( aprsPosition.length == 7 )
    {
        degrees = [aprsPosition substringWithRange:NSMakeRange( 0, 2 )].intValue;
        minutes = [aprsPosition substringWithRange:NSMakeRange( 2, 2 )].intValue;
        hundredthsMinutes = [aprsPosition substringWithRange:NSMakeRange( 4, 3 )].floatValue;
    }
    else
    {
        degrees = [aprsPosition substringWithRange:NSMakeRange( 0, 3 )].intValue;
        minutes = [aprsPosition substringWithRange:NSMakeRange( 3, 2 )].intValue;
        hundredthsMinutes = [aprsPosition substringWithRange:NSMakeRange( 5, 3 )].floatValue;
    }
    
    // convert to seconds
    int seconds = hundredthsMinutes * 60.0f;
    
    float fraction = ((seconds / 60.0f) + minutes) / 60.0f;
    return degrees + fraction;
}


- (void)parse_position_data:(NSString*)raw_lat longitude:(NSString*)raw_long
{
    NSString* latitude = [raw_lat substringWithRange:NSMakeRange( 0, raw_lat.length - 1 )];
    if( latitude.length == 7 )
    {
        char n = [raw_lat characterAtIndex:7];

        NSString* longitude = [raw_long substringWithRange:NSMakeRange( 0, raw_long.length - 1 )];
        if( longitude.length >= 8 )
        {
            char w = [raw_long characterAtIndex:8];

            CLLocationDegrees lat = [self convertToDegrees:latitude];
            CLLocationDegrees lng = [self convertToDegrees:longitude];
            
            if( lng > 1 )
            {
                // flip sign to deal with East vs West
                if( w == 'W' || w == 'w' )
                    lng = -lng;

                if( n != 'N' && n != 'n' )
                    lat = -lat;

                _coordinate.latitude  = lat;
                _coordinate.longitude = lng;
                _flags |= kPacketFlag_CoordinatesValid;

//                [s_map_controller plotMessage:lat longitude:lng sender:address];
            }
        }
    }
}




- (void)parse:(const char*)rawstring address:(const char*)rawaddress
{
    NSString* info = [NSString stringWithUTF8String:rawstring];
    NSString* addr = [NSString stringWithUTF8String:rawaddress];

    // positions without timestamps
    if( [info characterAtIndex:0]  == '!' || [info characterAtIndex:0]  == '=' )
    {
        NSString* data = [info substringFromIndex:1];
        NSArray* listItems = [data componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"z/\\>_"]];
        
        if( listItems.count >= 2 )
        {
            [self parse_position_data:listItems[0] longitude:listItems[1]];
        }
    }


    // positions with timestamps
    if( [info characterAtIndex:0]  == '@' || [info characterAtIndex:0]  == '/' )
    {
        NSString* data = [info substringFromIndex:1];
        NSArray* listItems = [data componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"z/\\>_"]];
        
        if( listItems.count >= 3 )
        {
            [self parse_position_data:listItems[1] longitude:listItems[2]];
        }
    }

    // get sender's callsign
    NSArray* addressComponents = [addr componentsSeparatedByString:@">"];
    if( addressComponents.count >= 1 )
        _call = addressComponents.firstObject;
    
    // store the entire packet data
    _address = addr;
    _info = info;
}




@end
