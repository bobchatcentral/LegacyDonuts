#import <Foundation/Foundation.h>

// JSON helpers that compile against the iOS 4.3 SDK but use NSJSONSerialization
// at run time (iOS 5 and later).
@interface JSONUtil : NSObject
+ (id)parse:(NSData *)data;                 // nil if invalid, or on iOS 4
+ (NSData *)dataFromObject:(id)object;
@end
