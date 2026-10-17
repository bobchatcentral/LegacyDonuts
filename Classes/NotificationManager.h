#import <Foundation/Foundation.h>

// Local reminders created by this app on the phone itself (no server involved).
// They are NOT Dunkin' push notifications.
@interface NotificationManager : NSObject
+ (BOOL)remindersEnabled;
+ (void)setRemindersEnabled:(BOOL)on;
+ (NSDate *)reminderTime;                          // today at the saved hour and minute
+ (void)setReminderTime:(NSDate *)time;
+ (void)reschedule;                                // cancel ours, then recreate if switched on
+ (void)sendTestIn:(NSTimeInterval)seconds;
@end
