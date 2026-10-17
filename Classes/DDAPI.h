#import <Foundation/Foundation.h>

// Both callbacks run on the main thread.
typedef void (^DDStoresCompletion)(NSArray *stores, NSError *error);
typedef void (^DDMenuCompletion)(NSDictionary *menu, NSError *error);

// Store dictionaries: id, line1, city, state, zip, phone, distance (NSNumber), lat, lng,
//   status, hours (array of day/s/e/all), pickup (array of strings), amenities (array of strings)
// Menu dictionary: root (key), cats {key: {n, subs[], items[]}}, prods {key: {n, d, c}}
@interface DDAPI : NSObject
+ (void)searchStoresNearLatitude:(double)lat longitude:(double)lng radius:(int)miles
                      completion:(DDStoresCompletion)done;
+ (void)loadMenu:(DDMenuCompletion)done;   // cached in memory and on disk for 24 hours
@end
