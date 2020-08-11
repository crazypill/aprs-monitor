//
//  ViewController.m
//  aprs-monitor
//
//  Created by Alex Lelievre on 8/10/20.
//  Copyright © 2020 Alex Lelievre. All rights reserved.
//

#import "MapViewController.h"
#import "MapKit/MKMarkerAnnotationView.h"
#import "Packet.h"

#include "main.h"


static MapViewController* s_map_controller = nil;
static bool               s_have_location  = false;




@interface MapViewController ()
@property (strong, nonatomic) NSTimer* timer;
@end




CLLocationDegrees convertToDegrees( NSString* aprsPosition )
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


void parse_data( NSString* raw_lat, NSString* raw_long, NSString* raw_address )
{
    NSString* latitude = [raw_lat substringWithRange:NSMakeRange( 0, raw_lat.length - 1 )];
    if( latitude.length == 7 )
    {
        char n = [raw_lat characterAtIndex:7];

        NSString* longitude = [raw_long substringWithRange:NSMakeRange( 0, raw_long.length - 1 )];
        if( longitude.length >= 8 )
        {
            char w = [raw_long characterAtIndex:8];

            CLLocationDegrees lat = convertToDegrees( latitude );
            CLLocationDegrees lng = convertToDegrees( longitude );
            
            if( s_map_controller && lng > 1 )
            {
                // flip sign to deal with East vs West
                if( w == 'W' || w == 'w' )
                    lng = -lng;

                if( n != 'N' && n != 'n' )
                    lat = -lat;

                // get sender
                NSArray* addressComponents = [raw_address componentsSeparatedByString:@">"];
                NSString* address = nil;
                if( addressComponents.count >= 1 )
                    address = addressComponents.firstObject;
                
                [s_map_controller plotMessage:lat longitude:lng sender:address];
            }
        }
    }
}





void map_callback( const char* address, const char* frameData )
{
    if( !s_map_controller )
    {
        NSLog( @"map_callback: no controller!\n" );
        return;
    }

    NSLog( @"%s%s\n", address, frameData );
    
    [s_map_controller blinkMessageButton];
    
    NSString* info = [NSString stringWithUTF8String:frameData];
    
    // positions without timestamps
    if( [info characterAtIndex:0]  == '!' || [info characterAtIndex:0]  == '=' )
    {
        NSString* data = [info substringFromIndex:1];
        NSArray* listItems = [data componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"z/\\>_"]];
//        NSLog( @"%@\n", listItems );
        
        if( listItems.count >= 2 )
        {
            parse_data( listItems[0], listItems[1], [NSString stringWithUTF8String:address] );
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
            parse_data( listItems[1], listItems[2], [NSString stringWithUTF8String:address] );
        }
    }
}


#pragma mark -



@implementation MapViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    s_map_controller = self;
    
    
//    [self.mapView registerClass:[CustomAnnotationView class] forAnnotationViewWithReuseIdentifier:NSStringFromClass( [CustomAnnotation class] )];
    [self.mapView registerClass:[MKMarkerAnnotationView class] forAnnotationViewWithReuseIdentifier:NSStringFromClass( [Packet class] )];

    // Do any additional setup after loading the view
    init_socket_layer( map_callback );
}


- (void)blinkMessageButton
{
    __weak MapViewController* weakself = self;

    dispatch_async( dispatch_get_main_queue(), ^{
        // kill any existing timer, we will reset it
        if( weakself.timer )
        {
            weakself.status.tintColor = [UIColor systemBlueColor];
            [weakself.timer invalidate];
            weakself.timer = nil;
        }
        
        // change to red, timer will set to blue
        weakself.status.tintColor = [UIColor redColor];

        // set timer to turn off status light after a tiny bit
         weakself.timer = [NSTimer scheduledTimerWithTimeInterval:0.6 target:weakself selector:@selector(restoreMessageButton) userInfo:nil repeats:NO];
    });
}


- (void)restoreMessageButton
{
    _status.tintColor = [UIColor systemBlueColor];
    [_timer invalidate];
    _timer = nil;
}

- (void)plotMessage:(CLLocationDegrees)latitude longitude:(CLLocationDegrees)longitude sender:(NSString*)sender
{
    NSLog( @"plotMessage %@: %0.4f, %0.4f\n", sender, latitude, longitude );
    
    __weak MapViewController* weakself = self;
    
    dispatch_async( dispatch_get_main_queue(), ^{
        CLLocationCoordinate2D coord = CLLocationCoordinate2DMake( latitude, longitude );
        Packet* annotation = [Packet initWithCoordinates:coord];
        annotation.call = sender;
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
    MKMarkerAnnotationView* anno = (MKMarkerAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:NSStringFromClass( [Packet class] ) forAnnotation:annotation];
    
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
