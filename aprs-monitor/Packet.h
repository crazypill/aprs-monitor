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
    kPacketFlag_CoordinatesValid = 1 << 0,
    kPacketFlag_Weather          = 1 << 1,
    kPacketFlag_CourseSpeed      = 1 << 2
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
@property (nonatomic, copy, nullable) NSString* comment;
@property (nonatomic, copy, nullable) NSString* weather;
@property (nonatomic, copy, nullable) NSString* course;
@property (nonatomic, copy, nullable) NSDate*   timeStamp;
@property (nonatomic, nullable)       wx_data*  wx;


+ (_Nullable id)initWithPacket_t:(packet_t _Nullable)packet;
+ (NSString*)makeWeatherString:(wx_data*)wxdata;

- (UIImage* _Nullable)getWindIndicatorIcon:(CGRect)imageBounds;

@end

