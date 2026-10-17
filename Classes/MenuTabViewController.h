#import <UIKit/UIKit.h>

@interface MenuTabViewController : UIViewController <UITableViewDataSource, UITableViewDelegate> {
    UIButton *_drinksBtn;
    UIButton *_foodBtn;
    UISegmentedControl *_seg;
    UIScrollView *_chipScroll;
    UITableView *_table;
    UILabel *_status;
    UIActivityIndicatorView *_spinner;
    NSDictionary *_menu;
    NSMutableArray *_chips;      // each: n (title), key (category key)
    NSArray *_products;          // product keys
    int _mode;                   // 0 drinks, 1 food
    int _selChip;
}
@end
