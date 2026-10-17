#import "BlockingProtocol.h"

static NSArray *BlockedHosts(void) {
    static NSArray *hosts = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        hosts = [[NSArray alloc] initWithObjects:
            @"doubleclick.net", @"googlesyndication.com", @"googleadservices.com",
            @"google-analytics.com", @"googletagmanager.com", @"googletagservices.com",
            @"connect.facebook.net", @"facebook.com", @"flurry.com", @"localytics.com",
            @"fiksu.com", @"demdex.net", @"omtrdc.net", @"adobedtm.com",
            @"hotjar.com", @"newrelic.com", @"nr-data.net", @"tiktok.com",
            @"snapchat.com", @"pinterest.com", @"criteo.com", @"taboola.com",
            @"outbrain.com", @"scorecardresearch.com", @"quantserve.com", nil];
    });
    return hosts;
}

// Set to YES to also block every image (text-only mode, very light).
static BOOL const kBlockImages = NO;

@implementation BlockingProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)req {
    NSString *host = [[req.URL host] lowercaseString];
    for (NSString *b in BlockedHosts()) {
        if ([host isEqualToString:b] || [host hasSuffix:[@"." stringByAppendingString:b]]) return YES;
    }
    NSString *ext = [[req.URL pathExtension] lowercaseString];
    if ([ext isEqualToString:@"mp4"] || [ext isEqualToString:@"webm"] ||
        [ext isEqualToString:@"mov"] || [ext isEqualToString:@"m3u8"]) return YES;
    if (kBlockImages && ([ext isEqualToString:@"jpg"] || [ext isEqualToString:@"jpeg"] ||
        [ext isEqualToString:@"png"] || [ext isEqualToString:@"gif"] || [ext isEqualToString:@"webp"])) return YES;
    return NO;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)req { return req; }

- (void)startLoading {
    NSHTTPURLResponse *resp = [[NSHTTPURLResponse alloc]
        initWithURL:self.request.URL statusCode:200 HTTPVersion:@"HTTP/1.1"
        headerFields:[NSDictionary dictionaryWithObject:@"0" forKey:@"Content-Length"]];
    [self.client URLProtocol:self didReceiveResponse:resp cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    [self.client URLProtocolDidFinishLoading:self];
    [resp release];
}

- (void)stopLoading {}

@end
