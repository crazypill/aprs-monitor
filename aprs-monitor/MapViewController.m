//
//  ViewController.m
//  aprs-monitor
//
//  Created by Alex Lelievre on 8/10/20.
//  Copyright © 2020 Alex Lelievre. All rights reserved.
//

#import "MapViewController.h"
#import "MapKit/MKMarkerAnnotationView.h"

#include "RemoteTNC.h"
#include "PacketManager.h"

#include "decode_aprs.h"  // Direwolf


static MapViewController* s_map_controller = nil;
static bool               s_have_location  = false;




@interface MapViewController ()
@property (nonatomic)         bool     thread_running;
@property (strong, nonatomic) NSTimer* timer;
@end





void stat_callback( bool running )
{
    if( !s_map_controller )
    {
        NSLog( @"map_callback: no controller!\n" );
        return;
    }

    dispatch_async( dispatch_get_main_queue(), ^{
        if( running )
        {
            s_map_controller.connect.enabled = YES;
            s_map_controller.connect.title = @"Disconnect";
        }
        else
        {
            s_map_controller.connect.enabled = YES;
            s_map_controller.connect.title = @"Connect";
        }

        s_map_controller.thread_running = running;
    });
}


void map_callback( packet_t packet )
{
    if( !s_map_controller )
    {
        NSLog( @"map_callback: no controller!\n" );
        return;
    }
    
    if( !packet )
    {
        NSLog( @"map_callback: no iput packet!\n" );
        return;
    }
    
    [s_map_controller blinkMessageButton];
    
    // create packet
    PacketManager* pm = [PacketManager shared];
    if( pm )
    {
        Packet* pkt = [Packet initWithPacket_t:packet];
        if( pkt )
        {
            [pm addItem:pkt];
            if( s_map_controller && (pkt.flags & kPacketFlag_CoordinatesValid) )
                [s_map_controller plotMessage:pkt];
        }
    }

    ax25_delete( packet );
}


#pragma mark -



@implementation MapViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [PacketManager shared].documentUpdatedBlock = ^{ [[NSNotificationCenter defaultCenter] postNotificationName:@"NewPacket" object:nil]; };        // !!@ remove literals
    
    [self.mapView registerClass:[MKMarkerAnnotationView class] forAnnotationViewWithReuseIdentifier:NSStringFromClass( [Packet class] )];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:@"appResigning" object:nil];       // !!@ remove literals

    if( !s_map_controller )
    {
        s_map_controller = self;
        [self connectButtonPressed:nil];    // when we start, automatically connect !!@
    }
}


- (void)applicationWillResignActive:(UIApplication *)application
{
    if( _thread_running )
        shutdown_socket_layer();
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
        
        // change to green, timer will set to blue
        weakself.status.tintColor = [UIColor greenColor];

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


- (IBAction)connectButtonPressed:(id)sender
{
    s_map_controller.connect.enabled = NO;  // grey button while connecting or disconnecting...
    if( !_thread_running )
    {
        init_socket_layer( map_callback, stat_callback );
    }
    else
    {
        shutdown_socket_layer();
    }
}


- (void)plotMessage:(const Packet*)packet
{
    __weak MapViewController* weakself = self;
    
    dispatch_async( dispatch_get_main_queue(), ^{
        [weakself.mapView addAnnotations:@[packet]];
        
        if( !s_have_location )
        {
            MKCoordinateSpan span = MKCoordinateSpanMake( 0.15, 0.15 );
            [weakself.mapView setRegion:MKCoordinateRegionMake( packet.coordinate, span ) animated: true];
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
