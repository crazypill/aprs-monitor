//
//  SettingsController.m
//  aprs-monitor
//
//  Created by Alex Lelievre on 8/16/20.
//  Copyright © 2020 Far Out Labs, LLC. All rights reserved.
//

#import "SettingsController.h"
#import "MapViewController.h"


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
@property (weak, nonatomic)   UIButton*     __nullable connectButton;
@property (weak, nonatomic)   UILabel*      __nullable statusLabel;
@property (weak, nonatomic)   UITextField*  __nullable addressField;
@property (weak, nonatomic)   UITextField*  __nullable portField;

@property (strong, nonatomic) NSString* __nullable serverAddress;
@property (nonatomic)         NSInteger            serverPort;
@end


@implementation SettingsController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard:)];
    [self.tableView addGestureRecognizer:tap];
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
            cell.field.placeholder = @"aprs.local"; // my server :)
            _addressField = cell.field;
            [_addressField addTarget:self action:@selector(nextField:) forControlEvents:UIControlEventEditingDidEndOnExit];
        }
        else if( indexPath.row == kSettings_KissPort )
        {
            cell = [tableView dequeueReusableCellWithIdentifier:@"settings.number.cell" forIndexPath:indexPath];
            cell.label.text = @"KISS Port";
            cell.field.placeholder = @"8001";     // standard KISS port
            _portField = cell.field;
            [_portField addTarget:self action:@selector(dismissKeyboard:) forControlEvents:UIControlEventEditingDidEndOnExit];
        }
        else
        {
            SettingsButtonCell* button = [tableView dequeueReusableCellWithIdentifier:@"settings.button.cell" forIndexPath:indexPath];
            [button.button setTitle:@"Connect" forState:UIControlStateNormal];
            [button.button setTitle:@"Disconnect" forState:UIControlStateSelected];
            [button.button addTarget:self action:@selector(connectButtonPressed:) forControlEvents:UIControlEventPrimaryActionTriggered];
            button.label.text = nil;
            _connectButton = button.button;
            _statusLabel = button.label;
            
            if( [MapViewController shared].connected )
            {
                _connectButton.selected = YES; // this changes the text to disconnect...
                _statusLabel.text = @"Connected...";    // !!@ remove literals
            }
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

#pragma mark -

- (void)nextField:(UITextField*)sender
{
    if( _portField )
        [_portField becomeFirstResponder];
}


- (void)dismissKeyboard:(UITextField*)sender
{
    if( _portField && _portField.self.isFirstResponder )
        [_portField resignFirstResponder];

    if( _addressField && _addressField.self.isFirstResponder )
        [_addressField resignFirstResponder];
}


- (IBAction)connectButtonPressed:(id)sender
{
    // focus the fields if they are empty... (leaving port field empty is fine, but not server)
    if( ![MapViewController shared].connected && !_serverAddress )
    {
        [_addressField becomeFirstResponder];
        return;
    }
    
    [self dismissKeyboard:nil];
    
    // make sure to set the server address in the prefs as this routine will read it before connecting async...
    if( _connectButton )
        _connectButton.enabled = NO;
    
    __weak SettingsController* weakself = self;

    if( [MapViewController shared].connected )
    {
        [[MapViewController shared] disconnectFromServer:^( bool wasConnecting, int errorCode ) {
            dispatch_async( dispatch_get_main_queue(), ^{
                if( weakself.statusLabel )
                    weakself.statusLabel.text = @"Disconnected...\n";
                if( weakself.connectButton )
                {
                    weakself.connectButton.enabled = YES;
                    weakself.connectButton.selected = NO;
                }
            });
        }];
    }
    else
    {
        [[MapViewController shared] connectToServer:^( bool wasConnecting, int errorCode ) {
            if( wasConnecting && weakself.statusLabel )
            {
                dispatch_async( dispatch_get_main_queue(), ^{
                    if( !errorCode )
                        weakself.statusLabel.text = @"Connected...\n";
                    else
                        weakself.statusLabel.text = [NSString stringWithFormat:@"Error connecting... %d\n", errorCode];
                    
                    if( weakself.connectButton )
                    {
                        weakself.connectButton.enabled = YES;
                        weakself.connectButton.selected = YES; // this changes the text to disconnect...
                    }
                });
            }
        }];
    }
}



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
