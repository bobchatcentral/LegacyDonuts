#import <UIKit/UIKit.h>

@interface WebViewController : UIViewController <UIWebViewDelegate> {
    UIWebView *_web;
    UIActivityIndicatorView *_spinner;
    NSString *_urlString;
}
- (id)initWithURL:(NSString *)url title:(NSString *)title;
@end
