#import "MemoryUtils.h"
#import <dlfcn.h>
#import <mach-o/dyld.h>

@implementation MemoryUtils

+ (uintptr_t)getGameBase {
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && (strstr(name, "Standoff2") != NULL || strstr(name, "standoff") != NULL)) {
            return (uintptr_t)_dyld_get_image_vmaddr_slide(i);
        }
    }
    return 0;
}

+ (kern_return_t)readMemory:(uintptr_t)address buffer:(void *)buffer size:(size_t)size {
    vm_size_t bytesRead;
    return vm_read_overwrite(mach_task_self(), address, size, (vm_address_t)buffer, &bytesRead);
}

+ (kern_return_t)writeMemory:(uintptr_t)address buffer:(void *)buffer size:(size_t)size {
    return vm_write(mach_task_self(), address, (vm_offset_t)buffer, (mach_msg_type_number_t)size);
}

+ (uintptr_t)readPointer:(uintptr_t)address {
    uintptr_t value = 0;
    [self readMemory:address buffer:&value size:sizeof(value)];
    return value;
}

+ (float)readFloat:(uintptr_t)address {
    float value = 0;
    [self readMemory:address buffer:&value size:sizeof(value)];
    return value;
}

+ (int)readInt:(uintptr_t)address {
    int value = 0;
    [self readMemory:address buffer:&value size:sizeof(value)];
    return value;
}

+ (void)writeFloat:(uintptr_t)address value:(float)value {
    [self writeMemory:address buffer:&value size:sizeof(value)];
}

+ (void)writeInt:(uintptr_t)address value:(int)value {
    [self writeMemory:address buffer:&value size:sizeof(value)];
}

@end
