#import "MoreViewController.h"
#import "WebViewController.h"
#import "NotificationsViewController.h"
#import "SpeedTest.h"
#import "DDStyle.h"
#import "Theme.h"

@implementation MoreViewController

- (id)init {
    if ((self = [super init])) {
        self.title = @"More";
        _sections = [[NSArray alloc] initWithObjects:
            [NSDictionary dictionaryWithObjectsAndKeys:@"Order", @"title",
                [NSArray arrayWithObjects:@"Order online (website)", nil], @"rows", nil],
            [NSDictionary dictionaryWithObjectsAndKeys:@"Dunkin' Donuts", @"title",
                [NSArray arrayWithObjects:@"Dunkin' Donuts website", nil], @"rows", nil],
            [NSDictionary dictionaryWithObjectsAndKeys:@"Notifications", @"title",
                [NSArray arrayWithObjects:@"Reminders", nil], @"rows", nil],
            [NSDictionary dictionaryWithObjectsAndKeys:@"Tools", @"title",
                [NSArray arrayWithObjects:@"Speed test", nil], @"rows", nil],
            [NSDictionary dictionaryWithObjectsAndKeys:@"About", @"title",
                [NSArray arrayWithObjects:@"About this app", nil], @"rows", nil],
            nil];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _table = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    _table.dataSource = self;
    _table.delegate = self;
    _table.backgroundView = nil;
    _table.backgroundColor = [DDStyle backgroundPattern];
    _table.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_table];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv { return (NSInteger)[_sections count]; }

- (NSString *)tableView:(UITableView *)tv titleForHeaderInSection:(NSInteger)s {
    return [[_sections objectAtIndex:(NSUInteger)s] objectForKey:@"title"];
}

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s {
    return (NSInteger)[[[_sections objectAtIndex:(NSUInteger)s] objectForKey:@"rows"] count];
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:@"more"];
    if (!cell) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"more"] autorelease];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.font = [UIFont boldSystemFontOfSize:17];
    }
    cell.textLabel.text = [[[_sections objectAtIndex:(NSUInteger)ip.section] objectForKey:@"rows"]
                           objectAtIndex:(NSUInteger)ip.row];
    return cell;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)ip {
    [tv deselectRowAtIndexPath:ip animated:YES];
    NSString *title = [[_sections objectAtIndex:(NSUInteger)ip.section] objectForKey:@"title"];
    if ([title isEqualToString:@"Order"]) {
        WebViewController *vc = [[WebViewController alloc] initWithURL:kURLOrder title:@"Order"];
        [self.navigationController pushViewController:vc animated:YES];
        [vc release];
    } else if ([title isEqualToString:@"Dunkin' Donuts"]) {
        WebViewController *vc = [[WebViewController alloc] initWithURL:kURLHome title:@"Dunkin' Donuts"];
        [self.navigationController pushViewController:vc animated:YES];
        [vc release];
    } else if ([title isEqualToString:@"Notifications"]) {
        NotificationsViewController *vc = [[NotificationsViewController alloc] init];
        [self.navigationController pushViewController:vc animated:YES];
        [vc release];
    } else if ([title isEqualToString:@"Tools"]) {
        [SpeedTest run];
    } else {
        UIAlertView *a = [[UIAlertView alloc] initWithTitle:@"About this app"
            message:@"This is an unofficial fan-made app. It is not made by or connected to Dunkin' Brands. Store and menu information comes from dunkindonuts.com and may be out of date. Sample cards have no value."
            delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [a show];
        [a release];
    }
}

- (void)dealloc {
    _table.delegate = nil;
    _table.dataSource = nil;
    [_table release];
    [_sections release];
    [super dealloc];
}

@end
