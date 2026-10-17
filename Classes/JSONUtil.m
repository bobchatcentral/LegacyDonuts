#import "JSONUtil.h"
#import <objc/message.h>

@implementation JSONUtil

+ (id)parse:(NSData *)data {
    Class c = NSClassFromString(@"NSJSONSerialization");
    if (!c || !data) return nil;
    NSError *err = nil;
    id (*send)(id, SEL, NSData *, NSUInteger, NSError **) =
        (id (*)(id, SEL, NSData *, NSUInteger, NSError **))objc_msgSend;
    return send(c, @selector(JSONObjectWithData:options:error:), data, 0, &err);
}

+ (NSData *)dataFromObject:(id)object {
    Class c = NSClassFromString(@"NSJSONSerialization");
    if (!c || !object) return nil;
    NSError *err = nil;
    NSData *(*send)(id, SEL, id, NSUInteger, NSError **) =
        (NSData *(*)(id, SEL, id, NSUInteger, NSError **))objc_msgSend;
    return send(c, @selector(dataWithJSONObject:options:error:), object, 0, &err);
}

@end
