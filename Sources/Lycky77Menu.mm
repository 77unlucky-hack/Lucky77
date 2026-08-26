#import "Lucky77Menu.h"
#import "Lucky77Theme.h"
#import "HooksManager.h"
#import "MemoryUtils.h"
#import <QuartzCore/QuartzCore.h>

// ============ ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ ============
BOOL g_espEnabled = NO;
BOOL g_aimbotEnabled = NO;
BOOL g_radarHack = NO;
BOOL g_noRecoil = NO;
BOOL g_unlimitedAmmo = NO;
BOOL g_triggerbot = NO;
NSInteger g_fpsLimit = 60;
NSInteger g_language = 0;

#define LOGO_URL @"https://raw.githubusercontent.com/77unlucky-hack/Lucky77/main/logo.png"

// ============ ЛОКАЛИЗАЦИЯ ============
static NSDictionary *enStrings = nil;
static NSDictionary *ruStrings = nil;

static NSString* L(NSString *key) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        enStrings = @{
            @"aimbot": @"AIMBOT",
            @"visuals": @"VISUALS",
            @"settings": @"SETTINGS",
            @"enable_aimbot": @"ENABLE AIMBOT",
            @"triggerbot": @"TRIGGERBOT",
            @"smooth_aim": @"SMOOTH AIM",
            @"visible_check": @"VISIBLE CHECK",
            @"fov_slider": @"AIM FOV",
            @"esp_box": @"ESP BOX",
            @"esp_name": @"ESP NAME",
            @"esp_health": @"ESP HEALTH",
            @"snap_lines": @"SNAP LINES",
            @"radar_hack": @"RADAR HACK",
            @"no_recoil": @"NO RECOIL",
            @"unlimited_ammo": @"UNLIMITED AMMO",
            @"language": @"LANGUAGE",
            @"fps_limit": @"FPS LIMIT",
            @"developer": @"DEVELOPER",
            @"config": @"CONFIG",
            @"save_config": @"SAVE CONFIG",
            @"load_config": @"LOAD CONFIG",
            @"fps": @"FPS",
        };
        ruStrings = @{
            @"aimbot": @"АИМБОТ",
            @"visuals": @"ВИЗУАЛ",
            @"settings": @"НАСТРОЙКИ",
            @"enable_aimbot": @"ВКЛЮЧИТЬ АИМБОТ",
            @"triggerbot": @"ТРИГГЕРБОТ",
            @"smooth_aim": @"ПЛАВНЫЙ ПРИЦЕЛ",
            @"visible_check": @"ПРОВЕРКА ВИДИМОСТИ",
            @"fov_slider": @"УГОЛ ПРИЦЕЛА",
            @"esp_box": @"ESP КОНТУР",
            @"esp_name": @"ESP ИМЯ",
            @"esp_health": @"ESP ЗДОРОВЬЕ",
            @"snap_lines": @"ЛИНИИ К ЦЕЛИ",
            @"radar_hack": @"РАДАР",
            @"no_recoil": @"БЕЗ ОТДАЧИ",
            @"unlimited_ammo": @"БЕСКОНЕЧНЫЕ ПАТРОНЫ",
            @"language": @"ЯЗЫК",
            @"fps_limit": @"ЛИМИТ FPS",
            @"developer": @"РАЗРАБОТЧИК",
            @"config": @"КОНФИГ",
            @"save_config": @"СОХРАНИТЬ КОНФИГ",
            @"load_config": @"ЗАГРУЗИТЬ КОНФИГ",
            @"fps": @"FPS",
        };
    });
    return g_language == 0 ? enStrings[key] : ruStrings[key];
}

// ============ КАСТОМНЫЙ TOGGLE ============
@interface L77DemoToggle : UIControl
@property (nonatomic, strong) UIView *box;
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, assign, getter=isOn) BOOL on;
@property (nonatomic, copy) NSString *key;
@end

@implementation L77DemoToggle

- (instancetype)initWithTitle:(NSString *)title key:(NSString *)key {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.key = key;
        
        self.box = [UIView new];
        self.box.layer.cornerRadius = 4;
        self.box.layer.borderWidth = 1.5;
        self.box.layer.borderColor = Lucky77Theme.border.CGColor;
        self.box.backgroundColor = UIColor.clearColor;
        self.box.translatesAutoresizingMaskIntoConstraints = NO;
        
        self.label = [UILabel new];
        self.label.text = title;
        self.label.font = [Lucky77Theme bodyFont:13];
        self.label.textColor = Lucky77Theme.textPrimary;
        self.label.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self addSubview:self.box];
        [self addSubview:self.label];
        
        [NSLayoutConstraint activateConstraints:@[
            [self.heightAnchor constraintEqualToConstant:34],
            [self.box.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [self.box.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
            [self.box.widthAnchor constraintEqualToConstant:22],
            [self.box.heightAnchor constraintEqualToConstant:22],
            [self.label.leadingAnchor constraintEqualToAnchor:self.box.trailingAnchor constant:12],
            [self.label.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [self.label.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        ]];
        
        [self addTarget:self action:@selector(tap) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

- (void)tap {
    self.on = !self.on;
    
    [UIView animateWithDuration:0.18 animations:^{
        self.box.backgroundColor = self.on ? Lucky77Theme.purple : UIColor.clearColor;
        self.box.layer.borderColor = (self.on ? Lucky77Theme.purpleGlow : Lucky77Theme.border).CGColor;
        self.box.transform = CGAffineTransformMakeScale(0.92, 0.92);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.12 animations:^{
            self.box.transform = CGAffineTransformIdentity;
        }];
    }];
    
    if ([self.key isEqualToString:@"esp"]) g_espEnabled = self.on;
    else if ([self.key isEqualToString:@"aimbot"]) g_aimbotEnabled = self.on;
    else if ([self.key isEqualToString:@"radar"]) g_radarHack = self.on;
    else if ([self.key isEqualToString:@"recoil"]) g_noRecoil = self.on;
    else if ([self.key isEqualToString:@"ammo"]) g_unlimitedAmmo = self.on;
    else if ([self.key isEqualToString:@"trigger"]) g_triggerbot = self.on;
}

@end

// ============ ГЛАВНЫЙ КОНТРОЛЛЕР ============
@interface L77MenuViewController : UIViewController
@property (nonatomic, strong) UIView *menuCard;
@property (nonatomic, strong) UIView *introView;
@property (nonatomic, strong) UIImageView *logoView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *versionLabel;
@property (nonatomic, strong) UILabel *fpsLabel;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) CFTimeInterval lastTimestamp;
@property (nonatomic, assign) NSInteger frameCount;
@property (nonatomic, strong) UIStackView *contentStack;
@property (nonatomic, strong) UIButton *launcherButton;
@property (nonatomic, assign) BOOL isDragging;
@property (nonatomic, assign) CGPoint dragOffset;
@property (nonatomic, strong) NSArray *menuItems;
@property (nonatomic, strong) NSMutableDictionary *config;
@property (nonatomic, strong) UIScrollView *sidebarScroll;
@property (nonatomic, strong) UIStackView *navStack;
@property (nonatomic, strong) NSArray *navButtons;
@end

@implementation L77MenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // ============ НАСТРОЙКИ БЕЗ БЛОКИРОВКИ ============
    self.view.backgroundColor = [UIColor clearColor];
    self.view.opaque = NO;
    self.view.userInteractionEnabled = NO;
    self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    self.config = [NSMutableDictionary dictionary];
    [self loadConfig];
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [HooksManager installHooks];
    });
    
    [self buildLauncherButton];
    [self buildMenu];
    [self buildIntroAnimation];
    [self startFPS];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.view.backgroundColor = [UIColor clearColor];
}

- (void)dealloc {
    [self.displayLink invalidate];
}

// ============ КНОПКА-ЛАУНЧЕР ============
- (void)buildLauncherButton {
    self.launcherButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.launcherButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.launcherButton.backgroundColor = [Lucky77Theme.panel colorWithAlphaComponent:0.9];
    self.launcherButton.layer.cornerRadius = 14;
    self.launcherButton.layer.borderWidth = 1.5;
    self.launcherButton.layer.borderColor = Lucky77Theme.purple.CGColor;
    self.launcherButton.layer.shadowColor = Lucky77Theme.purpleGlow.CGColor;
    self.launcherButton.layer.shadowOpacity = 0.4;
    self.launcherButton.layer.shadowRadius = 14;
    [self.launcherButton setTitle:@"⚡" forState:UIControlStateNormal];
    [self.launcherButton setTitleColor:Lucky77Theme.purpleGlow forState:UIControlStateNormal];
    self.launcherButton.titleLabel.font = [UIFont systemFontOfSize:28 weight:UIFontWeightBold];
    self.launcherButton.userInteractionEnabled = YES;
    [self.launcherButton addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragLauncher:)];
    [self.launcherButton addGestureRecognizer:pan];
    
    [self.view addSubview:self.launcherButton];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.launcherButton.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:12],
        [self.launcherButton.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:12],
        [self.launcherButton.widthAnchor constraintEqualToConstant:48],
        [self.launcherButton.heightAnchor constraintEqualToConstant:48],
    ]];
}

- (void)dragLauncher:(UIPanGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        self.isDragging = YES;
        CGPoint touch = [gesture locationInView:self.view];
        CGPoint center = self.launcherButton.center;
        self.dragOffset = CGPointMake(center.x - touch.x, center.y - touch.y);
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        CGPoint touch = [gesture locationInView:self.view];
        self.launcherButton.center = CGPointMake(touch.x + self.dragOffset.x, touch.y + self.dragOffset.y);
    } else if (gesture.state == UIGestureRecognizerStateEnded) {
        self.isDragging = NO;
    }
}

// ============ ПОСТРОЕНИЕ МЕНЮ ============
- (void)buildMenu {
    self.menuCard = [UIView new];
    self.menuCard.translatesAutoresizingMaskIntoConstraints = NO;
    self.menuCard.backgroundColor = [Lucky77Theme.panel colorWithAlphaComponent:0.92];
    self.menuCard.layer.cornerRadius = 20;
    self.menuCard.layer.borderWidth = 1;
    self.menuCard.layer.borderColor = Lucky77Theme.border.CGColor;
    self.menuCard.layer.shadowColor = UIColor.blackColor.CGColor;
    self.menuCard.layer.shadowOpacity = 0.6;
    self.menuCard.layer.shadowRadius = 28;
    self.menuCard.hidden = YES;
    self.menuCard.userInteractionEnabled = YES;
    [self.view addSubview:self.menuCard];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.menuCard.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:80],
        [self.menuCard.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-20],
        [self.menuCard.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:18],
        [self.menuCard.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-18],
    ]];
    
    // HEADER
    UIView *header = [UIView new];
    header.translatesAutoresizingMaskIntoConstraints = NO;
    [self.menuCard addSubview:header];
    
    self.fpsLabel = [UILabel new];
    self.fpsLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.fpsLabel.text = @"-- FPS";
    self.fpsLabel.font = [Lucky77Theme bodyFont:13];
    self.fpsLabel.textColor = Lucky77Theme.purpleGlow;
    
    UILabel *logo = [UILabel new];
    logo.translatesAutoresizingMaskIntoConstraints = NO;
    logo.text = @"⚡";
    logo.font = [UIFont systemFontOfSize:28 weight:UIFontWeightBold];
    logo.textColor = Lucky77Theme.purpleGlow;
    logo.layer.shadowColor = Lucky77Theme.purpleGlow.CGColor;
    logo.layer.shadowOpacity = 0.7;
    logo.layer.shadowRadius = 12;
    
    UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
    close.translatesAutoresizingMaskIntoConstraints = NO;
    [close setTitle:@"✕" forState:UIControlStateNormal];
    [close setTitleColor:Lucky77Theme.purpleGlow forState:UIControlStateNormal];
    close.titleLabel.font = [Lucky77Theme titleFont:24];
    [close addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
    
    [header addSubview:self.fpsLabel];
    [header addSubview:logo];
    [header addSubview:close];
    
    [NSLayoutConstraint activateConstraints:@[
        [header.leadingAnchor constraintEqualToAnchor:self.menuCard.leadingAnchor],
        [header.trailingAnchor constraintEqualToAnchor:self.menuCard.trailingAnchor],
        [header.topAnchor constraintEqualToAnchor:self.menuCard.topAnchor],
        [header.heightAnchor constraintEqualToConstant:50],
        [self.fpsLabel.leadingAnchor constraintEqualToAnchor:header.leadingAnchor constant:18],
        [self.fpsLabel.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [logo.centerXAnchor constraintEqualToAnchor:header.centerXAnchor],
        [logo.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [close.trailingAnchor constraintEqualToAnchor:header.trailingAnchor constant:-14],
        [close.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [close.widthAnchor constraintEqualToConstant:36],
        [close.heightAnchor constraintEqualToConstant:36],
    ]];
    
    UIView *divider = [UIView new];
    divider.translatesAutoresizingMaskIntoConstraints = NO;
    divider.backgroundColor = Lucky77Theme.border;
    [self.menuCard addSubview:divider];
    
    // SIDEBAR
    self.sidebarScroll = [UIScrollView new];
    self.sidebarScroll.translatesAutoresizingMaskIntoConstraints = NO;
    self.sidebarScroll.backgroundColor = [Lucky77Theme.background colorWithAlphaComponent:0.7];
    self.sidebarScroll.layer.cornerRadius = 14;
    self.sidebarScroll.showsVerticalScrollIndicator = YES;
    [self.menuCard addSubview:self.sidebarScroll];
    
    self.navStack = [[UIStackView alloc] init];
    self.navStack.translatesAutoresizingMaskIntoConstraints = NO;
    self.navStack.axis = UILayoutConstraintAxisVertical;
    self.navStack.spacing = 7;
    [self.sidebarScroll addSubview:self.navStack];
    
    self.menuItems = @[@"aimbot", @"visuals", @"settings"];
    NSArray *sections = @[L(@"aimbot"), L(@"visuals"), L(@"settings")];
    NSMutableArray *buttons = [NSMutableArray array];
    
    for (NSInteger i = 0; i < self.menuItems.count; i++) {
        UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
        b.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [b setTitle:[NSString stringWithFormat:@"   %@", sections[i]] forState:UIControlStateNormal];
        [b setTitleColor:Lucky77Theme.textPrimary forState:UIControlStateNormal];
        b.titleLabel.font = [Lucky77Theme bodyFont:14];
        b.layer.cornerRadius = 8;
        b.backgroundColor = (i == 0) ? [Lucky77Theme.purpleDark colorWithAlphaComponent:0.9] : UIColor.clearColor;
        [b.heightAnchor constraintEqualToConstant:40].active = YES;
        b.tag = i;
        [b addTarget:self action:@selector(navTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.navStack addArrangedSubview:b];
        [buttons addObject:b];
    }
    self.navButtons = buttons;
    
    // CONTENT
    UIScrollView *scroll = [UIScrollView new];
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    scroll.showsVerticalScrollIndicator = YES;
    [self.menuCard addSubview:scroll];
    
    self.contentStack = [[UIStackView alloc] init];
    self.contentStack.translatesAutoresizingMaskIntoConstraints = NO;
    self.contentStack.axis = UILayoutConstraintAxisVertical;
    self.contentStack.spacing = 16;
    [scroll addSubview:self.contentStack];
