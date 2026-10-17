#import "MenuTabViewController.h"
#import "ProductViewController.h"
#import "DDAPI.h"
#import "DDStyle.h"
#import "Theme.h"

static NSArray *GroupTitles(int mode) {
    return mode == 0 ? [NSArray arrayWithObjects:@"Hot", @"Iced", @"Frozen", nil]
                     : [NSArray arrayWithObjects:@"Bakery", @"Sandwiches", @"Snacks", nil];
}

// Which top-level menu categories (matched by key prefix) belong to each segment.
static NSArray *GroupPrefixes(int mode, int idx) {
    if (mode == 0) {
        if (idx == 0) return [NSArray arrayWithObject:@"hot-drinks"];
        if (idx == 1) return [NSArray arrayWithObjects:@"iced-coffee", @"iced-refreshers", nil];
        return [NSArray arrayWithObject:@"frozen-drinks"];
    }
    if (idx == 0) return [NSArray arrayWithObject:@"donuts"];
    if (idx == 1) return [NSArray arrayWithObject:@"sandwiches"];
    return [NSArray arrayWithObjects:@"savory", @"snacks", nil];
}

@interface MenuTabViewController ()
- (void)styleModeButtons;
- (void)groupChanged;
- (void)layoutChips;
- (void)styleChips;
- (void)reloadProducts;
@end

@implementation MenuTabViewController

- (id)init {
    if ((self = [super init])) {
        self.title = @"Menu";
        _chips = [[NSMutableArray alloc] init];
    }
    return self;
}

- (UIButton *)modeButton:(NSString *)title tag:(int)tag frame:(CGRect)f {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
    b.frame = f;
    b.tag = tag;
    b.titleLabel.font = [UIFont boldSystemFontOfSize:17];
    [b setTitle:title forState:UIControlStateNormal];
    [b addTarget:self action:@selector(modeTapped:) forControlEvents:UIControlEventTouchUpInside];
    return b;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    CGRect b = self.view.bounds;
    CGFloat W = b.size.width;
    self.view.backgroundColor = [UIColor whiteColor];

    _drinksBtn = [[self modeButton:@"Drinks" tag:0 frame:CGRectMake(0, 0, W / 2, 50)] retain];
    _foodBtn   = [[self modeButton:@"Food"   tag:1 frame:CGRectMake(W / 2, 0, W / 2, 50)] retain];
    [self.view addSubview:_drinksBtn];
    [self.view addSubview:_foodBtn];

    UIView *band = [[UIView alloc] initWithFrame:CGRectMake(0, 50, W, 46)];
    band.backgroundColor = [UIColor colorWithWhite:0.90f alpha:1];
    [self.view addSubview:band];
    [band release];

    _seg = [[UISegmentedControl alloc] initWithItems:GroupTitles(0)];
    _seg.frame = CGRectMake(10, 58, W - 20, 30);
    _seg.segmentedControlStyle = UISegmentedControlStyleBar;
    _seg.tintColor = DD_PINK;
    _seg.selectedSegmentIndex = 0;
    [_seg addTarget:self action:@selector(groupChanged) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:_seg];

    _chipScroll = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 96, W, 84)];
    _chipScroll.backgroundColor = [DDStyle gray:0.90f];
    _chipScroll.showsHorizontalScrollIndicator = NO;
    [self.view addSubview:_chipScroll];

    _table = [[UITableView alloc] initWithFrame:CGRectMake(0, 180, W, b.size.height - 180) style:UITableViewStylePlain];
    _table.dataSource = self;
    _table.delegate = self;
    _table.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _table.hidden = YES;
    [self.view addSubview:_table];

    _status = [[UILabel alloc] initWithFrame:CGRectMake(24, 230, W - 48, 100)];
    _status.numberOfLines = 0;
    _status.textAlignment = UITextAlignmentCenter;
    _status.font = [UIFont systemFontOfSize:16];
    _status.textColor = [UIColor grayColor];
    _status.backgroundColor = [UIColor clearColor];
    _status.text = @"Loading the menu...\nThe first time can take a little while.";
    [self.view addSubview:_status];

    _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    _spinner.center = CGPointMake(W / 2, 205);
    [self.view addSubview:_spinner];
    [_spinner startAnimating];

    [self styleModeButtons];

    [DDAPI loadMenu:^(NSDictionary *menu, NSError *err) {
        [_spinner stopAnimating];
        if (!menu) {
            _status.text = [NSString stringWithFormat:@"Couldn't load the menu.\n%@", [err localizedDescription]];
            return;
        }
        [_menu release];
        _menu = [menu retain];
        [self groupChanged];
    }];
}

#pragma mark - Controls

- (void)styleModeButtons {
    UIButton *btns[2] = {_drinksBtn, _foodBtn};
    for (int i = 0; i < 2; i++) {
        BOOL sel = (i == _mode);
        UIImage *img = sel
            ? [DDStyle gradientTop:[UIColor colorWithRed:0.95f green:0.38f blue:0.68f alpha:1]
                          bottom:[UIColor colorWithRed:0.80f green:0.07f blue:0.45f alpha:1] height:50]
            : [DDStyle gradientTop:[DDStyle gray:0.90f] bottom:[DDStyle gray:0.76f] height:50];
        [btns[i] setBackgroundImage:img forState:UIControlStateNormal];
        [btns[i] setTitleColor:(sel ? [UIColor whiteColor] : [DDStyle gray:0.30f]) forState:UIControlStateNormal];
        [btns[i] setTitleShadowColor:(sel ? [UIColor colorWithWhite:0 alpha:0.3f] : [UIColor colorWithWhite:1 alpha:0.6f])
                            forState:UIControlStateNormal];
        btns[i].titleLabel.shadowOffset = CGSizeMake(0, -1);
    }
}

- (void)modeTapped:(UIButton *)b {
    _mode = (int)b.tag;
    [self styleModeButtons];
    [_seg removeAllSegments];
    NSArray *titles = GroupTitles(_mode);
    for (NSUInteger i = 0; i < [titles count]; i++) {
        [_seg insertSegmentWithTitle:[titles objectAtIndex:i] atIndex:i animated:NO];
    }
    _seg.selectedSegmentIndex = 0;
    [self groupChanged];
}

- (void)groupChanged {
    if (!_menu) return;
    NSDictionary *cats = [_menu objectForKey:@"cats"];
    NSString *root = [_menu objectForKey:@"root"];
    NSArray *rootSubs = [[cats objectForKey:root] objectForKey:@"subs"];
    [_chips removeAllObjects];
    NSMutableSet *added = [NSMutableSet set];

    for (NSString *prefix in GroupPrefixes(_mode, (int)_seg.selectedSegmentIndex)) {
        for (NSString *rk in rootSubs) {
            if (![rk hasPrefix:prefix]) continue;
            NSDictionary *rc = [cats objectForKey:rk];
            NSArray *subs = [rc objectForKey:@"subs"];
            if ([subs count]) {
                for (NSString *sk in subs) {
                    if ([added containsObject:sk]) continue;
                    [added addObject:sk];
                    [_chips addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                        [[cats objectForKey:sk] objectForKey:@"n"], @"n", sk, @"key", nil]];
                }
            }
            if ([[rc objectForKey:@"items"] count] || [subs count] == 0) {
                if (![added containsObject:rk]) {
                    [added addObject:rk];
                    [_chips addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                        [rc objectForKey:@"n"], @"n", rk, @"key", nil]];
                }
            }
        }
    }
    _selChip = 0;
    [self layoutChips];
    [self reloadProducts];
}

- (void)layoutChips {
    for (UIView *v in [[[_chipScroll subviews] copy] autorelease]) {
        if ([v isKindOfClass:[UIButton class]]) [v removeFromSuperview];
    }
    for (NSUInteger i = 0; i < [_chips count]; i++) {
        UIButton *c = [UIButton buttonWithType:UIButtonTypeCustom];
        c.frame = CGRectMake(8 + i * 106, 7, 100, 70);
        c.tag = (NSInteger)i;
        c.titleLabel.numberOfLines = 3;
        c.titleLabel.textAlignment = UITextAlignmentCenter;
        c.titleLabel.font = [UIFont boldSystemFontOfSize:14];
        [c setTitle:[[_chips objectAtIndex:i] objectForKey:@"n"] forState:UIControlStateNormal];
        [c addTarget:self action:@selector(chipTapped:) forControlEvents:UIControlEventTouchUpInside];
        [_chipScroll addSubview:c];
    }
    _chipScroll.contentSize = CGSizeMake(8 + [_chips count] * 106 + 8, 84);
    [_chipScroll setContentOffset:CGPointZero animated:NO];
    [self styleChips];
}

- (void)styleChips {
    // Selected item is a white tile with pink text; the others sit flat on the gray band.
    UIImage *tile = [DDStyle buttonTop:[UIColor whiteColor] bottom:[DDStyle gray:0.96f]
                              border:[DDStyle gray:0.70f] radius:8];
    for (UIView *v in [_chipScroll subviews]) {
        if (![v isKindOfClass:[UIButton class]]) continue;
        UIButton *c = (UIButton *)v;
        BOOL sel = (c.tag == _selChip);
        c.backgroundColor = [UIColor clearColor];
        [c setBackgroundImage:(sel ? tile : nil) forState:UIControlStateNormal];
        [c setTitleColor:(sel ? DD_PINK : [DDStyle gray:0.42f]) forState:UIControlStateNormal];
    }
}

- (void)chipTapped:(UIButton *)b {
    _selChip = (int)b.tag;
    [self styleChips];
    [self reloadProducts];
}

- (void)collectKey:(NSString *)key into:(NSMutableArray *)out seen:(NSMutableSet *)seen {
    NSString *marker = [@"cat:" stringByAppendingString:key];
    if ([seen containsObject:marker]) return;
    [seen addObject:marker];
    NSDictionary *c = [[_menu objectForKey:@"cats"] objectForKey:key];
    for (NSString *i in [c objectForKey:@"items"]) {
        if (![seen containsObject:i]) { [seen addObject:i]; [out addObject:i]; }
    }
    for (NSString *s in [c objectForKey:@"subs"]) [self collectKey:s into:out seen:seen];
}

- (void)reloadProducts {
    [_products release];
    _products = nil;
    NSMutableArray *list = [NSMutableArray array];
    if (_selChip >= 0 && (NSUInteger)_selChip < [_chips count]) {
        [self collectKey:[[_chips objectAtIndex:(NSUInteger)_selChip] objectForKey:@"key"]
                    into:list seen:[NSMutableSet set]];
    }
    _products = [list retain];
    _status.hidden = ([_products count] > 0);
    if ([_products count] == 0) _status.text = @"Nothing here right now.";
    _table.hidden = ([_products count] == 0);
    [_table reloadData];
    [_table setContentOffset:CGPointZero animated:NO];
}

#pragma mark - Table

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s {
    return (NSInteger)[_products count];
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:@"p"];
    if (!cell) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"p"] autorelease];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    NSDictionary *p = [[_menu objectForKey:@"prods"] objectForKey:[_products objectAtIndex:(NSUInteger)ip.row]];
    cell.textLabel.text = [p objectForKey:@"n"];
    NSString *cal = [p objectForKey:@"c"];
    cell.detailTextLabel.text = cal ? [NSString stringWithFormat:@"%@ cal", cal] : nil;
    return cell;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)ip {
    [tv deselectRowAtIndexPath:ip animated:YES];
    NSDictionary *p = [[_menu objectForKey:@"prods"] objectForKey:[_products objectAtIndex:(NSUInteger)ip.row]];
    ProductViewController *vc = [[ProductViewController alloc] initWithProduct:p];
    [self.navigationController pushViewController:vc animated:YES];
    [vc release];
}

- (void)dealloc {
    _table.delegate = nil;
    _table.dataSource = nil;
    [_drinksBtn release];
    [_foodBtn release];
    [_seg release];
    [_chipScroll release];
    [_table release];
    [_status release];
    [_spinner release];
    [_menu release];
    [_chips release];
    [_products release];
    [super dealloc];
}

@end
