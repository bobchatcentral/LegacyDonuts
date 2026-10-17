#import <Foundation/Foundation.h>

extern NSString *const SampleCardsChangedNotification;

// SAMPLE cards only: they live on this phone, hold no value and have no barcode or card number.
// Each entry: amount (NSNumber), design (NSNumber), date (NSDate).
@interface SampleCards : NSObject
+ (NSArray *)all;     // the first launch seeds one $50.00 sample; after that it can be empty
+ (void)addCardWithAmount:(double)amount design:(int)design;
+ (void)removeCardAtIndex:(NSUInteger)index;
@end
