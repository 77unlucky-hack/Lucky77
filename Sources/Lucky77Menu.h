#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT void Lucky77PresentMenu(UIViewController *presenter);
FOUNDATION_EXPORT UIViewController *Lucky77CreateMenuViewController(void);

// Глобальные флаги
extern BOOL g_espEnabled;
extern BOOL g_aimbotEnabled;
extern BOOL g_radarHack;
extern BOOL g_noRecoil;
extern BOOL g_unlimitedAmmo;
extern BOOL g_triggerbot;
extern NSInteger g_fpsLimit;

// Язык меню (0 - English, 1 - Русский)
extern NSInteger g_language;

NS_ASSUME_NONNULL_END
