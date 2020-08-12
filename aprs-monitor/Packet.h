//
//  Packet.h
//
//  Created by Alex Lelievre on 8/11/20.
//  Copyright © 2020 Far Out Labs, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MKMapView.h>

#include "decode_aprs.h"  // Direwolf


enum
{
    kPacketFlag_CoordinatesValid = 1 << 0
};


@interface Packet : NSObject <MKAnnotation, NSCoding, NSCopying>

@property (nonatomic) uint8_t                             flags;
@property (nonatomic) CLLocationCoordinate2D              coordinate;
@property (nonatomic, readonly, copy, nullable) NSString* title;
@property (nonatomic, readonly, copy, nullable) NSString* subtitle;

@property (nonatomic, copy, nullable) NSString* call;
@property (nonatomic, copy, nullable) NSString* address;
@property (nonatomic, copy, nullable) NSString* info;
@property (nonatomic, copy, nullable) NSString* type;
@property (nonatomic, copy, nullable) NSString* symbol;
@property (nonatomic, copy, nullable) NSDate*   timeStamp;

+ (_Nullable id)initWithCoordinates:(CLLocationCoordinate2D)coordinate;
+ (_Nullable id)initWithRaw:(const char* _Nullable)rawstringUTF8 address:(const char* _Nullable)rawaddressUTF8;
+ (_Nullable id)initWithPacket_t:(packet_t _Nullable)packet;

@end

