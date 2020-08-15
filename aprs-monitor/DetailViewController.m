//
//  DetailViewController.m
//  aprs-monitor
//
//  Created by Alex Lelievre on 8/14/20.
//  Copyright © 2020 Apple. All rights reserved.
//

#import "DetailViewController.h"
#import "Packet.h"



@interface DetailGenericCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel* name;
@property (weak, nonatomic) IBOutlet UILabel* data;
@end

@implementation DetailGenericCell
@end



@interface WindCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView* windIcon;
@property (weak, nonatomic) IBOutlet UILabel*     line1;
@property (weak, nonatomic) IBOutlet UILabel*     line2;
@end

@implementation WindCell
@end




@interface DetailViewController ()
@property (nonatomic, strong) NSDateFormatter* dateFormatter;
@property (nonatomic, strong) NSDateFormatter* timeFormatter;
@end

@implementation DetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _dateFormatter = [[NSDateFormatter alloc] init];
    _dateFormatter.timeStyle = NSDateFormatterNoStyle;
    _dateFormatter.dateStyle = NSDateFormatterMediumStyle;
    _dateFormatter.locale    = [NSLocale currentLocale];
    _dateFormatter.doesRelativeDateFormatting = YES;
    
    _timeFormatter = [[NSDateFormatter alloc] init];
    _timeFormatter.timeStyle = NSDateFormatterMediumStyle;
    _timeFormatter.dateStyle = NSDateFormatterNoStyle;
    _timeFormatter.locale    = [NSLocale currentLocale];

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


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 6;
}


// detail.wind.cell
- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    
    if( indexPath.row == 0 )
    {
        // !!@ test code
        WindCell* cell = [tableView dequeueReusableCellWithIdentifier:@"detail.wind.cell" forIndexPath:indexPath];

        // Configure the cell...
        cell.line1.text = @"wind speed and direction";
        cell.line2.text = @"gust: blah mph";

        Packet* pkt = [[Packet alloc] init];
        pkt.flags |= (kPacketFlag_CoordinatesValid | kPacketFlag_Weather);
        pkt.coordinate = CLLocationCoordinate2DMake( -34.5, 118.20 );
        pkt.call = @"K6TEST";
        pkt.weather = @"fake weather";
        pkt.symbol = @"/_";
        
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
        }
        
        cell.windIcon.image = [pkt getWindIndicatorIcon:CGRectMake( 0, 0,  40, 40 )];
        return cell;
    }
    else if( indexPath.row == 1 )
    {
        DetailGenericCell* cell = [tableView dequeueReusableCellWithIdentifier:@"detail.generic.field" forIndexPath:indexPath];
        cell.name.text = @"Received";
        cell.data.text = [self getDateString:[NSDate now]];
        return cell;
    }
    else if( indexPath.row == 2 )
    {
        DetailGenericCell* cell = [tableView dequeueReusableCellWithIdentifier:@"detail.generic.field" forIndexPath:indexPath];
        cell.name.text = @"Latitude";
        cell.data.text = @"34.45345N";
        return cell;
    }
    else if( indexPath.row == 3 )
    {
        DetailGenericCell* cell = [tableView dequeueReusableCellWithIdentifier:@"detail.generic.field" forIndexPath:indexPath];
        cell.name.text = @"Longitude";
        cell.data.text = @"118.45345W";
        return cell;
    }
    else if( indexPath.row == 4 )
    {
        DetailGenericCell* cell = [tableView dequeueReusableCellWithIdentifier:@"detail.generic.field" forIndexPath:indexPath];
        cell.name.text = @"Comment";
        cell.data.text = @"blah blah";
        return cell;
    }
    else if( indexPath.row == 5 )
    {
        DetailGenericCell* cell = [tableView dequeueReusableCellWithIdentifier:@"detail.generic.field" forIndexPath:indexPath];
        cell.name.text = @"Path";
        cell.data.text = @"WEER>WEREWR-DSFDSF->BEER";
        return cell;
    }
    else
    {
    }
    
    return nil;
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
