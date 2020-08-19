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
#define kInitialSettingDelaySecs  2.5
#define kExpirePacketTimeHours    2
#define kAgePacketTimeHours       1
#define kAgePacketTimeMinutes     30

static MapViewController* s_map_controller     = nil;
static bool               s_have_location      = false;
static CGFloat            s_default_map_span   = 10.0f;
static netStatusBlock     s_connect_completion = NULL;


@interface MapViewController ()
@property (strong, nonatomic) NSTimer*             timer;
@property (strong, nonatomic) dispatch_queue_t     netQueue;
@property (strong, nonatomic) dispatch_source_t    reaper;
@property (strong, nonatomic) NSString* __nullable filterSymbol;
@end



void stat_callback( bool running )
{
    if( !s_map_controller )
    {
        NSLog( @"map_callback: no controller!\n" );
        return;
    }

    s_map_controller.in_progress = NO;
    s_map_controller.thread_running = running;

    dispatch_async( dispatch_get_main_queue(), ^{
        if( running )
            dispatch_resume( s_map_controller.reaper );
        else
            dispatch_suspend( s_map_controller.reaper );

        if( s_connect_completion )
            s_connect_completion( running, 0 );
    });
}


void map_callback( unsigned char* frame_data, size_t data_length )
{
    if( !s_map_controller )
    {
        NSLog( @"map_callback: no controller!\n" );
        return;
    }
    
    if( !frame_data || !data_length )
    {
        NSLog( @"map_callback: no input data!\n" );
        return;
    }
    
    [s_map_controller blinkMessageButton];
    
    // create packet
    PacketManager* pm = [PacketManager shared];
    if( pm )
    {
        NSData* data = [NSData dataWithBytes:frame_data length:data_length];
        Packet* pkt = [Packet initWithData:data];
        if( pkt )
        {
            [pm addItem:pkt];
            if( s_map_controller && (pkt.flags & kCoordinatesMask) )
                [s_map_controller plotMessage:pkt];
        }
    }
}


#pragma mark -





@implementation MapViewController


+ (MapViewController*)shared
{
    if( !s_map_controller )
        NSLog( @"Calling MapViewController*)shared too early, is nil!\n" );
    
    return s_map_controller;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [PacketManager shared].documentUpdatedBlock = ^{ [[NSNotificationCenter defaultCenter] postNotificationName:@"NewPacket" object:nil]; };        // !!@ remove literals
    
    [self.mapView registerClass:[MKMarkerAnnotationView class] forAnnotationViewWithReuseIdentifier:@"marker.pin"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(packetsWiped:) name:@"PacketLogWiped" object:nil];

    _netQueue = dispatch_queue_create( "networkqueue", NULL );
    if( !s_map_controller )
    {
        s_map_controller = self;
        
        NSString* server = [[NSUserDefaults standardUserDefaults] objectForKey:kPrefsServerKey];
        if( !server || !server.length )
        {
            // !!@ change this to display a dialog that the user can then read some stuff, and choose to do the setup... !!@

            // wait a few seconds for things to "load", then display prefs...
            dispatch_after( dispatch_time( DISPATCH_TIME_NOW, kInitialSettingDelaySecs * NSEC_PER_SEC ), dispatch_get_main_queue(), ^{
                [self performSegueWithIdentifier:@"settings.segue" sender:self];
            });
        }
        else
            [self connectToServer:nil];    // when we start, automatically connect
    }
    
    _reaper = dispatch_source_create( DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue() );
    if( _reaper )
    {
        uint64_t interval = 30;
        dispatch_source_set_timer( _reaper, dispatch_time( DISPATCH_TIME_NOW, interval * NSEC_PER_SEC ), interval * NSEC_PER_SEC, (1ull * NSEC_PER_SEC) / 10 );
        dispatch_source_set_event_handler( _reaper, ^{
            [self expireAnnotations];
            [self ageAnnotations];
        });
    }
}


- (void)applicationDidEnterBackground:(UIApplication*)application
{
    [self disconnectFromServer:nil];
}


- (void)applicationWillEnterForeground:(UIApplication*)application
{
    // reconnect automatically...
    [self connectToServer:nil];
}


#pragma mark -


// connect and disconnect cannot overlap due to sharing a static block
- (void)connectToServer:(netStatusBlock)completionHandler
{
    if( !_thread_running )
    {
        _in_progress = YES;
        
        // get server name and port from settings...
        NSString* server = [[NSUserDefaults standardUserDefaults] objectForKey:kPrefsServerKey];
        NSInteger port   = [[NSUserDefaults standardUserDefaults] integerForKey:kPrefsServerPortKey];
        
        if( completionHandler )
            s_connect_completion = completionHandler;
        
        dispatch_async( _netQueue, ^{
            init_socket_layer( server.UTF8String, (int)port, map_callback, stat_callback );
        });
    }
    else
    {
        NSLog( @"Already connected!\n" );
    }
}


- (void)disconnectFromServer:(netStatusBlock)completionHandler
{
    if( _thread_running )
    {
        if( completionHandler )
            s_connect_completion = completionHandler;

        dispatch_async( _netQueue, ^{
            shutdown_socket_layer();
        });
    }
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


- (IBAction)positionButtonPressed:(id)sender
{
    
}


- (IBAction)weatherButtonPressed:(id)sender
{
    [self filterForWeather];
    _filterSymbol = @"/_";       // !!@ there needs to be a better way to do this...
}


- (IBAction)statusButtonPressed:(id)sender
{
    Packet* pkt = [[Packet alloc] init];
    pkt.flags |= kCoordinatesMask;
    pkt.coordinate = CLLocationCoordinate2DMake( 34.108, -118.336 ); // near folabs hq
    pkt.call = @"K6TEST";
    pkt.weather = @"fake symbol test";
    pkt.symbol = @"/8";
    
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


- (IBAction)objectButtonPressed:(id)sender
{
    
}


- (IBAction)allButtonPressed:(id)sender
{
    [self filterForAll];
    _filterSymbol = nil;
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
            Packet* pkt = (Packet*)[weakself.mapView.annotations objectAtIndex:index];
            MKMarkerAnnotationView* anno = (MKMarkerAnnotationView*)[weakself.mapView viewForAnnotation:pkt];   // this supposedly only works for visible pins
            if( anno )
            {
                [self setupAnnotationView:anno forAnnotation:pkt];
                return;
            }
            
            // yank the old one, we will stick a new one in its place
            [weakself.mapView removeAnnotation:[weakself.mapView.annotations objectAtIndex:index]];
            
            // note: for moving objects, we should be updating the paths here I think !!@
        }
        
        // check to see if we are filtering packets and if so possibly skip adding this one (unless it matches the current filter) !!@
        if( weakself.filterSymbol && ![weakself.filterSymbol isEqualToString:packet.symbol] )
            return;
        
        [weakself.mapView addAnnotations:@[packet]];
        
        if( !s_have_location )
        {
            MKCoordinateSpan span = MKCoordinateSpanMake( s_default_map_span, s_default_map_span );
            [weakself.mapView setRegion:MKCoordinateRegionMake( packet.coordinate, span ) animated: true];
            s_have_location = true;
        }
    });
}


// this routine goes thru the currently visible annotations and finds the old ones and makes them greyer until they die (and are removed)
- (void)expireAnnotations
{
    NSIndexSet* deadPins = [self.mapView.annotations indexesOfObjectsPassingTest:^BOOL ( __kindof Packet* _Nonnull pkt, NSUInteger idx, BOOL* stop )
    {
        NSCalendarUnit units = NSCalendarUnitHour;
        NSDateComponents* components = [[NSCalendar currentCalendar] components:units fromDate:pkt.timeStamp toDate:[NSDate now] options:0];
        return (components.hour >= kExpirePacketTimeHours);
    }];
    
    if( !deadPins.count )
        return;

    NSArray* deathRow = [self.mapView.annotations objectsAtIndexes:deadPins];
    if( deathRow )
        [self.mapView removeAnnotations:deathRow];
}


- (void)ageAnnotations
{
    NSIndexSet* dyingPins = [self.mapView.annotations indexesOfObjectsPassingTest:^BOOL ( __kindof Packet* _Nonnull pkt, NSUInteger idx, BOOL* stop )
    {
        NSCalendarUnit units = (NSCalendarUnitHour | NSCalendarUnitMinute);
        NSDateComponents* components = [[NSCalendar currentCalendar] components:units fromDate:pkt.timeStamp toDate:[NSDate now] options:0];
        return ((components.hour >= kAgePacketTimeHours) && (components.minute >= kAgePacketTimeMinutes));
    }];
    
    if( !dyingPins.count )
        return;

    NSArray* agingStation = [self.mapView.annotations objectsAtIndexes:dyingPins];
    if( agingStation )
    {
        [agingStation enumerateObjectsUsingBlock:^( Packet* pkt, NSUInteger idx, BOOL* stop ) {
            MKMarkerAnnotationView* anno = (MKMarkerAnnotationView*)[self.mapView viewForAnnotation:pkt];
            anno.alpha = 0.45f;
        }];
    }
}



- (void)filterForWeather
{
    NSIndexSet* wxPins = [self.mapView.annotations indexesOfObjectsPassingTest:^BOOL ( __kindof Packet* _Nonnull pkt, NSUInteger idx, BOOL* stop )
    {
        NSCalendarUnit units = NSCalendarUnitHour;
        NSDateComponents* components = [[NSCalendar currentCalendar] components:units fromDate:pkt.timeStamp toDate:[NSDate now] options:0];
        
        // don't go too far back in time (nothing older than the oldest showing pins)
        if( components.hour > kExpirePacketTimeHours )
        {
            *stop = YES;
            return false;
        }
        
        return [pkt.symbol isEqualToString:@"/_"]; // really need a type field that's not a string !!@
    }];
    
    NSArray* wx = [self.mapView.annotations objectsAtIndexes:wxPins];
    [self.mapView removeAnnotations:self.mapView.annotations];
    if( wx )
    {
        [wx enumerateObjectsUsingBlock:^( __kindof Packet* _Nonnull pkt, NSUInteger idx, BOOL* stop )
        {
            [self plotMessage:pkt];
        }];
    }
}


- (void)filterForAll
{
    [[PacketManager shared].items enumerateObjectsUsingBlock:^( __kindof Packet* _Nonnull pkt, NSUInteger idx, BOOL* stop )
    {
        NSCalendarUnit units = NSCalendarUnitHour;
        NSDateComponents* components = [[NSCalendar currentCalendar] components:units fromDate:pkt.timeStamp toDate:[NSDate now] options:0];
        
        // don't go too far back in time (nothing older than the oldest showing pins)
        if( components.hour > kExpirePacketTimeHours )
        {
            *stop = YES;
            return;
        }
        
        // we do this instead of adding them all at once (which is in the last checkin) so that we get the
        // checks for existing pins (and eventually so we plot routes correctly)
        [self plotMessage:pkt];
    }];
}




#pragma mark -



+ (UIImage*)getSymbolImage:(NSString*)symbol
{
    UIImage* image = nil;
    const SymbolEntry* sym = getSymbolEntry( symbol );
    if( sym )
    {
        UIColor* tintColor = [UIColor colorWithRed:sym->red green:sym->grn blue:sym->blu alpha:sym->alpha];
        
        if( sym->emoji && sym->glyph )
        {
            image = emojiToImage( sym->glyph );
        }
        else
        {
            image = sym->glyph ? [UIImage systemImageNamed:sym->glyph withConfiguration:[UIImageSymbolConfiguration configurationWithScale:UIImageSymbolScaleLarge]] : nil;
        }
            
        if( sym->tint )
            image = [image imageWithTintColor:tintColor];
    }
    return image;
}


+ (UIColor*)getSymbolTint:(NSString*)symbol
{
    const SymbolEntry* sym = getSymbolEntry( symbol );
    if( sym )
    {
        UIColor* tintColor = [UIColor colorWithRed:sym->red green:sym->grn blue:sym->blu alpha:sym->alpha];
        if( sym->tint )
            return tintColor;
    }
    return nil;
}


+ (void)setButtonBar:(UIBarButtonItem*)item fromSymbol:(NSString*)symbol
{
    const SymbolEntry* sym = getSymbolEntry( symbol );
    if( sym )
    {
        item.tintColor = [UIColor colorWithRed:sym->red green:sym->grn blue:sym->blu alpha:sym->alpha];
//        UIImage* leftCallout = nil;
        
        if( sym->emoji && sym->glyph )
        {
            item.image = nil;
            item.title = sym->glyph;
//            leftCallout = emojiToImage( sym->glyph );
        }
        else
        {
            item.image = sym->glyph ? [UIImage systemImageNamed:sym->glyph withConfiguration:[UIImageSymbolConfiguration configurationWithScale:UIImageSymbolScaleLarge]] : nil;
            item.title  = nil;
//            leftCallout = item.image;
        }
            
//        if( sym->tint )
//            anno.leftCalloutAccessoryView = [[UIImageView alloc] initWithImage:[leftCallout imageWithTintColor:anno.markerTintColor]];
//        else
//            anno.leftCalloutAccessoryView = [[UIImageView alloc] initWithImage:leftCallout];
    }
}


#pragma mark -


- (void)setupAnnotationView:(MKAnnotationView*)view forAnnotation:(id <MKAnnotation>)annotation
{
    Packet* pkt = (Packet*)annotation;
    MKMarkerAnnotationView* anno = (MKMarkerAnnotationView*)view;
    
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
//              anno.detailCalloutAccessoryView = [[UIImageView alloc] initWithImage:windIcon]; // test code to see if we can easily attach custom view (yes!)
            }
        }
    }
    else
    {
        // generic marker case...
//        anno.markerTintColor = [UIColor colorNamed:@"internationalOrange"];
//        anno.markerTintColor = [anno.markerTintColor colorWithAlphaComponent:0.7f];
        anno.glyphImage = nil;
        anno.glyphText  = nil;
        anno.leftCalloutAccessoryView = nil;
    }
}


- (nullable MKAnnotationView*)mapView:(MKMapView*)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    MKMarkerAnnotationView* anno = (MKMarkerAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:@"marker.pin" forAnnotation:annotation];
    [self setupAnnotationView:anno forAnnotation:annotation];
    return anno;
}


- (void)mapView:(MKMapView*)mapView annotationView:(MKAnnotationView*)view calloutAccessoryControlTapped:(UIControl*)control
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
            dvc.customTitle.text = pkt.title;
            dvc.customIcon.image = [MapViewController getSymbolImage:pkt.symbol];
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


#pragma mark -

- (IBAction)packetsWiped:(id)sender
{
    [self.mapView removeAnnotations:self.mapView.annotations];
}


@end
