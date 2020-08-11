//
//  ViewController.m
//  aprs-monitor
//
//  Created by Alex Lelievre on 8/10/20.
//  Copyright © 2020 Alex Lelievre. All rights reserved.
//

#import "ViewController.h"

#include "main.h"


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

            CLLocationDegrees lat = latitude.doubleValue;
            CLLocationDegrees lng = longitude.doubleValue;
            
            if( lng > 1 )
                NSLog( @"lat: %0.5f%c, %0.5f%c\n", lat / 100, n, lng / 100, w );
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

            CLLocationDegrees lat = latitude.doubleValue;
            CLLocationDegrees lng = longitude.doubleValue;
            
            if( lng > 1 )
                NSLog( @"lat: %0.5f%c, %0.5f%c\n", lat / 100, n, lng / 100, w );
        }
    }

}


@interface MapViewController ()

@end



@implementation MapViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Do any additional setup after loading the view
    init_socket_layer( map_callback );
}


@end
