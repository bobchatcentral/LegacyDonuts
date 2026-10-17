#import <UIKit/UIKit.h>

@interface MoreViewController : UIViewController <UITableViewDataSource, UITableViewDelegate> {
    UITableView *_table;
    NSArray *_sections;
}
@end
