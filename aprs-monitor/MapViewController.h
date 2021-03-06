//
//  MapViewController.h
//  aprs-monitor
//
//  Created by Alex Lelievre on 8/10/20.
//  Copyright © 2020 Alex Lelievre. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MKMapView.h>

#import "Packet.h"

#define kPrefsServerKey      @"server"
#define kPrefsServerPortKey  @"port"

typedef void (^ __nullable netStatusBlock)( bool isConnected, int errorCode ); 


@interface MapViewController : UIViewController <MKMapViewDelegate>

@property (strong, nonatomic)        UIWindow* __nullable        window;
@property (weak, nonatomic) IBOutlet MKMapView* __nullable       mapView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem* __nullable status;
@property (weak, nonatomic) IBOutlet UIBarButtonItem* __nullable connect;
@property (weak, nonatomic) IBOutlet UIBarButtonItem* __nullable weatherFilter;
@property (weak, nonatomic) IBOutlet UIBarButtonItem* __nullable allFilter;
@property (atomic)                   bool                        in_progress;
@property (atomic)                   bool                        thread_running;

+ (MapViewController* __nullable)shared;

+ (UIImage* __nullable)getSymbolImage:(NSString* __nullable)symbol;
+ (UIColor* __nullable)getSymbolTint:(NSString* __nullable)symbol;
+ (void)setButtonBar:(UIBarButtonItem* __nullable)item fromSymbol:(NSString* __nullable)symbol;

- (void)connectToServer:(netStatusBlock)completionHandler;
- (void)disconnectFromServer:(netStatusBlock)completionHandler;

- (void)blinkMessageButton;
- (void)plotMessage:(const Packet* __nullable)packet;


@end

