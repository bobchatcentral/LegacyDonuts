#import "NotificationManager.h"
#import <UIKit/UIKit.h>

static NSString *const kOn = @"RemindersOn";
static NSString *const kHour = @"ReminderHour";
static NSString *const kMinute = @"ReminderMinute";

@implementation NotificationManager

+ (BOOL)remindersEnabled {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kOn];
}

+ (void)setRemindersEnabled:(BOOL)on {
    [[NSUserDefaults standardUserDefaults] setBool:on forKey:kOn];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self reschedule];
}

+ (int)hour {
    NSNumber *n = [[NSUserDefaults standardUserDefaults] objectForKey:kHour];
    return n ? [n intValue] : 8;
}

+ (int)minute {
    NSNumber *n = [[NSUserDefaults standardUserDefaults] objectForKey:kMinute];
    return n ? [n intValue] : 0;
}

+ (NSDate *)reminderTime {
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *dc = [cal components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit)
                                  fromDate:[NSDate date]];
    dc.hour = [self hour];
    dc.minute = [self minute];
    return [cal dateFromComponents:dc];
}

+ (void)setReminderTime:(NSDate *)time {
    NSDateComponents *dc = [[NSCalendar currentCalendar] components:(NSHourCalendarUnit | NSMinuteCalendarUnit)
                                                           fromDate:time];
    [[NSUserDefaults standardUserDefaults] setInteger:dc.hour forKey:kHour];
    [[NSUserDefaults standardUserDefaults] setInteger:dc.minute forKey:kMinute];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self reschedule];
}

+ (void)reschedule {
    UIApplication *app = [UIApplication sharedApplication];
    for (UILocalNotification *n in [[[app scheduledLocalNotifications] copy] autorelease]) {
        if ([[n.userInfo objectForKey:@"kind"] isEqual:@"reminder"]) [app cancelLocalNotification:n];
    }
    if (![self remindersEnabled]) return;

    // One message per weekday, Sunday first.
    NSArray *messages = [NSArray arrayWithObjects:
        @"Sunday coffee time. Tap to check store hours.",
        @"Monday! Time for a coffee run?",
        @"Tuesday pick-me-up? Find a Dunkin' near you.",
        @"Donut o'clock. Tap to find the closest store.",
        @"Iced or hot today? Tap to browse the menu.",
        @"Almost the weekend. Treat yourself!",
        @"Weekend coffee? Tap to find a store.", nil];

    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDate *now = [NSDate date];
    NSDateComponents *today = [cal components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit)
                                     fromDate:now];
    for (int i = 0; i < 7; i++) {
        NSDateComponents *dc = [[today copy] autorelease];
        dc.day = dc.day + i;
        dc.hour = [self hour];
        dc.minute = [self minute];
        NSDate *fire = [cal dateFromComponents:dc];
        if ([fire timeIntervalSinceDate:now] <= 0) fire = [fire dateByAddingTimeInterval:7 * 86400];

        NSDateComponents *wd = [cal components:NSWeekdayCalendarUnit fromDate:fire];
        UILocalNotification *n = [[UILocalNotification alloc] init];
        n.fireDate = fire;
        n.timeZone = [NSTimeZone defaultTimeZone];
        n.repeatInterval = NSWeekCalendarUnit;
        n.alertBody = [messages objectAtIndex:(NSUInteger)((wd.weekday - 1) % 7)];
        n.alertAction = @"Find a store";
        n.soundName = UILocalNotificationDefaultSoundName;
        n.userInfo = [NSDictionary dictionaryWithObject:@"reminder" forKey:@"kind"];
        [app scheduleLocalNotification:n];
        [n release];
    }
}

+ (void)sendTestIn:(NSTimeInterval)seconds {
    UILocalNotification *n = [[UILocalNotification alloc] init];
    n.fireDate = [NSDate dateWithTimeIntervalSinceNow:seconds];
    n.timeZone = [NSTimeZone defaultTimeZone];
    n.alertBody = @"This is a test notification from Dunkin' Lite.";
    n.alertAction = @"Open";
    n.soundName = UILocalNotificationDefaultSoundName;
    n.userInfo = [NSDictionary dictionaryWithObject:@"test" forKey:@"kind"];
    [[UIApplication sharedApplication] scheduleLocalNotification:n];
    [n release];
}

@end
