//
//  ViewController.m
//  aprs-monitor
//
//  Created by Alex Lelievre on 8/10/20.
//  Copyright © 2020 Alex Lelievre. All rights reserved.
//

#import "ViewController.h"
#import "MapKit/MKMarkerAnnotationView.h"

#include "main.h"


static MapViewController* s_map_controller = nil;
static bool               s_have_location  = false;

@interface CustomAnnotation : NSObject <MKAnnotation>

@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic, copy, nullable) NSString* title;
@property (nonatomic, copy, nullable) NSString* subtitle;

- (id)init:(CLLocationCoordinate2D)coordinate;
@end


@implementation CustomAnnotation

- (id)init:(CLLocationCoordinate2D)coordinate
{
    self = [super init];
    
    if( self )
        self.coordinate = coordinate;
    
//    _title = @"Test";
//    _subtitle = @"subtitle";

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
    
    // positions without timestamps
    if( [info characterAtIndex:0]  == '!' || [info characterAtIndex:0]  == '=' )
    {
        NSString* data = [info substringFromIndex:1];
        NSArray* listItems = [data componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"z/\\>_"]];
//        NSLog( @"%@\n", listItems );
        
        if( listItems.count >= 2 )
        {
            NSString* raw      = listItems[0];
            NSRange   trim     = NSMakeRange( 0, raw.length - 1 );
            NSString* latitude = [raw substringWithRange:trim];
            char n = 0;
            if( latitude.length >= 7 )
                n = [raw characterAtIndex:7];

            raw      = listItems[1];
            trim     = NSMakeRange( 0, raw.length - 1 );
            NSString* longitude = [raw substringWithRange:trim];
            char w = 0;
            if( longitude.length >= 8 )
                w = [raw characterAtIndex:8];

            CLLocationDegrees lat = latitude.doubleValue / 100;
            CLLocationDegrees lng = longitude.doubleValue / 100;
            
            if( s_map_controller && lng > 1 )
            {
                // flip sign to deal with East vs West
                if( w == 'W' || w == 'w' )
                    lng = -lng;

                if( n != 'N' && n != 'n' )
                    lat = -lat;

                // get sender
                NSArray* addressComponents = [[NSString stringWithUTF8String:address] componentsSeparatedByString:@">"];
                NSString* addr = nil;
                if( addressComponents.count >= 1 )
                    addr = addressComponents.firstObject;
                
                [s_map_controller plotMessage:lat longitude:lng sender:addr];
            }
        }
    }


    // positions with timestamps
    if( [info characterAtIndex:0]  == '@' || [info characterAtIndex:0]  == '/' )
    {
        NSString* data = [info substringFromIndex:1];
        NSArray* listItems = [data componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"z/\\>_"]];
//        NSLog( @"%@\n", listItems );
        
        if( listItems.count >= 3 )
        {
            NSString* raw      = listItems[1];
            NSRange   trim     = NSMakeRange( 0, raw.length - 1 );
            NSString* latitude = [raw substringWithRange:trim];
            char n = 0;
            if( latitude.length >= 7 )
                n = [raw characterAtIndex:7];

            raw      = listItems[2];
            trim     = NSMakeRange( 0, raw.length - 1 );
            NSString* longitude = [raw substringWithRange:trim];
            char w = 0;
            if( longitude.length >= 8 )
                w = [raw characterAtIndex:8];

            CLLocationDegrees lat = latitude.doubleValue / 100;
            CLLocationDegrees lng = longitude.doubleValue / 100;
            
            if( s_map_controller && lng > 1 )
            {
                // flip sign to deal with East vs West
                if( w == 'W' || w == 'w' )
                    lng = -lng;

                if( n != 'N' && n != 'n' )
                    lat = -lat;

                // get sender
                NSArray* addressComponents = [[NSString stringWithUTF8String:address] componentsSeparatedByString:@">"];
                NSString* addr = nil;
                if( addressComponents.count >= 1 )
                    addr = addressComponents.firstObject;

                [s_map_controller plotMessage:lat longitude:lng sender:addr];
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
    
    
//    [self.mapView registerClass:[CustomAnnotationView class] forAnnotationViewWithReuseIdentifier:NSStringFromClass( [CustomAnnotation class] )];
    [self.mapView registerClass:[MKMarkerAnnotationView class] forAnnotationViewWithReuseIdentifier:NSStringFromClass( [CustomAnnotation class] )];

    // Do any additional setup after loading the view
    init_socket_layer( map_callback );
}



- (void)plotMessage:(CLLocationDegrees)latitude longitude:(CLLocationDegrees)longitude sender:(NSString*)sender
{
    NSLog( @"plotMessage %@: %0.4f, %0.4f\n", sender, latitude, longitude );
    
    __weak MapViewController* weakself = self;
    
    dispatch_async( dispatch_get_main_queue(), ^{
        CLLocationCoordinate2D coord = {.latitude = latitude, .longitude = longitude };
        CustomAnnotation* annotation = [[CustomAnnotation alloc] init: coord];
        annotation.title = sender;
        [weakself.mapView addAnnotations:@[annotation]];
        
        if( !s_have_location )
        {
            MKCoordinateSpan span = MKCoordinateSpanMake( 0.15, 0.15 );
            [weakself.mapView setRegion: MKCoordinateRegionMake( coord, span) animated: true];
            s_have_location = true;
        }
    });
}


- (nullable MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    MKMarkerAnnotationView* anno = (MKMarkerAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:NSStringFromClass( [CustomAnnotation class] ) forAnnotation:annotation];
    
    anno.canShowCallout = true;
    anno.animatesWhenAdded = true;
    anno.markerTintColor = [UIColor colorNamed:@"internationalOrange"];
    
    // Provide the left image icon for the annotation.
    UIImage* image = [UIImage imageNamed:@"flag"];
    anno.leftCalloutAccessoryView = [[UIImageView alloc] initWithImage:image];
    
    // Offset the flag annotation so that the flag pole rests on the map coordinate.
    CGPoint offset = CGPointMake( image.size.width / 2, -(image.size.height / 2) );
    anno.centerOffset = offset;
    return anno;
}

@end
