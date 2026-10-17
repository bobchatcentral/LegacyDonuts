#import "AppDelegate.h"
#import "BlockingProtocol.h"
#import "CardsViewController.h"
#import "MenuTabViewController.h"
#import "StoresViewController.h"
#import "GiftViewController.h"
#import "MoreViewController.h"
#import "NotificationManager.h"
#import "DDAPI.h"
#import "DDStyle.h"
#import "Theme.h"

static UINavigationController *Nav(UIViewController *vc, NSString *title, NSString *imageName) {
    UINavigationController *n = [[[UINavigationController alloc] initWithRootViewController:vc] autorelease];
    UITabBarItem *item = [[UITabBarItem alloc] initWithTitle:title image:[UIImage imageNamed:imageName] tag:0];
    n.tabBarItem = item;
    [item release];
    return n;
}

@implementation AppDelegate

@synthesize window;

- (BOOL)application:(UIApplication *)app didFinishLaunchingWithOptions:(NSDictionary *)opts {
    NSLog(@"DunkinLite build %s %s", __DATE__, __TIME__);

    // Blocks ad and analytics requests in web pages (saves memory on old phones).
    [NSURLProtocol registerClass:[BlockingProtocol class]];

    // Orange bars, black tab bar: the look of the original app.
    [DDStyle applyAppearance];

    CardsViewController *cards = [[CardsViewController alloc] init];
    MenuTabViewController *menu = [[MenuTabViewController alloc] init];
    StoresViewController *stores = [[StoresViewController alloc] init];
    GiftViewController *gift = [[GiftViewController alloc] init];
    MoreViewController *more = [[MoreViewController alloc] init];

    tabs = [[UITabBarController alloc] init];
    tabs.viewControllers = [NSArray arrayWithObjects:
        Nav(cards,  @"My Cards",    @"tab_cards.png"),
        Nav(menu,   @"Menu",        @"tab_menu.png"),
        Nav(stores, @"Restaurants", @"tab_restaurants.png"),
        Nav(gift,   @"Gift",        @"tab_gift.png"),
        Nav(more,   @"More",        @"tab_more.png"),
        nil];
    [cards release]; [menu release]; [stores release]; [gift release]; [more release];

    UIWindow *w = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window = w;
    [w release];
    self.window.rootViewController = tabs;
    [self.window makeKeyAndVisible];

    // Refresh the weekly reminders (if switched on) and open Restaurants if we were launched from one.
    [NotificationManager reschedule];
    if ([opts objectForKey:UIApplicationLaunchOptionsLocalNotificationKey]) tabs.selectedIndex = 2;

    // Start the menu download early so the Menu tab feels instant.
    [DDAPI loadMenu:^(NSDictionary *m, NSError *e) {}];
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)app {
    app.applicationIconBadgeNumber = 0;
}

- (void)application:(UIApplication *)app didReceiveLocalNotification:(UILocalNotification *)n {
    if (app.applicationState == UIApplicationStateActive) {
        UIAlertView *a = [[UIAlertView alloc] initWithTitle:@"Dunkin' Lite" message:n.alertBody
            delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:@"Find a store", nil];
        [a show];
        [a release];
    } else {
        tabs.selectedIndex = 2;
    }
}

- (void)alertView:(UIAlertView *)alert clickedButtonAtIndex:(NSInteger)i {
    if (i != [alert cancelButtonIndex]) tabs.selectedIndex = 2;
}

- (void)dealloc {
    [tabs release];
    [window release];
    [super dealloc];
}

@end
