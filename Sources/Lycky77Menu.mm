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
            @"app_name": @"Lucky77",
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
            @"settings_tab": @"SETTINGS",
            @"language": @"LANGUAGE",
            @"fps_limit": @"FPS LIMIT",
            @"developer": @"DEVELOPER",
            @"config": @"CONFIG",
            @"save_config": @"SAVE CONFIG",
            @"load_config": @"LOAD CONFIG",
            @"fps": @"FPS",
            @"game_not_found": @"Game not found",
            @"initializing": @"Initializing...",
            @"fps_30": @"30 FPS",
            @"fps_60": @"60 FPS",
            @"fps_90": @"90 FPS",
            @"fps_120": @"120 FPS",
        };
        ruStrings = @{
            @"app_name": @"Lucky77",
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
            @"settings_tab": @"НАСТРОЙКИ",
            @"language": @"ЯЗЫК",
            @"fps_limit": @"ЛИМИТ FPS",
            @"developer": @"РАЗРАБОТЧИК",
            @"config": @"КОНФИГ",
            @"save_config": @"СОХРАНИТЬ КОНФИГ",
            @"load_config": @"ЗАГРУЗИТЬ КОНФИГ",
            @"fps": @"FPS",
            @"game_not_found": @"Игра не найдена",
            @"initializing": @"Загрузка...",
            @"fps_30": @"30 FPS",
            @"fps_60": @"60 FPS",
            @"fps_90": @"90 FPS",
            @"fps_120": @"120 FPS",
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
@interface L77MenuViewController : UIViewController <UIScrollViewDelegate>
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
    self.view.backgroundColor = [UIColor clearColor];
    self.modalPresentationStyle = UIModalPresentationOverFullScreen;
    
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

- (void)dealloc {
    [self.displayLink invalidate];
}

// ============ КНОПКА-ЛАУНЧЕР ============
- (void)buildLauncherButton {
    self.launcherButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.launcherButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.launcherButton.backgroundColor = [Lucky77Theme.panel colorWithAlphaComponent:0.95];
    self.launcherButton.layer.cornerRadius = 14;
    self.launcherButton.layer.borderWidth = 1.5;
    self.launcherButton.layer.borderColor = Lucky77Theme.purple.CGColor;
    self.launcherButton.layer.shadowColor = Lucky77Theme.purpleGlow.CGColor;
    self.launcherButton.layer.shadowOpacity = 0.4;
    self.launcherButton.layer.shadowRadius = 14;
    [self.launcherButton setTitle:@"⚡" forState:UIControlStateNormal];
    [self.launcherButton setTitleColor:Lucky77Theme.purpleGlow forState:UIControlStateNormal];
    self.launcherButton.titleLabel.font = [UIFont systemFontOfSize:28 weight:UIFontWeightBold];
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
    
    // SIDEBAR с прокруткой
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
    
    UIView *defaultContent = [self makeContentForTab:0];
    [self.contentStack addArrangedSubview:defaultContent];
    
    [NSLayoutConstraint activateConstraints:@[
        [divider.leadingAnchor constraintEqualToAnchor:self.menuCard.leadingAnchor],
        [divider.trailingAnchor constraintEqualToAnchor:self.menuCard.trailingAnchor],
        [divider.topAnchor constraintEqualToAnchor:header.bottomAnchor],
        [divider.heightAnchor constraintEqualToConstant:1],
        
        [self.sidebarScroll.leadingAnchor constraintEqualToAnchor:self.menuCard.leadingAnchor constant:12],
        [self.sidebarScroll.topAnchor constraintEqualToAnchor:divider.bottomAnchor constant:12],
        [self.sidebarScroll.bottomAnchor constraintEqualToAnchor:self.menuCard.bottomAnchor constant:-12],
        [self.sidebarScroll.widthAnchor constraintEqualToConstant:160],
        
        [self.navStack.leadingAnchor constraintEqualToAnchor:self.sidebarScroll.leadingAnchor constant:14],
        [self.navStack.trailingAnchor constraintEqualToAnchor:self.sidebarScroll.trailingAnchor constant:-14],
        [self.navStack.topAnchor constraintEqualToAnchor:self.sidebarScroll.topAnchor constant:18],
        [self.navStack.bottomAnchor constraintEqualToAnchor:self.sidebarScroll.bottomAnchor constant:-18],
        [self.navStack.widthAnchor constraintEqualToAnchor:self.sidebarScroll.widthAnchor constant:-28],
        
        [scroll.leadingAnchor constraintEqualToAnchor:self.sidebarScroll.trailingAnchor constant:14],
        [scroll.trailingAnchor constraintEqualToAnchor:self.menuCard.trailingAnchor constant:-12],
        [scroll.topAnchor constraintEqualToAnchor:divider.bottomAnchor constant:12],
        [scroll.bottomAnchor constraintEqualToAnchor:self.menuCard.bottomAnchor constant:-12],
        
        [self.contentStack.leadingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.leadingAnchor],
        [self.contentStack.trailingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.trailingAnchor],
        [self.contentStack.topAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.topAnchor],
        [self.contentStack.bottomAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.bottomAnchor],
        [self.contentStack.widthAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.widthAnchor],
    ]];
}

// ============ КОНТЕНТ ВКЛАДОК ============
- (UIView *)makeContentForTab:(NSInteger)tabIndex {
    switch (tabIndex) {
        case 0: return [self makeAimbotContent];
        case 1: return [self makeVisualsContent];
        case 2: return [self makeSettingsContent];
        default: return [self makeAimbotContent];
    }
}

- (UIView *)makeAimbotContent {
    return [self makeColumn:L(@"aimbot")
                     items:@[L(@"enable_aimbot"), L(@"triggerbot"), L(@"smooth_aim"), L(@"visible_check")]
                     keys:@[@"aimbot", @"trigger", @"smooth", @"visible"]];
}

- (UIView *)makeVisualsContent {
    return [self makeColumn:L(@"visuals")
                     items:@[L(@"esp_box"), L(@"esp_name"), L(@"esp_health"), L(@"snap_lines"), L(@"radar_hack"), L(@"no_recoil"), L(@"unlimited_ammo")]
                     keys:@[@"esp", @"name", @"health", @"lines", @"radar", @"recoil", @"ammo"]];
}

- (UIView *)makeSettingsContent {
    UIView *container = [UIView new];
    container.backgroundColor = [Lucky77Theme.panelAlt colorWithAlphaComponent:0.7];
    container.layer.cornerRadius = 14;
    container.layer.borderWidth = 1;
    container.layer.borderColor = Lucky77Theme.border.CGColor;
    
    UIStackView *stack = [UIStackView new];
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 12;
    [container addSubview:stack];
    
    // Язык
    UILabel *langLabel = [UILabel new];
    langLabel.text = L(@"language");
    langLabel.font = [Lucky77Theme titleFont:16];
    langLabel.textColor = Lucky77Theme.textPrimary;
    [stack addArrangedSubview:langLabel];
    
    UISegmentedControl *langSeg = [[UISegmentedControl alloc] initWithItems:@[@"English", @"Русский"]];
    langSeg.selectedSegmentIndex = g_language;
    langSeg.tintColor = Lucky77Theme.purple;
    [langSeg addTarget:self action:@selector(languageChanged:) forControlEvents:UIControlEventValueChanged];
    [stack addArrangedSubview:langSeg];
    
    // FPS лимит
    UILabel *fpsLabel = [UILabel new];
    fpsLabel.text = L(@"fps_limit");
    fpsLabel.font = [Lucky77Theme titleFont:16];
    fpsLabel.textColor = Lucky77Theme.textPrimary;
    [stack addArrangedSubview:fpsLabel];
    
    UISegmentedControl *fpsSeg = [[UISegmentedControl alloc] initWithItems:@[@"30", @"60", @"90", @"120"]];
    NSInteger index = 0;
    if (g_fpsLimit == 30) index = 0;
    else if (g_fpsLimit == 60) index = 1;
    else if (g_fpsLimit == 90) index = 2;
    else if (g_fpsLimit == 120) index = 3;
    fpsSeg.selectedSegmentIndex = index;
    fpsSeg.tintColor = Lucky77Theme.purple;
    [fpsSeg addTarget:self action:@selector(fpsLimitChanged:) forControlEvents:UIControlEventValueChanged];
    [stack addArrangedSubview:fpsSeg];
    
    // Конфиги
    UILabel *configLabel = [UILabel new];
    configLabel.text = L(@"config");
    configLabel.font = [Lucky77Theme titleFont:16];
    configLabel.textColor = Lucky77Theme.textPrimary;
    [stack addArrangedSubview:configLabel];
    
    UIStackView *configButtons = [UIStackView new];
    configButtons.axis = UILayoutConstraintAxisHorizontal;
    configButtons.spacing = 12;
    configButtons.distribution = UIStackViewDistributionFillEqually;
    
    UIButton *saveBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [saveBtn setTitle:L(@"save_config") forState:UIControlStateNormal];
    saveBtn.backgroundColor = Lucky77Theme.purple;
    saveBtn.layer.cornerRadius = 8;
    [saveBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [saveBtn addTarget:self action:@selector(saveConfig) forControlEvents:UIControlEventTouchUpInside];
    [configButtons addArrangedSubview:saveBtn];
    
    UIButton *loadBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [loadBtn setTitle:L(@"load_config") forState:UIControlStateNormal];
    loadBtn.backgroundColor = Lucky77Theme.purpleDark;
    loadBtn.layer.cornerRadius = 8;
    [loadBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [loadBtn addTarget:self action:@selector(loadConfig) forControlEvents:UIControlEventTouchUpInside];
    [configButtons addArrangedSubview:loadBtn];
    
    [stack addArrangedSubview:configButtons];
    
    // Разработчик
    UILabel *devLabel = [UILabel new];
    devLabel.text = L(@"developer");
    devLabel.font = [Lucky77Theme titleFont:16];
    devLabel.textColor = Lucky77Theme.textPrimary;
    [stack addArrangedSubview:devLabel];
    
    UIButton *devBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [devBtn setTitle:@"@hack77ios" forState:UIControlStateNormal];
    [devBtn setTitleColor:Lucky77Theme.purpleGlow forState:UIControlStateNormal];
    devBtn.titleLabel.font = [Lucky77Theme bodyFont:16];
    [devBtn addTarget:self action:@selector(openTelegram) forControlEvents:UIControlEventTouchUpInside];
    [stack addArrangedSubview:devBtn];
    
    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:18],
        [stack.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-18],
        [stack.topAnchor constraintEqualToAnchor:container.topAnchor constant:18],
        [stack.bottomAnchor constraintLessThanOrEqualToAnchor:container.bottomAnchor constant:-18],
        [container.heightAnchor constraintGreaterThanOrEqualToConstant:400],
    ]];
    
    return container;
}

// ============ ОБЩИЙ КОМПОНЕНТ КОЛОНКИ ============
- (UIView *)makeColumn:(NSString *)title items:(NSArray *)items keys:(NSArray *)keys {
    UIView *container = [UIView new];
    container.backgroundColor = [Lucky77Theme.panelAlt colorWithAlphaComponent:0.7];
    container.layer.cornerRadius = 14;
    container.layer.borderWidth = 1;
    container.layer.borderColor = Lucky77Theme.border.CGColor;
    
    UIStackView *stack = [UIStackView new];
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 8;
    [container addSubview:stack];
    
    UILabel *heading = [UILabel new];
    heading.text = title;
    heading.font = [Lucky77Theme titleFont:16];
    heading.textColor = Lucky77Theme.purpleGlow;
    [stack addArrangedSubview:heading];
    
    UIView *line = [UIView new];
    line.backgroundColor = Lucky77Theme.border;
    [line.heightAnchor constraintEqualToConstant:1].active = YES;
    [stack addArrangedSubview:line];
    
    for (NSInteger i = 0; i < items.count && i < keys.count; i++) {
        L77DemoToggle *t = [[L77DemoToggle alloc] initWithTitle:items[i] key:keys[i]];
        [stack addArrangedSubview:t];
    }
    
    // FOV слайдер (только для AIMBOT)
    if ([title isEqualToString:L(@"aimbot")]) {
        UILabel *sliderLabel = [UILabel new];
        sliderLabel.text = [NSString stringWithFormat:@"%@: 90°", L(@"fov_slider")];
        sliderLabel.font = [Lucky77Theme bodyFont:12];
        sliderLabel.textColor = Lucky77Theme.textSecondary;
        [stack addArrangedSubview:sliderLabel];
        
        UISlider *slider = [UISlider new];
        slider.minimumValue = 0;
        slider.maximumValue = 360;
        slider.value = 90;
        slider.minimumTrackTintColor = Lucky77Theme.purple;
        slider.maximumTrackTintColor = [UIColor colorWithWhite:0.35 alpha:0.35];
        slider.thumbTintColor = Lucky77Theme.purpleGlow;
        [slider addTarget:self action:@selector(fovChanged:) forControlEvents:UIControlEventValueChanged];
        [stack addArrangedSubview:slider];
    }
    
    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:18],
        [stack.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-18],
        [stack.topAnchor constraintEqualToAnchor:container.topAnchor constant:18],
        [stack.bottomAnchor constraintLessThanOrEqualToAnchor:container.bottomAnchor constant:-18],
        [container.heightAnchor constraintGreaterThanOrEqualToConstant:300],
    ]];
    
    return container;
}

// ============ INTRO АНИМАЦИЯ ============
- (void)buildIntroAnimation {
    self.introView = [UIView new];
    self.introView.translatesAutoresizingMaskIntoConstraints = NO;
    self.introView.backgroundColor = [Lucky77Theme.background colorWithAlphaComponent:0.98];
    self.introView.layer.cornerRadius = 20;
    [self.view addSubview:self.introView];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.introView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.introView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [self.introView.widthAnchor constraintEqualToConstant:300],
        [self.introView.heightAnchor constraintEqualToConstant:300],
    ]];
    
    // Логотип с GitHub
    self.logoView = [UIImageView new];
    self.logoView.translatesAutoresizingMaskIntoConstraints = NO;
    self.logoView.contentMode = UIViewContentModeScaleAspectFit;
    self.logoView.layer.cornerRadius = 20;
    self.logoView.clipsToBounds = YES;
    [self.introView addSubview:self.logoView];
    
    // Загрузка логотипа
    [self loadLogo];
    
    // Название
    self.titleLabel = [UILabel new];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.text = @"Lucky77";
    self.titleLabel.font = [UIFont systemFontOfSize:36 weight:UIFontWeightBold];
    self.titleLabel.textColor = Lucky77Theme.purpleGlow;
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.layer.shadowColor = Lucky77Theme.purpleGlow.CGColor;
    self.titleLabel.layer.shadowOpacity = 0.8;
    self.titleLabel.layer.shadowRadius = 20;
    [self.introView addSubview:self.titleLabel];
    
    // Версия
    self.versionLabel = [UILabel new];
    self.versionLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.versionLabel.text = @"v0.1";
    self.versionLabel.font = [Lucky77Theme bodyFont:16];
    self.versionLabel.textColor = Lucky77Theme.textSecondary;
    self.versionLabel.textAlignment = NSTextAlignmentCenter;
    [self.introView addSubview:self.versionLabel];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.logoView.centerXAnchor constraintEqualToAnchor:self.introView.centerXAnchor],
        [self.logoView.topAnchor constraintEqualToAnchor:self.introView.topAnchor constant:30],
        [self.logoView.widthAnchor constraintEqualToConstant:120],
        [self.logoView.heightAnchor constraintEqualToConstant:120],
        [self.titleLabel.centerXAnchor constraintEqualToAnchor:self.introView.centerXAnchor],
        [self.titleLabel.topAnchor constraintEqualToAnchor:self.logoView.bottomAnchor constant:16],
        [self.versionLabel.centerXAnchor constraintEqualToAnchor:self.introView.centerXAnchor],
        [self.versionLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:4],
    ]];
    
    // Анимация
    self.introView.transform = CGAffineTransformMakeScale(0.5, 0.5);
    self.introView.alpha = 0;
    
    [UIView animateWithDuration:0.8 delay:0.2 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:0 animations:^{
        self.introView.transform = CGAffineTransformIdentity;
        self.introView.alpha = 1;
    } completion:^(BOOL finished) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.6 animations:^{
                self.introView.alpha = 0;
                self.introView.transform = CGAffineTransformMakeScale(1.2, 1.2);
            } completion:^(BOOL finished2) {
                self.introView.hidden = YES;
            }];
        });
    }];
}

- (void)loadLogo {
    NSURL *url = [NSURL URLWithString:LOGO_URL];
    NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (data && !error) {
            UIImage *image = [UIImage imageWithData:data];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.logoView.image = image;
                if (!self.logoView.image) {
                    self.logoView.backgroundColor = Lucky77Theme.purple;
                    self.logoView.layer.cornerRadius = 20;
                }
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.logoView.backgroundColor = Lucky77Theme.purple;
                self.logoView.layer.cornerRadius = 20;
            });
        }
    }];
    [task resume];
}

// ============ УПРАВЛЕНИЕ МЕНЮ ============
- (void)toggleMenu {
    if (self.menuCard.hidden) {
        self.menuCard.hidden = NO;
        self.menuCard.alpha = 0;
        self.launcherButton.hidden = YES;
        
        [UIView animateWithDuration:0.3 animations:^{
            self.menuCard.alpha = 1;
        }];
    } else {
        [UIView animateWithDuration:0.22 animations:^{
            self.menuCard.alpha = 0;
        } completion:^(BOOL finished) {
            self.menuCard.hidden = YES;
            self.menuCard.alpha = 1;
            self.launcherButton.hidden = NO;
        }];
    }
}

- (void)navTapped:(UIButton *)sender {
    for (UIView *v in self.navStack.arrangedSubviews) {
        if ([v isKindOfClass:[UIButton class]]) {
            UIButton *b = (UIButton *)v;
            b.backgroundColor = UIColor.clearColor;
        }
    }
    sender.backgroundColor = [Lucky77Theme.purpleDark colorWithAlphaComponent:0.9];
    
    [self switchToTab:sender.tag];
}

- (void)switchToTab:(NSInteger)tabIndex {
    for (UIView *view in self.contentStack.arrangedSubviews) {
        [self.contentStack removeArrangedSubview:view];
        [view removeFromSuperview];
    }
    
    UIView *newContent = [self makeContentForTab:tabIndex];
    [self.contentStack addArrangedSubview:newContent];
}

// ============ FPS ============
- (void)startFPS {
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(tick:)];
    self.displayLink.preferredFramesPerSecond = g_fpsLimit;
    [self.displayLink addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
}

- (void)tick:(CADisplayLink *)link {
    if (self.lastTimestamp == 0) {
        self.lastTimestamp = link.timestamp;
    }
    self.frameCount += 1;
    CFTimeInterval elapsed = link.timestamp - self.lastTimestamp;
    if (elapsed >= 0.5) {
        double fps = self.frameCount / elapsed;
        self.fpsLabel.text = [NSString stringWithFormat:@"%.0f %@", fps, L(@"fps")];
        self.frameCount = 0;
        self.lastTimestamp = link.timestamp;
    }
}

// ============ НАСТРОЙКИ ============
- (void)languageChanged:(UISegmentedControl *)sender {
    g_language = sender.selectedSegmentIndex;
    [self refreshSettingsTab];
}

- (void)fpsLimitChanged:(UISegmentedControl *)sender {
    NSArray *values = @[@30, @60, @90, @120];
    g_fpsLimit = [values[sender.selectedSegmentIndex] integerValue];
    self.displayLink.preferredFramesPerSecond = g_fpsLimit;
}

- (void)refreshSettingsTab {
    // Обновляем содержимое вкладки настроек
    [self switchToTab:2];
    // Обновляем заголовки кнопок в навигации
    NSArray *sections = @[L(@"aimbot"), L(@"visuals"), L(@"settings")];
    for (NSInteger i = 0; i < self.navButtons.count && i < sections.count; i++) {
        UIButton *btn = self.navButtons[i];
        [btn setTitle:[NSString stringWithFormat:@"   %@", sections[i]] forState:UIControlStateNormal];
    }
}

- (void)fovChanged:(UISlider *)slider {
    UIStackView *stack = (UIStackView *)slider.superview;
    for (UIView *view in stack.arrangedSubviews) {
        if ([view isKindOfClass:[UILabel class]]) {
            UILabel *label = (UILabel *)view;
            if ([label.text containsString:L(@"fov_slider")]) {
                label.text = [NSString stringWithFormat:@"%@: %.0f°", L(@"fov_slider"), slider.value];
                break;
            }
        }
    }
}

- (void)openTelegram {
    NSURL *url = [NSURL URLWithString:@"https://t.me/hack77ios"];
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    }
}

// ============ КОНФИГИ ============
- (void)saveConfig {
    NSDictionary *config = @{
        @"esp": @(g_espEnabled),
        @"aimbot": @(g_aimbotEnabled),
        @"radar": @(g_radarHack),
        @"recoil": @(g_noRecoil),
        @"ammo": @(g_unlimitedAmmo),
        @"trigger": @(g_triggerbot),
        @"fps": @(g_fpsLimit),
        @"lang": @(g_language)
    };
    [config writeToFile:[self configPath] atomically:YES];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"✅" message:g_language == 0 ? @"Config saved!" : @"Конфиг сохранён!" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)loadConfig {
    NSDictionary *config = [NSDictionary dictionaryWithContentsOfFile:[self configPath]];
    if (config) {
        g_espEnabled = [config[@"esp"] boolValue];
        g_aimbotEnabled = [config[@"aimbot"] boolValue];
        g_radarHack = [config[@"radar"] boolValue];
        g_noRecoil = [config[@"recoil"] boolValue];
        g_unlimitedAmmo = [config[@"ammo"] boolValue];
        g_triggerbot = [config[@"trigger"] boolValue];
        g_fpsLimit = [config[@"fps"] integerValue];
        g_language = [config[@"lang"] integerValue];
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"✅" message:g_language == 0 ? @"Config loaded!" : @"Конфиг загружен!" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (NSString *)configPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documents = paths.firstObject;
    return [documents stringByAppendingPathComponent:@"lucky77_config.plist"];
}

@end

// ============ ЭКСПОРТ ФУНКЦИЙ ============
UIViewController *Lucky77CreateMenuViewController(void) {
    L77MenuViewController *vc = [L77MenuViewController new];
    vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
    return vc;
}

void Lucky77PresentMenu(UIViewController *presenter) {
    if (!presenter) return;
    [presenter presentViewController:Lucky77CreateMenuViewController() animated:YES completion:nil];
}

// ============ ТОЧКА ВХОДА ============
__attribute__((constructor)) void init() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        UIWindow *window = nil;
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if ([scene isKindOfClass:[UIWindowScene class]] && scene.activationState == UISceneActivationStateForegroundActive) {
                    for (UIWindow *w in scene.windows) {
                        if (w.isKeyWindow) {
                            window = w;
                            break;
                        }
                    }
                    if (window) break;
                }
            }
        }
        if (!window) {
            window = [UIApplication sharedApplication].windows.firstObject;
        }
        UIViewController *root = window.rootViewController;
        if (root) {
            Lucky77PresentMenu(root);
        }
    });
}
