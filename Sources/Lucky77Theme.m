#import "Lucky77Theme.h"

@implementation Lucky77Theme
+ (UIColor *)background { return [UIColor colorWithRed:0.025 green:0.025 blue:0.045 alpha:1.0]; }
+ (UIColor *)panel { return [UIColor colorWithRed:0.045 green:0.045 blue:0.075 alpha:0.98]; }
+ (UIColor *)panelAlt { return [UIColor colorWithRed:0.065 green:0.055 blue:0.10 alpha:0.98]; }
+ (UIColor *)border { return [UIColor colorWithWhite:0.38 alpha:0.35]; }
+ (UIColor *)textPrimary { return [UIColor colorWithWhite:0.97 alpha:1.0]; }
+ (UIColor *)textSecondary { return [UIColor colorWithWhite:0.72 alpha:1.0]; }
+ (UIColor *)purple { return [UIColor colorWithRed:0.62 green:0.20 blue:1.0 alpha:1.0]; }
+ (UIColor *)purpleDark { return [UIColor colorWithRed:0.20 green:0.03 blue:0.34 alpha:1.0]; }
+ (UIColor *)purpleGlow { return [UIColor colorWithRed:0.73 green:0.36 blue:1.0 alpha:1.0]; }
+ (UIFont *)titleFont:(CGFloat)size { return [UIFont systemFontOfSize:size weight:UIFontWeightSemibold]; }
+ (UIFont *)bodyFont:(CGFloat)size { return [UIFont systemFontOfSize:size weight:UIFontWeightMedium]; }
@end
