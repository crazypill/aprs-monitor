//
//  SettingsController.h
//  aprs-monitor
//
//  Created by Alex Lelievre on 8/16/20.
//  Copyright © 2020 Far Out Labs, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN



@interface SettingsChevronCell : UITableViewCell
@property (weak) IBOutlet UILabel*  _Nullable text;
@property (weak) IBOutlet UIButton* _Nullable chevron;
@end

@interface SettingsAboutCell : UITableViewCell
@property (weak) IBOutlet UILabel*     _Nullable text;
@property (weak) IBOutlet UIImageView* _Nullable image;
@end


@interface SettingsController : UITableViewController
@end

NS_ASSUME_NONNULL_END
