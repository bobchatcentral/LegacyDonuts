#import "NotificationsViewController.h"
#import "NotificationManager.h"
#import "DDStyle.h"
#import "Theme.h"

@implementation NotificationsViewController

- (id)init {
    if ((self = [super init])) {
        self.title = @"Notifications";
    }
    return self;
}

- (UILabel *)labelAt:(CGRect)r text:(NSString *)t font:(UIFont *)f color:(UIColor *)c {
    UILabel *l = [[[UILabel alloc] initWithFrame:r] autorelease];
    l.text = t;
    l.font = f;
    l.textColor = c;
    l.numberOfLines = 0;
    l.backgroundColor = [UIColor clearColor];
    return l;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    CGFloat W = self.view.bounds.size.width;
    self.view.backgroundColor = [DDStyle backgroundPattern];

    UIScrollView *sv = [[[UIScrollView alloc] initWithFrame:self.view.bounds] autorelease];
    sv.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    sv.contentSize = CGSizeMake(W, 560);
    [self.view addSubview:sv];

    PanelView *panel = [[[PanelView alloc] initWithFrame:CGRectMake(16, 16, W - 32, 56)] autorelease];
    [sv addSubview:panel];
    [panel addSubview:[self labelAt:CGRectMake(14, 14, 190, 28) text:@"Daily reminder"
        font:[UIFont boldSystemFontOfSize:18] color:[UIColor blackColor]]];
    _switch = [[UISwitch alloc] initWithFrame:CGRectMake(panel.bounds.size.width - 100, 14, 94, 27)];
    _switch.on = [NotificationManager remindersEnabled];
    [_switch addTarget:self action:@selector(switchChanged) forControlEvents:UIControlEventValueChanged];
    [panel addSubview:_switch];

    _timeHint = [self labelAt:CGRectMake(20, 84, W - 40, 20) text:@"Remind me at:"
        font:[UIFont boldSystemFontOfSize:15] color:[DDStyle gray:0.3f]];
    [sv addSubview:_timeHint];

    _picker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, 108, W, 216)];
    _picker.datePickerMode = UIDatePickerModeTime;
    [_picker setDate:[NotificationManager reminderTime] animated:NO];
    [_picker addTarget:self action:@selector(timeChanged) forControlEvents:UIControlEventValueChanged];
    [sv addSubview:_picker];

    UIButton *test = [UIButton buttonWithType:UIButtonTypeCustom];
    test.frame = CGRectMake(16, 340, W - 32, 44);
    [test setTitle:@"Send a test notification" forState:UIControlStateNormal];
    [DDStyle styleButton:test kind:1];
    [test addTarget:self action:@selector(sendTest) forControlEvents:UIControlEventTouchUpInside];
    [sv addSubview:test];

    [sv addSubview:[self labelAt:CGRectMake(20, 398, W - 40, 100)
        text:@"These reminders are created by this app on your phone, one for each day of the week. They are not messages from Dunkin', and Dunkin's own notifications can't be used by other apps. Nothing is sent over the internet."
        font:[UIFont systemFontOfSize:13] color:[DDStyle gray:0.4f]]];

    [self switchChanged];
}

- (void)switchChanged {
    [NotificationManager setRemindersEnabled:_switch.on];
    _picker.alpha = _switch.on ? 1.0f : 0.35f;
    _picker.userInteractionEnabled = _switch.on;
    _timeHint.alpha = _picker.alpha;
}

- (void)timeChanged {
    [NotificationManager setReminderTime:_picker.date];
}

- (void)sendTest {
    [NotificationManager sendTestIn:5];
    UIAlertView *a = [[UIAlertView alloc] initWithTitle:@"Test scheduled"
        message:@"Press the Home button now. The notification arrives in about 5 seconds."
        delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [a show];
    [a release];
}

- (void)dealloc {
    [_switch release];
    [_picker release];
    [super dealloc];
}

@end
