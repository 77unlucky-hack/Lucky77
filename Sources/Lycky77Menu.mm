#import "Lucky77Menu.h"
#import "Lucky77Theme.h"
#import "HooksManager.h"
#import "MemoryUtils.h"
#import <QuartzCore/QuartzCore.h>

// ============ ГЛОБАЛЬНЫЕ ФЛАГИ ============
BOOL g_espEnabled = NO;
BOOL g_aimbotEnabled = NO;
BOOL g_radarHack = NO;
BOOL g_noRecoil = NO;
BOOL g_unlimitedAmmo = NO;
BOOL g_triggerbot = NO;

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
    
    // Привязка к глобальным флагам
    if ([self.key isEqualToString:@"esp"]) {
        g_espEnabled = self.on;
    } else if ([self.key isEqualToString:@"aimbot"]) {
        g_aimbotEnabled = self.on;
    } else if ([self.key isEqualToString:@"radar"]) {
        g_radarHack = self.on;
    } else if ([self.key isEqualToString:@"recoil"]) {
        g_noRecoil = self.on;
    } else if ([self.key isEqualToString:@"ammo"]) {
        g_unlimitedAmmo = self.on;
    } else if ([self.key isEqualToString:@"trigger"]) {
        g_triggerbot = self.on;
    }
    
    NSLog(@"[Lucky77] %@ = %@", self.key, self.on ? @"ON" : @"OFF");
}

@end

// ============ ГЛАВНЫЙ КОНТРОЛЛЕР МЕНЮ ============
@interface L77MenuViewController : UIViewController
@property (nonatomic, strong) UIView *menuCard;
@property (nonatomic, strong) UIView *intro;
@property (nonatomic, strong) UILabel *fpsLabel;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) CFTimeInterval lastTimestamp;
@property (nonatomic, assign) NSInteger frameCount;
@property (nonatomic, strong) UIStackView *contentStack;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIButton *launcherButton;
@property (nonatomic, assign) BOOL isDragging;
@property (nonatomic, assign) CGPoint dragOffset;
@property (nonatomic, assign) BOOL menuVisible;
@property (nonatomic, strong) NSArray *menuItems;
@property (nonatomic, strong) NSArray *menuKeys;
@end

@implementation L77MenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    self.modalPresentationStyle = UIModalPresentationOverFullScreen;
    self.menuVisible = NO;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [HooksManager installHooks];
    });
    
    [self buildLauncherButton];
    [self buildMenu];
    [self buildIntro];
    [self startFPS];
    [self updateStatus];
    
    // Тройной тап для вызова меню
    UITapGestureRecognizer *tripleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleMenu)];
    tripleTap.numberOfTapsRequired = 3;
    [self.view addGestureRecognizer:tripleTap];
    
    // Двойной тап двумя пальцами как альтернатива
    UITapGestureRecognizer *twoFingerDoubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleMenu)];
    twoFingerDoubleTap.numberOfTapsRequired = 2;
    twoFingerDoubleTap.numberOfTouchesRequired = 2;
    [self.view addGestureRecognizer:twoFingerDoubleTap];
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
    
    UILabel *title = [UILabel new];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    title.text = @"Lucky77 v2.0";
    title.font = [Lucky77Theme titleFont:20];
    title.textColor = Lucky77Theme.textPrimary;
    
    self.fpsLabel = [UILabel new];
    self.fpsLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.fpsLabel.text = @"-- FPS";
    self.fpsLabel.font = [Lucky77Theme bodyFont:13];
    self.fpsLabel.textColor = Lucky77Theme.purpleGlow;
    
    UILabel *logo = [UILabel new];
    logo.translatesAutoresizingMaskIntoConstraints = NO;
    logo.text = @"⚡";
    logo.font = [UIFont systemFontOfSize:32 weight:UIFontWeightBold];
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
    
    [header addSubview:title];
    [header addSubview:self.fpsLabel];
    [header addSubview:logo];
    [header addSubview:close];
    
    [NSLayoutConstraint activateConstraints:@[
        [header.leadingAnchor constraintEqualToAnchor:self.menuCard.leadingAnchor],
        [header.trailingAnchor constraintEqualToAnchor:self.menuCard.trailingAnchor],
        [header.topAnchor constraintEqualToAnchor:self.menuCard.topAnchor],
        [header.heightAnchor constraintEqualToConstant:62],
        [title.leadingAnchor constraintEqualToAnchor:header.leadingAnchor constant:18],
        [title.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [self.fpsLabel.leadingAnchor constraintEqualToAnchor:title.trailingAnchor constant:14],
        [self.fpsLabel.centerYAnchor constraintEqualToAnchor:title.centerYAnchor],
        [logo.centerXAnchor constraintEqualToAnchor:header.centerXAnchor],
        [logo.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [close.trailingAnchor constraintEqualToAnchor:header.trailingAnchor constant:-14],
        [close.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [close.widthAnchor constraintEqualToConstant:36],
        [close.heightAnchor constraintEqualToConstant:36],
    ]];
    
    // DIVIDER
    UIView *divider = [UIView new];
    divider.translatesAutoresizingMaskIntoConstraints = NO;
    divider.backgroundColor = Lucky77Theme.border;
    [self.menuCard addSubview:divider];
    
    // SIDEBAR
    UIView *sidebar = [UIView new];
    sidebar.translatesAutoresizingMaskIntoConstraints = NO;
    sidebar.backgroundColor = [Lucky77Theme.background colorWithAlphaComponent:0.7];
    sidebar.layer.cornerRadius = 14;
    [self.menuCard addSubview:sidebar];
    
    UIStackView *nav = [[UIStackView alloc] init];
    nav.translatesAutoresizingMaskIntoConstraints = NO;
    nav.axis = UILayoutConstraintAxisVertical;
    nav.spacing = 7;
    [sidebar addSubview:nav];
    
    self.menuItems = @[@"AIMBOT", @"ESP", @"RADAR", @"INFO"];
    NSArray *sections = @[@"AIM", @"VISUALS", @"MISC", @"STATUS"];
    
    for (NSInteger i = 0; i < self.menuItems.count; i++) {
        UILabel *sec = [UILabel new];
        sec.text = sections[i];
        sec.font = [Lucky77Theme bodyFont:11];
        sec.textColor = Lucky77Theme.purpleGlow;
        [nav addArrangedSubview:sec];
        
        UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
        b.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [b setTitle:[NSString stringWithFormat:@"   %@", self.menuItems[i]] forState:UIControlStateNormal];
        [b setTitleColor:Lucky77Theme.textPrimary forState:UIControlStateNormal];
        b.titleLabel.font = [Lucky77Theme bodyFont:14];
        b.layer.cornerRadius = 8;
        b.backgroundColor = (i == 0) ? [Lucky77Theme.purpleDark colorWithAlphaComponent:0.9] : UIColor.clearColor;
        [b.heightAnchor constraintEqualToConstant:40].active = YES;
        b.tag = i;
        [b addTarget:self action:@selector(navTapped:) forControlEvents:UIControlEventTouchUpInside];
        [nav addArrangedSubview:b];
    }
    
    // CONTENT SCROLL
    UIScrollView *scroll = [UIScrollView new];
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    scroll.showsVerticalScrollIndicator = YES;
    [self.menuCard addSubview:scroll];
    
    self.contentStack = [[UIStackView alloc] init];
    self.contentStack.translatesAutoresizingMaskIntoConstraints = NO;
    self.contentStack.axis = UILayoutConstraintAxisVertical;
    self.contentStack.spacing = 16;
    [scroll addSubview:self.contentStack];
    
    // Дефолтный контент - AIMBOT
    UIView *defaultContent = [self makeContentForTab:0];
    [self.contentStack addArrangedSubview:defaultContent];
    
    [NSLayoutConstraint activateConstraints:@[
        [divider.leadingAnchor constraintEqualToAnchor:self.menuCard.leadingAnchor],
        [divider.trailingAnchor constraintEqualToAnchor:self.menuCard.trailingAnchor],
        [divider.topAnchor constraintEqualToAnchor:header.bottomAnchor],
        [divider.heightAnchor constraintEqualToConstant:1],
        
        [sidebar.leadingAnchor constraintEqualToAnchor:self.menuCard.leadingAnchor constant:12],
        [sidebar.topAnchor constraintEqualToAnchor:divider.bottomAnchor constant:12],
        [sidebar.bottomAnchor constraintEqualToAnchor:self.menuCard.bottomAnchor constant:-12],
        [sidebar.widthAnchor constraintEqualToConstant:160],
        
        [nav.leadingAnchor constraintEqualToAnchor:sidebar.leadingAnchor constant:14],
        [nav.trailingAnchor constraintEqualToAnchor:sidebar.trailingAnchor constant:-14],
        [nav.topAnchor constraintEqualToAnchor:sidebar.topAnchor constant:18],
        
        [scroll.leadingAnchor constraintEqualToAnchor:sidebar.trailingAnchor constant:14],
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

// ============ КОНТЕНТ ДЛЯ ВКЛАДОК ============
- (UIView *)makeContentForTab:(NSInteger)tabIndex {
    switch (tabIndex) {
        case 0:
            return [self makeAimbotContent];
        case 1:
            return [self makeESPContent];
        case 2:
            return [self makeRadarContent];
        case 3:
            return [self makeInfoContent];
        default:
            return [self makeAimbotContent];
    }
}

- (UIView *)makeAimbotContent {
    return [self makeColumn:@"AIMBOT"
                     items:@[@"ENABLE AIMBOT", @"TRIGGERBOT", @"SMOOTH AIM", @"VISIBLE CHECK", @"FOV SLIDER"]
                     keys:@[@"aimbot", @"trigger", @"smooth", @"visible", @"fov"]];
}

- (UIView *)makeESPContent {
    return [self makeColumn:@"ESP SETTINGS"
                     items:@[@"ESP BOX", @"ESP NAME", @"ESP HEALTH", @"SNAP LINES", @"RADAR HACK"]
                     keys:@[@"esp", @"name", @"health", @"lines", @"radar"]];
}

- (UIView *)makeRadarContent {
    return [self makeColumn:@"RADAR & MISC"
                     items:@[@"SHOW RADAR", @"ENEMY SPOTS", @"BOMB TIMER", @"NO RECOIL", @"UNLIMITED AMMO"]
                     keys:@[@"radar", @"spots", @"bomb", @"recoil", @"ammo"]];
}

- (UIView *)makeInfoContent {
    UIView *info = [UIView new];
    info.backgroundColor = [Lucky77Theme.panelAlt colorWithAlphaComponent:0.7];
    info.layer.cornerRadius = 14;
    info.layer.borderWidth = 1;
    info.layer.borderColor = Lucky77Theme.border.CGColor;
    
    UILabel *title = [UILabel new];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    title.text = @"⚡ Lucky77 v2.0\nStandoff 2 iOS\n0.39.2";
    title.numberOfLines = 0;
    title.textAlignment = NSTextAlignmentCenter;
    title.font = [Lucky77Theme titleFont:18];
    title.textColor = Lucky77Theme.textPrimary;
    [info addSubview:title];
    
    UILabel *status = [UILabel new];
    status.translatesAutoresizingMaskIntoConstraints = NO;
    uintptr_t base = [MemoryUtils getGameBase];
    status.text = base ? [NSString stringWithFormat:@"Base: 0x%lX", (unsigned long)base] : @"Game not found";
    status.textAlignment = NSTextAlignmentCenter;
    status.font = [Lucky77Theme bodyFont:13];
    status.textColor = Lucky77Theme.textSecondary;
    [info addSubview:status];
    
    UILabel *hint = [UILabel new];
    hint.translatesAutoresizingMaskIntoConstraints = NO;
    hint.text = @"Triple tap to toggle menu";
    hint.textAlignment = NSTextAlignmentCenter;
    hint.font = [Lucky77Theme bodyFont:12];
    hint.textColor = Lucky77Theme.textSecondary;
    [info addSubview:hint];
    
    [NSLayoutConstraint activateConstraints:@[
        [title.centerXAnchor constraintEqualToAnchor:info.centerXAnchor],
        [title.centerYAnchor constraintEqualToAnchor:info.centerYAnchor constant:-30],
        [status.centerXAnchor constraintEqualToAnchor:info.centerXAnchor],
        [status.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:12],
        [hint.centerXAnchor constraintEqualToAnchor:info.centerXAnchor],
        [hint.topAnchor constraintEqualToAnchor:status.bottomAnchor constant:8],
        [info.heightAnchor constraintGreaterThanOrEqualToConstant:220],
    ]];
    
    return info;
}

// ============ ОБЩИЙ КОМПОНЕНТ КОЛОНКИ ============
- (UIView *)makeColumn:(NSString *)title items:(NSArray<NSString *> *)items keys:(NSArray<NSString *> *)keys {
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
    
    // SLIDER для FOV (только в AIMBOT)
    if ([title isEqualToString:@"AIMBOT"]) {
        UILabel *sliderLabel = [UILabel new];
        sliderLabel.text = @"AIM FOV: 90°";
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
    
    UIView *spacer = [UIView new];
    [spacer.heightAnchor constraintEqualToConstant:20].active = YES;
    [stack addArrangedSubview:spacer];
    
    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:18],
        [stack.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-18],
        [stack.topAnchor constraintEqualToAnchor:container.topAnchor constant:18],
        [stack.bottomAnchor constraintLessThanOrEqualToAnchor:container.bottomAnchor constant:-18],
        [container.heightAnchor constraintGreaterThanOrEqualToConstant:300],
    ]];
    
    return container;
}

// ============ ОБРАБОТЧИК FOV ============
- (void)fovChanged:(UISlider *)slider {
    // Находим лейбл с FOV в родительском стеке
    UIStackView *stack = (UIStackView *)slider.superview;
    for (UIView *view in stack.arrangedSubviews) {
        if ([view isKindOfClass:[UILabel class]]) {
            UILabel *label = (UILabel *)view;
            if ([label.text hasPrefix:@"AIM FOV:"]) {
                label.text = [NSString stringWithFormat:@"AIM FOV: %.0f°", slider.value];
                break;
            }
        }
    }
    // TODO: сохранять значение FOV в глобальную переменную
}

// ============ ПЕРЕКЛЮЧЕНИЕ ВКЛАДОК ============
- (void)navTapped:(UIButton *)sender {
    // Сбрасываем фон у всех кнопок
    UIStackView *navStack = (UIStackView *)sender.superview;
    for (UIView *v in navStack.arrangedSubviews) {
        if ([v isKindOfClass:[UIButton class]]) {
            UIButton *b = (UIButton *)v;
            b.backgroundColor = UIColor.clearColor;
        }
    }
    // Подсвечиваем нажатую
    sender.backgroundColor = [Lucky77Theme.purpleDark colorWithAlphaComponent:0.9];
    
    // Меняем контент
    NSInteger tabIndex = sender.tag;
    [self switchToTab:tabIndex];
}

- (void)switchToTab:(NSInteger)tabIndex {
    // Очищаем текущий контент
    for (UIView *view in self.contentStack.arrangedSubviews) {
        [self.contentStack removeArrangedSubview:view];
        [view removeFromSuperview];
    }
    
    // Добавляем новый контент
    UIView *newContent = [self makeContentForTab:tabIndex];
    [self.contentStack addArrangedSubview:newContent];
}

// ============ INTRO АНИМАЦИЯ ============
- (void)buildIntro {
    self.intro = [UIView new];
    self.intro.translatesAutoresizingMaskIntoConstraints = NO;
    self.intro.backgroundColor = [Lucky77Theme.background colorWithAlphaComponent:0.95];
    self.intro.layer.cornerRadius = 20;
    self.intro.alpha = 0;
    [self.menuCard addSubview:self.intro];
    
    UILabel *label = [UILabel new];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = @"⚡";
    label.font = [UIFont systemFontOfSize:64 weight:UIFontWeightBold];
    label.textColor = Lucky77Theme.purpleGlow;
    label.layer.shadowColor = Lucky77Theme.purpleGlow.CGColor;
    label.layer.shadowOpacity = 0.9;
    label.layer.shadowRadius = 20;
    [self.intro addSubview:label];
    
    UILabel *title = [UILabel new];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    title.text = @"Lucky77";
    title.font = [Lucky77Theme titleFont:28];
    title.textColor = Lucky77Theme.textPrimary;
    [self.intro addSubview:title];
    
    self.statusLabel = [UILabel new];
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.statusLabel.text = @"Initializing...";
    self.statusLabel.font = [Lucky77Theme bodyFont:16];
    self.statusLabel.textColor = Lucky77Theme.textSecondary;
    [self.intro addSubview:self.statusLabel];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.intro.leadingAnchor constraintEqualToAnchor:self.menuCard.leadingAnchor],
        [self.intro.trailingAnchor constraintEqualToAnchor:self.menuCard.trailingAnchor],
        [self.intro.topAnchor constraintEqualToAnchor:self.menuCard.topAnchor],
        [self.intro.bottomAnchor constraintEqualToAnchor:self.menuCard.bottomAnchor],
        [label.centerXAnchor constraintEqualToAnchor:self.intro.centerXAnchor],
        [label.centerYAnchor constraintEqualToAnchor:self.intro.centerYAnchor constant:-30],
        [title.centerXAnchor constraintEqualToAnchor:self.intro.centerXAnchor],
        [title.topAnchor constraintEqualToAnchor:label.bottomAnchor constant:8],
        [self.statusLabel.centerXAnchor constraintEqualToAnchor:self.intro.centerXAnchor],
        [self.statusLabel.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:12],
    ]];
}

- (void)updateStatus {
    uintptr_t base = [MemoryUtils getGameBase];
    BOOL hooked = [HooksManager isHooked];
    self.statusLabel.text = base ?
    [NSString stringWithFormat:@"Base: 0x%lX | Hooks: %@", (unsigned long)base, hooked ? @"✅" : @"❌"] :
    @"Game not found";
}

// ============ УПРАВЛЕНИЕ МЕНЮ ============
- (void)toggleMenu {
    if (self.menuCard.hidden) {
        // Показываем меню
        self.menuCard.hidden = NO;
        self.menuCard.alpha = 0;
        self.intro.alpha = 0;
        self.intro.hidden = NO;
        [self updateStatus];
        
        [UIView animateWithDuration:0.3 animations:^{
            self.menuCard.alpha = 1;
        }];
        
        [UIView animateWithDuration:0.55 animations:^{
            self.intro.alpha = 1;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.55 delay:1.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                self.intro.alpha = 0;
            } completion:^(BOOL finished2) {
                self.intro.hidden = YES;
            }];
        }];
    } else {
        // Скрываем меню
        [UIView animateWithDuration:0.22 animations:^{
            self.menuCard.alpha = 0;
        } completion:^(BOOL finished) {
            self.menuCard.hidden = YES;
            self.menuCard.alpha = 1;
        }];
    }
}

// ============ FPS СЧЁТЧИК ============
- (void)startFPS {
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(tick:)];
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
        self.fpsLabel.text = [NSString stringWithFormat:@"%.0f FPS", fps];
        self.frameCount = 0;
        self.lastTimestamp = link.timestamp;
    }
}

@end

// ============ ЭКСПОРТИРУЕМЫЕ ФУНКЦИИ ============
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
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        UIWindow *window = [UIApplication sharedApplication].windows.firstObject;
        if (!window) {
            if (@available(iOS 13.0, *)) {
                NSSet *scenes = [UIApplication sharedApplication].connectedScenes;
                for (UIScene *scene in scenes) {
                    if ([scene isKindOfClass:[UIWindowScene class]]) {
                        UIWindowScene *windowScene = (UIWindowScene *)scene;
                        if (windowScene.activationState == UISceneActivationStateForegroundActive) {
                            for (UIWindow *w in windowScene.windows) {
                                if (w.isKeyWindow) {
                                    window = w;
                                    break;
                                }
                            }
                            if (window) break;
                        }
                    }
                }
            } else {
                #pragma clang diagnostic push
                #pragma clang diagnostic ignored "-Wdeprecated-declarations"
                window = [UIApplication sharedApplication].keyWindow;
                #pragma clang diagnostic pop
            }
        }
        
        UIViewController *root = window.rootViewController;
        if (root) {
            Lucky77PresentMenu(root);
            NSLog(@"[Lucky77] ✅ Menu injected successfully!");
        } else {
            NSLog(@"[Lucky77] ❌ No root view controller found");
        }
    });
}
