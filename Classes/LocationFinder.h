#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

// loc is nil and message is set when something went wrong. Always called on the main thread.
typedef void (^LocationCompletion)(CLLocation *loc, NSString *message);

@interface LocationFinder : NSObject <CLLocationManagerDelegate> {
    CLLocationManager *_mgr;
    LocationCompletion _done;
    BOOL _finished;
}
+ (void)findCurrent:(LocationCompletion)done;                        // GPS / Wi-Fi location
+ (void)geocode:(NSString *)text completion:(LocationCompletion)done; // ZIP code or city (iOS 5+)
@end
