#import "SampleCards.h"

NSString *const SampleCardsChangedNotification = @"SampleCardsChanged";
static NSString *const kSampleCardsKey = @"SampleCards";
static NSString *const kSeededKey = @"SampleCardsSeeded";

@implementation SampleCards

+ (NSArray *)all {
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    NSArray *a = [d arrayForKey:kSampleCardsKey];
    if ([a count] == 0 && ![d boolForKey:kSeededKey]) {
        NSDictionary *first = [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithDouble:50.0], @"amount",
            [NSNumber numberWithInt:0], @"design",
            [NSDate date], @"date", nil];
        a = [NSArray arrayWithObject:first];
        [d setObject:a forKey:kSampleCardsKey];
        [d setBool:YES forKey:kSeededKey];
        [d synchronize];
    }
    return a ? a : [NSArray array];
}

+ (void)save:(NSArray *)cards {
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    [d setObject:cards forKey:kSampleCardsKey];
    [d setBool:YES forKey:kSeededKey];
    [d synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:SampleCardsChangedNotification object:nil];
}

+ (void)addCardWithAmount:(double)amount design:(int)design {
    NSMutableArray *a = [NSMutableArray arrayWithArray:[self all]];
    [a addObject:[NSDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithDouble:amount], @"amount",
        [NSNumber numberWithInt:design], @"design",
        [NSDate date], @"date", nil]];
    while ([a count] > 10) [a removeObjectAtIndex:0];
    [self save:a];
}

+ (void)removeCardAtIndex:(NSUInteger)index {
    NSMutableArray *a = [NSMutableArray arrayWithArray:[self all]];
    if (index >= [a count]) return;
    [a removeObjectAtIndex:index];
    [self save:a];
}

@end
