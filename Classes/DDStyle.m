#import "DDStyle.h"
#import "Theme.h"

@implementation DDStyle

+ (UIColor *)gray:(CGFloat)v {
    return [UIColor colorWithRed:v green:v blue:v alpha:1];
}

+ (UIImage *)gradientTop:(UIColor *)top bottom:(UIColor *)bottom height:(CGFloat)h {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(4, h), YES, 0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
    NSArray *colors = [NSArray arrayWithObjects:(id)[top CGColor], (id)[bottom CGColor], nil];
    CGGradientRef g = CGGradientCreateWithColors(cs, (CFArrayRef)colors, NULL);
    CGContextDrawLinearGradient(ctx, g, CGPointMake(0, 0), CGPointMake(0, h), 0);
    CGGradientRelease(g);
    CGColorSpaceRelease(cs);
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [img resizableImageWithCapInsets:UIEdgeInsetsMake(0, 1, 0, 1)];
}

+ (UIImage *)buttonTop:(UIColor *)top bottom:(UIColor *)bottom border:(UIColor *)border radius:(CGFloat)r {
    CGFloat w = r * 2 + 4, h = 34;
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(w, h), NO, 0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    UIBezierPath *p = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0.5f, 0.5f, w - 1, h - 1) cornerRadius:r];
    CGContextSaveGState(ctx);
    [p addClip];
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
    NSArray *colors = [NSArray arrayWithObjects:(id)[top CGColor], (id)[bottom CGColor], nil];
    CGGradientRef g = CGGradientCreateWithColors(cs, (CFArrayRef)colors, NULL);
    CGContextDrawLinearGradient(ctx, g, CGPointMake(0, 0), CGPointMake(0, h), 0);
    CGGradientRelease(g);
    CGColorSpaceRelease(cs);
    CGContextRestoreGState(ctx);
    [border setStroke];
    p.lineWidth = 1;
    [p stroke];
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [img resizableImageWithCapInsets:UIEdgeInsetsMake(r, r, r, r)];
}

+ (UIColor *)backgroundPattern {
    static UIColor *pattern = nil;
    if (!pattern) {
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(4, 4), YES, 0);
        [[self gray:0.935f] setFill];
        UIRectFill(CGRectMake(0, 0, 4, 4));
        [[self gray:0.915f] setFill];
        UIRectFill(CGRectMake(0, 0, 2, 2));
        UIRectFill(CGRectMake(2, 2, 2, 2));
        UIImage *tile = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        pattern = [[UIColor colorWithPatternImage:tile] retain];
    }
    return pattern;
}

+ (void)styleButton:(UIButton *)b kind:(int)kind {
    UIColor *top, *bottom, *border, *hTop, *hBottom, *text;
    if (kind == 1) {          // orange
        top = [UIColor colorWithRed:1.00f green:0.58f blue:0.27f alpha:1];
        bottom = [UIColor colorWithRed:0.94f green:0.40f blue:0.06f alpha:1];
        border = [UIColor colorWithRed:0.72f green:0.28f blue:0.02f alpha:1];
        hTop = [UIColor colorWithRed:0.90f green:0.45f blue:0.12f alpha:1];
        hBottom = [UIColor colorWithRed:0.78f green:0.30f blue:0.03f alpha:1];
        text = [UIColor whiteColor];
    } else if (kind == 2) {   // pink
        top = [UIColor colorWithRed:0.95f green:0.38f blue:0.68f alpha:1];
        bottom = [UIColor colorWithRed:0.80f green:0.07f blue:0.45f alpha:1];
        border = [UIColor colorWithRed:0.60f green:0.04f blue:0.33f alpha:1];
        hTop = [UIColor colorWithRed:0.82f green:0.25f blue:0.55f alpha:1];
        hBottom = [UIColor colorWithRed:0.62f green:0.04f blue:0.34f alpha:1];
        text = [UIColor whiteColor];
    } else {                  // gray
        top = [self gray:0.80f];
        bottom = [self gray:0.62f];
        border = [self gray:0.50f];
        hTop = [self gray:0.66f];
        hBottom = [self gray:0.50f];
        text = [UIColor whiteColor];
    }
    [b setBackgroundImage:[self buttonTop:top bottom:bottom border:border radius:6] forState:UIControlStateNormal];
    [b setBackgroundImage:[self buttonTop:hTop bottom:hBottom border:border radius:6] forState:UIControlStateHighlighted];
    [b setTitleColor:text forState:UIControlStateNormal];
    [b setTitleShadowColor:[UIColor colorWithWhite:0 alpha:0.35f] forState:UIControlStateNormal];
    b.titleLabel.shadowOffset = CGSizeMake(0, -1);
    b.titleLabel.font = [UIFont boldSystemFontOfSize:14];
}

+ (void)applyAppearance {
    // Orange glossy navigation bar with a white, shadowed title.
    UIImage *bar = [self gradientTop:[UIColor colorWithRed:1.00f green:0.60f blue:0.28f alpha:1]
                              bottom:[UIColor colorWithRed:0.93f green:0.39f blue:0.05f alpha:1] height:44];
    [[UINavigationBar appearance] setBackgroundImage:bar forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
        [UIColor whiteColor], UITextAttributeTextColor,
        [UIColor colorWithWhite:0 alpha:0.35f], UITextAttributeTextShadowColor,
        [NSValue valueWithUIOffset:UIOffsetMake(0, -1)], UITextAttributeTextShadowOffset,
        [UIFont boldSystemFontOfSize:20], UITextAttributeFont, nil]];
    [[UIBarButtonItem appearanceWhenContainedIn:[UINavigationBar class], nil]
        setTintColor:[UIColor colorWithRed:0.78f green:0.30f blue:0.03f alpha:1]];

    // Black tab bar with a lighter highlight behind the selected tab.
    [[UITabBar appearance] setBackgroundImage:[self gradientTop:[self gray:0.30f] bottom:[self gray:0.04f] height:49]];
    [[UITabBar appearance] setSelectionIndicatorImage:[self gradientTop:[self gray:0.46f] bottom:[self gray:0.20f] height:49]];
    [[UITabBar appearance] setSelectedImageTintColor:DD_ORANGE];
}

@end

#pragma mark - PanelView

@implementation PanelView

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.opaque = NO;
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    CGRect b = CGRectInset(self.bounds, 0.5f, 0.5f);
    UIBezierPath *p = [UIBezierPath bezierPathWithRoundedRect:b cornerRadius:8];
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    [p addClip];
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
    NSArray *colors = [NSArray arrayWithObjects:
        (id)[[UIColor colorWithRed:1 green:1 blue:1 alpha:1] CGColor],
        (id)[[UIColor colorWithRed:0.95f green:0.95f blue:0.95f alpha:1] CGColor], nil];
    CGGradientRef g = CGGradientCreateWithColors(cs, (CFArrayRef)colors, NULL);
    CGContextDrawLinearGradient(ctx, g, CGPointMake(0, 0), CGPointMake(0, self.bounds.size.height), 0);
    CGGradientRelease(g);
    CGColorSpaceRelease(cs);
    CGContextRestoreGState(ctx);
    [[UIColor colorWithRed:0.76f green:0.76f blue:0.76f alpha:1] setStroke];
    p.lineWidth = 1;
    [p stroke];
}

@end
