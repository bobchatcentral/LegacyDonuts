#import "WebViewController.h"
#import "Theme.h"

// Removes the heaviest elements after each page load (helps a lot on old iPhones).
static NSString *const kSlimJS =
    @"(function(){var t=['video','iframe','canvas'];"
    @"for(var i=0;i<t.length;i++){var n=document.getElementsByTagName(t[i]);"
    @"for(var j=n.length-1;j>=0;j--){n[j].parentNode.removeChild(n[j]);}}})();";

@implementation WebViewController

- (id)initWithURL:(NSString *)url title:(NSString *)title {
    if ((self = [super init])) {
        _urlString = [url copy];
        self.title = title;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    _web = [[UIWebView alloc] initWithFrame:self.view.bounds];
    _web.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _web.delegate = self;
    _web.scalesPageToFit = YES;
    _web.mediaPlaybackRequiresUserAction = YES;
    [self.view addSubview:_web];

    _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:_spinner];
    self.navigationItem.rightBarButtonItem = item;
    [item release];

    [_web loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:_urlString]]];
}

- (BOOL)webView:(UIWebView *)w shouldStartLoadWithRequest:(NSURLRequest *)req navigationType:(UIWebViewNavigationType)type {
    NSString *scheme = [[req.URL scheme] lowercaseString];
    if ([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"] ||
        [scheme isEqualToString:@"about"] || [scheme isEqualToString:@"javascript"] ||
        [scheme isEqualToString:@"data"]) return YES;
    [[UIApplication sharedApplication] openURL:req.URL];
    return NO;
}

- (void)webViewDidStartLoad:(UIWebView *)w {
    [_spinner startAnimating];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)w {
    [_spinner stopAnimating];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [w stringByEvaluatingJavaScriptFromString:kSlimJS];
}

- (void)webView:(UIWebView *)w didFailLoadWithError:(NSError *)err {
    [_spinner stopAnimating];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    if (err.code == NSURLErrorCancelled) return;
    if ([err.domain isEqualToString:@"WebKitErrorDomain"] && err.code == 102) return;
    NSString *html = [NSString stringWithFormat:
        @"<html><body style='font-family:Helvetica;padding:20px'><h3>Couldn't load page</h3><p>%@ (%d)</p>"
        @"<p>Older iPhones can be slow on this website. Try again in a moment.</p></body></html>",
        [err localizedDescription], (int)err.code];
    [w loadHTMLString:html baseURL:nil];
}

- (void)dealloc {
    _web.delegate = nil;
    [_web release];
    [_spinner release];
    [_urlString release];
    [super dealloc];
}

@end
