//
//  SettingsController.h
//  aprs-monitor
//
//  Created by Alex Lelievre on 8/16/20.
//  Copyright © 2020 Far Out Labs, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN



@interface SettingsCell : UITableViewCell
@property (weak) IBOutlet UILabel*     _Nullable label;
@property (weak) IBOutlet UITextField* _Nullable field;
@end

@interface SettingsButtonCell : UITableViewCell
@property (weak) IBOutlet UILabel*  _Nullable label;
@property (weak) IBOutlet UIButton* _Nullable button;
@end


@interface SettingsAboutCell : UITableViewCell
@property (weak) IBOutlet UILabel*     _Nullable text;
@property (weak) IBOutlet UIImageView* _Nullable image;
@end


@interface SettingsController : UITableViewController <UITextFieldDelegate>
@end

NS_ASSUME_NONNULL_END
