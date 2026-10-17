#import "GiftViewController.h"
#import "SampleCardView.h"
#import "SampleCards.h"
#import "WebViewController.h"
#import "DDStyle.h"
#import "Theme.h"

#define kDesignCount 7
// Design ids shown here (design 2 is the "Add a card" tile and is not offered).
static const int kGiftDesigns[kDesignCount] = {0, 1, 3, 4, 5, 6, 7};

@implementation GiftViewController

- (id)init {
    if ((self = [super init])) {
        self.title = @"Gift";
    }
    return self;
}

- (UILabel *)labelAt:(CGRect)r text:(NSString *)t font:(UIFont *)f color:(UIColor *)c {
    UILabel *l = [[[UILabel alloc] initWithFrame:r] autorelease];
    l.text = t;
    l.font = f;
    l.textColor = c;
    l.numberOfLines = 0;
    l.backgroundColor = [UIColor clearColor];
    return l;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    CGFloat W = self.view.bounds.size.width;
    self.view.backgroundColor = [DDStyle backgroundPattern];

    UIBarButtonItem *next = [[UIBarButtonItem alloc] initWithTitle:@"Next"
        style:UIBarButtonItemStyleDone target:self action:@selector(createCard)];
    next.tintColor = DD_RED;
    self.navigationItem.rightBarButtonItem = next;
    [next release];

    _page = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    _page.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _page.contentSize = CGSizeMake(W, 545);
    [self.view addSubview:_page];

    UIFont *h = [UIFont boldSystemFontOfSize:17];
    UIColor *hc = [DDStyle gray:0.25f];
    [_page addSubview:[self labelAt:CGRectMake(16, 10, W - 32, 22) text:@"Select a card design" font:h color:hc]];

    _designs = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 38, W, 176)];
    _designs.pagingEnabled = YES;
    _designs.showsHorizontalScrollIndicator = NO;
    _designs.delegate = self;
    _designs.contentSize = CGSizeMake(W * kDesignCount, 176);
    for (int i = 0; i < kDesignCount; i++) {
        SampleCardView *c = [[SampleCardView alloc] initWithFrame:CGRectMake(i * W + 20, 4, W - 40, 168)
                                                           design:kGiftDesigns[i]];
        [_designs addSubview:c];
        [c release];
    }
    [_page addSubview:_designs];

    _dots = [[UIPageControl alloc] initWithFrame:CGRectMake(0, 212, W, 18)];
    _dots.numberOfPages = kDesignCount;
    _dots.userInteractionEnabled = NO;
    [_page addSubview:_dots];

    [_page addSubview:[self labelAt:CGRectMake(16, 236, W - 32, 22) text:@"Select amount" font:h color:hc]];

    _amount = [[UISegmentedControl alloc] initWithItems:
        [NSArray arrayWithObjects:@"$15", @"$25", @"$50", @"$100", nil]];
    _amount.frame = CGRectMake(16, 262, W - 32, 40);
    _amount.segmentedControlStyle = UISegmentedControlStyleBar;
    _amount.tintColor = DD_PINK;
    _amount.selectedSegmentIndex = 1;
    [_amount addTarget:self action:@selector(amountChanged) forControlEvents:UIControlEventValueChanged];
    [_page addSubview:_amount];

    [_page addSubview:[self labelAt:CGRectMake(16, 318, 54, 34) text:@"Other" font:h color:hc]];
    _other = [[UITextField alloc] initWithFrame:CGRectMake(74, 316, W - 90, 34)];
    _other.borderStyle = UITextBorderStyleRoundedRect;
    _other.placeholder = @"amount between $2 and $100";
    _other.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    _other.returnKeyType = UIReturnKeyDone;
    _other.delegate = self;
    [_page addSubview:_other];

    [_page addSubview:[self labelAt:CGRectMake(16, 362, W - 32, 62)
        text:@"SAMPLE CARDS ONLY. These cards are made inside this app for fun. They have no money on them, no barcode, and can't be scanned or used to pay in any store."
        font:[UIFont boldSystemFontOfSize:13] color:DD_RED]];

    UIButton *web = [UIButton buttonWithType:UIButtonTypeCustom];
    web.frame = CGRectMake(16, 438, W - 32, 44);
    [web setTitle:@"Open dunkindonuts.com" forState:UIControlStateNormal];
    [DDStyle styleButton:web kind:0];
    [web addTarget:self action:@selector(openWebsite) forControlEvents:UIControlEventTouchUpInside];
    [_page addSubview:web];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)sv {
    if (sv == _designs) {
        _design = (int)(sv.contentOffset.x / sv.bounds.size.width + 0.5f);
        if (_design < 0) _design = 0;
        if (_design >= kDesignCount) _design = kDesignCount - 1;
        _dots.currentPage = _design;
    }
}

- (void)amountChanged {
    _other.text = @"";
    [_other resignFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)tf {
    [tf resignFirstResponder];
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)tf {
    [_page setContentOffset:CGPointMake(0, 210) animated:YES];
}

- (void)openWebsite {
    WebViewController *vc = [[WebViewController alloc] initWithURL:kURLHome title:@"Dunkin' Donuts"];
    [self.navigationController pushViewController:vc animated:YES];
    [vc release];
}

- (void)createCard {
    [_other resignFirstResponder];
    double amount;
    NSString *text = [[_other.text stringByReplacingOccurrencesOfString:@"$" withString:@""]
        stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([text length]) {
        amount = [text doubleValue];
    } else {
        double amounts[4] = {15, 25, 50, 100};
        NSInteger i = _amount.selectedSegmentIndex;
        amount = amounts[(i >= 0 && i < 4) ? i : 1];
    }
    if (amount < 2 || amount > 100) {
        UIAlertView *a = [[UIAlertView alloc] initWithTitle:@"Amount"
            message:@"Please enter an amount between $2 and $100." delegate:nil
            cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [a show];
        [a release];
        return;
    }
    [SampleCards addCardWithAmount:amount design:kGiftDesigns[_design]];
    UIAlertView *a = [[UIAlertView alloc] initWithTitle:@"Sample card created"
        message:@"Your SAMPLE card is in My Cards. It has no value and can't be used to pay."
        delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [a show];
    [a release];
}

- (void)alertView:(UIAlertView *)alert didDismissWithButtonIndex:(NSInteger)i {
    self.tabBarController.selectedIndex = 0;
}

- (void)dealloc {
    _designs.delegate = nil;
    _other.delegate = nil;
    [_page release];
    [_designs release];
    [_dots release];
    [_amount release];
    [_other release];
    [super dealloc];
}

@end
