//
//  DetailViewController.h
//  aprs-monitor
//
//  Created by Alex Lelievre on 8/14/20.
//  Copyright © 2020 Apple. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Packet.h"

NS_ASSUME_NONNULL_BEGIN

@interface DetailViewController : UITableViewController
@property (nonatomic, strong)        Packet* detail;
@property (weak, nonatomic) IBOutlet UIView*      customView;
@property (weak, nonatomic) IBOutlet UILabel*     customTitle;
@property (weak, nonatomic) IBOutlet UIImageView* customIcon;
@end

NS_ASSUME_NONNULL_END
