//
//  PacketViewController.h
//  aprs-monitor
//
//  Created by Alex Lelievre on 8/11/20.
//  Copyright © 2020 Apple. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


@interface PacketViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel* date;
@property (weak, nonatomic) IBOutlet UILabel* address;
@property (weak, nonatomic) IBOutlet UILabel* info;
@end


@interface PacketViewController : UITableViewController
@end

NS_ASSUME_NONNULL_END
