#import <UIKit/UIKit.h>

@interface AppDelegate : NSObject <UIApplicationDelegate, UIAlertViewDelegate> {
    UIWindow *window;
    UITabBarController *tabs;
}
@property (nonatomic, retain) UIWindow *window;
@end
