#import "DDAPI.h"
#import "JSONUtil.h"

static NSString *const kAPIBase = @"https://api-idp.dunkindonuts.com";
static NSString *const kMenuCacheFile = @"ddmenu_v1.plist";

static NSDictionary *gMenu = nil;          // main thread only
static NSMutableArray *gPending = nil;     // main thread only
static BOOL gLoading = NO;

#pragma mark - Helpers

static NSString *SessionID(void) {
    static NSString *sid = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        CFUUIDRef u = CFUUIDCreate(NULL);
        NSString *s = (NSString *)CFUUIDCreateString(NULL, u);
        CFRelease(u);
        sid = [[[s stringByReplacingOccurrencesOfString:@"-" withString:@""] lowercaseString] retain];
        [s release];
    });
    return sid;
}

static NSError *Err(NSString *msg, NSInteger code) {
    return [NSError errorWithDomain:@"DDAPI" code:code
            userInfo:[NSDictionary dictionaryWithObject:msg forKey:NSLocalizedDescriptionKey]];
}

static NSMutableURLRequest *MakeRequest(NSString *path, NSString *method, NSTimeInterval timeout) {
    NSMutableURLRequest *r = [NSMutableURLRequest
        requestWithURL:[NSURL URLWithString:[kAPIBase stringByAppendingString:path]]
        cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:timeout];
    [r setHTTPMethod:method];
    [r setValue:@"application/json" forHTTPHeaderField:@"accept"];
    [r setValue:@"WEBOA" forHTTPHeaderField:@"x-channel"];
    [r setValue:@"https://www.dunkindonuts.com" forHTTPHeaderField:@"origin"];
    [r setValue:SessionID() forHTTPHeaderField:@"x-session-id"];
    [r setValue:SessionID() forHTTPHeaderField:@"session-id"];
    return r;
}

static NSData *Fetch(NSURLRequest *req, NSError **err) {
    NSURLResponse *resp = nil;
    NSError *e = nil;
    NSData *d = [NSURLConnection sendSynchronousRequest:req returningResponse:&resp error:&e];
    if (!d) { *err = e ? e : Err(@"No response from the server.", -1); return nil; }
    NSInteger sc = [resp isKindOfClass:[NSHTTPURLResponse class]] ? [(NSHTTPURLResponse *)resp statusCode] : 0;
    if (sc < 200 || sc >= 300) {
        NSString *body = [[[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding] autorelease];
        if ([body length] > 140) body = [body substringToIndex:140];
        *err = Err([NSString stringWithFormat:@"The server returned HTTP %d. %@", (int)sc, body ? body : @""], sc);
        return nil;
    }
    return d;
}

static NSString *Str(id v) {
    if ([v isKindOfClass:[NSString class]]) return v;
    if ([v isKindOfClass:[NSNumber class]]) return [v stringValue];
    return nil;
}

static NSString *Trim(NSString *s) {
    return [s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

static void Put(NSMutableDictionary *d, NSString *k, id v) {
    if (v) [d setObject:v forKey:k];
}

static NSString *StripPrefix(NSString *s, NSString *prefix) {
    return [s hasPrefix:prefix] ? [s substringFromIndex:[prefix length]] : s;
}

static NSString *CachePath(void) {
    NSArray *dirs = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return [[dirs objectAtIndex:0] stringByAppendingPathComponent:kMenuCacheFile];
}

#pragma mark - Stores

static NSDictionary *TrimStore(NSDictionary *s) {
    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    Put(d, @"id", Str([s objectForKey:@"id"]));

    NSDictionary *info = [s objectForKey:@"restaurantInfo"];
    NSDictionary *contact = [s objectForKey:@"contactDetails"];
    NSDictionary *addr = [contact isKindOfClass:[NSDictionary class]] ? [contact objectForKey:@"address"] : nil;
    NSString *line1 = [addr isKindOfClass:[NSDictionary class]] ? Str([addr objectForKey:@"line1"]) : nil;
    if (!line1 && [info isKindOfClass:[NSDictionary class]]) line1 = Str([info objectForKey:@"publicName"]);
    Put(d, @"line1", line1 ? line1 : @"Dunkin'");
    if ([addr isKindOfClass:[NSDictionary class]]) {
        Put(d, @"city", Str([addr objectForKey:@"cityName"]));
        Put(d, @"state", Str([addr objectForKey:@"stateProvinceCode"]));
        Put(d, @"zip", Str([addr objectForKey:@"postalCode"]));
    }
    if ([contact isKindOfClass:[NSDictionary class]]) Put(d, @"phone", Str([contact objectForKey:@"phone"]));

    NSDictionary *geo = [s objectForKey:@"geoDetails"];
    if ([geo isKindOfClass:[NSDictionary class]]) {
        Put(d, @"distance", [geo objectForKey:@"distance"]);
        Put(d, @"lat", [geo objectForKey:@"latitude"]);
        Put(d, @"lng", [geo objectForKey:@"longitude"]);
    }
    Put(d, @"status", Str([s objectForKey:@"status"]));

    // Hours, in Monday-first order.
    NSArray *hrs = [s objectForKey:@"locationHours"];
    if ([hrs isKindOfClass:[NSArray class]]) {
        NSArray *order = [NSArray arrayWithObjects:@"MONDAY", @"TUESDAY", @"WEDNESDAY", @"THURSDAY",
                          @"FRIDAY", @"SATURDAY", @"SUNDAY", nil];
        NSMutableArray *out = [NSMutableArray array];
        for (NSString *day in order) {
            for (NSDictionary *h in hrs) {
                if (![h isKindOfClass:[NSDictionary class]]) continue;
                if (![[h objectForKey:@"dayOfWeek"] isEqual:day]) continue;
                NSMutableDictionary *hd = [NSMutableDictionary dictionary];
                Put(hd, @"day", [[day lowercaseString] capitalizedString]);
                Put(hd, @"s", Str([h objectForKey:@"startTime"]));
                Put(hd, @"e", Str([h objectForKey:@"endTime"]));
                Put(hd, @"all", [NSNumber numberWithBool:[[h objectForKey:@"isTwentyFourHourService"] boolValue]]);
                [out addObject:hd];
                break;
            }
        }
        Put(d, @"hours", out);
    }

    NSDictionary *po = [s objectForKey:@"pickupOptions"];
    if ([po isKindOfClass:[NSDictionary class]]) {
        NSMutableArray *p = [NSMutableArray array];
        if ([[po objectForKey:@"hasWalkIn"] boolValue] || [[po objectForKey:@"isWalkInEnabled"] boolValue]) [p addObject:@"Walk-in"];
        if ([[po objectForKey:@"hasDriveThrough"] boolValue] || [[po objectForKey:@"isDriveThroughEnabled"] boolValue]) [p addObject:@"Drive-thru"];
        if ([[po objectForKey:@"hasCurbsidePickup"] boolValue] || [[po objectForKey:@"isCurbsidePickupEnabled"] boolValue]) [p addObject:@"Curbside pickup"];
        if ([[po objectForKey:@"hasWalkUp"] boolValue] || [[po objectForKey:@"isWalkUpEnabled"] boolValue]) [p addObject:@"Walk-up window"];
        Put(d, @"pickup", p);
    }

    NSArray *am = [s objectForKey:@"amenities"];
    if ([am isKindOfClass:[NSArray class]]) {
        NSMutableArray *a = [NSMutableArray array];
        for (id x in am) if ([x isKindOfClass:[NSString class]]) [a addObject:x];
        Put(d, @"amenities", a);
    }
    return d;
}

#pragma mark - Menu

static NSString *NameOf(NSDictionary *dict, NSString *key) {
    NSString *n = Str([[dict objectForKey:key] objectForKey:@"displayName"]);
    return n ? Trim(n) : key;
}

static int RootRank(NSString *key) {
    static NSArray *prefixes = nil;
    if (!prefixes) {
        prefixes = [[NSArray alloc] initWithObjects:@"hot-drinks", @"iced-coffee", @"frozen-drinks",
            @"iced-refreshers", @"donuts", @"sandwiches", @"savory", @"snacks", @"6-meal", @"brew",
            @"bottled", nil];
    }
    for (NSUInteger i = 0; i < [prefixes count]; i++) {
        if ([key hasPrefix:[prefixes objectAtIndex:i]]) return (int)i;
    }
    return 99;
}

static NSDictionary *TrimMenu(NSDictionary *raw) {
    NSDictionary *cats = [raw objectForKey:@"categories"];
    NSDictionary *prods = [raw objectForKey:@"products"];
    NSString *rootRef = [raw objectForKey:@"rootCategoryRef"];
    if (![cats isKindOfClass:[NSDictionary class]] || ![prods isKindOfClass:[NSDictionary class]] ||
        ![rootRef isKindOfClass:[NSString class]]) return nil;

    NSString *rootKey = StripPrefix(rootRef, @"categories.");
    NSMutableDictionary *outCats = [NSMutableDictionary dictionary];
    NSMutableDictionary *outProds = [NSMutableDictionary dictionary];
    NSMutableArray *queue = [NSMutableArray arrayWithObject:rootKey];
    NSMutableSet *seen = [NSMutableSet set];

    while ([queue count]) {
        NSString *ck = [[[queue objectAtIndex:0] retain] autorelease];
        [queue removeObjectAtIndex:0];
        if ([seen containsObject:ck]) continue;
        [seen addObject:ck];
        NSDictionary *c = [cats objectForKey:ck];
        if (![c isKindOfClass:[NSDictionary class]]) continue;

        NSMutableArray *subs = [NSMutableArray array];
        NSMutableArray *items = [NSMutableArray array];
        NSDictionary *refs = [c objectForKey:@"childRefs"];
        if ([refs isKindOfClass:[NSDictionary class]]) {
            for (NSString *ref in refs) {
                if ([ref hasPrefix:@"categories."]) {
                    NSString *k = StripPrefix(ref, @"categories.");
                    if ([cats objectForKey:k]) { [subs addObject:k]; [queue addObject:k]; }
                } else if ([ref hasPrefix:@"products."]) {
                    NSString *k = StripPrefix(ref, @"products.");
                    NSDictionary *p = [prods objectForKey:k];
                    if (![p isKindOfClass:[NSDictionary class]]) continue;
                    [items addObject:k];
                    if ([outProds objectForKey:k]) continue;
                    NSMutableDictionary *pd = [NSMutableDictionary dictionary];
                    Put(pd, @"n", NameOf(prods, k));
                    NSString *desc = Str([p objectForKey:@"description"]);
                    if (desc) Put(pd, @"d", Trim(desc));
                    NSDictionary *nu = [p objectForKey:@"nutrition"];
                    if ([nu isKindOfClass:[NSDictionary class]]) {
                        NSDictionary *rng = [nu objectForKey:@"caloriesRange"];
                        int mn = [[rng objectForKey:@"min"] intValue], mx = [[rng objectForKey:@"max"] intValue];
                        int tot = [[nu objectForKey:@"totalCalories"] intValue];
                        if (mx > mn) Put(pd, @"c", [NSString stringWithFormat:@"%d-%d", mn, mx]);
                        else if (tot > 0) Put(pd, @"c", [NSString stringWithFormat:@"%d", tot]);
                    }
                    [outProds setObject:pd forKey:k];
                }
            }
        }

        BOOL isRoot = [ck isEqualToString:rootKey];
        [subs sortUsingComparator:^NSComparisonResult(id a, id b) {
            if (isRoot) {
                int ra = RootRank(a), rb = RootRank(b);
                if (ra != rb) return ra < rb ? NSOrderedAscending : NSOrderedDescending;
            }
            return [NameOf(cats, a) caseInsensitiveCompare:NameOf(cats, b)];
        }];
        [items sortUsingComparator:^NSComparisonResult(id a, id b) {
            return [NameOf(prods, a) caseInsensitiveCompare:NameOf(prods, b)];
        }];
        [outCats setObject:[NSDictionary dictionaryWithObjectsAndKeys:
            NameOf(cats, ck), @"n", subs, @"subs", items, @"items", nil] forKey:ck];
    }
    if (![outCats objectForKey:rootKey]) return nil;
    return [NSDictionary dictionaryWithObjectsAndKeys:rootKey, @"root", outCats, @"cats", outProds, @"prods", nil];
}

#pragma mark - Public API

@implementation DDAPI

+ (void)searchStoresNearLatitude:(double)lat longitude:(double)lng radius:(int)miles
                      completion:(DDStoresCompletion)done {
    DDStoresCompletion cb = [[done copy] autorelease];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        NSMutableArray *stores = nil;
        NSError *err = nil;

        NSDictionary *area = [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithDouble:lat], @"latitude",
            [NSNumber numberWithDouble:lng], @"longitude",
            [NSNumber numberWithInt:miles], @"radius", nil];
        NSDictionary *body = [NSDictionary dictionaryWithObjectsAndKeys:
            [NSDictionary dictionaryWithObject:area forKey:@"area"], @"query",
            [NSDictionary dictionary], @"filter",
            [NSNumber numberWithInt:0], @"page",
            [NSNumber numberWithInt:15], @"size", nil];

        NSMutableURLRequest *req = MakeRequest(@"/dun/digital-exp-api/v2/locations/search", @"POST", 30);
        [req setValue:@"application/json" forHTTPHeaderField:@"content-type"];
        [req setHTTPBody:[JSONUtil dataFromObject:body]];

        NSData *data = Fetch(req, &err);
        if (data) {
            id root = [JSONUtil parse:data];
            NSArray *locs = [root isKindOfClass:[NSDictionary class]] ? [root objectForKey:@"locations"] : nil;
            if ([locs isKindOfClass:[NSArray class]]) {
                stores = [NSMutableArray array];
                for (id loc in locs) {
                    if ([loc isKindOfClass:[NSDictionary class]]) [stores addObject:TrimStore(loc)];
                }
            } else {
                err = Err(@"Unexpected reply from the store service.", -2);
            }
        }
        NSLog(@"DDAPI: store search -> %d stores, error %@", (int)[stores count], err);
        dispatch_async(dispatch_get_main_queue(), ^{ cb(stores, err); });
        [pool release];
    });
}

+ (void)loadMenu:(DDMenuCompletion)done {
    if (gMenu) { done(gMenu, nil); return; }
    if (!gPending) gPending = [[NSMutableArray alloc] init];
    [gPending addObject:[[done copy] autorelease]];
    if (gLoading) return;
    gLoading = YES;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        NSDictionary *menu = nil;
        NSError *err = nil;
        NSString *path = CachePath();
        double t0 = CFAbsoluteTimeGetCurrent();

        NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:NULL];
        NSDate *mod = [attrs objectForKey:NSFileModificationDate];
        if (mod && [[NSDate date] timeIntervalSinceDate:mod] < 86400.0) {
            NSDictionary *disk = [NSDictionary dictionaryWithContentsOfFile:path];
            if ([disk objectForKey:@"cats"]) menu = disk;
        }
        if (!menu) {
            NSData *data = Fetch(MakeRequest(@"/menu/0", @"GET", 90), &err);
            if (data) {
                id raw = [JSONUtil parse:data];
                if ([raw isKindOfClass:[NSDictionary class]]) menu = TrimMenu(raw);
                if (menu) [menu writeToFile:path atomically:YES];
                else err = Err(@"Unexpected reply from the menu service.", -3);
            }
            if (!menu) {   // fall back to an old cached copy rather than showing nothing
                NSDictionary *old = [NSDictionary dictionaryWithContentsOfFile:path];
                if ([old objectForKey:@"cats"]) { menu = old; err = nil; }
            }
        }
        NSLog(@"DDAPI: menu ready in %.0f ms (%@)", (CFAbsoluteTimeGetCurrent() - t0) * 1000.0,
              menu ? @"ok" : [err localizedDescription]);

        dispatch_async(dispatch_get_main_queue(), ^{
            if (menu) { [gMenu release]; gMenu = [menu retain]; }
            gLoading = NO;
            NSArray *cbs = [[gPending copy] autorelease];
            [gPending removeAllObjects];
            for (id cbo in cbs) { DDMenuCompletion cb = (DDMenuCompletion)cbo; cb(menu, err); }
        });
        [pool release];
    });
}

@end
