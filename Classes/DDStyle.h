#import <UIKit/UIKit.h>

// Look of the 2012 Dunkin' app, drawn in code (no image files needed).
@interface DDStyle : NSObject
+ (void)applyAppearance;                                     // call once at launch (iOS 5+)
+ (UIColor *)gray:(CGFloat)v;                                // RGB gray, safe for gradients
+ (UIImage *)gradientTop:(UIColor *)top bottom:(UIColor *)bottom height:(CGFloat)h;
+ (UIImage *)buttonTop:(UIColor *)top bottom:(UIColor *)bottom border:(UIColor *)border radius:(CGFloat)r;
+ (UIColor *)backgroundPattern;                              // light linen-like gray
// kind: 0 gray, 1 orange, 2 pink
+ (void)styleButton:(UIButton *)b kind:(int)kind;
@end

// A white rounded panel with a thin border, like the balance box in the original app.
@interface PanelView : UIView
@end
