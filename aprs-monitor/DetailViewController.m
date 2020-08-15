//
//  DetailViewController.m
//  aprs-monitor
//
//  Created by Alex Lelievre on 8/14/20.
//  Copyright © 2020 Apple. All rights reserved.
//

#import "DetailViewController.h"
#import "RemoteTNC.h"
#import "Packet.h"



enum
{
    kDetailSection_Weather,
    kDetailSection_Position,
    kDetailSection_Properties,
    kDetailSection_Telemetry
};


int count_bits( uint32_t input )
{
    int bit_count = 0;
    for( int i = 0; i < 32; i++ )
    {
        if( input & (1 << i) )
            ++bit_count;
    }
    
    return bit_count;
}


int get_bit_number( uint32_t input )
{
    for( int i = 0; i < 32; i++ )
    {
        if( input & (1 << i) )
            return i + 1;
    }
    
    return 0;
}



uint32_t get_next_on_bit( uint32_t input, uint32_t startingBit )
{
    int startBitNumber = get_bit_number( startingBit );
    
    for( int i = startBitNumber; i < (32 - startBitNumber); i++ )
    {
        if( input & (1 << i) )
            return 1 << i;
    }
    
    return 0;
}



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
    
    NSInteger sections = 0;

    // let's see how many sections we have - only two at the moment tops
    if( (_detail.flags & kCoordinatesMask) | (_detail.flags & kCourseSpeedMask) )
        ++sections;
    
    if( (_detail.flags & kPacketFlag_Weather) && _detail.wx )
        ++sections;
    
    return sections;
}


static uint32_t s_weather_state  = 0;
static uint32_t s_position_state = 0;



- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if( section == kDetailSection_Weather )
    {
        s_weather_state = 0;
        // count the number of weather bits we have
        return count_bits( _detail.wx->wxflags );
    }
    else if( section == kDetailSection_Position )
    {
        s_position_state = 0;
        // mask out weather and things
        return count_bits( _detail.flags & kPositionMask );
    }
    return 0;
}



- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    if( indexPath.section == kDetailSection_Weather )
    {
        s_weather_state = get_next_on_bit( _detail.wx->wxflags, s_weather_state );
        
        if( s_weather_state & (kWxDataFlag_gust | kWxDataFlag_windDir | kWxDataFlag_wind) )
        {
            WindCell* cell = [tableView dequeueReusableCellWithIdentifier:@"detail.wind.cell" forIndexPath:indexPath];

            // Configure the cell...
            int windIndex = (int)(_detail.wx->windDirection / 22.5f); // truncate
            const char* compass[] = { "N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW" };
            
            // !!@ use attributed string here to make data part grey !!@
            cell.line1.text = [NSString stringWithFormat:@"Wind    🧭%s  %.0f°  %0.1f mph", compass[windIndex], _detail.wx->windDirection, _detail.wx->windSpeedMph];
            cell.line2.text = [NSString stringWithFormat:@"Gusts   💨%0.1f mph", _detail.wx->windGustMph];

            cell.windIcon.image = [_detail getWindIndicatorIcon:CGRectMake( 0, 0,  40, 40 )];
            return cell;
        }
        else if( s_weather_state & kWxDataFlag_temp )
        {
            DetailGenericCell* cell = [tableView dequeueReusableCellWithIdentifier:@"detail.generic.field" forIndexPath:indexPath];
            cell.name.text = @"Temperature";
            cell.data.text = [NSString stringWithFormat:@"🌡%.2f °F", _detail.wx->tempF];
            return cell;
        }
        else if( s_weather_state & kWxDataFlag_humidity )
        {
            DetailGenericCell* cell = [tableView dequeueReusableCellWithIdentifier:@"detail.generic.field" forIndexPath:indexPath];
            cell.name.text = @"Humidity";
            cell.data.text = [NSString stringWithFormat:@"💧%.2d%%", _detail.wx->humidity];
            return cell;
        }
        else if( s_weather_state & kWxDataFlag_pressure )
        {
            DetailGenericCell* cell = [tableView dequeueReusableCellWithIdentifier:@"detail.generic.field" forIndexPath:indexPath];
            cell.name.text = @"Pressure";
            cell.data.text = [NSString stringWithFormat:@"🔻%.2f InHg", _detail.wx->pressure * millibar2inchHg];
            return cell;
        }
        else if( s_weather_state & kWxDataFlag_rainHr )
        {
            DetailGenericCell* cell = [tableView dequeueReusableCellWithIdentifier:@"detail.generic.field" forIndexPath:indexPath];
            cell.name.text = @"Rain last hour";
            cell.data.text = [NSString stringWithFormat:@"🌧 %.2f inches", _detail.wx->rainLastHour];
            return cell;
        }
        else if( s_weather_state & kWxDataFlag_rain24 )
        {
            DetailGenericCell* cell = [tableView dequeueReusableCellWithIdentifier:@"detail.generic.field" forIndexPath:indexPath];
            cell.name.text = @"Rain over 24 hours";
            cell.data.text = [NSString stringWithFormat:@"☔️ %.2f inches", _detail.wx->rainLast24Hrs];
            return cell;
        }
        else if( s_weather_state & kWxDataFlag_rainMid )
        {
            DetailGenericCell* cell = [tableView dequeueReusableCellWithIdentifier:@"detail.generic.field" forIndexPath:indexPath];
            cell.name.text = @"Rain since midnight";
            cell.data.text = [NSString stringWithFormat:@"☂️ %.2f inches", _detail.wx->rainSinceMidnight];
            return cell;
        }
        else if( s_weather_state & kWxDataFlag_rainRaw )
        {
            DetailGenericCell* cell = [tableView dequeueReusableCellWithIdentifier:@"detail.generic.field" forIndexPath:indexPath];
            cell.name.text = @"Raw rain count";
            cell.data.text = [NSString stringWithFormat:@"%.0f buckets", _detail.wx->rainRaw];
            return cell;
        }
        else if( s_weather_state & kWxDataFlag_snow24 )
        {
            DetailGenericCell* cell = [tableView dequeueReusableCellWithIdentifier:@"detail.generic.field" forIndexPath:indexPath];
            cell.name.text = @"Snow over 24 hours";
            cell.data.text = [NSString stringWithFormat:@"❄️ %.2f inches", _detail.wx->snowLast24Hrs];
            return cell;
        }
    }
    else if( indexPath.section == kDetailSection_Position )
    {
        s_position_state = get_next_on_bit( _detail.flags & kPositionMask, s_position_state );
        
        if( s_position_state & kPacketFlag_Latitude )
        {
            DetailGenericCell* cell = [tableView dequeueReusableCellWithIdentifier:@"detail.generic.field" forIndexPath:indexPath];
            cell.name.text = _detail.coordinate.latitude;
            cell.data.text = @"34.45345N";
            return cell;
        }
        else if( s_position_state & kPacketFlag_Longitude )
        {
            DetailGenericCell* cell = [tableView dequeueReusableCellWithIdentifier:@"detail.generic.field" forIndexPath:indexPath];
            cell.name.text = @"Longitude";
            cell.data.text = @"118.45345W";
            return cell;
        }
        else if( s_position_state & kPacketFlag_Course )
        {
            DetailGenericCell* cell = [tableView dequeueReusableCellWithIdentifier:@"detail.generic.field" forIndexPath:indexPath];
            cell.name.text = @"Course";
            cell.data.text = @"295°";
            return cell;
        }
        else if( s_position_state & kPacketFlag_Speed )
        {
            DetailGenericCell* cell = [tableView dequeueReusableCellWithIdentifier:@"detail.generic.field" forIndexPath:indexPath];
            cell.name.text = @"Speed";
            cell.data.text = @"55 mph";
            return cell;
        }
    }

    
    // section properties:
    //        if( indexPath.row == 9 )
    //        {
    //            DetailGenericCell* cell = [tableView dequeueReusableCellWithIdentifier:@"detail.generic.field" forIndexPath:indexPath];
    //            cell.name.text = @"Received";
    //            cell.data.text = [self getDateString:[NSDate now]];
    //            return cell;
    //        }
    //        else if( indexPath.row == 15 )
    //        {
    //            DetailGenericCell* cell = [tableView dequeueReusableCellWithIdentifier:@"detail.generic.field" forIndexPath:indexPath];
    //            cell.name.text = @"Path";
    //            cell.data.text = @"WEER>WEREWR-DSFDSF->BEER";
    //            return cell;
    //        }

    
    
    return nil;
}



//- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
//{
//
//    Packet* pkt = [[Packet alloc] init];
//    pkt.flags |= (kCoordinatesMask | kPacketFlag_Weather);
//    pkt.coordinate = CLLocationCoordinate2DMake( -34.5, 118.20 );
//    pkt.call = @"K6TESTies";
//    pkt.weather = @"fake weather";
//    pkt.symbol = @"/_";
//
//    pkt.wx = malloc( sizeof( wx_data ) );
//    if( pkt.wx )
//    {
//        pkt.wx->wxflags |= (kWxDataFlag_gust | kWxDataFlag_windDir | kWxDataFlag_wind | kWxDataFlag_temp | kWxDataFlag_humidity | kWxDataFlag_pressure);
//        pkt.wx->windGustMph = 10;
//        pkt.wx->windSpeedMph = 2;
//        pkt.wx->windDirection = 195;
//
//        pkt.wx->tempF    = 100;
//        pkt.wx->humidity = 55;
//        pkt.wx->pressure = 1013;
//
//        pkt.weather = [Packet makeWeatherString:pkt.wx];
//    }
//
//    uint32_t bitState = get_next_on_bit( pkt.wx->wxflags, 0 );
//    bitState = get_next_on_bit( pkt.wx->wxflags, bitState );
//    bitState = get_next_on_bit( pkt.wx->wxflags, bitState );
//    bitState = get_next_on_bit( pkt.wx->wxflags, bitState );
//    bitState = get_next_on_bit( pkt.wx->wxflags, bitState );
//
//
//
//    if( indexPath.row == 0 )
//    {
//        // !!@ test code
//        WindCell* cell = [tableView dequeueReusableCellWithIdentifier:@"detail.wind.cell" forIndexPath:indexPath];
//
//        // Configure the cell...
//        int windIndex = (int)(_detail.wx->windDirection / 22.5f); // truncate
//        const char* compass[] = { "N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW" };
//
//        // !!@ use attributed string here to make data part grey !!@
//        cell.line1.text = [NSString stringWithFormat:@"Wind    🧭%s  %.0f°  %0.1f mph", compass[windIndex], _detail.wx->windDirection, _detail.wx->windSpeedMph];
//        cell.line2.text = [NSString stringWithFormat:@"Gusts   💨%0.1f mph", _detail.wx->windGustMph];
//
//        cell.windIcon.image = [pkt getWindIndicatorIcon:CGRectMake( 0, 0,  40, 40 )];
//        return cell;
//    }
//    else if( indexPath.row == 1 )
//    {
//        DetailGenericCell* cell = [tableView dequeueReusableCellWithIdentifier:@"detail.generic.field" forIndexPath:indexPath];
//        cell.name.text = @"Temperature";
//        cell.data.text = [NSString stringWithFormat:@"🌡%.2f °F", pkt.wx->tempF];
//        return cell;
//    }
//    else if( indexPath.row == 2 )
//    {
//        DetailGenericCell* cell = [tableView dequeueReusableCellWithIdentifier:@"detail.generic.field" forIndexPath:indexPath];
//        cell.name.text = @"Humidity";
//        cell.data.text = [NSString stringWithFormat:@"💧%.2d%%", pkt.wx->humidity];
//        return cell;
//    }
//    else if( indexPath.row == 3 )
//    {
//        DetailGenericCell* cell = [tableView dequeueReusableCellWithIdentifier:@"detail.generic.field" forIndexPath:indexPath];
//        cell.name.text = @"Pressure";
//        cell.data.text = [NSString stringWithFormat:@"🔻%.2f InHg", pkt.wx->pressure * millibar2inchHg];
//        return cell;
//    }
//    else if( indexPath.row == 4 )
//    {
//        DetailGenericCell* cell = [tableView dequeueReusableCellWithIdentifier:@"detail.generic.field" forIndexPath:indexPath];
//        cell.name.text = @"Rain last hour";
//        cell.data.text = [NSString stringWithFormat:@"🌧 %.2f inches", 1.];
//        return cell;
//    }
//    else if( indexPath.row == 5 )
//    {
//        DetailGenericCell* cell = [tableView dequeueReusableCellWithIdentifier:@"detail.generic.field" forIndexPath:indexPath];
//        cell.name.text = @"Rain over 24 hours";
//        cell.data.text = [NSString stringWithFormat:@"☔️ %.2f inches", 2.];
//        return cell;
//    }
//    else if( indexPath.row == 6 )
//    {
//        DetailGenericCell* cell = [tableView dequeueReusableCellWithIdentifier:@"detail.generic.field" forIndexPath:indexPath];
//        cell.name.text = @"Rain since midnight";
//        cell.data.text = [NSString stringWithFormat:@"☂️ %.2f inches", 3.2];
//        return cell;
//    }
//    else if( indexPath.row == 7 )
//    {
//        DetailGenericCell* cell = [tableView dequeueReusableCellWithIdentifier:@"detail.generic.field" forIndexPath:indexPath];
//        cell.name.text = @"Raw rain count";
//        cell.data.text = [NSString stringWithFormat:@"%d buckets", 2];
//        return cell;
//    }
//    else if( indexPath.row == 8 )
//    {
//        DetailGenericCell* cell = [tableView dequeueReusableCellWithIdentifier:@"detail.generic.field" forIndexPath:indexPath];
//        cell.name.text = @"Snow over 24 hours";
//        cell.data.text = [NSString stringWithFormat:@"❄️ %.2f inches", 12.7];
//        return cell;
//    }
//    else if( indexPath.row == 9 )
//    {
//        DetailGenericCell* cell = [tableView dequeueReusableCellWithIdentifier:@"detail.generic.field" forIndexPath:indexPath];
//        cell.name.text = @"Received";
//        cell.data.text = [self getDateString:[NSDate now]];
//        return cell;
//    }
//    else if( indexPath.row == 10 )
//    {
//        DetailGenericCell* cell = [tableView dequeueReusableCellWithIdentifier:@"detail.generic.field" forIndexPath:indexPath];
//        cell.name.text = @"Latitude";
//        cell.data.text = @"34.45345N";
//        return cell;
//    }
//    else if( indexPath.row == 11 )
//    {
//        DetailGenericCell* cell = [tableView dequeueReusableCellWithIdentifier:@"detail.generic.field" forIndexPath:indexPath];
//        cell.name.text = @"Longitude";
//        cell.data.text = @"118.45345W";
//        return cell;
//    }
//    else if( indexPath.row == 12 )
//    {
//        DetailGenericCell* cell = [tableView dequeueReusableCellWithIdentifier:@"detail.generic.field" forIndexPath:indexPath];
//        cell.name.text = @"Longitude";
//        cell.data.text = @"118.45345W";
//        return cell;
//    }
//    else if( indexPath.row == 13 )
//    {
//        DetailGenericCell* cell = [tableView dequeueReusableCellWithIdentifier:@"detail.generic.field" forIndexPath:indexPath];
//        cell.name.text = @"Course";
//        cell.data.text = @"295°";
//        return cell;
//    }
//    else if( indexPath.row == 14 )
//    {
//        DetailGenericCell* cell = [tableView dequeueReusableCellWithIdentifier:@"detail.generic.field" forIndexPath:indexPath];
//        cell.name.text = @"Speed";
//        cell.data.text = @"55 mph";
//        return cell;
//    }
//    else if( indexPath.row == 15 )
//    {
//        DetailGenericCell* cell = [tableView dequeueReusableCellWithIdentifier:@"detail.generic.field" forIndexPath:indexPath];
//        cell.name.text = @"Path";
//        cell.data.text = @"WEER>WEREWR-DSFDSF->BEER";
//        return cell;
//    }
//    else
//    {
//    }
//
//    return nil;
//}


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
