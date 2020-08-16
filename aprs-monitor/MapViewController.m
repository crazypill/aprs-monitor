//
//  ViewController.m
//  aprs-monitor
//
//  Created by Alex Lelievre on 8/10/20.
//  Copyright © 2020 Alex Lelievre. All rights reserved.
//

#import "MapViewController.h"
#import "MapKit/MKMarkerAnnotationView.h"

#include "DetailViewController.h"
#include "RemoteTNC.h"
#include "PacketManager.h"
#include "SymbolTable.h"

#include "decode_aprs.h"  // Direwolf


#define kBlinkColor [UIColor redColor]



static MapViewController* s_map_controller   = nil;
static bool               s_have_location    = false;
static CGFloat            s_default_map_span = 10.0f;




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
            if( s_map_controller && (pkt.flags & kCoordinatesMask) )
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


#pragma mark -

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


- (IBAction)positionButtonPressed:(id)sender
{
    
}


- (IBAction)weatherButtonPressed:(id)sender
{
    Packet* pkt = [[Packet alloc] init];
    pkt.flags |= (kCoordinatesMask | kPacketFlag_Weather);
    pkt.coordinate = CLLocationCoordinate2DMake( 34.108, -118.335 ); // folabs hq
    pkt.call = @"K6TEST";
    pkt.weather = @"fake weather";
    pkt.symbol = @"/_";
    
    pkt.wx = malloc( sizeof( wx_data ) );
    if( pkt.wx )
    {
        pkt.wx->wxflags |= (kWxDataFlag_gust | kWxDataFlag_windDir | kWxDataFlag_wind | kWxDataFlag_temp | kWxDataFlag_humidity | kWxDataFlag_pressure);
        pkt.wx->windGustMph = 10;
        pkt.wx->windSpeedMph = 2;
        pkt.wx->windDirection = 195;

        pkt.wx->tempF    = 100;
        pkt.wx->humidity = 55;
        pkt.wx->pressure = 1013;
     
        pkt.weather = [Packet makeWeatherString:pkt.wx];
        [self plotMessage:pkt];
    }
    pkt = nil;
}


- (IBAction)statusButtonPressed:(id)sender
{
    
}


- (IBAction)objectButtonPressed:(id)sender
{
    
}


- (IBAction)allButtonPressed:(id)sender
{
    
}



#pragma mark -

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
            MKCoordinateSpan span = MKCoordinateSpanMake( s_default_map_span, s_default_map_span );
            [weakself.mapView setRegion:MKCoordinateRegionMake( packet.coordinate, span ) animated: true];
            s_have_location = true;
        }
    });
}



#pragma mark -

- (nullable MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    Packet* pkt = (Packet*)annotation;
    MKMarkerAnnotationView* anno = (MKMarkerAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:@"marker.pin" forAnnotation:annotation];

    anno.canShowCallout  = true;
    anno.animatesWhenAdded = true;
    
    anno.displayPriority = MKFeatureDisplayPriorityRequired;
    anno.titleVisibility = MKFeatureVisibilityAdaptive;

    // this prevents a tap from selecting this item! using the detailDisclosure type causes the entire text field to also act like a button press.
    anno.rightCalloutAccessoryView = [UIButton systemButtonWithImage:[UIImage systemImageNamed:@"info.circle"] target:nil action:nil];
    
    
    const SymbolEntry* sym = getSymbolEntry( pkt.symbol );
    if( sym )
    {
        anno.markerTintColor = [UIColor colorWithRed:sym->red green:sym->grn blue:sym->blu alpha:sym->alpha];
        UIImage* leftCallout = nil;
        
        if( sym->emoji && sym->glyph )
        {
            anno.glyphImage = nil;
            anno.glyphText  = sym->glyph;
            leftCallout     = emojiToImage( sym->glyph );
        }
        else
        {
            anno.glyphImage = sym->glyph ? [UIImage systemImageNamed:sym->glyph withConfiguration:[UIImageSymbolConfiguration configurationWithScale:UIImageSymbolScaleLarge]] : nil;
            anno.glyphText  = nil;
            leftCallout     = anno.glyphImage;
        }
            
        if( sym->tint )
            anno.leftCalloutAccessoryView = [[UIImageView alloc] initWithImage:[leftCallout imageWithTintColor:anno.markerTintColor]];
        else
            anno.leftCalloutAccessoryView = [[UIImageView alloc] initWithImage:leftCallout];

        
        // see if we need to replace the callout image... we do this for wind only...
        if( pkt.flags & kPacketFlag_Weather )
        {
            UIImage* windIcon = [pkt getWindIndicatorIcon:CGRectMake( 0, 0,  40, 40 )];
            if( windIcon )
            {
                anno.leftCalloutAccessoryView = [[UIImageView alloc] initWithImage:windIcon];
//                anno.detailCalloutAccessoryView = [[UIImageView alloc] initWithImage:windIcon]; // test code to see if we can easily attach custom view (yes!)
            }
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
    UINavigationController* detailNavController = [self.storyboard instantiateViewControllerWithIdentifier:@"DetailNavController"];
    if( detailNavController )
    {
        Packet* pkt = (Packet*)view.annotation;
        if( pkt )
        {
            DetailViewController* dvc = detailNavController.viewControllers.firstObject;
            dvc.detail = pkt;
            dvc.title  = pkt.title;
        }
        
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
