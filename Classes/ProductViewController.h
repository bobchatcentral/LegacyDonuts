#import <UIKit/UIKit.h>

@interface ProductViewController : UIViewController {
    NSDictionary *_product;
}
- (id)initWithProduct:(NSDictionary *)product;
@end
