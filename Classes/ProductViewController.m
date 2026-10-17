#import "ProductViewController.h"
#import "DDStyle.h"
#import "Theme.h"

@implementation ProductViewController

- (id)initWithProduct:(NSDictionary *)product {
    if ((self = [super init])) {
        _product = [product retain];
        self.title = @"Details";
    }
    return self;
}

- (UILabel *)labelWithText:(NSString *)text font:(UIFont *)font color:(UIColor *)color y:(CGFloat)y width:(CGFloat)w {
    CGSize size = [text sizeWithFont:font constrainedToSize:CGSizeMake(w, 4000) lineBreakMode:UILineBreakModeWordWrap];
    UILabel *l = [[[UILabel alloc] initWithFrame:CGRectMake(16, y, w, size.height)] autorelease];
    l.numberOfLines = 0;
    l.lineBreakMode = UILineBreakModeWordWrap;
    l.font = font;
    l.textColor = color;
    l.backgroundColor = [UIColor clearColor];
    l.text = text;
    return l;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [DDStyle backgroundPattern];
    CGRect b = self.view.bounds;
    CGFloat w = b.size.width - 32;

    UIScrollView *sv = [[[UIScrollView alloc] initWithFrame:b] autorelease];
    sv.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:sv];

    CGFloat y = 18;
    UILabel *name = [self labelWithText:[_product objectForKey:@"n"] font:[UIFont boldSystemFontOfSize:26]
                                  color:DD_BROWN y:y width:w];
    [sv addSubview:name];
    y += name.frame.size.height + 8;

    NSString *cal = [_product objectForKey:@"c"];
    if (cal) {
        UILabel *c = [self labelWithText:[NSString stringWithFormat:@"%@ calories", cal]
                                    font:[UIFont boldSystemFontOfSize:17] color:DD_PINK y:y width:w];
        [sv addSubview:c];
        y += c.frame.size.height + 14;
    }

    NSString *desc = [_product objectForKey:@"d"];
    if ([desc length]) {
        UILabel *d = [self labelWithText:desc font:[UIFont systemFontOfSize:17] color:DD_BROWN y:y width:w];
        [sv addSubview:d];
        y += d.frame.size.height + 14;
    }

    UILabel *note = [self labelWithText:@"Prices and customizations vary by store. Order at the counter or by phone."
                                   font:[UIFont italicSystemFontOfSize:14] color:[UIColor grayColor] y:y + 10 width:w];
    [sv addSubview:note];
    sv.contentSize = CGSizeMake(b.size.width, y + 10 + note.frame.size.height + 24);
}

- (void)dealloc {
    [_product release];
    [super dealloc];
}

@end
