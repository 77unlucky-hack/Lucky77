#import "Lucky77Menu.h"
#import "Lucky77Theme.h"
#import "HooksManager.h"
#import "MemoryUtils.h"
#import <QuartzCore/QuartzCore.h>

// Глобальные флаги (определены в .h)
BOOL g_espEnabled = NO;
BOOL g_aimbotEnabled = NO;
BOOL g_radarHack = NO;
BOOL g_noRecoil = NO;
BOOL g_unlimitedAmmo = NO;
BOOL g_triggerbot = NO;

// ============ КАСТОМНЫЙ TOGGLE ============
@interface L77DemoToggle : UIControl
@property(nonatomic,strong) UIView *box;
@property(nonatomic,strong) UILabel *label;
@property(nonatomic,assign,getter=isOn) BOOL on;
@property(nonatomic,copy) NSString *key;
@end

@implementation L77DemoToggle
- (instancetype)initWithTitle:(NSString *)title key:(NSString *)key {
    if ((self = [super initWithFrame:CGRectZero])) {
        self.key = key;
        self.box = [UIView new];
        self.box.layer.cornerRadius = 4;
        self.box.layer.borderWidth = 1;
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
        self.box.transform = CGAffineTransformMakeScale(0.94, 0.94);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.12 animations:^{ self.box.transform = CGAffineTransformIdentity; }];
    }];
    
    // Привязка к глобальным флагам
    if ([self.key isEqualToString:@"esp"]) g_espEnabled = self.on;
    else if ([self.key isEqualToString:@"aimbot"]) g_aimbotEnabled = self.on;
    else if ([self.key isEqualToString:@"radar"]) g_radarHack = self.on;
    else if ([self.key isEqualToString:@"recoil"]) g_noRecoil = self.on;
    else if ([self.key isEqualToString:@"ammo"]) g_unlimitedAmmo = self.on;
    else if ([self.key isEqualToString:@"trigger"]) g_triggerbot = self.on;
    
    NSLog(@"[Lucky77] %@ = %@", self.key, self.on ? @"ON" : @"OFF");
}
@end

// ============ ГЛАВНОЕ МЕНЮ ============
@interface L77MenuViewController : UIViewController
@property(nonatomic,strong) UIView *menuCard;
@property(nonatomic,strong) UIView *intro;
@property(nonatomic,strong) UILabel *fpsLabel;
@property(nonatomic,strong) CADisplayLink *displayLink;
@property(nonatomic,assign) CFTimeInterval lastTimestamp;
@property(nonatomic,assign) NSInteger frameCount;
@property(nonatomic,strong) UIStackView *contentStack;
@property(nonatomic,strong) UILabel *statusLabel;
@end

@implementation L77MenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = Lucky77Theme.background;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [HooksManager installHooks];
    });

    [self buildLauncherButton];
    [self buildMenu];
    [self buildIntro];
    [self startFPS];
    [self updateStatus];
}

- (void)dealloc {
    [self.displayLink invalidate];
}

- (void)buildLauncherButton {
    UIButton *launcher = [UIButton buttonWithType:UIButtonTypeSystem];
    launcher.translatesAutoresizingMaskIntoConstraints = NO;
    launcher.backgroundColor = [Lucky77Theme.panel colorWithAlphaComponent:0.98];
    launcher.layer.cornerRadius = 14;
    launcher.layer.borderWidth = 1;
    launcher.layer.borderColor = Lucky77Theme.purple.CGColor;
    launcher.layer.shadowColor = Lucky77Theme.purpleGlow.CGColor;
    launcher.layer.shadowOpacity = 0.35;
    launcher.layer.shadowRadius = 12;
    [launcher setTitle:@"77" forState:UIControlStateNormal];
    [launcher setTitleColor:Lucky77Theme.purpleGlow forState:UIControlStateNormal];
    launcher.titleLabel.font = [UIFont italicSystemFontOfSize:22];
    [launcher addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:launcher];

    [NSLayoutConstraint activateConstraints:@[
        [launcher.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:12],
        [launcher.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:12],
        [launcher.widthAnchor constraintEqualToConstant:66],
        [launcher.heightAnchor constraintEqualToConstant:48],
    ]];
}

- (void)buildMenu {
    self.menuCard = [UIView new];
    self.menuCard.translatesAutoresizingMaskIntoConstraints = NO;
    self.menuCard.backgroundColor = Lucky77Theme.panel;
    self.menuCard.layer.cornerRadius = 18;
    self.menuCard.layer.borderWidth = 1;
    self.menuCard.layer.borderColor = Lucky77Theme.border.CGColor;
    self.menuCard.layer.shadowColor = UIColor.blackColor.CGColor;
    self.menuCard.layer.shadowOpacity = 0.55;
    self.menuCard.layer.shadowRadius = 24;
    [self.view addSubview:self.menuCard];

    [NSLayoutConstraint activateConstraints:@[
        [self.menuCard.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:90],
        [self.menuCard.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-20],
        [self.menuCard.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:18],
        [self.menuCard.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-18],
    ]];

    // Header
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
    logo.text = @"77";
    logo.font = [UIFont italicSystemFontOfSize:30];
    logo.textColor = Lucky77Theme.purpleGlow;
    logo.layer.shadowColor = Lucky77Theme.purpleGlow.CGColor;
    logo.layer.shadowOpacity = 0.8;
    logo.layer.shadowRadius = 10;

    UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
    close.translatesAutoresizingMaskIntoConstraints = NO;
    [close setTitle:@"×" forState:UIControlStateNormal];
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

    UIView *divider = [UIView new];
    divider.translatesAutoresizingMaskIntoConstraints = NO;
    divider.backgroundColor = Lucky77Theme.border;
    [self.menuCard addSubview:divider];

    // Sidebar
    UIView *sidebar = [UIView new];
    sidebar.translatesAutoresizingMaskIntoConstraints = NO;
    sidebar.backgroundColor = [Lucky77Theme.background colorWithAlphaComponent:0.72];
    sidebar.layer.cornerRadius = 14;
    [self.menuCard addSubview:sidebar];

    UIStackView *nav = [[UIStackView alloc] init];
    nav.translatesAutoresizingMaskIntoConstraints = NO;
    nav.axis = UILayoutConstraintAxisVertical;
    nav.spacing = 7;
    [sidebar addSubview:nav];

    NSArray *sections = @[@"AIM", @"VISUALS", @"MISC", @"STATUS"];
    NSArray *items = @[@"AIMBOT", @"ESP", @"RADAR", @"INFO"];
    for (NSInteger i=0; i<items.count; i++) {
        UILabel *sec = [UILabel new];
        sec.text = sections[i];
        sec.font = [Lucky77Theme bodyFont:11];
        sec.textColor = Lucky77Theme.purpleGlow;
        [nav addArrangedSubview:sec];

        UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
        b.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [b setTitle:[NSString stringWithFormat:@"   %@", items[i]] forState:UIControlStateNormal];
        [b setTitleColor:Lucky77Theme.textPrimary forState:UIControlStateNormal];
        b.titleLabel.font = [Lucky77Theme bodyFont:14];
        b.layer.cornerRadius = 8;
        b.backgroundColor = (i==0) ? [Lucky77Theme.purpleDark colorWithAlphaComponent:0.9] : UIColor.clearColor;
        [b.heightAnchor constraintEqualToConstant:40].active = YES;
        [b addTarget:self action:@selector(navTapped:) forControlEvents:UIControlEventTouchUpInside];
        [nav addArrangedSubview:b];
    }

    // Content
    UIScrollView *scroll = [UIScrollView new];
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    scroll.showsVerticalScrollIndicator = YES;
    [self.menuCard addSubview:scroll];

    self.contentStack = [[UIStackView alloc] init];
    self.contentStack.translatesAutoresizingMaskIntoConstraints = NO;
    self.contentStack.axis = UILayoutConstraintAxisVertical;
    self.contentStack.spacing = 16;
    [scroll addSubview:self.contentStack];

    UIView *content = [self makeContentPanel];
    [self.contentStack addArrangedSubview:content];

    [NSLayoutConstraint activateConstraints:@[
        [divider.leadingAnchor constraintEqualToAnchor:self.menuCard.leadingAnchor],
        [divider.trailingAnchor constraintEqualToAnchor:self.menuCard.trailingAnchor],
        [divider.topAnchor constraintEqualToAnchor:header.bottomAnchor],
        [divider.heightAnchor constraintEqualToConstant:1],

        [sidebar.leadingAnchor constraintEqualToAnchor:self.menuCard.leadingAnchor constant:12],
        [sidebar.topAnchor constraintEqualToAnchor:divider.bottomAnchor constant:12],
        [sidebar.bottomAnchor constraintEqualToAnchor:self.menuCard.bottomAnchor constant:-12],
        [sidebar.widthAnchor constraintEqualToConstant:190],

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

- (UIView *)makeContentPanel {
    UIView *panel = [UIView new];
    panel.backgroundColor = [Lucky77Theme.panelAlt colorWithAlphaComponent:0.72];
    panel.layer.cornerRadius = 14;
    panel.layer.borderWidth = 1;
    panel.layer.borderColor = Lucky77Theme.border.CGColor;

    UIStackView *row = [UIStackView new];
    row.translatesAutoresizingMaskIntoConstraints = NO;
    row.axis = UILayoutConstraintAxisHorizontal;
    row.spacing = 22;
    row.distribution = UIStackViewDistributionFillEqually;
    [panel addSubview:row];

    [row addArrangedSubview:[self makeColumn:@"AIMBOT"
                                      items:@[@"ENABLE AIMBOT", @"TRIGGERBOT", @"SMOOTH AIM", @"VISIBLE CHECK", @"FOV SLIDER"]
                                      keys:@[@"aimbot", @"trigger", @"smooth", @"visible", @"fov"]]];
    
    [row addArrangedSubview:[self makeColumn:@"VISUALS"
                                      items:@[@"ESP BOX", @"ESP NAME", @"ESP HEALTH", @"SNAP LINES", @"RADAR HACK"]
                                      keys:@[@"esp", @"name", @"health", @"lines", @"radar"]]];

    [NSLayoutConstraint activateConstraints:@[
        [panel.heightAnchor constraintGreaterThanOrEqualToConstant:440],
        [row.leadingAnchor constraintEqualToAnchor:panel.leadingAnchor constant:22],
        [row.trailingAnchor constraintEqualToAnchor:panel.trailingAnchor constant:-22],
        [row.topAnchor constraintEqualToAnchor:panel.topAnchor constant:22],
        [row.bottomAnchor constraintLessThanOrEqualToAnchor:panel.bottomAnchor constant:-22],
    ]];
    return panel;
}

- (UIView *)makeColumn:(NSString *)title items:(NSArray<NSString *> *)items keys:(NSArray<NSString *> *)keys {
    UIStackView *stack = [UIStackView new];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 8;

    UILabel *heading = [UILabel new];
    heading.text = title;
    heading.font = [Lucky77Theme titleFont:14];
    heading.textColor = Lucky77Theme.purpleGlow;
    [stack addArrangedSubview:heading];

    UIView *line = [UIView new];
    line.backgroundColor = Lucky77Theme.border;
    [line.heightAnchor constraintEqualToConstant:1].active = YES;
    [stack addArrangedSubview:line];

    for (NSInteger i=0; i<items.count && i<keys.count; i++) {
        L77DemoToggle *t = [[L77DemoToggle alloc] initWithTitle:items[i] key:keys[i]];
        [stack addArrangedSubview:t];
    }

    // Slider для FOV
    UILabel *sliderLabel = [UILabel new];
    sliderLabel.text = @"AIM FOV";
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
    [stack addArrangedSubview:slider];

    UIView *spacer = [UIView new];
    [spacer.heightAnchor constraintEqualToConstant:50].active = YES;
    [stack addArrangedSubview:spacer];

    return stack;
}

- (void)buildIntro {
    self.intro = [UIView new];
    self.intro.translatesAutoresizingMaskIntoConstraints = NO;
    self.intro.backgroundColor = [Lucky77Theme.background colorWithAlphaComponent:0.97];
    self.intro.layer.cornerRadius = 18;
    self.intro.alpha = 0;
    [self.menuCard addSubview:self.intro];

    UILabel *label = [UILabel new];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = @"Lucky77";
    label.font = [UIFont italicSystemFontOfSize:48];
    label.textColor = Lucky77Theme.purpleGlow;
    label.layer.shadowColor = Lucky77Theme.purpleGlow.CGColor;
    label.layer.shadowOpacity = 0.9;
    label.layer.shadowRadius = 18;
    [self.intro addSubview:label];
    
    self.statusLabel = [UILabel new];
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.statusLabel.text = @"Initializing...";
    self.statusLabel.font = [Lucky77Theme bodyFont:16];
    self.statusLabel.textColor = Lucky77Theme.textSecondary;
    [self.intro addSubview:self.statusLabel];

    [NSLayoutConstraint activateConstraints:@[
        [self.intro.leadingAnchor constraintEqualToAnchor:self.menuCard.
