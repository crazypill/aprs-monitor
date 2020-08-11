//
//  ViewController.m
//  aprs-monitor
//
//  Created by Alex Lelievre on 8/10/20.
//  Copyright © 2020 Alex Lelievre. All rights reserved.
//

#import "ViewController.h"

#include "main.h"


static MapViewController* s_map_controller = nil;


@interface CustomAnnotation : NSObject <MKAnnotation>

@property (nonatomic) CLLocationCoordinate2D coordinate;

- (id)init:(CLLocationCoordinate2D)coordinate;
@end


@implementation CustomAnnotation

- (id)init:(CLLocationCoordinate2D)coordinate
{
    self = [super init];
    
    if( self )
        self.coordinate = coordinate;
        
    return self;
}

@end




@interface CustomAnnotationView : MKAnnotationView
@end


@implementation CustomAnnotationView
@end







void map_callback( const char* address, const char* frameData )
{
    NSLog( @"%s%s\n", address, frameData );
    
    NSString* info = [NSString stringWithUTF8String:frameData];
    
    if( [info characterAtIndex:0]  == '!' )
    {
        NSString* data = [info substringFromIndex:1];
        NSArray* listItems = [data componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"z/\\>_"]];
//        NSLog( @"%@\n", listItems );
        
        if( listItems.count >= 2 )
        {
            NSString* raw      = listItems[0];
            NSRange   trim     = NSMakeRange( 0, raw.length - 1 );
            NSString* latitude = [raw substringWithRange:trim];
            char n = [raw characterAtIndex:raw.length - 1];

            raw      = listItems[1];
            trim     = NSMakeRange( 0, raw.length - 1 );
            NSString* longitude = [raw substringWithRange:trim];
            char w = [raw characterAtIndex:raw.length - 1];

            CLLocationDegrees lat = latitude.doubleValue / 100;
            CLLocationDegrees lng = longitude.doubleValue / 100;
            
            if( s_map_controller && lng > 1 )
            {
//                NSLog( @"lat: %0.4f%c, %0.4f%c\n", lat, n, lng, w );
                [s_map_controller plotMessage:lat longitude:lng];
            }
        }
    }


    if( [info characterAtIndex:0]  == '@' )
    {
        NSString* data = [info substringFromIndex:1];
        NSArray* listItems = [data componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"z/\\>_"]];
//        NSLog( @"%@\n", listItems );
        
        if( listItems.count >= 3 )
        {
            NSString* raw      = listItems[1];
            NSRange   trim     = NSMakeRange( 0, raw.length - 1 );
            NSString* latitude = [raw substringWithRange:trim];
            char n = [raw characterAtIndex:raw.length - 1];

            raw      = listItems[2];
            trim     = NSMakeRange( 0, raw.length - 1 );
            NSString* longitude = [raw substringWithRange:trim];
            char w = [raw characterAtIndex:raw.length - 1];

            CLLocationDegrees lat = latitude.doubleValue / 100;
            CLLocationDegrees lng = longitude.doubleValue / 100;
            
            if( s_map_controller && lng > 1 )
            {
//                NSLog( @"lat: %0.4f%c, %0.4f%c\n", lat, n, lng, w );
                [s_map_controller plotMessage:lat longitude:lng];
            }
        }
    }
}




@interface MapViewController ()

@end



@implementation MapViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    s_map_controller = self;
    
     [self.mapView registerClass:[CustomAnnotationView class] forAnnotationViewWithReuseIdentifier:NSStringFromClass( [CustomAnnotation class] )];

    // Do any additional setup after loading the view
    init_socket_layer( map_callback );
}



- (void)plotMessage:(CLLocationDegrees)latitude longitude:(CLLocationDegrees)longitude
{
    NSLog( @"plotMessage lat: %0.4f, %0.4f\n", latitude, longitude );
    
    CLLocationCoordinate2D coord = {.latitude = latitude, .longitude = longitude };
    CustomAnnotation* annotation = [[CustomAnnotation alloc] init: coord];
    
    [_mapView addAnnotations:@[annotation]];
}


- (nullable MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    return [mapView dequeueReusableAnnotationViewWithIdentifier:NSStringFromClass( [CustomAnnotation class] ) forAnnotation:annotation];
}

@end
