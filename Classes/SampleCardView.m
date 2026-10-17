#import "SampleCardView.h"
#import "Theme.h"
#include <math.h>

// Designs: 0 brown, 1 orange "thank you", 2 "Add a card" tile, 3 big DD, 4 love,
//          5 one in a million, 6 sprinkles, 7 flowers.

#pragma mark - Drawing helpers

static CGFloat DDRand(unsigned int *seed) {
    *seed = *seed * 1664525u + 1013904223u;
    return (CGFloat)((*seed >> 8) & 0xFFFF) / 65535.0f;
}

static UIColor *DDSprinkleColor(int i) {
    switch (i % 5) {
        case 0: return [UIColor colorWithRed:0.86f green:0.10f blue:0.52f alpha:1];
        case 1: return [UIColor colorWithRed:1.00f green:0.40f blue:0.12f alpha:1];
        case 2: return [UIColor colorWithRed:0.40f green:0.78f blue:0.80f alpha:1];
        case 3: return [UIColor colorWithRed:0.98f green:0.80f blue:0.20f alpha:1];
        default: return [UIColor colorWithRed:0.45f green:0.22f blue:0.10f alpha:1];
    }
}

static void DDDrawSprinkle(CGPoint p, CGFloat angle, CGFloat len, UIColor *col) {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx, p.x, p.y);
    CGContextRotateCTM(ctx, angle);
    [col setFill];
    [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(-len / 2, -1.6f, len, 3.2f) cornerRadius:1.6f] fill];
    CGContextRestoreGState(ctx);
}

static void DDDrawDonut(CGPoint c, CGFloat r, UIColor *glaze, UIColor *hole, BOOL sprinkles) {
    [glaze setFill];
    [[UIBezierPath bezierPathWithOvalInRect:CGRectMake(c.x - r, c.y - r, r * 2, r * 2)] fill];
    if (sprinkles) {
        for (int i = 0; i < 12; i++) {
            CGFloat a = i * 0.52f + 0.3f;
            CGPoint p = CGPointMake(c.x + cosf(a) * r * 0.68f, c.y + sinf(a) * r * 0.68f);
            DDDrawSprinkle(p, a + 1.2f + i, r * 0.30f, DDSprinkleColor(i));
        }
    }
    [hole setFill];
    [[UIBezierPath bezierPathWithOvalInRect:CGRectMake(c.x - r * 0.3f, c.y - r * 0.3f, r * 0.6f, r * 0.6f)] fill];
}

static void DDDrawText(NSString *s, CGPoint p, UIFont *f, UIColor *c, BOOL shadow) {
    if (shadow) {
        [[UIColor colorWithWhite:0 alpha:0.45f] set];
        [s drawAtPoint:CGPointMake(p.x + 1, p.y + 1) withFont:f];
    }
    [c set];
    [s drawAtPoint:p withFont:f];
}

@implementation SampleCardView

- (id)initWithFrame:(CGRect)frame design:(int)design {
    if ((self = [super initWithFrame:frame])) {
        _design = design;
        self.opaque = NO;
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

#pragma mark - Shared pieces

- (void)drawStamp:(CGRect)b {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx, b.size.width / 2, b.size.height / 2);
    CGContextRotateCTM(ctx, -0.33f);
    [[UIColor colorWithRed:0.80f green:0.10f blue:0.10f alpha:0.93f] setFill];
    UIRectFill(CGRectMake(-b.size.width, -19, b.size.width * 2, 38));
    [[UIColor whiteColor] set];
    [@"SAMPLE - NOT A REAL CARD" drawInRect:CGRectMake(-b.size.width / 2, -14, b.size.width, 28)
                                   withFont:[UIFont boldSystemFontOfSize:20]
                              lineBreakMode:UILineBreakModeClip
                                  alignment:UITextAlignmentCenter];
    CGContextRestoreGState(ctx);
}

- (void)drawNote:(CGRect)b {
    [[UIColor colorWithWhite:0 alpha:0.55f] setFill];
    UIRectFill(CGRectMake(0, b.size.height - 20, b.size.width, 20));
    [[UIColor whiteColor] set];
    [@"No value. Cannot be scanned or used to pay." drawInRect:CGRectMake(8, b.size.height - 17, b.size.width - 16, 14)
                                                     withFont:[UIFont systemFontOfSize:11]
                                                lineBreakMode:UILineBreakModeClip
                                                    alignment:UITextAlignmentCenter];
}

#pragma mark - Designs

- (void)drawAddTile:(CGRect)b {
    [[UIColor colorWithRed:0.86f green:0.86f blue:0.86f alpha:1] setFill];
    UIRectFill(b);
    [[UIColor colorWithRed:0.66f green:0.66f blue:0.66f alpha:1] setFill];
    UIRectFill(CGRectMake(b.size.width / 2 - 8, 26, 16, 52));
    UIRectFill(CGRectMake(b.size.width / 2 - 26, 44, 52, 16));
    [[UIColor colorWithRed:0.38f green:0.38f blue:0.38f alpha:1] set];
    [@"Add a Dunkin' Card" drawInRect:CGRectMake(0, 88, b.size.width, 28)
                             withFont:[UIFont boldSystemFontOfSize:21]
                        lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentCenter];
    [DD_ORANGE setFill];
    UIRectFill(CGRectMake(0, b.size.height - 40, b.size.width, 40));
    [[UIColor whiteColor] set];
    [@"DUNKIN' DONUTS" drawAtPoint:CGPointMake(14, b.size.height - 30) withFont:[UIFont boldSystemFontOfSize:16]];
}

- (void)drawBrown:(CGRect)b {
    [DD_BROWN setFill];
    UIRectFill(b);
    [[UIImage imageNamed:@"Icon.png"] drawInRect:CGRectMake(14, 12, 46, 46)];
    DDDrawText(@"DUNKIN'", CGPointMake(68, 8), [UIFont boldSystemFontOfSize:27], DD_ORANGE, NO);
    DDDrawText(@"DONUTS", CGPointMake(68, 34), [UIFont boldSystemFontOfSize:27], DD_PINK, NO);
}

- (void)drawThankYou:(CGRect)b {
    [DD_ORANGE setFill];
    UIRectFill(b);
    [[UIImage imageNamed:@"Icon.png"] drawInRect:CGRectMake(b.size.width - 60, 12, 46, 46)];
    DDDrawText(@"thank you", CGPointMake(b.size.width - 138, b.size.height - 74), [UIFont boldSystemFontOfSize:26],
             [UIColor whiteColor], NO);
    DDDrawText(@"DUNKIN' DONUTS", CGPointMake(14, 18), [UIFont boldSystemFontOfSize:19], [UIColor whiteColor], NO);
}

- (void)drawBigDD:(CGRect)b {
    [DD_BROWN setFill];
    UIRectFill(b);
    CGRect blob = CGRectMake(20, 14, b.size.width - 40, b.size.height - 48);
    [[UIColor whiteColor] setFill];
    [[UIBezierPath bezierPathWithRoundedRect:blob cornerRadius:46] fill];
    UIFont *f = [UIFont boldSystemFontOfSize:92];
    CGSize s = [@"D" sizeWithFont:f];
    CGFloat total = s.width * 2 - 8;
    CGFloat x = (b.size.width - total) / 2;
    CGFloat y = blob.origin.y + (blob.size.height - s.height) / 2;
    DDDrawText(@"D", CGPointMake(x, y), f, DD_ORANGE, NO);
    DDDrawText(@"D", CGPointMake(x + s.width - 8, y), f, DD_PINK, NO);
}

- (void)drawLove:(CGRect)b {
    [DD_PINK setFill];
    UIRectFill(b);
    UIFont *f = [UIFont boldSystemFontOfSize:62];
    CGSize sL = [@"L" sizeWithFont:f], sV = [@"V" sizeWithFont:f], sE = [@"E" sizeWithFont:f];
    CGFloat dr = 30, gap = 4;
    CGFloat total = sL.width + dr * 2 + gap * 2 + sV.width + sE.width;
    CGFloat x = (b.size.width - total) / 2;
    CGFloat y = (b.size.height - sL.height) / 2 - 8;
    UIColor *white = [UIColor whiteColor];
    DDDrawText(@"L", CGPointMake(x, y), f, white, NO);
    x += sL.width + gap;
    DDDrawDonut(CGPointMake(x + dr, y + sL.height / 2), dr, white, DD_PINK, YES);
    x += dr * 2 + gap;
    DDDrawText(@"V", CGPointMake(x, y), f, white, NO);
    x += sV.width;
    DDDrawText(@"E", CGPointMake(x, y), f, white, NO);
}

- (void)drawMillion:(CGRect)b {
    [[UIColor colorWithRed:0.24f green:0.11f blue:0.05f alpha:1] setFill];
    UIRectFill(b);
    for (CGFloat y = 4; y < b.size.height; y += 20) {
        CGFloat startX = (((int)(y / 20)) % 2) ? 14 : 4;
        for (CGFloat x = startX; x < b.size.width; x += 20) {
            [[UIColor colorWithRed:0.38f green:0.20f blue:0.09f alpha:1] setFill];
            [[UIBezierPath bezierPathWithOvalInRect:CGRectMake(x, y, 17, 17)] fill];
            [[UIColor colorWithRed:0.30f green:0.15f blue:0.07f alpha:1] setFill];
            [[UIBezierPath bezierPathWithOvalInRect:CGRectMake(x + 5, y + 5, 7, 7)] fill];
        }
    }
    UIFont *f = [UIFont boldSystemFontOfSize:30];
    UIColor *white = [UIColor whiteColor];
    DDDrawText(@"YOU'RE", CGPointMake(16, 20), f, white, YES);
    DDDrawText(@"ONE IN A", CGPointMake(16, 54), f, white, YES);
    DDDrawText(@"MILLION", CGPointMake(16, 88), f, white, YES);
}

- (void)drawSprinkles:(CGRect)b {
    [[UIColor colorWithRed:0.99f green:0.97f blue:0.93f alpha:1] setFill];
    UIRectFill(b);
    unsigned int seed = 12345;
    for (int i = 0; i < 90; i++) {
        CGFloat x = DDRand(&seed) * b.size.width;
        CGFloat y = DDRand(&seed) * b.size.height;
        CGFloat a = DDRand(&seed) * 3.14f;
        DDDrawSprinkle(CGPointMake(x, y), a, 16, DDSprinkleColor(i));
    }
    [[UIColor colorWithWhite:1 alpha:0.88f] setFill];
    [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(12, 12, 160, 30) cornerRadius:6] fill];
    DDDrawText(@"congratulations!", CGPointMake(20, 16), [UIFont boldSystemFontOfSize:18], DD_BROWN, NO);
    [[UIImage imageNamed:@"Icon.png"] drawInRect:CGRectMake(b.size.width - 56, 10, 42, 42)];
}

- (void)drawFlowers:(CGRect)b {
    [[UIColor whiteColor] setFill];
    UIRectFill(b);
    UIFont *tf = [UIFont boldSystemFontOfSize:23];
    CGSize s1 = [@"DUNKIN' " sizeWithFont:tf], s2 = [@"DONUTS" sizeWithFont:tf];
    CGFloat x = (b.size.width - s1.width - s2.width) / 2;
    DDDrawText(@"DUNKIN' ", CGPointMake(x, 10), tf, DD_ORANGE, NO);
    DDDrawText(@"DONUTS", CGPointMake(x + s1.width, 10), tf, DD_BROWN, NO);

    CGFloat tops[5] = {96, 78, 104, 84, 98};
    CGFloat radii[5] = {17, 19, 16, 19, 17};
    UIColor *glazes[5] = {
        DD_PINK,
        [UIColor colorWithRed:0.45f green:0.25f blue:0.12f alpha:1],
        [UIColor colorWithRed:0.92f green:0.74f blue:0.47f alpha:1],
        DD_ORANGE,
        [UIColor colorWithRed:0.75f green:0.15f blue:0.55f alpha:1]
    };
    UIColor *green = [UIColor colorWithRed:0.36f green:0.66f blue:0.30f alpha:1];
    for (int i = 0; i < 5; i++) {
        CGFloat cx = 28 + i * 56;
        UIBezierPath *stem = [UIBezierPath bezierPath];
        [stem moveToPoint:CGPointMake(cx, b.size.height - 24)];
        [stem addLineToPoint:CGPointMake(cx, tops[i] + radii[i])];
        stem.lineWidth = 3;
        [green setStroke];
        [stem stroke];
        [green setFill];
        CGFloat ly = (tops[i] + b.size.height) / 2 + 6;
        [[UIBezierPath bezierPathWithOvalInRect:CGRectMake(cx + 2, ly, 14, 7)] fill];
        [[UIBezierPath bezierPathWithOvalInRect:CGRectMake(cx - 16, ly + 10, 14, 7)] fill];
        DDDrawDonut(CGPointMake(cx, tops[i]), radii[i], glazes[i], [UIColor whiteColor], (i % 2) == 0);
    }
}

- (void)drawRect:(CGRect)rect {
    CGRect b = self.bounds;
    [[UIBezierPath bezierPathWithRoundedRect:b cornerRadius:12] addClip];

    switch (_design) {
        case 2: [self drawAddTile:b]; return;      // no stamp, it is not a card
        case 0: [self drawBrown:b]; break;
        case 1: [self drawThankYou:b]; break;
        case 3: [self drawBigDD:b]; break;
        case 4: [self drawLove:b]; break;
        case 5: [self drawMillion:b]; break;
        case 6: [self drawSprinkles:b]; break;
        default: [self drawFlowers:b]; break;
    }
    [self drawNote:b];
    [self drawStamp:b];
}

@end
