#import <UIKit/UIKit.h>

// A card drawn in code. Designs 0 and 1 always carry a large red SAMPLE banner.
// Design 2 is the "Add a Dunkin' Card" tile.
@interface SampleCardView : UIView {
    int _design;
}
- (id)initWithFrame:(CGRect)frame design:(int)design;
@end
