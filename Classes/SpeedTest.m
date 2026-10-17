#import "SpeedTest.h"
#include <netdb.h>

static NSString *Fetch(NSString *label, NSString *urlString) {
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]
        cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:60];
    NSURLResponse *resp = nil;
    NSError *err = nil;
    double t0 = CFAbsoluteTimeGetCurrent();
    NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:&resp error:&err];
    double ms = (CFAbsoluteTimeGetCurrent() - t0) * 1000.0;
    if (err) {
        return [NSString stringWithFormat:@"%@: FAILED after %.0f ms (%@ %d)",
                label, ms, [err domain], (int)[err code]];
    }
    int code = [resp isKindOfClass:[NSHTTPURLResponse class]] ? (int)[(NSHTTPURLResponse *)resp statusCode] : 0;
    return [NSString stringWithFormat:@"%@: %.0f ms, HTTP %d, %lu KB",
            label, ms, code, (unsigned long)([data length] / 1024)];
}

@implementation SpeedTest

+ (void)run {
    UIAlertView *wait = [[UIAlertView alloc] initWithTitle:@"Speed test"
        message:@"Running... this can take a minute." delegate:nil
        cancelButtonTitle:nil otherButtonTitles:nil];
    [wait show];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        NSMutableArray *lines = [NSMutableArray array];

        double t0 = CFAbsoluteTimeGetCurrent();
        struct hostent *h = gethostbyname("www.dunkindonuts.com");
        double dns = (CFAbsoluteTimeGetCurrent() - t0) * 1000.0;
        [lines addObject:[NSString stringWithFormat:@"DNS lookup: %.0f ms (%@)", dns, h ? @"ok" : @"FAILED"]];

        [lines addObject:Fetch(@"Plain HTTP", @"http://captive.apple.com/")];
        [lines addObject:Fetch(@"HTTPS small #1", @"https://www.dunkindonuts.com/robots.txt")];
        [lines addObject:Fetch(@"HTTPS small #2", @"https://www.dunkindonuts.com/robots.txt")];
        [lines addObject:Fetch(@"HTTPS menu page", @"https://www.dunkindonuts.com/menu/categories/hot-drinks")];

        NSString *report = [lines componentsJoinedByString:@"\n"];
        NSLog(@"SpeedTest:\n%@", report);

        dispatch_async(dispatch_get_main_queue(), ^{
            [wait dismissWithClickedButtonIndex:0 animated:NO];
            [wait release];
            UIAlertView *a = [[UIAlertView alloc] initWithTitle:@"Speed test" message:report
                delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [a show];
            [a release];
        });
        [pool release];
    });
}

@end
