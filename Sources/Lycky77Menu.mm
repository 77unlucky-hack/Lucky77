#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>

// ============ ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ ============
BOOL g_espEnabled = NO;
BOOL g_aimbotEnabled = NO;
BOOL g_radarHack = NO;
BOOL g_noRecoil = NO;
BOOL g_unlimitedAmmo = NO;
BOOL g_triggerbot = NO;
NSInteger g_fpsLimit = 60;
NSInteger g_language = 0;

// ============ ЗВУКИ ============
static void PlayToggleSound(BOOL isOn) {
    @try {
        SystemSoundID soundID = isOn ? 1103 : 1104;
        AudioServicesPlaySystemSound(soundID);
    } @catch (NSException *exception) {}
}

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
        self.box.layer.borderColor = [UIColor colorWithWhite:0.38 alpha:0.35].CGColor;
        self.box.backgroundColor = UIColor.clearColor;
        self.box.translatesAutoresizingMaskIntoConstraints = NO;
        
        self.label = [UILabel new];
        self.label.text = title;
        self.label.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
        self.label.textColor = [UIColor colorWithWhite:0.97 alpha:1.0];
        self.label.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self addSubview:self.box];
        [self addSubview:self.label];
        
        [NSLayoutConstraint activateConstraints:@[
            [self.heightAnchor constraintEqualToConstant:30],
            [self.box.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [self.box.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
            [self.box.widthAnchor constraintEqualToConstant:18],
            [self.box.heightAnchor constraintEqualToConstant:18],
            [self.label.leadingAnchor constraintEqualToAnchor:self.box.trailingAnchor constant:10],
            [self.label.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [self.label.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        ]];
        
        [self addTarget:self action:@selector(tap) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

- (void)tap {
    self.on = !self.on;
    PlayToggleSound(self.on);
    
    [UIView animateWithDuration:0.18 animations:^{
        self.box.backgroundColor = self.on ? [UIColor colorWithRed:0.62 green:0.20 blue:1.0 alpha:1.0] : UIColor.clearColor;
        self.box.layer.borderColor = (self.on ? [UIColor colorWithRed:0.73 green:0.36 blue:1.0 alpha:1.0] : [UIColor colorWithWhite:0.38 alpha:0.35]).CGColor;
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
@property (nonatomic, strong) UILabel *bigLogo;
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
@property (nonatomic, assign) BOOL firstOpen;
@property (nonatomic, assign) BOOL logoLoaded;
@end

// ============ ВСЯ ЛОГИКА МЕНЮ ============
@implementation L77MenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor clearColor];
    self.view.opaque = NO;
    self.modalPresentationStyle = UIModalPresentationOverFullScreen;
    self.firstOpen = YES;
    self.logoLoaded = NO;
    
    self.config = [NSMutableDictionary dictionary];
    [self loadConfig];
    
    [self buildLauncherButton];
    [self buildMenu];
    [self buildIntroView];
    [self startFPS];
}

- (void)dealloc {
    if (self.displayLink) {
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
}

// ============ FPS ============
- (void)startFPS {
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(tick:)];
    self.displayLink.preferredFramesPerSecond = g_fpsLimit;
    [self.displayLink addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
}

- (void)tick:(CADisplayLink *)link {
    if (!self.fpsLabel) return;
    
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

// ============ КНОПКА-ЛАУНЧЕР ============
- (void)buildLauncherButton {
    self.launcherButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.launcherButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.launcherButton.backgroundColor = [[UIColor colorWithRed:0.045 green:0.045 blue:0.075 alpha:1.0] colorWithAlphaComponent:0.85];
    self.launcherButton.layer.cornerRadius = 14;
    self.launcherButton.layer.borderWidth = 1;
    self.launcherButton.layer.borderColor = [UIColor colorWithRed:0.62 green:0.20 blue:1.0 alpha:1.0].CGColor;
    [self.launcherButton setTitle:@"⚡" forState:UIControlStateNormal];
    [self.launcherButton setTitleColor:[UIColor colorWithRed:0.73 green:0.36 blue:1.0 alpha:1.0] forState:UIControlStateNormal];
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

// ============ МЕНЮ ============
- (void)buildMenu {
    self.menuCard = [UIView new];
    self.menuCard.translatesAutoresizingMaskIntoConstraints = NO;
    self.menuCard.backgroundColor = [[UIColor colorWithRed:0.045 green:0.045 blue:0.075 alpha:1.0] colorWithAlphaComponent:0.9];
    self.menuCard.layer.cornerRadius = 16;
    self.menuCard.layer.borderWidth = 1;
    self.menuCard.layer.borderColor = [UIColor colorWithWhite:0.38 alpha:0.35].CGColor;
    self.menuCard.hidden = YES;
    self.menuCard.userInteractionEnabled = YES;
    [self.view addSubview:self.menuCard];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.menuCard.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.menuCard.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [self.menuCard.widthAnchor constraintEqualToConstant:280],
        [self.menuCard.heightAnchor constraintEqualToConstant:350],
    ]];
    
    UIView *header = [UIView new];
    header.translatesAutoresizingMaskIntoConstraints = NO;
    [self.menuCard addSubview:header];
    
    self.fpsLabel = [UILabel new];
    self.fpsLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.fpsLabel.text = @"-- FPS";
    self.fpsLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
    self.fpsLabel.textColor = [UIColor colorWithRed:0.73 green:0.36 blue:1.0 alpha:1.0];
    
    UILabel *logo = [UILabel new];
    logo.translatesAutoresizingMaskIntoConstraints = NO;
    logo.text = @"⚡";
    logo.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    logo.textColor = [UIColor colorWithRed:0.73 green:0.36 blue:1.0 alpha:1.0];
    
    UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
    close.translatesAutoresizingMaskIntoConstraints = NO;
    [close setTitle:@"✕" forState:UIControlStateNormal];
    [close setTitleColor:[UIColor colorWithRed:0.73 green:0.36 blue:1.0 alpha:1.0] forState:UIControlStateNormal];
    close.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    [close addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
    
    [header addSubview:self.fpsLabel];
    [header addSubview:logo];
    [header addSubview:close];
    
    [NSLayoutConstraint activateConstraints:@[
        [header.leadingAnchor constraintEqualToAnchor:self.menuCard.leadingAnchor],
        [header.trailingAnchor constraintEqualToAnchor:self.menuCard.trailingAnchor],
        [header.topAnchor constraintEqualToAnchor:self.menuCard.topAnchor],
        [header.heightAnchor constraintEqualToConstant:36],
        [self.fpsLabel.leadingAnchor constraintEqualToAnchor:header.leadingAnchor constant:12],
        [self.fpsLabel.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [logo.centerXAnchor constraintEqualToAnchor:header.centerXAnchor],
        [logo.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [close.trailingAnchor constraintEqualToAnchor:header.trailingAnchor constant:-10],
        [close.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [close.widthAnchor constraintEqualToConstant:28],
        [close.heightAnchor constraintEqualToConstant:28],
    ]];
    
    UIView *divider = [UIView new];
    divider.translatesAutoresizingMaskIntoConstraints = NO;
    divider.backgroundColor = [UIColor colorWithWhite:0.38 alpha:0.35];
    [self.menuCard addSubview:divider];
    
    self.sidebarScroll = [UIScrollView new];
    self.sidebarScroll.translatesAutoresizingMaskIntoConstraints = NO;
    self.sidebarScroll.backgroundColor = [[UIColor colorWithRed:0.025 green:0.025 blue:0.045 alpha:1.0] colorWithAlphaComponent:0.5];
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
        [b setTitleColor:[UIColor colorWithWhite:0.97 alpha:1.0] forState:UIControlStateNormal];
        b.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
        b.layer.cornerRadius = 6;
        b.backgroundColor = (i == 0) ? [[UIColor colorWithRed:0.20 green:0.03 blue:0.34 alpha:1.0] colorWithAlphaComponent:0.8] : UIColor.clearColor;
        b.tag = i;
        [b addTarget:self action:@selector(navTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.navStack addArrangedSubview:b];
        [buttons addObject:b];
    }
    self.navButtons = buttons;
    
    UIScrollView *scroll = [UIScrollView new];
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    scroll.showsVerticalScrollIndicator = NO;
    [self.menuCard addSubview:scroll];
    
    self.contentStack = [[UIStackView alloc] init];
    self.contentStack.translatesAutoresizingMaskIntoConstraints = NO;
    self.contentStack.axis = UILayoutConstraintAxisVertical;
    self.contentStack.spacing = 6;
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
        [self.sidebarScroll.widthAnchor constraintEqualToConstant:60],
        
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

// ============ КОНТЕНТ ВКЛАДОК ============
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
    container.backgroundColor = [[UIColor colorWithRed:0.065 green:0.055 blue:0.10 alpha:1.0] colorWithAlphaComponent:0.5];
    container.layer.cornerRadius = 8;
    container.layer.borderWidth = 1;
    container.layer.borderColor = [UIColor colorWithWhite:0.38 alpha:0.35].CGColor;
    
    UIStackView *stack = [UIStackView new];
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 2;
    [container addSubview:stack];
    
    for (NSInteger i = 0; i < items.count && i < keys.count; i++) {
        L77DemoToggle *t = [[L77DemoToggle alloc] initWithTitle:items[i] key:keys[i]];
        [stack addArrangedSubview:t];
    }
    
    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:8],
        [stack.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-8],
        [stack.topAnchor constraintEqualToAnchor:container.topAnchor constant:6],
        [stack.bottomAnchor constraintEqualToAnchor:container.bottomAnchor constant:-6],
        [container.heightAnchor constraintGreaterThanOrEqualToConstant:100],
    ]];
    
    return container;
}

- (UIView *)makeSettingsContent {
    UIView *container = [UIView new];
    container.backgroundColor = [[UIColor colorWithRed:0.065 green:0.055 blue:0.10 alpha:1.0] colorWithAlphaComponent:0.5];
    container.layer.cornerRadius = 8;
    container.layer.borderWidth = 1;
    container.layer.borderColor = [UIColor colorWithWhite:0.38 alpha:0.35].CGColor;
    
    UIStackView *stack = [UIStackView new];
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 4;
    [container addSubview:stack];
    
    UILabel *langLabel = [UILabel new];
    langLabel.text = L(@"language");
    langLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
    langLabel.textColor = [UIColor colorWithWhite:0.72 alpha:1.0];
    [stack addArrangedSubview:langLabel];
    
    UISegmentedControl *langSeg = [[UISegmentedControl alloc] initWithItems:@[@"EN", @"RU"]];
    langSeg.selectedSegmentIndex = g_language;
    langSeg.tintColor = [UIColor colorWithRed:0.62 green:0.20 blue:1.0 alpha:1.0];
    [langSeg addTarget:self action:@selector(languageChanged:) forControlEvents:UIControlEventValueChanged];
    [stack addArrangedSubview:langSeg];
    
    UILabel *fpsLabel = [UILabel new];
    fpsLabel.text = L(@"fps_limit");
    fpsLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
    fpsLabel.textColor = [UIColor colorWithWhite:0.72 alpha:1.0];
    [stack addArrangedSubview:fpsLabel];
    
    UISegmentedControl *fpsSeg = [[UISegmentedControl alloc] initWithItems:@[@"30", @"60", @"90", @"120"]];
    NSInteger index = 0;
    if (g_fpsLimit == 30) index = 0;
    else if (g_fpsLimit == 60) index = 1;
    else if (g_fpsLimit == 90) index = 2;
    else if (g_fpsLimit == 120) index = 3;
    fpsSeg.selectedSegmentIndex = index;
    fpsSeg.tintColor = [UIColor colorWithRed:0.62 green:0.20 blue:1.0 alpha:1.0];
    [fpsSeg addTarget:self action:@selector(fpsLimitChanged:) forControlEvents:UIControlEventValueChanged];
    [stack addArrangedSubview:fpsSeg];
    
    UIStackView *configButtons = [UIStackView new];
    configButtons.axis = UILayoutConstraintAxisHorizontal;
    configButtons.spacing = 6;
    configButtons.distribution = UIStackViewDistributionFillEqually;
    
    UIButton *saveBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [saveBtn setTitle:L(@"save_config") forState:UIControlStateNormal];
    saveBtn.backgroundColor = [UIColor colorWithRed:0.62 green:0.20 blue:1.0 alpha:1.0];
    saveBtn.layer.cornerRadius = 4;
    [saveBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    saveBtn.titleLabel.font = [UIFont systemFontOfSize:10 weight:UIFontWeightMedium];
    [saveBtn addTarget:self action:@selector(saveConfig) forControlEvents:UIControlEventTouchUpInside];
    [configButtons addArrangedSubview:saveBtn];
    
    UIButton *loadBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [loadBtn setTitle:L(@"load_config") forState:UIControlStateNormal];
    loadBtn.backgroundColor = [UIColor colorWithRed:0.20 green:0.03 blue:0.34 alpha:1.0];
    loadBtn.layer.cornerRadius = 4;
    [loadBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    loadBtn.titleLabel.font = [UIFont systemFontOfSize:10 weight:UIFontWeightMedium];
    [loadBtn addTarget:self action:@selector(loadConfig) forControlEvents:UIControlEventTouchUpInside];
    [configButtons addArrangedSubview:loadBtn];
    
    [stack addArrangedSubview:configButtons];
    
    UIButton *devBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [devBtn setTitle:@"👨‍💻 @hack77ios" forState:UIControlStateNormal];
    [devBtn setTitleColor:[UIColor colorWithRed:0.73 green:0.36 blue:1.0 alpha:1.0] forState:UIControlStateNormal];
    devBtn.titleLabel.font = [UIFont systemFontOfSize:10 weight:UIFontWeightMedium];
    [devBtn addTarget:self action:@selector(openTelegram) forControlEvents:UIControlEventTouchUpInside];
    [stack addArrangedSubview:devBtn];
    
    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:8],
        [stack.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-8],
        [stack.topAnchor constraintEqualToAnchor:container.topAnchor constant:6],
        [stack.bottomAnchor constraintEqualToAnchor:container.bottomAnchor constant:-6],
        [container.heightAnchor constraintGreaterThanOrEqualToConstant:140],
    ]];
    
    return container;
}

// ============ ИНТРО ============
- (void)buildIntroView {
    self.introView = [UIView new];
    self.introView.translatesAutoresizingMaskIntoConstraints = NO;
    self.introView.backgroundColor = [[UIColor colorWithRed:0.025 green:0.025 blue:0.045 alpha:1.0] colorWithAlphaComponent:0.95];
    self.introView.layer.cornerRadius = 20;
    self.introView.userInteractionEnabled = NO;
    self.introView.hidden = YES;
    [self.view addSubview:self.introView];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.introView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.introView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [self.introView.widthAnchor constraintEqualToConstant:280],
        [self.introView.heightAnchor constraintEqualToConstant:260],
    ]];
    
    self.logoView = [UIImageView new];
    self.logoView.translatesAutoresizingMaskIntoConstraints = NO;
    self.logoView.contentMode = UIViewContentModeScaleAspectFit;
    self.logoView.layer.cornerRadius = 20;
    self.logoView.clipsToBounds = YES;
    self.logoView.backgroundColor = [UIColor clearColor];
    [self.introView addSubview:self.logoView];
    
    [self loadLogo];
    
    self.bigLogo = [UILabel new];
    self.bigLogo.translatesAutoresizingMaskIntoConstraints = NO;
    self.bigLogo.text = @"⚡";
    self.bigLogo.font = [UIFont systemFontOfSize:80 weight:UIFontWeightBold];
    self.bigLogo.textColor = [UIColor colorWithRed:0.73 green:0.36 blue:1.0 alpha:1.0];
    self.bigLogo.textAlignment = NSTextAlignmentCenter;
    self.bigLogo.layer.shadowColor = [UIColor colorWithRed:0.73 green:0.36 blue:1.0 alpha:1.0].CGColor;
    self.bigLogo.layer.shadowOpacity = 0.9;
    self.bigLogo.layer.shadowRadius = 30;
    self.bigLogo.hidden = YES;
    [self.introView addSubview:self.bigLogo];
    
    self.titleLabel = [UILabel new];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.text = @"Lucky77";
    self.titleLabel.font = [UIFont systemFontOfSize:36 weight:UIFontWeightBold];
    self.titleLabel.textColor = [UIColor colorWithRed:0.73 green:0.36 blue:1.0 alpha:1.0];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.layer.shadowColor = [UIColor colorWithRed:0.73 green:0.36 blue:1.0 alpha:1.0].CGColor;
    self.titleLabel.layer.shadowOpacity = 0.8;
    self.titleLabel.layer.shadowRadius = 20;
    [self.introView addSubview:self.titleLabel];
    
    self.versionLabel = [UILabel new];
    self.versionLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.versionLabel.text = @"v0.1";
    self.versionLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    self.versionLabel.textColor = [UIColor colorWithWhite:0.72 alpha:1.0];
    self.versionLabel.textAlignment = NSTextAlignmentCenter;
    [self.introView addSubview:self.versionLabel];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.logoView.centerXAnchor constraintEqualToAnchor:self.introView.centerXAnchor],
        [self.logoView.topAnchor constraintEqualToAnchor:self.introView.topAnchor constant:20],
        [self.logoView.widthAnchor constraintEqualToConstant:120],
        [self.logoView.heightAnchor constraintEqualToConstant:120],
        [self.bigLogo.centerXAnchor constraintEqualToAnchor:self.introView.centerXAnchor],
        [self.bigLogo.topAnchor constraintEqualToAnchor:self.introView.topAnchor constant:20],
        [self.bigLogo.widthAnchor constraintEqualToConstant:120],
        [self.bigLogo.heightAnchor constraintEqualToConstant:120],
        [self.titleLabel.centerXAnchor constraintEqualToAnchor:self.introView.centerXAnchor],
        [self.titleLabel.topAnchor constraintEqualToAnchor:self.logoView.bottomAnchor constant:16],
        [self.versionLabel.centerXAnchor constraintEqualToAnchor:self.introView.centerXAnchor],
        [self.versionLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:4],
    ]];
}

// ============ ЗАГРУЗКА ЛОГОТИПА ============
- (void)loadLogo {
    NSString *logoURL = @"https://raw.githubusercontent.com/77unlucky-hack/Stadnoff2IosHack77/main/logo.png";
    NSURL *url = [NSURL URLWithString:logoURL];
    NSLog(@"[Lucky77] Loading logo from: %@", logoURL);
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    config.timeoutIntervalForRequest = 10.0;
    config.timeoutIntervalForResource = 15.0;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    
    NSURLSessionDataTask *task = [session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            NSLog(@"[Lucky77] Logo download error: %@", error.localizedDescription);
            [self showFallbackLogo];
            return;
        }
        
        if (data && data.length > 0) {
            UIImage *image = [UIImage imageWithData:data];
            if (image) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.logoView.image = image;
                    self.logoView.backgroundColor = [UIColor clearColor];
                    self.logoLoaded = YES;
                    self.bigLogo.hidden = YES;
                    NSLog(@"[Lucky77] Logo loaded successfully!");
                });
            } else {
                [self showFallbackLogo];
            }
        } else {
            [self showFallbackLogo];
        }
    }];
    [task resume];
}

- (void)showFallbackLogo {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.logoView.hidden = YES;
        self.bigLogo.hidden = NO;
    });
}

// ============ ПОКАЗ ИНТРО ============
- (void)showIntroWithCompletion:(void (^)(void))completion {
    if (!self.firstOpen) {
        if (completion) completion();
        return;
    }
    
    self.firstOpen = NO;
    self.introView.hidden = NO;
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
                if (completion) completion();
            }];
        });
    }];
}

// ============ УПРАВЛЕНИЕ ============
- (void)toggleMenu {
    if (self.menuCard.hidden) {
        [self showIntroWithCompletion:^{
            self.menuCard.hidden = NO;
            self.menuCard.alpha = 0;
            self.launcherButton.hidden = YES;
            
            [UIView animateWithDuration:0.2 animations:^{
                self.menuCard.alpha = 1;
            }];
        }];
    } else {
        [UIView animateWithDuration:0.15 animations:^{
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
    sender.backgroundColor = [[UIColor colorWithRed:0.20 green:0.03 blue:0.34 alpha:1.0] colorWithAlphaComponent:0.8];
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

// ============ ТОЧКА ВХОДА (ЗАМЕНЯЕТ %ctor) ============
__attribute__((constructor)) void init() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
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
            #pragma clang diagnostic push
            #pragma clang diagnostic ignored "-Wdeprecated-declarations"
            window = [UIApplication sharedApplication].keyWindow;
            #pragma clang diagnostic pop
        }
        if (!window) {
            #pragma clang diagnostic push
            #pragma clang diagnostic ignored "-Wdeprecated-declarations"
            window = [UIApplication sharedApplication].windows.firstObject;
            #pragma clang diagnostic pop
        }
        UIViewController *root = window.rootViewController;
        if (root) {
            L77MenuViewController *menuVC = [L77MenuViewController new];
            menuVC.modalPresentationStyle = UIModalPresentationOverFullScreen;
            [root presentViewController:menuVC animated:NO completion:nil];
            NSLog(@"[Lucky77] ✅ Tweak injected!");
        } else {
            NSLog(@"[Lucky77] ❌ No root view controller");
        }
    });
}
