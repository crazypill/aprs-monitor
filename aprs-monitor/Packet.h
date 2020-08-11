//
//  MeetItem.h
//
//  Created by Alex Lelievre on 8/11/20.
//  Copyright © 2020 Far Out Labs, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MKMapView.h>



@interface Packet : NSObject <MKAnnotation, NSCoding, NSCopying>

@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic, readonly, copy, nullable) NSString* title;
@property (nonatomic, readonly, copy, nullable) NSString* subtitle;

@property (nonatomic, copy, nullable) NSString* call;
@property (nonatomic, copy, nullable) NSString* address;
@property (nonatomic, copy, nullable) NSString* info;
@property (nonatomic, copy, nullable) NSString* type;
@property (nonatomic, copy, nullable) NSString* symbol;
@property (nonatomic, copy, nullable) NSDate*   timeStamp;

+ (_Nullable id)initWithCoordinates:(CLLocationCoordinate2D)coordinate;
+ (_Nullable id)initWithRaw:(NSString*)rawstring;

@end

