#import "StoresViewController.h"
#import "StoreDetailViewController.h"
#import "DDAPI.h"
#import "LocationFinder.h"
#import "Theme.h"

#pragma mark - Map pin model

@interface StoreAnnotation : NSObject <MKAnnotation> {
    CLLocationCoordinate2D _coordinate;
    NSString *_title;
    NSString *_subtitle;
    NSUInteger _index;
}
@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, assign) NSUInteger index;
@end

@implementation StoreAnnotation
@synthesize coordinate = _coordinate;
@synthesize title = _title;
@synthesize subtitle = _subtitle;
@synthesize index = _index;
- (void)dealloc {
    [_title release];
    [_subtitle release];
    [super dealloc];
}
@end

#pragma mark - Screen

@interface StoresViewController ()
- (void)nearMe;
- (void)toggleChanged;
- (void)showMessage:(NSString *)msg busy:(BOOL)busy;
- (void)searchLat:(double)lat lng:(double)lng;
- (void)showStoreAtIndex:(NSUInteger)i;
@end

@implementation StoresViewController

- (id)init {
    if ((self = [super init])) {
        self.title = @"Restaurants";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    CGRect b = self.view.bounds;
    CGRect below = CGRectMake(0, 44, b.size.width, b.size.height - 44);

    _toggle = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Map", @"List", nil]];
    _toggle.segmentedControlStyle = UISegmentedControlStyleBar;
    _toggle.tintColor = [UIColor colorWithRed:0.82f green:0.32f blue:0.05f alpha:1];
    _toggle.frame = CGRectMake(0, 0, 130, 30);
    _toggle.selectedSegmentIndex = 0;
    [_toggle addTarget:self action:@selector(toggleChanged) forControlEvents:UIControlEventValueChanged];
    self.navigationItem.titleView = _toggle;

    UIBarButtonItem *near = [[UIBarButtonItem alloc] initWithTitle:@"Near Me"
        style:UIBarButtonItemStyleBordered target:self action:@selector(nearMe)];
    self.navigationItem.rightBarButtonItem = near;
    [near release];

    _map = [[MKMapView alloc] initWithFrame:below];
    _map.delegate = self;
    _map.showsUserLocation = YES;
    _map.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_map];

    _table = [[UITableView alloc] initWithFrame:below style:UITableViewStylePlain];
    _table.dataSource = self;
    _table.delegate = self;
    _table.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _table.hidden = YES;
    [self.view addSubview:_table];

    _status = [[UILabel alloc] initWithFrame:CGRectMake(24, 110, b.size.width - 48, 130)];
    _status.numberOfLines = 0;
    _status.textAlignment = UITextAlignmentCenter;
    _status.font = [UIFont systemFontOfSize:16];
    _status.textColor = [UIColor grayColor];
    _status.backgroundColor = [UIColor colorWithWhite:1 alpha:0.9f];
    _status.hidden = YES;
    [self.view addSubview:_status];

    _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    _spinner.center = CGPointMake(b.size.width / 2, 90);
    _spinner.hidesWhenStopped = YES;
    [self.view addSubview:_spinner];

    // Search bar last so it sits on top of the map.
    _search = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, b.size.width, 44)];
    _search.delegate = self;
    _search.placeholder = @"Enter city and state or Zip Code";
    _search.tintColor = DD_ORANGE;
    _search.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:_search];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!_didAuto) {
        _didAuto = YES;
        [self nearMe];
    }
}

- (void)toggleChanged {
    BOOL showMap = (_toggle.selectedSegmentIndex == 0);
    _map.hidden = !showMap || !_status.hidden;
    _table.hidden = showMap || !_status.hidden;
}

- (void)showMessage:(NSString *)msg busy:(BOOL)busy {
    if (busy) [_spinner startAnimating]; else [_spinner stopAnimating];
    _status.text = msg;
    _status.frame = CGRectMake(24, busy ? 120 : 70, self.view.bounds.size.width - 48, 110);
    _status.hidden = (msg == nil);
    if (msg) { _map.hidden = YES; _table.hidden = YES; }
    else [self toggleChanged];
}

- (void)nearMe {
    [_search resignFirstResponder];
    int gen = ++_gen;
    [self showMessage:@"Finding your location..." busy:YES];
    [LocationFinder findCurrent:^(CLLocation *loc, NSString *message) {
        if (gen != _gen) return;
        if (!loc) { [self showMessage:message busy:NO]; return; }
        [self searchLat:loc.coordinate.latitude lng:loc.coordinate.longitude];
    }];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)bar {
    [bar resignFirstResponder];
    NSString *text = [bar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([text length] == 0) return;
    int gen = ++_gen;
    [self showMessage:@"Looking up that place..." busy:YES];
    [LocationFinder geocode:text completion:^(CLLocation *loc, NSString *message) {
        if (gen != _gen) return;
        if (!loc) { [self showMessage:message busy:NO]; return; }
        [self searchLat:loc.coordinate.latitude lng:loc.coordinate.longitude];
    }];
}

- (void)searchLat:(double)lat lng:(double)lng {
    int gen = ++_gen;
    [self showMessage:@"Finding stores..." busy:YES];
    [DDAPI searchStoresNearLatitude:lat longitude:lng radius:15 completion:^(NSArray *stores, NSError *err) {
        if (gen != _gen) return;
        if (!stores) {
            [self showMessage:[NSString stringWithFormat:@"Couldn't load stores.\n%@", [err localizedDescription]] busy:NO];
            return;
        }
        [_stores release];
        _stores = [stores retain];
        if ([stores count] == 0) { [self showMessage:@"No stores found within 15 miles." busy:NO]; return; }

        // Map pins
        for (id a in [[[_map annotations] copy] autorelease]) {
            if ([a isKindOfClass:[StoreAnnotation class]]) [_map removeAnnotation:a];
        }
        double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;
        int pins = 0;
        for (NSUInteger i = 0; i < [stores count]; i++) {
            NSDictionary *s = [stores objectAtIndex:i];
            double la = [[s objectForKey:@"lat"] doubleValue], lo = [[s objectForKey:@"lng"] doubleValue];
            if (la == 0 && lo == 0) continue;
            StoreAnnotation *pin = [[StoreAnnotation alloc] init];
            pin.coordinate = CLLocationCoordinate2DMake(la, lo);
            pin.title = [s objectForKey:@"line1"];
            NSString *city = [s objectForKey:@"city"], *state = [s objectForKey:@"state"], *zip = [s objectForKey:@"zip"];
            pin.subtitle = [NSString stringWithFormat:@"%@%@%@", city ? city : @"", state ? [@" " stringByAppendingString:state] : @"",
                            zip ? [@" " stringByAppendingString:zip] : @""];
            pin.index = i;
            [_map addAnnotation:pin];
            [pin release];
            if (la < minLat) minLat = la;
            if (la > maxLat) maxLat = la;
            if (lo < minLng) minLng = lo;
            if (lo > maxLng) maxLng = lo;
            pins++;
        }
        if (pins > 0) {
            MKCoordinateRegion r;
            r.center = CLLocationCoordinate2DMake((minLat + maxLat) / 2, (minLng + maxLng) / 2);
            r.span = MKCoordinateSpanMake(MAX((maxLat - minLat) * 1.4, 0.02), MAX((maxLng - minLng) * 1.4, 0.02));
            [_map setRegion:r animated:NO];
        } else {
            [_map setCenterCoordinate:CLLocationCoordinate2DMake(lat, lng) animated:NO];
        }

        [self showMessage:nil busy:NO];
        [_table reloadData];
        [_table setContentOffset:CGPointZero animated:NO];
    }];
}

#pragma mark - Map

- (MKAnnotationView *)mapView:(MKMapView *)mv viewForAnnotation:(id<MKAnnotation>)annotation {
    if (![annotation isKindOfClass:[StoreAnnotation class]]) return nil;
    MKPinAnnotationView *v = (MKPinAnnotationView *)[mv dequeueReusableAnnotationViewWithIdentifier:@"pin"];
    if (!v) {
        v = [[[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"pin"] autorelease];
        v.canShowCallout = YES;
        v.pinColor = MKPinAnnotationColorPurple;
        v.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    } else {
        v.annotation = annotation;
    }
    return v;
}

- (void)mapView:(MKMapView *)mv annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
    if ([view.annotation isKindOfClass:[StoreAnnotation class]]) {
        [self showStoreAtIndex:((StoreAnnotation *)view.annotation).index];
    }
}

- (void)showStoreAtIndex:(NSUInteger)i {
    if (i >= [_stores count]) return;
    StoreDetailViewController *vc = [[StoreDetailViewController alloc] initWithStore:[_stores objectAtIndex:i]];
    [self.navigationController pushViewController:vc animated:YES];
    [vc release];
}

#pragma mark - List

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)[_stores count];
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    static NSString *cid = @"store";
    UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:cid];
    if (!cell) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cid] autorelease];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    NSDictionary *s = [_stores objectAtIndex:(NSUInteger)ip.row];
    cell.textLabel.text = [s objectForKey:@"line1"];
    NSMutableArray *parts = [NSMutableArray array];
    NSString *city = [s objectForKey:@"city"], *state = [s objectForKey:@"state"];
    if (city && state) [parts addObject:[NSString stringWithFormat:@"%@, %@", city, state]];
    else if (city) [parts addObject:city];
    NSNumber *dist = [s objectForKey:@"distance"];
    if (dist) [parts addObject:[NSString stringWithFormat:@"%.1f mi", [dist doubleValue]]];
    NSString *status = [s objectForKey:@"status"];
    if (status) [parts addObject:[[status lowercaseString] capitalizedString]];
    cell.detailTextLabel.text = [parts componentsJoinedByString:@"  -  "];
    return cell;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)ip {
    [tv deselectRowAtIndexPath:ip animated:YES];
    [self showStoreAtIndex:(NSUInteger)ip.row];
}

- (void)dealloc {
    _search.delegate = nil;
    _table.delegate = nil;
    _table.dataSource = nil;
    _map.delegate = nil;
    [_search release];
    [_table release];
    [_map release];
    [_toggle release];
    [_status release];
    [_spinner release];
    [_stores release];
    [super dealloc];
}

@end
