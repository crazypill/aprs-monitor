//
//  SettingsController.m
//  aprs-monitor
//
//  Created by Alex Lelievre on 8/16/20.
//  Copyright © 2020 Far Out Labs, LLC. All rights reserved.
//

#import "SettingsController.h"


#define kNSBundleVersionKey         @"CFBundleVersion"
#define kNSApplicationVersionKey    @"CFBundleShortVersionString"
#define kPrefsAboutFormat           @"APRS Monitor v%@\n© 2020 Far Out Labs, LLC\nWritten by: Alex Lelièvre K6LOT"

static const float kPrefsTableTitleHeight       = 60.0f;
static const float kPrefsTableAboutHeight       = 69.0f;
static const float kPrefsTableAboutFooterHeight = 260.0f;


enum
{
    kSettingsSection_Settings,
    kSettingsSection_About
};


enum
{
    kSettings_KissServer,
    kSettings_KissPort,
    kSettings_Connect
};


@implementation SettingsCell
@end

@implementation SettingsButtonCell
@end

@implementation SettingsAboutCell
@end



@interface SettingsController ()
@end


@implementation SettingsController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}


#pragma mark -


- (NSString*)getBuildVersion
{
    NSDictionary* infoDict = [[NSBundle mainBundle] infoDictionary];
    return [infoDict valueForKey:kNSBundleVersionKey];
}


- (NSString*)getFullVersion
{
    NSDictionary* infoDict = [[NSBundle mainBundle] infoDictionary];
    return  [NSString stringWithFormat:@"%@ (%@)", [infoDict valueForKey:kNSApplicationVersionKey], [self getBuildVersion]];
}



- (NSString*)aboutVersionString
{
    return [NSString stringWithFormat:kPrefsAboutFormat, [self getFullVersion]];
}



#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return 2;
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    if( section == kSettingsSection_Settings )
        return 3;
    
    return 1;
}



- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    
    // Configure the cell...
    if( indexPath.section == kSettingsSection_Settings )
    {
        SettingsCell* cell = nil;
        if( indexPath.row == kSettings_KissServer )
        {
            cell = [tableView dequeueReusableCellWithIdentifier:@"settings.text.cell" forIndexPath:indexPath];
            cell.label.text = @"KISS Server";
        }
        else if( indexPath.row == kSettings_KissPort )
        {
            cell = [tableView dequeueReusableCellWithIdentifier:@"settings.number.cell" forIndexPath:indexPath];
            cell.label.text = @"KISS Port";
        }
        else
        {
            SettingsButtonCell* button = [tableView dequeueReusableCellWithIdentifier:@"settings.button.cell" forIndexPath:indexPath];
            [button.button setTitle:@"Connect" forState:UIControlStateNormal];
            [button.button setTitle:@"Disconnect" forState:UIControlStateSelected];
            button.label.text = @"Status text here";
            return button;
        }
        return cell;
    }
    else
    {
        SettingsAboutCell* cell = [tableView dequeueReusableCellWithIdentifier:@"settings.about.cell" forIndexPath:indexPath];
        cell.text.font             = [UIFont systemFontOfSize:11];
        cell.text.text             = [self aboutVersionString];

        cell.image.image = [UIImage imageNamed:@"LogoWhite"];
        return cell;
    }

    return nil;
}



- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    if( section == kSettingsSection_Settings )
        return @"Settings";
    
    return nil;
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if( section == kSettingsSection_Settings )
        return kPrefsTableTitleHeight;

    return 0.0f;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if( indexPath.section == kSettingsSection_About )
        return kPrefsTableAboutHeight;
        
    return tableView.rowHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if( section == kSettingsSection_Settings )
        return self.tableView.safeAreaLayoutGuide.layoutFrame.size.height - kPrefsTableAboutFooterHeight;

    return 0.0f;
}

#pragma mark - Navigation

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
