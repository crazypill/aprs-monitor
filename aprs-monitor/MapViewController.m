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
#include "SymbolTable.h"

#include "decode_aprs.h"  // Direwolf


#define kBlinkColor [UIColor redColor]



static MapViewController* s_map_controller = nil;
static bool               s_have_location  = false;






//@interface PacketAnnotationView : MKMarkerAnnotationView
//@end
//
//@implementation PacketAnnotationView
//
//- (void)setSelected:(BOOL)selected animated:(BOOL)animated
//{
//    [super setSelected:selected animated:animated];
//
//    // Get the custom callout view.
//    UIView* calloutView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"thermometer"]];
//    if( selected )
//    {
//        CGRect annotationViewBounds = self.bounds;
//        CGRect calloutViewFrame = calloutView.frame;
//
//        // Center the callout view above and to the right of the annotation view.
//        calloutViewFrame.origin.x = -(calloutViewFrame.size.width - annotationViewBounds.size.width) * 0.5;
//        calloutViewFrame.origin.y = -(calloutViewFrame.size.height) + 15.0;
//        calloutView.frame = calloutViewFrame;
//
//        [self addSubview:calloutView];
//    }
//    else
//    {
//        [calloutView removeFromSuperview];
//    }
//}
//
//@end






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
    
    [self.mapView registerClass:[MKMarkerAnnotationView class] forAnnotationViewWithReuseIdentifier:@"marker.pin"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];

    if( !s_map_controller )
    {
        s_map_controller = self;
        [self connectButtonPressed:nil];    // when we start, automatically connect !!@
    }
}


- (void)applicationDidEnterBackground:(UIApplication*)application
{
    if( _thread_running )
        shutdown_socket_layer();
}


- (void)applicationWillEnterForeground:(UIApplication*)application
{
    // reconnect automatically...
    [self connectButtonPressed:nil];
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
        
        // change to highlited color, timer will set to blue later
        weakself.status.tintColor = kBlinkColor;

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
        
        // first look to see if we already have a position plotted for this exact call sign...
        NSInteger index = [weakself.mapView.annotations indexOfObjectPassingTest:^BOOL ( __kindof Packet* _Nonnull pkt, NSUInteger idx, BOOL* stop ) {
            return [pkt.call isEqualToString:packet.call];
        }];
        
        if( index != NSNotFound )
        {
            // yank the old one, we will stick a new one in its place
            [weakself.mapView removeAnnotation:[weakself.mapView.annotations objectAtIndex:index]];
            
            // note: for moving objects, we should be updating the paths here I think !!@
        }
        
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
    Packet* pkt = (Packet*)annotation;
    MKMarkerAnnotationView* anno = (MKMarkerAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:@"marker.pin" forAnnotation:annotation];

    anno.canShowCallout  = true;
    anno.animatesWhenAdded = true;
    
    anno.displayPriority = MKFeatureDisplayPriorityRequired;
    anno.titleVisibility = MKFeatureVisibilityAdaptive;

    anno.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    
    const SymbolEntry* sym = getSymbolEntry( pkt.symbol );
    if( sym )
    {
        anno.markerTintColor = [UIColor colorWithRed:sym->red green:sym->grn blue:sym->blu alpha:sym->alpha];
        if( sym->emoji && sym->glyph )
        {
            anno.glyphImage      = nil;
            anno.glyphText       = sym->glyph;
            anno.leftCalloutAccessoryView = [[UIImageView alloc] initWithImage:emojiToImage( sym->glyph )];
        }
        else
        {
            anno.glyphImage      = sym->glyph ? [UIImage systemImageNamed:sym->glyph withConfiguration:[UIImageSymbolConfiguration configurationWithScale:UIImageSymbolScaleLarge]] : nil;
            anno.glyphText       = nil;
            anno.leftCalloutAccessoryView = [[UIImageView alloc] initWithImage:anno.glyphImage];
        }
        
        // see if we need to replace the callout image... we do this for wind only...
        if( pkt.flags & kPacketFlag_Weather )
        {
            UIImage* windIcon = [pkt getWindIndicatorIcon:CGRectMake( 0, 0,  40, 40 )];
            if( windIcon )
                anno.leftCalloutAccessoryView = [[UIImageView alloc] initWithImage:windIcon];
        }
    }
    else
    {
        // generic marker case...
        anno.markerTintColor = [UIColor colorNamed:@"internationalOrange"];
        anno.glyphImage = nil;
        anno.glyphText  = nil;
        anno.leftCalloutAccessoryView = nil;
    }
   
    return anno;
}


- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    // This illustrates how to detect which annotation type was tapped on for its callout.
    UIViewController* detailNavController = [self.storyboard instantiateViewControllerWithIdentifier:@"DetailNavController"];
    if( detailNavController )
    {
        detailNavController.modalPresentationStyle = UIModalPresentationPopover;
        
        UIPopoverPresentationController* presentationController = detailNavController.popoverPresentationController;
        if( presentationController )
        {
            presentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
        
            // Anchor the popover to the button that triggered the popover.
            presentationController.sourceRect = control.frame;
            presentationController.sourceView = control;
            
            [self presentViewController:detailNavController animated:YES completion:nil];
        }
    }
}


@end
