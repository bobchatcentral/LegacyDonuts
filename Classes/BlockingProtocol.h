#import <Foundation/Foundation.h>

// Answers analytics/ad/video requests with an empty 200 so the page
// never downloads or runs them. Saves RAM on the 4s.
@interface BlockingProtocol : NSURLProtocol
@end
