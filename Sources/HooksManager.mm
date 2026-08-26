#import "HooksManager.h"
#import "MemoryUtils.h"
#import "GameStructs.h"
#import "Lucky77Menu.h"
#import <substrate.h>
#import <dlfcn.h>

// Оригинальные функции
static void (*original_glDrawArrays)(int mode, int first, int count);
static int (*original_getAmmo)(uintptr_t weapon);
static float (*original_getRecoil)(uintptr_t weapon);
static void (*original_aimAt)(uintptr_t player, float x, float y);
static void (*original_update)(void);

// Данные игроков
static Player players[64];
static int playerCount = 0;

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
    original_glDrawArrays(mode, first, count);
    
    if (g_espEnabled) {
        // TODO: Реализовать ESP (требуется WorldToScreen)
        // Здесь будет отрисовка поверх игры
    }
}

static int hooked_getAmmo(uintptr_t weapon) {
    if (g_unlimitedAmmo) {
        return 999;
    }
    return original_getAmmo(weapon);
}

static float hooked_getRecoil(uintptr_t weapon) {
    if (g_noRecoil) {
        return 0.0f;
    }
    return original_getRecoil(weapon);
}

static void hooked_aimAt(uintptr_t player, float x, float y) {
    if (g_aimbotEnabled) {
        Player *target = GetClosestEnemy();
        if (target) {
            // Наводимся на голову (Y + 1.5 для роста)
            original_aimAt(player, target->x, target->y + 1.5f);
            return;
        }
    }
    original_aimAt(player, x, y);
}

static void hooked_update(void) {
    original_update();
    
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

@implementation HooksManager

+ (void)installHooks {
    uintptr_t base = [MemoryUtils getGameBase];
    if (!base) {
        NSLog(@"[Lucky77] Game base not found");
        return;
    }
    
    NSLog(@"[Lucky77] Installing hooks at base: 0x%lx", (unsigned long)base);
    
    // TODO: Заменить на реальные адреса из дампа
    #define ADDR_DRAW_ARRAYS 0x00000000
    #define ADDR_GET_AMMO 0x00000000
    #define ADDR_GET_RECOIL 0x00000000
    #define ADDR_AIM_AT 0x00000000
    #define ADDR_UPDATE 0x00000000
    
    MSHookFunction((void *)(base + ADDR_DRAW_ARRAYS), (void *)&hooked_glDrawArrays, (void **)&original_glDrawArrays);
    MSHookFunction((void *)(base + ADDR_GET_AMMO), (void *)&hooked_getAmmo, (void **)&original_getAmmo);
    MSHookFunction((void *)(base + ADDR_GET_RECOIL), (void *)&hooked_getRecoil, (void **)&original_getRecoil);
    MSHookFunction((void *)(base + ADDR_AIM_AT), (void *)&hooked_aimAt, (void **)&original_aimAt);
    MSHookFunction((void *)(base + ADDR_UPDATE), (void *)&hooked_update, (void **)&original_update);
    
    NSLog(@"[Lucky77] Hooks installed successfully");
}

+ (void)uninstallHooks {
    NSLog(@"[Lucky77] Hooks uninstalled");
}

+ (BOOL)isHooked {
    return original_glDrawArrays != NULL;
}

@end
