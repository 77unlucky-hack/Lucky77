#import "HooksManager.h"
#import "MemoryUtils.h"
#import "GameStructs.h"
#import "Lucky77Menu.h"
#import <dlfcn.h>
#import <mach-o/dyld.h>
#import <objc/runtime.h>

// ============ ОРИГИНАЛЬНЫЕ ФУНКЦИИ (указатели) ============
static void (*original_glDrawArrays)(int mode, int first, int count) = NULL;
static int (*original_getAmmo)(uintptr_t weapon) = NULL;
static float (*original_getRecoil)(uintptr_t weapon) = NULL;
static void (*original_aimAt)(uintptr_t player, float x, float y) = NULL;
static void (*original_update)(void) = NULL;

// Данные игроков
static Player players[64];
static int playerCount = 0;

// Флаг установки хуков
static BOOL hooksInstalled = NO;

// ============ ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ============

static void UpdatePlayerList(void) {
    uintptr_t base = [MemoryUtils getGameBase];
    if (!base) return;
    
    // TODO: Заменить на актуальные офсеты для 0.39.2
    #define OFFSET_ENTITY_LIST 0x00000000
    #define OFFSET_PLAYER_COUNT 0x00000000
    #define OFFSET_LOCAL_PLAYER 0x00000000
    #define OFFSET_HEALTH 0x00000000
    #define OFFSET_TEAM 0x00000000
    #define OFFSET_IS_ALIVE 0x00000000
    #define OFFSET_POSITION 0x00000000
    
    uintptr_t entityList = [MemoryUtils readPointer:base + OFFSET_ENTITY_LIST];
    if (!entityList) return;
    
    playerCount = [MemoryUtils readInt:base + OFFSET_PLAYER_COUNT];
    if (playerCount > 64) playerCount = 64;
    
    for (int i = 0; i < playerCount; i++) {
        uintptr_t playerAddr = [MemoryUtils readPointer:entityList + (i * sizeof(uintptr_t))];
        if (!playerAddr) continue;
        
        Player *p = &players[i];
        p->address = playerAddr;
        p->health = [MemoryUtils readFloat:playerAddr + OFFSET_HEALTH];
        p->team = [MemoryUtils readInt:playerAddr + OFFSET_TEAM];
        p->isAlive = [MemoryUtils readInt:playerAddr + OFFSET_IS_ALIVE] > 0;
        p->x = [MemoryUtils readFloat:playerAddr + OFFSET_POSITION];
        p->y = [MemoryUtils readFloat:playerAddr + OFFSET_POSITION + 4];
        p->z = [MemoryUtils readFloat:playerAddr + OFFSET_POSITION + 8];
    }
}

static Player* GetClosestEnemy(void) {
    uintptr_t base = [MemoryUtils getGameBase];
    if (!base) return NULL;
    
    // TODO: Заменить на актуальные офсеты
    #define OFFSET_LOCAL_PLAYER 0x00000000
    #define OFFSET_TEAM 0x00000000
    #define OFFSET_POSITION 0x00000000
    
    uintptr_t localPlayer = [MemoryUtils readPointer:base + OFFSET_LOCAL_PLAYER];
    if (!localPlayer) return NULL;
    
    int localTeam = [MemoryUtils readInt:localPlayer + OFFSET_TEAM];
    float localX = [MemoryUtils readFloat:localPlayer + OFFSET_POSITION];
    float localY = [MemoryUtils readFloat:localPlayer + OFFSET_POSITION + 4];
    float localZ = [MemoryUtils readFloat:localPlayer + OFFSET_POSITION + 8];
    
    Player *best = NULL;
    float bestDist = 999999.0f;
    
    for (int i = 0; i < playerCount; i++) {
        if (!players[i].isAlive || players[i].team == localTeam) continue;
        
        float dx = players[i].x - localX;
        float dy = players[i].y - localY;
        float dz = players[i].z - localZ;
        float dist = dx*dx + dy*dy + dz*dz;
        
        if (dist < bestDist) {
            bestDist = dist;
            best = &players[i];
        }
    }
    return best;
}

// ============ ХУКНУТЫЕ ФУНКЦИИ ============

static void hooked_glDrawArrays(int mode, int first, int count) {
    if (original_glDrawArrays) {
        original_glDrawArrays(mode, first, count);
    }
    
    if (g_espEnabled) {
        // TODO: Реализовать ESP (требуется WorldToScreen)
        // Здесь будет отрисовка поверх игры
        // NSLog(@"[Lucky77] ESP enabled");
    }
}

static int hooked_getAmmo(uintptr_t weapon) {
    if (g_unlimitedAmmo && original_getAmmo) {
        return 999;
    }
    return original_getAmmo ? original_getAmmo(weapon) : 30;
}

static float hooked_getRecoil(uintptr_t weapon) {
    if (g_noRecoil && original_getRecoil) {
        return 0.0f;
    }
    return original_getRecoil ? original_getRecoil(weapon) : 0.5f;
}

static void hooked_aimAt(uintptr_t player, float x, float y) {
    if (g_aimbotEnabled) {
        Player *target = GetClosestEnemy();
        if (target && original_aimAt) {
            // Наводимся на голову (Y + 1.5 для роста)
            original_aimAt(player, target->x, target->y + 1.5f);
            return;
        }
    }
    if (original_aimAt) {
        original_aimAt(player, x, y);
    }
}

static void hooked_update(void) {
    if (original_update) {
        original_update();
    }
    
    if (g_radarHack) {
        UpdatePlayerList();
        // TODO: Изменить флаги видимости на радаре
    }
    
    if (g_triggerbot) {
        Player *target = GetClosestEnemy();
        if (target && target->isAlive) {
            // TODO: Эмулировать нажатие на стрельбу
        }
    }
}

// ============ УСТАНОВКА ХУКОВ ============

// Функция для поиска адреса символа в бинарнике
static void *FindSymbolInImage(const char *imageName, const char *symbolName) {
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, imageName) != NULL) {
            void *handle = dlopen(name, RTLD_LAZY);
            if (handle) {
                void *addr = dlsym(handle, symbolName);
                dlclose(handle);
                if (addr) {
                    return addr;
                }
            }
        }
    }
    return NULL;
}

// Функция для получения адреса функции по смещению от базы
static void *GetFunctionAddress(uintptr_t base, uintptr_t offset) {
    if (base == 0 || offset == 0) return NULL;
    return (void *)(base + offset);
}

@implementation HooksManager

+ (void)installHooks {
    if (hooksInstalled) {
        NSLog(@"[Lucky77] Hooks already installed");
        return;
    }
    
    uintptr_t base = [MemoryUtils getGameBase];
    if (!base) {
        NSLog(@"[Lucky77] Game base not found");
        return;
    }
    
    NSLog(@"[Lucky77] Installing hooks at base: 0x%lx", (unsigned long)base);
    
    // TODO: Заменить на реальные адреса из дампа для версии 0.39.2
    #define ADDR_DRAW_ARRAYS 0x00000000
    #define ADDR_GET_AMMO 0x00000000
    #define ADDR_GET_RECOIL 0x00000000
    #define ADDR_AIM_AT 0x00000000
    #define ADDR_UPDATE 0x00000000
    
    // Получаем адреса функций
    void *addr_drawArrays = GetFunctionAddress(base, ADDR_DRAW_ARRAYS);
    void *addr_getAmmo = GetFunctionAddress(base, ADDR_GET_AMMO);
    void *addr_getRecoil = GetFunctionAddress(base, ADDR_GET_RECOIL);
    void *addr_aimAt = GetFunctionAddress(base, ADDR_AIM_AT);
    void *addr_update = GetFunctionAddress(base, ADDR_UPDATE);
    
    // Сохраняем оригинальные указатели
    if (addr_drawArrays) {
        original_glDrawArrays = (void (*)(int, int, int))addr_drawArrays;
        NSLog(@"[Lucky77] Found glDrawArrays at: %p", addr_drawArrays);
    }
    if (addr_getAmmo) {
        original_getAmmo = (int (*)(uintptr_t))addr_getAmmo;
        NSLog(@"[Lucky77] Found getAmmo at: %p", addr_getAmmo);
    }
    if (addr_getRecoil) {
        original_getRecoil = (float (*)(uintptr_t))addr_getRecoil;
        NSLog(@"[Lucky77] Found getRecoil at: %p", addr_getRecoil);
    }
    if (addr_aimAt) {
        original_aimAt = (void (*)(uintptr_t, float, float))addr_aimAt;
        NSLog(@"[Lucky77] Found aimAt at: %p", addr_aimAt);
    }
    if (addr_update) {
        original_update = (void (*)(void))addr_update;
        NSLog(@"[Lucky77] Found update at: %p", addr_update);
    }
    
    // ВНИМАНИЕ: Для реального перехвата функций на iOS без джейлбрейка
    // нужны специальные методы (Substrate, fishhook или ручная запись в память)
    // Сейчас это демонстрационная заглушка
    
    if (original_glDrawArrays || original_getAmmo || original_getRecoil || original_aimAt || original_update) {
        hooksInstalled = YES;
        NSLog(@"[Lucky77] Hooks installed (placeholder - real hooks require Substrate or memory write)");
    } else {
        NSLog(@"[Lucky77] No functions found - check offsets!");
    }
    
    // Вывод статуса для отладки
    NSLog(@"[Lucky77] Hook status:");
    NSLog(@"  glDrawArrays: %@", original_glDrawArrays ? @"✅" : @"❌");
    NSLog(@"  getAmmo: %@", original_getAmmo ? @"✅" : @"❌");
    NSLog(@"  getRecoil: %@", original_getRecoil ? @"✅" : @"❌");
    NSLog(@"  aimAt: %@", original_aimAt ? @"✅" : @"❌");
    NSLog(@"  update: %@", original_update ? @"✅" : @"❌");
}

+ (void)uninstallHooks {
    hooksInstalled = NO;
    NSLog(@"[Lucky77] Hooks uninstalled");
}

+ (BOOL)isHooked {
    return hooksInstalled;
}

@end
