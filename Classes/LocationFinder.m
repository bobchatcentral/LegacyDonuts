#import "LocationFinder.h"

static id gGeocoder = nil;

@interface LocationFinder ()
- (void)startWithCompletion:(LocationCompletion)done;
- (void)finish:(CLLocation *)loc message:(NSString *)msg;
@end

@implementation LocationFinder

// The instance keeps itself alive until it finishes.
+ (void)findCurrent:(LocationCompletion)done {
    LocationFinder *f = [[LocationFinder alloc] init];
    [f startWithCompletion:done];
}

- (void)startWithCompletion:(LocationCompletion)done {
    _done = [done copy];
    if (![CLLocationManager locationServicesEnabled]) {
        [self finish:nil message:@"Location Services are turned off. Search by ZIP code instead."];
        return;
    }
    _mgr = [[CLLocationManager alloc] init];
    _mgr.delegate = self;
    _mgr.desiredAccuracy = kCLLocationAccuracyKilometer;
    _mgr.purpose = @"Find Dunkin' stores near you.";
    [_mgr startUpdatingLocation];
    [self performSelector:@selector(timedOut) withObject:nil afterDelay:20.0];
}

- (void)timedOut {
    [self finish:nil message:@"Couldn't get your location. Search by ZIP code instead."];
}

- (void)finish:(CLLocation *)loc message:(NSString *)msg {
    if (_finished) return;
    _finished = YES;
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [_mgr stopUpdatingLocation];
    _mgr.delegate = nil;
    if (_done) _done(loc, msg);
    [self release];   // balances the alloc in +findCurrent:
}

- (void)locationManager:(CLLocationManager *)m didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation {
    if (newLocation.horizontalAccuracy < 0) return;
    if ([newLocation.timestamp timeIntervalSinceNow] < -120) return;   // stale cached fix
    [self finish:newLocation message:nil];
}

- (void)locationManager:(CLLocationManager *)m didFailWithError:(NSError *)error {
    if ([error code] == kCLErrorLocationUnknown) return;   // keep waiting
    if ([error code] == kCLErrorDenied) {
        [self finish:nil message:@"Location access was denied. Search by ZIP code instead."];
    } else {
        [self finish:nil message:@"Couldn't get your location. Search by ZIP code instead."];
    }
}

+ (void)geocode:(NSString *)text completion:(LocationCompletion)done {
    Class gc = NSClassFromString(@"CLGeocoder");
    if (!gc) { done(nil, @"ZIP code search needs iOS 5 or later. Use Near Me instead."); return; }
    [gGeocoder cancelGeocode];
    [gGeocoder release];
    gGeocoder = [[gc alloc] init];

    LocationCompletion cb = [[done copy] autorelease];
    void (^handler)(NSArray *, NSError *) = ^(NSArray *placemarks, NSError *err) {
        CLLocation *loc = nil;
        if ([placemarks count]) loc = [[placemarks objectAtIndex:0] valueForKey:@"location"];
        if (loc) cb(loc, nil);
        else cb(nil, @"Couldn't find that place. Try a ZIP code.");
    };
    [gGeocoder performSelector:@selector(geocodeAddressString:completionHandler:)
                    withObject:text
                    withObject:[[handler copy] autorelease]];
}

- (void)dealloc {
    [_mgr release];
    [_done release];
    [super dealloc];
}

@end
