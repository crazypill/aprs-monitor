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
    kDetailSection_Telemetry,
    
    kDetailSection_NumSections // leave last
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
    
    NSInteger sections = 1; // we always have the properties section...

    // let's see how many sections we have - only two at the moment tops
    if( (_detail.flags & kCoordinatesMask) | (_detail.flags & kCourseSpeedMask) )
        ++sections;
    
    if( (_detail.flags & kPacketFlag_Weather) && _detail.wx )
        ++sections;
    
    if( (_detail.flags & kPacketFlag_Telemetry) )
        ++sections;

    return sections;
}


- (NSInteger)getSection:(NSInteger)raw
{
    NSInteger sections = [self numberOfSectionsInTableView:self.tableView];
    // four sections we don't have to do anything.  Also the same for three sections
    if( sections >= (kDetailSection_NumSections - 1) )
        return raw;

    if( sections == 2 )
    {
        // if there are only two sections, they can be either weather and properties, or position and properties
        if( (_detail.flags & kPacketFlag_Weather) )
        {
            if( raw == 0 )
                return kDetailSection_Weather;
            else
                return kDetailSection_Properties;
        }
        else
        {
            if( raw == 0 )
                return kDetailSection_Position;
            else
                return kDetailSection_Properties;
        }
    }
    else if( sections == 1 )
    {
        if( (_detail.flags & kPacketFlag_Weather) )
            return kDetailSection_Weather;
        else
            return kDetailSection_Position;
    }
    
    return -1; // will surely cause a crash
}


- (NSInteger)getNumberOfWeatherRows
{
    int flags = _detail.wx->wxflags;
    if( flags & kWindMask )
    {
        // if we have any weather flags, only set a single bit instead of any combo of 3
        flags &= ~kWindMask;
        flags |= kWxDataFlag_wind;  // only one bit
    }
        
    return count_bits( flags );
}


- (NSInteger)getNumberOfPositionRows
{
    return count_bits( _detail.flags & kPositionMask );
}


- (NSInteger)getNumberOfPropertyRows
{
    // there are always these row in the properties: timestamp, type, destination, and path.
    NSInteger rows = 4;
    // there might also be a status message and a comment...
    if( _detail.comment )
        ++rows;

    return rows;
}


- (NSInteger)getWeatherFlagForRow:(NSInteger)raw
{
    // weather goes in this order, wind, temp, humidity, pressure, rain/rain/rain, snow.
    // if any are missing we just go to the next one.  So if we determined that we have three rows,
    // and the code asks for raw row 2, we need to go thru our weather field list 2 times and see which
    // one we land on based on that index and return the bit for it--
    uint16_t weatherBits = _detail.wx->wxflags;
    uint32_t startingBit = 0;
    
    if( weatherBits & kWindMask )
    {
        // if we have any weather flags, only set a single bit instead of any combo of 3
        weatherBits &= ~kWindMask;
        weatherBits |= kWxDataFlag_wind;  // only one bit
    }

    startingBit = get_next_on_bit( weatherBits, startingBit );

    for( NSInteger i = 0; i < raw; i++ )
        startingBit = get_next_on_bit( weatherBits, startingBit );

    return startingBit;
}


- (NSInteger)getPositionFlagForRow:(NSInteger)raw
{
    uint32_t startingBit = 0;
    startingBit = get_next_on_bit( _detail.flags, startingBit );
    
    for( NSInteger i = 0; i < raw; i++ )
        startingBit = get_next_on_bit( _detail.flags, startingBit );

    return startingBit;
}


- (NSInteger)getPropertiesFlagForRow:(NSInteger)raw
{
    return raw;
}


- (NSInteger)getTelemetryFlagForRow:(NSInteger)raw
{
    return raw;
}



- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if( [self getSection:section] == kDetailSection_Weather )
    {
        return [self getNumberOfWeatherRows];
    }
    else if( [self getSection:section] == kDetailSection_Position )
    {
        return [self getNumberOfPositionRows];
    }
    else if( [self getSection:section] == kDetailSection_Properties )
    {
        return [self getNumberOfPropertyRows];
    }
    return 0;
}


- (nullable NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if( [self getSection:section] == kDetailSection_Weather )
        return @"Weather";
    else if( [self getSection:section] == kDetailSection_Position )
        return @"Position";
    else
        return @"Properties";
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    const char* compass[] = { "N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW" };

    if( [self getSection:indexPath.section] == kDetailSection_Weather )
    {
        NSInteger flags = [self getWeatherFlagForRow:indexPath.row];
        if( flags & kWxDataFlag_wind )  // we only look for one flag as this is the only one that will be set even if there are others after calling getWeatherFlagForRow
        {
            WindCell* cell = [tableView dequeueReusableCellWithIdentifier:@"detail.wind.cell" forIndexPath:indexPath];

            // Configure the cell...
            if( (_detail.wx->wxflags & (kWxDataFlag_windDir | kWxDataFlag_wind)) == (kWxDataFlag_windDir | kWxDataFlag_wind) )
            {
                int windIndex = (int)(_detail.wx->windDirection / 22.5f); // truncate
                const char* compass[] = { "N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW" };
                
                // !!@ use attributed string here to make data part grey !!@
                cell.line1.text = [NSString stringWithFormat:@"Wind    🧭 %s  %.0f°  %0.1f mph", compass[windIndex], _detail.wx->windDirection, _detail.wx->windSpeedMph];
            }
            else if( _detail.wx->wxflags & kWxDataFlag_windDir )
            {
                int windIndex = (int)(_detail.wx->windDirection / 22.5f); // truncate
                
                // !!@ use attributed string here to make data part grey !!@
                cell.line1.text = [NSString stringWithFormat:@"Wind    🧭 %s  %.0f°", compass[windIndex], _detail.wx->windDirection];
            }
            else if( _detail.wx->wxflags & kWxDataFlag_wind )
            {
                cell.line1.text = [NSString stringWithFormat:@"Wind    %0.1f mph", _detail.wx->windSpeedMph];
            }
            else
                cell.line1.text = nil;
            
            if( _detail.wx->wxflags & kWxDataFlag_gust )
                cell.line2.text = [NSString stringWithFormat:@"Gusts   💨 %0.1f mph", _detail.wx->windGustMph];
            else
                cell.line2.text = nil;

            cell.windIcon.image = [_detail getWindIndicatorIcon:CGRectMake( 0, 0,  40, 40 )];
            return cell;
        }
        else if( flags & kWxDataFlag_temp )
        {
            DetailGenericCell* cell = [tableView dequeueReusableCellWithIdentifier:@"detail.generic.field" forIndexPath:indexPath];
            cell.name.text = @"Temperature";
            cell.data.text = [NSString stringWithFormat:@"🌡 %.2f °F", _detail.wx->tempF];
            return cell;
        }
        else if( flags & kWxDataFlag_humidity )
        {
            DetailGenericCell* cell = [tableView dequeueReusableCellWithIdentifier:@"detail.generic.field" forIndexPath:indexPath];
            cell.name.text = @"Humidity";
            cell.data.text = [NSString stringWithFormat:@"💧%.2d%%", _detail.wx->humidity];
            return cell;
        }
        else if( flags & kWxDataFlag_pressure )
        {
            DetailGenericCell* cell = [tableView dequeueReusableCellWithIdentifier:@"detail.generic.field" forIndexPath:indexPath];
            cell.name.text = @"Pressure";
            cell.data.text = [NSString stringWithFormat:@"🔻%.2f InHg", _detail.wx->pressure * millibar2inchHg];
            return cell;
        }
        else if( flags & kWxDataFlag_rainHr )
        {
            DetailGenericCell* cell = [tableView dequeueReusableCellWithIdentifier:@"detail.generic.field" forIndexPath:indexPath];
            cell.name.text = @"Rain last hour";
            cell.data.text = [NSString stringWithFormat:@"🌧 %.2f inches", _detail.wx->rainLastHour];
            return cell;
        }
        else if( flags & kWxDataFlag_rain24 )
        {
            DetailGenericCell* cell = [tableView dequeueReusableCellWithIdentifier:@"detail.generic.field" forIndexPath:indexPath];
            cell.name.text = @"Rain over 24 hours";
            cell.data.text = [NSString stringWithFormat:@"☔️ %.2f inches", _detail.wx->rainLast24Hrs];
            return cell;
        }
        else if( flags & kWxDataFlag_rainMid )
        {
            DetailGenericCell* cell = [tableView dequeueReusableCellWithIdentifier:@"detail.generic.field" forIndexPath:indexPath];
            cell.name.text = @"Rain since midnight";
            cell.data.text = [NSString stringWithFormat:@"☂️ %.2f inches", _detail.wx->rainSinceMidnight];
            return cell;
        }
        else if( flags & kWxDataFlag_rainRaw )
        {
            DetailGenericCell* cell = [tableView dequeueReusableCellWithIdentifier:@"detail.generic.field" forIndexPath:indexPath];
            cell.name.text = @"Raw rain count";
            cell.data.text = [NSString stringWithFormat:@"%.0f buckets", _detail.wx->rainRaw];
            return cell;
        }
        else if( flags & kWxDataFlag_snow24 )
        {
            DetailGenericCell* cell = [tableView dequeueReusableCellWithIdentifier:@"detail.generic.field" forIndexPath:indexPath];
            cell.name.text = @"Snow over 24 hours";
            cell.data.text = [NSString stringWithFormat:@"❄️ %.2f inches", _detail.wx->snowLast24Hrs];
            return cell;
        }
    }
    else if( [self getSection:indexPath.section] == kDetailSection_Position )
    {
        NSInteger flags = [self getPositionFlagForRow:indexPath.row];
        if( flags & kPacketFlag_Latitude )
        {
            DetailGenericCell* cell = [tableView dequeueReusableCellWithIdentifier:@"detail.generic.field" forIndexPath:indexPath];
            cell.name.text = @"Latitude";
            cell.data.text = [NSString stringWithFormat:@"%0.4f", _detail.coordinate.latitude]; // use a formatter so this read in degrees, minutes, seconds
            return cell;
        }
        else if( flags & kPacketFlag_Longitude )
        {
            DetailGenericCell* cell = [tableView dequeueReusableCellWithIdentifier:@"detail.generic.field" forIndexPath:indexPath];
            cell.name.text = @"Longitude";
            cell.data.text = [NSString stringWithFormat:@"%0.4f", _detail.coordinate.longitude]; // use a formatter so this read in degrees, minutes, seconds
            return cell;
        }
        else if( flags & kPacketFlag_Course )
        {
            int courseIndex = (int)(_detail.course / 22.5f); // truncate

            DetailGenericCell* cell = [tableView dequeueReusableCellWithIdentifier:@"detail.generic.field" forIndexPath:indexPath];
            cell.name.text = @"Course";
            cell.data.text = [NSString stringWithFormat:@"🧭 %s %.0f°", compass[courseIndex], _detail.course];
            return cell;
        }
        else if( flags & kPacketFlag_Speed )
        {
            DetailGenericCell* cell = [tableView dequeueReusableCellWithIdentifier:@"detail.generic.field" forIndexPath:indexPath];
            cell.name.text = @"Speed";
            cell.data.text = [NSString stringWithFormat:@"%.2f mph", _detail.speed];
            return cell;
        }
    }
    else if( [self getSection:indexPath.section] == kDetailSection_Properties )
    {
        if( indexPath.row == 0 )
        {
            DetailGenericCell* cell = [tableView dequeueReusableCellWithIdentifier:@"detail.generic.field" forIndexPath:indexPath];
            cell.name.text = @"Received";
            cell.data.text = [self getDateString:_detail.timeStamp];
            return cell;
        }
        if( indexPath.row == 1 )
        {
            DetailGenericCell* cell = [tableView dequeueReusableCellWithIdentifier:@"detail.generic.field" forIndexPath:indexPath];
            cell.name.text = @"Type";
            cell.data.text = _detail.type;
            return cell;
        }
        else if( indexPath.row == 2 )
        {
            DetailGenericCell* cell = [tableView dequeueReusableCellWithIdentifier:@"detail.generic.field" forIndexPath:indexPath];
            cell.name.text = @"Destination";
            cell.data.text = _detail.destination;
            return cell;
        }
        else if( indexPath.row == 3 )
        {
            DetailGenericCell* cell = [tableView dequeueReusableCellWithIdentifier:@"detail.generic.field" forIndexPath:indexPath];
            cell.name.text = @"Path";
            cell.data.text = _detail.path;
            return cell;
        }
        else if( indexPath.row == 4 )
        {
            DetailGenericCell* cell = [tableView dequeueReusableCellWithIdentifier:@"detail.generic.field" forIndexPath:indexPath];
            cell.name.text = @"Comment";
            cell.data.text = _detail.comment;
            return cell;
        }
//        else if( indexPath.row == 4 )
//        {
//            DetailGenericCell* cell = [tableView dequeueReusableCellWithIdentifier:@"detail.generic.field" forIndexPath:indexPath];
//            cell.name.text = @"Status";
//            cell.data.text = ??
//            return cell;
//        }
    }
    

    
    DetailGenericCell* cell = [tableView dequeueReusableCellWithIdentifier:@"detail.generic.field" forIndexPath:indexPath];
    cell.name.text = [NSString stringWithFormat:@"ERROR-> unknown: %@", indexPath];
    return cell;
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
