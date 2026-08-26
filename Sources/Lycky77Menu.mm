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
        self.label.font = [Lucky77Theme bodyFont:12];
        self.label.textColor = Lucky77Theme.textPrimary;
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
@property (nonatomic, strong) UIButton *launcherButton;
@property (nonatomic, assign) BOOL isDragging;
@property (nonatomic, assign) CGPoint dragOffset;
@property (nonatomic, strong) NSArray *menuItems;
@property (nonatomic, strong) NSMutableDictionary *config;
@property (nonatomic, strong) UIScrollView *sidebarScroll;
@property (nonatomic, strong) UIStackView *navStack;
@property (nonatomic, strong) NSArray *navButtons;
@property (nonatomic, strong) UIStackView *contentStack;
@end

@implementation L77MenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor clearColor];
    self.view.opaque = NO;
    self.modalPresentationStyle = UIModalPresentationOverFullScreen;
    
    self.config = [NSMutableDictionary dictionary];
    [self loadConfig];
    
    [self buildLauncherButton];
    [self buildMenu];
}

- (void)dealloc {
    // Ничего не делаем
}

// ============ КНОПКА-ЛАУНЧЕР ============
- (void)buildLauncherButton {
    self.launcherButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.launcherButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.launcherButton.backgroundColor = [Lucky77Theme.panel colorWithAlphaComponent:0.85];
    self.launcherButton.layer.cornerRadius = 14;
    self.launcherButton.layer.borderWidth = 1;
    self.launcherButton.layer.borderColor = Lucky77Theme.purple.CGColor;
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

// ============ МЕНЮ ============
- (void)buildMenu {
    self.menuCard = [UIView new];
    self.menuCard.translatesAutoresizingMaskIntoConstraints = NO;
    self.menuCard.backgroundColor = [Lucky77Theme.panel colorWithAlphaComponent:0.9];
    self.menuCard.layer.cornerRadius = 16;
    self.menuCard.layer.borderWidth = 1;
    self.menuCard.layer.borderColor = Lucky77Theme.border.CGColor;
    self.menuCard.hidden = YES;
    self.menuCard.userInteractionEnabled = YES;
    [self.view addSubview:self.menuCard];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.menuCard.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.menuCard.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [self.menuCard.widthAnchor constraintEqualToConstant:280],
        [self.menuCard.heightAnchor constraintEqualToConstant:320],
    ]];
    
    // HEADER
    UIView *header = [UIView new];
    header.translatesAutoresizingMaskIntoConstraints = NO;
    [self.menuCard addSubview:header];
    
    UILabel *logo = [UILabel new];
    logo.translatesAutoresizingMaskIntoConstraints = NO;
    logo.text = @"⚡";
    logo.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    logo.textColor = Lucky77Theme.purpleGlow;
    
    UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
    close.translatesAutoresizingMaskIntoConstraints = NO;
    [close setTitle:@"✕" forState:UIControlStateNormal];
    [close setTitleColor:Lucky77Theme.purpleGlow forState:UIControlStateNormal];
    close.titleLabel.font = [Lucky77Theme titleFont:16];
    [close addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
    
    [header addSubview:logo];
    [header addSubview:close];
    
    [NSLayoutConstraint activateConstraints:@[
        [header.leadingAnchor constraintEqualToAnchor:self.menuCard.leadingAnchor],
        [header.trailingAnchor constraintEqualToAnchor:self.menuCard.trailingAnchor],
        [header.topAnchor constraintEqualToAnchor:self.menuCard.topAnchor],
        [header.heightAnchor constraintEqualToConstant:36],
        [logo.centerXAnchor constraintEqualToAnchor:header.centerXAnchor],
        [logo.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [close.trailingAnchor constraintEqualToAnchor:header.trailingAnchor constant:-10],
        [close.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [close.widthAnchor constraintEqualToConstant:28],
        [close.heightAnchor constraintEqualToConstant:28],
    ]];
    
    UIView *divider = [UIView new];
    divider.translatesAutoresizingMaskIntoConstraints = NO;
    divider.backgroundColor = Lucky77Theme.border;
    [self.menuCard addSubview:divider];
    
    // SIDEBAR
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
        b.titleLabel.font = [Lucky77Theme bodyFont:12];
        b.layer.cornerRadius = 6;
        b.backgroundColor = (i == 0) ? [Lucky77Theme.purpleDark colorWithAlphaComponent:0.8] : UIColor.clearColor;
        b.tag = i;
        [b addTarget:self action:@selector(navTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.navStack addArrangedSubview:b];
        [buttons addObject:b];
    }
    self.navButtons = buttons;
    
    // CONTENT
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
    container.backgroundColor = [Lucky77Theme.panelAlt colorWithAlphaComponent:0.5];
    container.layer.cornerRadius = 8;
    container.layer.borderWidth = 1;
    container.layer.borderColor = Lucky77Theme.border.CGColor;
    
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
    container.backgroundColor = [Lucky77Theme.panelAlt colorWithAlphaComponent:0.5];
    container.layer.cornerRadius = 8;
    container.layer.borderWidth = 1;
    container.layer.borderColor = Lucky77Theme.border.CGColor;
    
    UIStackView *stack = [UIStackView new];
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 4;
    [container addSubview:stack];
    
    UILabel *langLabel = [UILabel new];
    langLabel.text = L(@"language");
    langLabel.font = [Lucky77Theme bodyFont:11];
    langLabel.textColor = Lucky77Theme.textSecondary;
    [stack addArrangedSubview:langLabel];
    
    UISegmentedControl *langSeg = [[UISegmentedControl alloc] initWithItems:@[@"EN", @"RU"]];
    langSeg.selectedSegmentIndex = g_language;
    langSeg.tintColor = Lucky77Theme.purple;
    [langSeg addTarget:self action:@selector(languageChanged:) forControlEvents:UIControlEventValueChanged];
    [stack addArrangedSubview:langSeg];
    
    UIStackView *configButtons = [UIStackView new];
    configButtons.axis = UILayoutConstraintAxisHorizontal;
    configButtons.spacing = 6;
    configButtons.distribution = UIStackViewDistributionFillEqually;
    
    UIButton *saveBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [saveBtn setTitle:L(@"save_config") forState:UIControlStateNormal];
    saveBtn.backgroundColor = Lucky77Theme.purple;
    saveBtn.layer.cornerRadius = 4;
    [saveBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    saveBtn.titleLabel.font = [Lucky77Theme bodyFont:10];
    [saveBtn addTarget:self action:@selector(saveConfig) forControlEvents:UIControlEventTouchUpInside];
    [configButtons addArrangedSubview:saveBtn];
    
    UIButton *loadBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [loadBtn setTitle:L(@"load_config") forState:UIControlStateNormal];
    loadBtn.backgroundColor = Lucky77Theme.purpleDark;
    loadBtn.layer.cornerRadius = 4;
    [loadBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    loadBtn.titleLabel.font = [Lucky77Theme bodyFont:10];
    [loadBtn addTarget:self action:@selector(loadConfig) forControlEvents:UIControlEventTouchUpInside];
    [configButtons addArrangedSubview:loadBtn];
    
    [stack addArrangedSubview:configButtons];
    
    UIButton *devBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [devBtn setTitle:@"👨‍💻 @hack77ios" forState:UIControlStateNormal];
    [devBtn setTitleColor:Lucky77Theme.purpleGlow forState:UIControlStateNormal];
    devBtn.titleLabel.font = [Lucky77Theme bodyFont:10];
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

// ============ УПРАВЛЕНИЕ ============
- (void)toggleMenu {
    if (self.menuCard.hidden) {
        self.menuCard.hidden = NO;
        self.menuCard.alpha = 0;
        self.launcherButton.hidden = YES;
        
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

// ============ НАСТРОЙКИ ============
- (void)languageChanged:(UISegmentedControl *)sender {
    g_language = sender.selectedSegmentIndex;
    [self refreshSettingsTab];
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

// ============ ЭКСПОРТ ============
UIViewController *Lucky77CreateMenuViewController(void) {
    L77MenuViewController *vc = [L77MenuViewController new];
    vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
    return vc;
}

void Lucky77PresentMenu(UIViewController *presenter) {
    if (!presenter) return;
    [presenter presentViewController:Lucky77CreateMenuViewController() animated:NO completion:nil];
}

// ============ ТОЧКА ВХОДА ============
__attribute__((constructor)) void init() {
    NSLog(@"[Lucky77] ✅ INIT CALLED!");
    
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
            window = [UIApplication sharedApplication].windows.firstObject;
        }
        UIViewController *root = window.rootViewController;
        if (root) {
            Lucky77PresentMenu(root);
            NSLog(@"[Lucky77] ✅ Menu presented!");
        } else {
            NSLog(@"[Lucky77] ❌ No root view controller");
        }
    });
}
