#import <UIKit/UIKit.h>

@interface GiftViewController : UIViewController <UIScrollViewDelegate, UITextFieldDelegate, UIAlertViewDelegate> {
    UIScrollView *_page;
    UIScrollView *_designs;
    UIPageControl *_dots;
    UISegmentedControl *_amount;
    UITextField *_other;
    int _design;          // index into the design list
}
@end
