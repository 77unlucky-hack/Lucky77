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
    
    // ============ КЛЮЧЕВЫЕ НАСТРОЙКИ ДЛЯ ПРЕДОТВРАЩЕНИЯ ЗАВИСАНИЙ ============
    self.view.backgroundColor = [UIColor clearColor];
    self.view.opaque = NO;
    self.view.userInteractionEnabled = NO; // По умолчанию не блокируем игру
    self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    // Отключаем анимацию для ускорения
    self.view.alpha = 1;
    
    self.config = [NSMutableDictionary dictionary];
    [self loadConfig];
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [HooksManager installHooks];
    });
    
    // Максимально упрощаем инициализацию
    [self buildLauncherButton];
    [self buildMenu];
    [self startFPS];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.view.backgroundColor = [UIColor clearColor];
    // Не блокируем игру
    self.view.userInteractionEnabled = NO;
}

- (void)dealloc {
    [self.displayLink invalidate];
}

// ============ КНОПКА-ЛАУНЧЕР ============
- (void)buildLauncherButton {
    self.launcherButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.launcherButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.launcherButton.backgroundColor = [Lucky77Theme.panel colorWithAlphaComponent:0.85];
    self.launcherButton.layer.cornerRadius = 14;
    self.launcherButton.layer.borderWidth = 1;
    self.launcherButton.layer.borderColor = Lucky77Theme.purple.CGColor;
    self.launcherButton.layer.shadowColor = Lucky77Theme.purpleGlow.CGColor;
    self.launcherButton.layer.shadowOpacity = 0.3;
    self.launcherButton.layer.shadowRadius = 10;
    [self.launcherButton setTitle:@"⚡" forState:UIControlStateNormal];
    [self.launcherButton setTitleColor:Lucky77Theme.purpleGlow forState:UIControlStateNormal];
    self.launcherButton.titleLabel.font = [UIFont systemFontOfSize:24 weight:UIFontWeightBold];
    self.launcherButton.userInteractionEnabled = YES;
    [self.launcherButton addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragLauncher:)];
    [self.launcherButton addGestureRecognizer:pan];
    
    [self.view addSubview:self.launcherButton];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.launcherButton.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:10],
        [self.launcherButton.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:10],
        [self.launcherButton.widthAnchor constraintEqualToConstant:44],
        [self.launcherButton.heightAnchor constraintEqualToConstant:44],
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
    self.menuCard.backgroundColor = [Lucky77Theme.panel colorWithAlphaComponent:0.9];
    self.menuCard.layer.cornerRadius = 16;
    self.menuCard.layer.borderWidth = 1;
    self.menuCard.layer.borderColor = Lucky77Theme.border.CGColor;
    self.menuCard.layer.shadowColor = UIColor.blackColor.CGColor;
    self.menuCard.layer.shadowOpacity = 0.5;
    self.menuCard.layer.shadowRadius = 20;
    self.menuCard.hidden = YES;
    self.menuCard.userInteractionEnabled = YES;
    [self.view addSubview:self.menuCard];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.menuCard.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor constant:40],
        [self.menuCard.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [self.menuCard.widthAnchor constraintEqualToConstant:300],
        [self.menuCard.heightAnchor constraintEqualToConstant:350],
    ]];
    
    // HEADER
    UIView *header = [UIView new];
    header.translatesAutoresizingMaskIntoConstraints = NO;
    [self.menuCard addSubview:header];
    
    self.fpsLabel = [UILabel new];
    self.fpsLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.fpsLabel.text = @"-- FPS";
    self.fpsLabel.font = [Lucky77Theme bodyFont:12];
    self.fpsLabel.textColor = Lucky77Theme.purpleGlow;
    
    UILabel *logo = [UILabel new];
    logo.translatesAutoresizingMaskIntoConstraints = NO;
    logo.text = @"⚡";
    logo.font = [UIFont systemFontOfSize:22 weight:UIFontWeightBold];
    logo.textColor = Lucky77Theme.purpleGlow;
    
    UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
    close.translatesAutoresizingMaskIntoConstraints = NO;
    [close setTitle:@"✕" forState:UIControlStateNormal];
    [close setTitleColor:Lucky77Theme.purpleGlow forState:UIControlStateNormal];
    close.titleLabel.font = [Lucky77Theme titleFont:18];
    [close addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
    
    [header addSubview:self.fpsLabel];
    [header addSubview:logo];
    [header addSubview:close];
    
    [NSLayoutConstraint activateConstraints:@[
        [header.leadingAnchor constraintEqualToAnchor:self.menuCard.leadingAnchor],
        [header.trailingAnchor constraintEqualToAnchor:self.menuCard.trailingAnchor],
        [header.topAnchor constraintEqualToAnchor:self.menuCard.topAnchor],
        [header.heightAnchor constraintEqualToConstant:40],
        [self.fpsLabel.leadingAnchor constraintEqualToAnchor:header.leadingAnchor constant:12],
        [self.fpsLabel.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [logo.centerXAnchor constraintEqualToAnchor:header.centerXAnchor],
        [logo.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [close.trailingAnchor constraintEqualToAnchor:header.trailingAnchor constant:-10],
        [close.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [close.widthAnchor constraintEqualToConstant:30],
        [close.heightAnchor constraintEqualToConstant:30],
    ]];
    
    UIView *divider = [UIView new];
    divider.translatesAutoresizingMaskIntoConstraints = NO;
    divider.backgroundColor = Lucky77Theme.border;
    [self.menuCard addSubview:divider];
    
    // SIDEBAR - упрощённая
    self.sidebarScroll = [UIScrollView new];
    self.sidebarScroll.translatesAutoresizingMaskIntoConstraints = NO;
    self.sidebarScroll.backgroundColor = [Lucky77Theme.background colorWithAlphaComponent:0.5];
    self.sidebarScroll.layer.cornerRadius = 10;
    self.sidebarScroll.showsVerticalScrollIndicator = NO;
    [self.menuCard addSubview:self.sidebarScroll];
    
    self.navStack = [[UIStackView alloc] init];
    self.navStack.translatesAutoresizingMaskIntoConstraints = NO;
    self.navStack.axis = UILayoutConstraintAxisVertical;
    self.navStack.spacing = 4;
    self.navStack.distribution = UIStackViewDistributionFillEqually;
    [self.sidebarScroll addSubview:self.navStack];
    
    self.menuItems = @[@"aimbot", @"visuals", @"settings"];
    NSArray *sections = @[L(@"aimbot"), L(@"visuals"), L(@"settings")];
    NSMutableArray *buttons = [NSMutableArray array];
    
    for (NSInteger i = 0; i < self.menuItems.count; i++) {
        UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
        b.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        [b setTitle:sections[i] forState:UIControlStateNormal];
        [b setTitleColor:Lucky77Theme.textPrimary forState:UIControlStateNormal];
        b.titleLabel.font = [Lucky77Theme bodyFont:13];
        b.layer.cornerRadius = 6;
        b.backgroundColor = (i == 0) ? [Lucky77Theme.purpleDark colorWithAlphaComponent:0.8] : UIColor.clearColor;
        b.tag = i;
        [b addTarget:self action:@selector(navTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.navStack addArrangedSubview:b];
        [buttons addObject:b];
    }
    self.navButtons = buttons;
    
    // CONTENT - упрощённый
    UIScrollView *scroll = [UIScrollView new];
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    scroll.showsVerticalScrollIndicator = NO;
    [self.menuCard addSubview:scroll];
    
    self.contentStack = [[UIStackView alloc] init];
    self.contentStack.translatesAutoresizingMaskIntoConstraints = NO;
    self.contentStack.axis = UILayoutConstraintAxisVertical;
    self.contentStack.spacing = 8;
    [scroll addSubview:self.contentStack];
    
    UIView *defaultContent = [self makeContentForTab:0];
    [self.contentStack addArrangedSubview:defaultContent];
    
    [NSLayoutConstraint activateConstraints:@[
        [divider.leadingAnchor constraintEqualToAnchor:self.menuCard.leadingAnchor],
        [divider.trailingAnchor constraintEqualToAnchor:self.menuCard.trailingAnchor],
        [divider.topAnchor constraintEqualToAnchor:header.bottomAnchor],
        [divider.heightAnchor constraintEqualToConstant:1],
        
        [self.sidebarScroll.leadingAnchor constraintEqualToAnchor:self.menuCard.leadingAnchor constant:8],
        [self.sidebarScroll.topAnchor constraintEqualToAnchor:divider.bottomAnchor constant:8],
        [self.sidebarScroll.bottomAnchor constraintEqualToAnchor:self.menuCard.bottomAnchor constant:-8],
        [self.sidebarScroll.widthAnchor constraintEqualToConstant:70],
        
        [self.navStack.leadingAnchor constraintEqualToAnchor:self.sidebarScroll.leadingAnchor],
        [self.navStack.trailingAnchor constraintEqualToAnchor:self.sidebarScroll.trailingAnchor],
        [self.navStack.topAnchor constraintEqualToAnchor:self.sidebarScroll.topAnchor],
        [self.navStack.bottomAnchor constraintEqualToAnchor:self.sidebarScroll.bottomAnchor],
        
        [scroll.leadingAnchor constraintEqualToAnchor:self.sidebarScroll.trailingAnchor constant:8],
        [scroll.trailingAnchor constraintEqualToAnchor:self.menuCard.trailingAnchor constant:-8],
        [scroll.topAnchor constraintEqualToAnchor:divider.bottomAnchor constant:8],
        [scroll.bottomAnchor constraintEqualToAnchor:self.menuCard.bottomAnchor constant:-8],
        
        [self.contentStack.leadingAnchor constraintEqualToAnchor:scroll.leadingAnchor],
        [self.contentStack.trailingAnchor constraintEqualToAnchor:scroll.trailingAnchor],
        [self.contentStack.topAnchor constraintEqualToAnchor:scroll.topAnchor],
        [self.contentStack.bottomAnchor constraintEqualToAnchor:scroll.bottomAnchor],
        [self.contentStack.widthAnchor constraintEqualToAnchor:scroll.widthAnchor],
    ]];
}

// ============ КОНТЕНТ ВКЛАДОК (упрощённый) ============
- (UIView *)makeContentForTab:(NSInteger)tabIndex {
    switch (tabIndex) {
        case 0: return [self makeColumn:@[L(@"enable_aimbot"), L(@"triggerbot"), L(@"smooth_aim"), L(@"visible_check")]
                                 keys:@[@"aimbot", @"trigger", @"smooth", @"visible"]];
        case 1: return [self makeColumn:@[L(@"esp_box"), L(@"esp_name"), L(@"esp_health"), L(@"snap_lines"), L(@"radar_hack"), L(@"no_recoil"), L(@"unlimited_ammo")]
                                 keys:@[@"esp", @"name", @"health", @"lines", @"radar", @"recoil", @"ammo"]];
        case 2: return [self makeSettingsContent];
        default: return [self makeColumn:@[L(@"enable_aimbot")] keys:@[@"aimbot"]];
    }
}

- (UIView *)makeColumn:(NSArray *)items keys:(NSArray *)keys {
    UIView *container = [UIView new];
    container.backgroundColor = [Lucky77Theme.panelAlt colorWithAlphaComponent:0.5];
    container.layer.cornerRadius = 10;
    container.layer.borderWidth = 1;
    container.layer.borderColor = Lucky77Theme.border.CGColor;
    
    UIStackView *stack = [UIStackView new];
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 4;
    [container addSubview:stack];
    
    for (NSInteger i = 0; i < items.count && i < keys.count; i++) {
        L77DemoToggle *t = [[L77DemoToggle alloc] initWithTitle:items[i] key:keys[i]];
        [stack addArrangedSubview:t];
    }
    
    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:10],
        [stack.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-10],
        [stack.topAnchor constraintEqualToAnchor:container.topAnchor constant:8],
        [stack.bottomAnchor constraintEqualToAnchor:container.bottomAnchor constant:-8],
        [container.heightAnchor constraintGreaterThanOrEqualToConstant:120],
    ]];
    
    return container;
}

- (UIView *)makeSettingsContent {
    UIView *container = [UIView new];
    container.backgroundColor = [Lucky77Theme.panelAlt colorWithAlphaComponent:0.5];
    container.layer.cornerRadius = 10;
    container.layer.borderWidth = 1;
    container.layer.borderColor = Lucky77Theme.border.CGColor;
    
    UIStackView *stack = [UIStackView new];
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 6;
    [container addSubview:stack];
    
    // Язык
    UILabel *langLabel = [UILabel new];
    langLabel.text = L(@"language");
    langLabel.font = [Lucky77Theme bodyFont:12];
    langLabel.textColor = Lucky77Theme.textSecondary;
    [stack addArrangedSubview:langLabel];
    
    UISegmentedControl *langSeg = [[UISegmentedControl alloc] initWithItems:@[@"EN", @"RU"]];
    langSeg.selectedSegmentIndex = g_language;
    langSeg.tintColor = Lucky77Theme.purple;
    [langSeg addTarget:self action:@selector(languageChanged:) forControlEvents:UIControlEventValueChanged];
    [stack addArrangedSubview:langSeg];
    
    // FPS лимит
    UILabel *fpsLabel = [UILabel new];
    fpsLabel.text = L(@"fps_limit");
    fpsLabel.font = [Lucky77Theme bodyFont:12];
    fpsLabel.textColor = Lucky77Theme.textSecondary;
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
    UIStackView *configButtons = [UIStackView new];
    configButtons.axis = UILayoutConstraintAxisHorizontal;
    configButtons.spacing = 8;
    configButtons.distribution = UIStackViewDistributionFillEqually;
    
    UIButton *saveBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [saveBtn setTitle:L(@"save_config") forState:UIControlStateNormal];
    saveBtn.backgroundColor = Lucky77Theme.purple;
    saveBtn.layer.cornerRadius = 6;
    [saveBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    saveBtn.titleLabel.font = [Lucky77Theme bodyFont:11];
    [saveBtn addTarget:self action:@selector(saveConfig) forControlEvents:UIControlEventTouchUpInside];
    [configButtons addArrangedSubview:saveBtn];
    
    UIButton *loadBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [loadBtn setTitle:L(@"load_config") forState:UIControlStateNormal];
    loadBtn.backgroundColor = Lucky77Theme.purpleDark;
    loadBtn.layer.cornerRadius = 6;
    [loadBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    loadBtn.titleLabel.font = [Lucky77Theme bodyFont:11];
    [loadBtn addTarget:self action:@selector(loadConfig) forControlEvents:UIControlEventTouchUpInside];
    [configButtons addArrangedSubview:loadBtn];
    
    [stack addArrangedSubview:configButtons];
    
    // Разработчик
    UIButton *devBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [devBtn setTitle:@"👨‍💻 @hack77ios" forState:UIControlStateNormal];
    [devBtn setTitleColor:Lucky77Theme.purpleGlow forState:UIControlStateNormal];
    devBtn.titleLabel.font = [Lucky77Theme bodyFont:12];
    [devBtn addTarget:self action:@selector(openTelegram) forControlEvents:UIControlEventTouchUpInside];
    [stack addArrangedSubview:devBtn];
    
    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:10],
        [stack.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-10],
        [stack.topAnchor constraintEqualToAnchor:container.topAnchor constant:8],
        [stack.bottomAnchor constraintEqualToAnchor:container.bottomAnchor constant:-8],
        [container.heightAnchor constraintGreaterThanOrEqualToConstant:180],
    ]];
    
    return container;
}

// ============ УПРАВЛЕНИЕ МЕНЮ ============
- (void)toggleMenu {
    if (self.menuCard.hidden) {
        self.menuCard.hidden = NO;
        self.menuCard.alpha = 0;
        self.launcherButton.hidden = YES;
        // Когда меню открыто - блокируем игру (только для кликов по меню)
        self.view.userInteractionEnabled = YES;
        
        [UIView animateWithDuration:0.2 animations:^{
            self.menuCard.alpha = 1;
        }];
    } else {
        [UIView animateWithDuration:0.15 animations:^{
            self.menuCard.alpha = 0;
        } completion:^(BOOL finished) {
            self.menuCard.hidden = YES;
            self.menuCard.alpha = 1;
            self.launcherButton.hidden = NO;
            // Возвращаем игре управление
            self.view.userInteractionEnabled = NO;
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
    sender.backgroundColor = [Lucky77Theme.purpleDark colorWithAlphaComponent:0.8];
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
    [self switchToTab:2];
    NSArray *sections = @[L(@"aimbot"), L(@"visuals"), L(@"settings")];
    for (NSInteger i = 0; i < self.navButtons.count && i < sections.count; i++) {
        UIButton *btn = self.navButtons[i];
        [btn setTitle:sections[i] forState:UIControlStateNormal];
    }
}

- (void)openTelegram {
    NSURL *url = [NSURL URLWithString:@"https://t.me/hack77ios"];
    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
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
    vc.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    return vc;
}

void Lucky77PresentMenu(UIViewController *presenter) {
    if (!presenter) return;
    [presenter presentViewController:Lucky77CreateMenuViewController() animated:NO completion:nil];
}

// ============ ТОЧКА ВХОДА ============
__attribute__((constructor)) void init() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
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
            NSLog(@"[Lucky77] ✅ Menu injected!");
        } else {
            NSLog(@"[Lucky77] ❌ No root view controller");
        }
    });
}
