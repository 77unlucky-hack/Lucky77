#import <Foundation/Foundation.h>
#import <mach/mach.h>

NS_ASSUME_NONNULL_BEGIN

@interface MemoryUtils : NSObject

+ (uintptr_t)getGameBase;
+ (kern_return_t)readMemory:(uintptr_t)address buffer:(void *)buffer size:(size_t)size;
+ (kern_return_t)writeMemory:(uintptr_t)address buffer:(void *)buffer size:(size_t)size;
+ (uintptr_t)readPointer:(uintptr_t)address;
+ (float)readFloat:(uintptr_t)address;
+ (int)readInt:(uintptr_t)address;
+ (void)writeFloat:(uintptr_t)address value:(float)value;
+ (void)writeInt:(uintptr_t)address value:(int)value;

@end

NS_ASSUME_NONNULL_END
