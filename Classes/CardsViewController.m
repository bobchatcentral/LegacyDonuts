#import "CardsViewController.h"
#import "SampleCardView.h"
#import "SampleCards.h"
#import "DDStyle.h"
#import "Theme.h"

@interface CardsViewController ()
- (void)rebuild;
- (void)updateForPage:(int)page;
- (void)showAlert:(NSString *)title message:(NSString *)msg;
@end

@implementation CardsViewController

- (id)init {
    if ((self = [super init])) {
        self.title = @"My Cards";
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cardsChanged)
            name:SampleCardsChangedNotification object:nil];
    }
    return self;
}

- (UIButton *)panelButton:(NSString *)title index:(int)i width:(CGFloat)pw {
    CGFloat bw = (pw - 32) / 3.0f;
    UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
    b.frame = CGRectMake(10 + i * (bw + 6), 86, bw, 32);
    [b setTitle:title forState:UIControlStateNormal];
    [DDStyle styleButton:b kind:0];
    [b addTarget:self action:@selector(panelButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    return b;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    CGFloat W = self.view.bounds.size.width;
    self.view.backgroundColor = [DDStyle backgroundPattern];

    _deleteItem = [[UIBarButtonItem alloc] initWithTitle:@"Delete" style:UIBarButtonItemStyleBordered
                                                  target:self action:@selector(confirmDelete)];

    _pager = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, W, 184)];
    _pager.pagingEnabled = YES;
    _pager.showsHorizontalScrollIndicator = NO;
    _pager.delegate = self;
    [self.view addSubview:_pager];

    _dots = [[UIPageControl alloc] initWithFrame:CGRectMake(0, 180, W, 18)];
    _dots.hidesForSinglePage = NO;
    [_dots addTarget:self action:@selector(dotsChanged) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:_dots];

    _hint = [[UILabel alloc] initWithFrame:CGRectMake(16, 202, W - 32, 18)];
    _hint.textAlignment = UITextAlignmentCenter;
    _hint.font = [UIFont boldSystemFontOfSize:13];
    _hint.textColor = DD_RED;
    _hint.backgroundColor = [UIColor clearColor];
    _hint.text = @"SAMPLE CARD - NOT VALID FOR PAYMENT";
    [self.view addSubview:_hint];

    CGFloat pw = W - 32;
    _panel = [[PanelView alloc] initWithFrame:CGRectMake(16, 226, pw, 128)];
    [self.view addSubview:_panel];

    _balance = [[UILabel alloc] initWithFrame:CGRectMake(0, 6, pw, 54)];
    _balance.textAlignment = UITextAlignmentCenter;
    _balance.font = [UIFont boldSystemFontOfSize:48];
    _balance.textColor = [UIColor blackColor];
    _balance.backgroundColor = [UIColor clearColor];
    [_panel addSubview:_balance];

    _dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 60, pw, 18)];
    _dateLabel.textAlignment = UITextAlignmentCenter;
    _dateLabel.font = [UIFont systemFontOfSize:13];
    _dateLabel.textColor = [DDStyle gray:0.35f];
    _dateLabel.backgroundColor = [UIColor clearColor];
    [_panel addSubview:_dateLabel];

    [_panel addSubview:[self panelButton:@"Reload" index:0 width:pw]];
    [_panel addSubview:[self panelButton:@"History" index:1 width:pw]];
    [_panel addSubview:[self panelButton:@"+ More" index:2 width:pw]];

    [self rebuild];
}

- (void)rebuild {
    [_cards release];
    _cards = [[SampleCards all] retain];
    for (UIView *v in [[[_pager subviews] copy] autorelease]) {
        if ([v isKindOfClass:[SampleCardView class]]) [v removeFromSuperview];
    }

    CGFloat W = _pager.bounds.size.width;
    NSUInteger n = [_cards count];
    for (NSUInteger i = 0; i <= n; i++) {
        int design = (i < n) ? [[[_cards objectAtIndex:i] objectForKey:@"design"] intValue] : 2;
        SampleCardView *c = [[SampleCardView alloc] initWithFrame:CGRectMake(i * W + 20, 8, W - 40, 168) design:design];
        c.tag = (NSInteger)i;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cardTapped:)];
        [c addGestureRecognizer:tap];
        [tap release];
        [_pager addSubview:c];
        [c release];
    }
    _pager.contentSize = CGSizeMake(W * (n + 1), 184);
    _dots.numberOfPages = (NSInteger)(n + 1);

    int page = (int)n - 1;                            // show the newest card...
    if (_keepPage) page = MIN(_page, (int)n - 1);     // ...unless a card was just deleted
    if (page < 0) page = 0;
    _keepPage = NO;
    _dots.currentPage = page;
    _pager.contentOffset = CGPointMake(W * page, 0);
    [self updateForPage:page];
}

- (void)updateForPage:(int)page {
    _page = page;
    BOOL isCard = page >= 0 && (NSUInteger)page < [_cards count];
    _panel.hidden = !isCard;
    _hint.hidden = !isCard;
    self.navigationItem.rightBarButtonItem = isCard ? _deleteItem : nil;
    if (!isCard) return;
    NSDictionary *card = [_cards objectAtIndex:(NSUInteger)page];
    _balance.text = [NSString stringWithFormat:@"$%.2f", [[card objectForKey:@"amount"] doubleValue]];
    NSDateFormatter *f = [[NSDateFormatter alloc] init];
    [f setDateFormat:@"MM/dd/yyyy 'at' h:mm a"];
    _dateLabel.text = [f stringFromDate:[card objectForKey:@"date"]];
    [f release];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)sv {
    int page = (int)(sv.contentOffset.x / sv.bounds.size.width + 0.5f);
    _dots.currentPage = page;
    [self updateForPage:page];
}

- (void)dotsChanged {
    int page = (int)_dots.currentPage;
    [_pager setContentOffset:CGPointMake(_pager.bounds.size.width * page, 0) animated:YES];
    [self updateForPage:page];
}

- (void)cardTapped:(UITapGestureRecognizer *)g {
    if ((NSUInteger)g.view.tag < [_cards count]) {
        [self showAlert:@"Sample card"
                message:@"This card was made inside this app. It has no money on it and no barcode, and it can't be used to pay."];
    } else {
        // The "Add a Dunkin' Card" tile opens the new card screen (Gift tab).
        self.tabBarController.selectedIndex = 3;
    }
}

- (void)panelButtonTapped {
    [self showAlert:@"Sample card"
            message:@"Reloading, history and other card actions aren't available for a sample card."];
}

- (void)confirmDelete {
    UIActionSheet *s = [[UIActionSheet alloc] initWithTitle:@"Delete this sample card?" delegate:self
        cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete Card" otherButtonTitles:nil];
    [s showFromTabBar:self.tabBarController.tabBar];
    [s release];
}

- (void)actionSheet:(UIActionSheet *)s clickedButtonAtIndex:(NSInteger)i {
    if (i == [s destructiveButtonIndex]) {
        _keepPage = YES;
        [SampleCards removeCardAtIndex:(NSUInteger)_page];
    }
}

- (void)cardsChanged {
    if ([self isViewLoaded]) [self rebuild];
}

- (void)showAlert:(NSString *)title message:(NSString *)msg {
    UIAlertView *a = [[UIAlertView alloc] initWithTitle:title message:msg delegate:nil
                                      cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [a show];
    [a release];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _pager.delegate = nil;
    [_pager release];
    [_dots release];
    [_hint release];
    [_panel release];
    [_balance release];
    [_dateLabel release];
    [_deleteItem release];
    [_cards release];
    [super dealloc];
}

@end
