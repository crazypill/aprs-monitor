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
    [encoder encodeFloat:_coordinate.latitude  forKey:@"latitude"];
    [encoder encodeFloat:_coordinate.longitude forKey:@"longitude"];
    
    [encoder encodeObject:_call      forKey:@"call"];
    [encoder encodeObject:_address   forKey:@"address"];
    [encoder encodeObject:_info      forKey:@"info"];
    [encoder encodeObject:_type      forKey:@"type"];
    [encoder encodeObject:_symbol    forKey:@"symbol"];
    [encoder encodeObject:_timeStamp forKey:@"timeStamp"];
}


- (id)initWithCoder:(NSCoder*)decoder
{
    if( self = [super init] )
    {
        _coordinate.latitude  = [decoder decodeFloatForKey:@"latitude"];
        _coordinate.longitude = [decoder decodeFloatForKey:@"longitude"];

        _call      = [decoder decodeObjectForKey:@"call"];
        _address   = [decoder decodeObjectForKey:@"address"];
        _info      = [decoder decodeObjectForKey:@"info"];
        _type      = [decoder decodeObjectForKey:@"type"];
        _symbol    = [decoder decodeObjectForKey:@"symbol"];
        _timeStamp = [decoder decodeObjectForKey:@"timeStamp"];
    }
    return self;
}


+ (_Nullable id)initWithCoordinates:(CLLocationCoordinate2D)coordinate
{
    Packet* us = [[Packet alloc] init];
    if( us )
        us.coordinate = coordinate;
    
    return us;
}


+ (_Nullable id)initWithRaw:(NSString*)rawstring
{
    Packet* us = [[Packet alloc] init];
    
    // this is where we would do all the parsing of the raw and stuff it into the appropriate fields... !!@
    
    return us;
}


- (_Nullable id)init
{
    self = [super init];
    if( self )
        self.timeStamp = [NSDate now];
    return self;
}



- (id)copyWithZone:(NSZone*)zone
{
    Packet* pkt = [[self class] allocWithZone:zone];

    pkt.coordinate = _coordinate;
    
    pkt.call      = [_call copyWithZone:zone];
    pkt.address   = [_address copyWithZone:zone];
    pkt.info      = [_info copyWithZone:zone];
    pkt.type      = [_type copyWithZone:zone];
    pkt.symbol    = [_symbol copyWithZone:zone];
    pkt.timeStamp = [_timeStamp copyWithZone:zone];
    return pkt;
}


- (NSString*)title
{
    return _call;
}


- (NSString*)subtitle
{
    return _address;
}




@end
