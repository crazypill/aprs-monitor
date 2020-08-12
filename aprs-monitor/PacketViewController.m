//
//  PacketViewController.m
//  aprs-monitor
//
//  Created by Alex Lelievre on 8/11/20.
//  Copyright © 2020 Apple. All rights reserved.
//

#import "PacketViewController.h"
#import "PacketManager.h"
#import "Packet.h"


@interface PacketViewController ()
@property (nonatomic, weak)   PacketManager*   pm;
@property (nonatomic, strong) NSDateFormatter* dateFormatter;
@property (nonatomic, strong) NSDateFormatter* timeFormatter;
@end


@implementation PacketViewCell
@end


@implementation PacketViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _pm = [PacketManager shared];

    _dateFormatter = [[NSDateFormatter alloc] init];
    _dateFormatter.timeStyle = NSDateFormatterNoStyle;
    _dateFormatter.dateStyle = NSDateFormatterMediumStyle;
    _dateFormatter.locale    = [NSLocale currentLocale];
    _dateFormatter.doesRelativeDateFormatting = YES;
    
    _timeFormatter = [[NSDateFormatter alloc] init];
    _timeFormatter.timeStyle = NSDateFormatterShortStyle;
    _timeFormatter.dateStyle = NSDateFormatterNoStyle;
    _timeFormatter.locale    = [NSLocale currentLocale];

    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newPacketArrived:) name:@"NewPacket" object:nil];

    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}


- (NSString*)getDateString:(NSDate*)date
{
    NSTimeZone* timeZone = [NSTimeZone localTimeZone];
    NSString* gmt = [timeZone abbreviationForDate:date];

    return [NSString stringWithFormat:@"%@ %@ %@", [_dateFormatter stringFromDate:date], [_timeFormatter stringFromDate:date], gmt];
}


#pragma mark -


- (void)newPacketArrived:(id)sender
{
    dispatch_async( dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}


- (IBAction)trashButtonPressed:(id)sender
{
    UIAlertController* actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    __weak PacketViewController* pvc = self;

    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [pvc.pm removeAllItemsAndNotify:YES];
    }]];
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];

    [self presentViewController:actionSheet animated:YES completion:nil];
}


#pragma mark -

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return _pm.items.count;
}


- (UITableViewCell* )tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    PacketViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"packet.info.cell" forIndexPath:indexPath];
    
    // Configure the cell...
    Packet* pkt = [_pm.items objectAtIndex:indexPath.item];
    
    cell.date.text    = [self getDateString:pkt.timeStamp];
    cell.address.text = pkt.address;
    cell.info.text    = pkt.info;

    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
