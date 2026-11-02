#import "BOSTheme.h"

static NSString *kFlagPath = @"/var/mobile/Library/BasementOS/light_theme";

@implementation BOSTheme {
    BOOL _light;
}

+ (instancetype)shared {
    static BOSTheme *s;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ s = [[BOSTheme alloc] init]; });
    return s;
}

- (instancetype)init {
    self = [super init];
    if (self) _light = [[NSFileManager defaultManager] fileExistsAtPath:kFlagPath];
    return self;
}

- (BOOL)light {
    return _light;
}

- (void)setLightTheme:(BOOL)light {
    _light = light;
    if (light) [@"" writeToFile:kFlagPath atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    else [[NSFileManager defaultManager] removeItemAtPath:kFlagPath error:NULL];
}

- (UIColor *)backgroundColor {
    return _light ? [UIColor colorWithWhite:0.96 alpha:1.0]
                  : [UIColor colorWithRed:0.075 green:0.06 blue:0.09 alpha:1.0];
}

- (UIColor *)textColor {
    return _light ? [UIColor colorWithWhite:0.1 alpha:1.0]
                  : [UIColor colorWithWhite:0.93 alpha:1.0];
}

- (UIColor *)secondaryTextColor {
    return _light ? [UIColor colorWithWhite:0.35 alpha:1.0]
                  : [UIColor colorWithWhite:0.62 alpha:1.0];
}

- (UIColor *)cardColor {
    return _light ? [UIColor whiteColor]
                  : [UIColor colorWithRed:0.13 green:0.11 blue:0.16 alpha:1.0];
}

- (UIColor *)accentColor {
    return [UIColor colorWithRed:0.714 green:0.616 blue:0.973 alpha:1.0];
}

- (UIColor *)strokeColor {
    return [self.accentColor colorWithAlphaComponent:0.35];
}


- (UIButton *)md3FilledButtonWithTitle:(NSString *)title target:(id)target action:(SEL)action {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    b.backgroundColor = [[BOSTheme shared] accentColor];
    [b setTitleColor:[[BOSTheme shared] backgroundColor] forState:UIControlStateNormal];
    b.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    [b setTitle:title forState:UIControlStateNormal];
    b.layer.cornerRadius = 20.0;
    b.contentEdgeInsets = UIEdgeInsetsMake(10.0, 20.0, 10.0, 20.0);
    if (target && action) [b addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    return b;
}

@end
