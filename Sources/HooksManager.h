#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HooksManager : NSObject

+ (void)installHooks;
+ (void)uninstallHooks;
+ (BOOL)isHooked;

@end

NS_ASSUME_NONNULL_END
