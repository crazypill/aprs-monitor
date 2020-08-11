//
//  ViewController.h
//  aprs-monitor
//
//  Created by Alex Lelievre on 8/10/20.
//  Copyright © 2020 Alex Lelievre. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MKMapView.h>

@interface MapViewController : UIViewController

@property (strong, nonatomic) UIWindow * window;
@property (weak, nonatomic) IBOutlet MKMapView* mapView;

@end

