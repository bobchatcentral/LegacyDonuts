#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface StoresViewController : UIViewController <UITableViewDataSource, UITableViewDelegate,
                                                    UISearchBarDelegate, MKMapViewDelegate> {
    UISearchBar *_search;
    UITableView *_table;
    MKMapView *_map;
    UISegmentedControl *_toggle;
    UILabel *_status;
    UIActivityIndicatorView *_spinner;
    NSArray *_stores;
    BOOL _didAuto;
    int _gen;
}
@end
