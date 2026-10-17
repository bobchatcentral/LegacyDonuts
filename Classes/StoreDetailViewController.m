#import "StoreDetailViewController.h"
#import "DDStyle.h"

static NSString *FormatTime(NSString *t) {
    NSArray *p = [t componentsSeparatedByString:@":"];
    if ([p count] < 2) return t;
    int h = [[p objectAtIndex:0] intValue] % 24;
    int m = [[p objectAtIndex:1] intValue];
    int h12 = h % 12;
    if (h12 == 0) h12 = 12;
    return [NSString stringWithFormat:@"%d:%02d %@", h12, m, (h >= 12) ? @"PM" : @"AM"];
}

static NSDictionary *Row(NSString *text, NSString *detail, NSString *action) {
    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    if (text) [d setObject:text forKey:@"text"];
    if (detail) [d setObject:detail forKey:@"detail"];
    if (action) [d setObject:action forKey:@"action"];
    return d;
}

@implementation StoreDetailViewController

- (NSString *)addressLine {
    NSMutableArray *parts = [NSMutableArray array];
    NSString *line1 = [_store objectForKey:@"line1"];
    NSString *city = [_store objectForKey:@"city"], *state = [_store objectForKey:@"state"];
    NSString *zip = [_store objectForKey:@"zip"];
    if (line1) [parts addObject:line1];
    NSMutableString *cs = [NSMutableString string];
    if (city) [cs appendString:city];
    if (state) [cs appendFormat:@"%@%@", [cs length] ? @", " : @"", state];
    if (zip) [cs appendFormat:@" %@", zip];
    if ([cs length]) [parts addObject:cs];
    return [parts componentsJoinedByString:@", "];
}

- (void)addSection:(NSString *)title style:(int)style rows:(NSArray *)rows {
    if ([rows count] == 0) return;
    [_sections addObject:[NSDictionary dictionaryWithObjectsAndKeys:
        title, @"title", [NSNumber numberWithInt:style], @"style", rows, @"rows", nil]];
}

- (id)initWithStore:(NSDictionary *)store {
    if ((self = [super init])) {
        _store = [store retain];
        _sections = [[NSMutableArray alloc] init];
        self.title = [store objectForKey:@"line1"];

        NSMutableArray *contact = [NSMutableArray array];
        NSString *city = [store objectForKey:@"city"];
        [contact addObject:Row([store objectForKey:@"line1"],
            [[self addressLine] length] ? [self addressLine] : city, @"maps")];
        NSString *phone = [store objectForKey:@"phone"];
        if ([phone length]) [contact addObject:Row(phone, @"Call this store", @"call")];
        NSString *status = [store objectForKey:@"status"];
        if (status) [contact addObject:Row([[status lowercaseString] capitalizedString], @"Status right now", nil)];
        [self addSection:@"Store" style:UITableViewCellStyleSubtitle rows:contact];

        NSMutableArray *hours = [NSMutableArray array];
        for (NSDictionary *h in [store objectForKey:@"hours"]) {
            NSString *time;
            if ([[h objectForKey:@"all"] boolValue]) time = @"Open 24 hours";
            else if ([h objectForKey:@"s"] && [h objectForKey:@"e"])
                time = [NSString stringWithFormat:@"%@ - %@", FormatTime([h objectForKey:@"s"]), FormatTime([h objectForKey:@"e"])];
            else time = @"Closed";
            [hours addObject:Row([h objectForKey:@"day"], time, nil)];
        }
        [self addSection:@"Hours" style:UITableViewCellStyleValue1 rows:hours];

        NSMutableArray *pickup = [NSMutableArray array];
        for (NSString *p in [store objectForKey:@"pickup"]) [pickup addObject:Row(p, nil, nil)];
        [self addSection:@"Pickup options" style:UITableViewCellStyleDefault rows:pickup];

        NSMutableArray *am = [NSMutableArray array];
        for (NSString *a in [store objectForKey:@"amenities"]) [am addObject:Row(a, nil, nil)];
        [self addSection:@"Amenities" style:UITableViewCellStyleDefault rows:am];
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
    NSDictionary *sec = [_sections objectAtIndex:(NSUInteger)ip.section];
    NSDictionary *row = [[sec objectForKey:@"rows"] objectAtIndex:(NSUInteger)ip.row];
    int style = [[sec objectForKey:@"style"] intValue];
    NSString *cid = [NSString stringWithFormat:@"c%d", style];
    UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:cid];
    if (!cell) cell = [[[UITableViewCell alloc] initWithStyle:(UITableViewCellStyle)style reuseIdentifier:cid] autorelease];
    cell.textLabel.text = [row objectForKey:@"text"];
    cell.detailTextLabel.text = [row objectForKey:@"detail"];
    NSString *action = [row objectForKey:@"action"];
    cell.accessoryType = action ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
    cell.selectionStyle = action ? UITableViewCellSelectionStyleBlue : UITableViewCellSelectionStyleNone;
    return cell;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)ip {
    [tv deselectRowAtIndexPath:ip animated:YES];
    NSDictionary *sec = [_sections objectAtIndex:(NSUInteger)ip.section];
    NSDictionary *row = [[sec objectForKey:@"rows"] objectAtIndex:(NSUInteger)ip.row];
    NSString *action = [row objectForKey:@"action"];
    if ([action isEqualToString:@"maps"]) {
        NSString *q = [[self addressLine] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:
            [@"http://maps.apple.com/?q=" stringByAppendingString:q]]];
    } else if ([action isEqualToString:@"call"]) {
        NSMutableString *digits = [NSMutableString string];
        NSString *phone = [_store objectForKey:@"phone"];
        for (NSUInteger i = 0; i < [phone length]; i++) {
            unichar c = [phone characterAtIndex:i];
            if ((c >= '0' && c <= '9') || c == '+') [digits appendFormat:@"%C", c];
        }
        NSURL *url = [NSURL URLWithString:[@"tel:" stringByAppendingString:digits]];
        if ([[UIApplication sharedApplication] canOpenURL:url]) [[UIApplication sharedApplication] openURL:url];
    }
}

- (void)dealloc {
    _table.delegate = nil;
    _table.dataSource = nil;
    [_table release];
    [_sections release];
    [_store release];
    [super dealloc];
}

@end
