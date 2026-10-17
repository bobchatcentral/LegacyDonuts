#import <UIKit/UIKit.h>

@interface CardsViewController : UIViewController <UIScrollViewDelegate, UIActionSheetDelegate> {
    UIScrollView *_pager;
    UIPageControl *_dots;
    UILabel *_hint;
    UIView *_panel;
    UILabel *_balance;
    UILabel *_dateLabel;
    UIBarButtonItem *_deleteItem;
    NSArray *_cards;
    int _page;
    BOOL _keepPage;
}
@end
