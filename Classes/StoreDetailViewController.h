#import <UIKit/UIKit.h>

@interface StoreDetailViewController : UIViewController <UITableViewDataSource, UITableViewDelegate> {
    NSDictionary *_store;
    NSMutableArray *_sections;
    UITableView *_table;
}
- (id)initWithStore:(NSDictionary *)store;
@end
