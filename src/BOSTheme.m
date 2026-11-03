#import "BOSTheme.h"
#import "BOSDatabase.h"

NSString *const BOSThemeDidChangeNotification = @"BOSThemeDidChangeNotification";

static NSString *kFlagPath = @"/var/mobile/Library/BasementOS/light_theme";

static UIColor *BOSColorFromHex(NSString *hex) {
    if (hex.length == 0) hex = @"#B69DF8";
    NSString *clean = [hex stringByReplacingOccurrencesOfString:@"#" withString:@""];
    unsigned int rgb = 0;
    NSScanner *scanner = [NSScanner scannerWithString:clean];
    if (![scanner scanHexInt:&rgb]) rgb = 0xB69DF8;
    return [UIColor colorWithRed:((rgb >> 16) & 0xFF) / 255.0
                           green:((rgb >> 8) & 0xFF) / 255.0
                            blue:(rgb & 0xFF) / 255.0
                           alpha:1.0];
}

@implementation BOSTheme {
    BOOL _light;
    BOOL _landscapeMode;
    NSUInteger _wallpaper;
    NSString *_accentHex;
}

+ (instancetype)shared {
    static BOSTheme *s;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ s = [[BOSTheme alloc] init]; });
    return s;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _light = [[NSFileManager defaultManager] fileExistsAtPath:kFlagPath];
        BOSDatabase *db = [BOSDatabase sharedDatabase];
        NSString *mode = [db stateForKey:@"mode"];
        _landscapeMode = [mode isEqualToString:@"landscape"];
        NSString *wall = [db stateForKey:@"wallpaper"];
        _wallpaper = wall ? (NSUInteger)[wall integerValue] : 0;
        if (_wallpaper > 3) _wallpaper = 0;
        _accentHex = [db stateForKey:@"accent"];
        if (!_accentHex.length) _accentHex = @"#B69DF8";
    }
    return self;
}

- (BOOL)light {
    return _light;
}

- (BOOL)isLandscapeMode {
    return _landscapeMode;
}

- (void)notifyChange {
    [[NSNotificationCenter defaultCenter] postNotificationName:BOSThemeDidChangeNotification object:self];
}

- (void)setLightTheme:(BOOL)light {
    _light = light;
    if (light) [@"" writeToFile:kFlagPath atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    else [[NSFileManager defaultManager] removeItemAtPath:kFlagPath error:NULL];
    [self notifyChange];
}

- (void)setLandscapeMode:(BOOL)on {
    _landscapeMode = on;
    [[BOSDatabase sharedDatabase] setStateValue:(on ? @"landscape" : @"portrait") forKey:@"mode"];
    [self notifyChange];
    [UIViewController attemptRotationToDeviceOrientation];
}

- (UIInterfaceOrientationMask)supportedOrientationsMask {
    if (_landscapeMode) return UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight;
    return UIInterfaceOrientationMaskPortrait;
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
    return _light ? [UIColor colorWithWhite:1.0 alpha:0.94]
                  : [UIColor colorWithRed:0.13 green:0.11 blue:0.16 alpha:0.88];
}

- (UIColor *)accentColor {
    return BOSColorFromHex(_accentHex);
}

- (UIColor *)strokeColor {
    return [self.accentColor colorWithAlphaComponent:0.35];
}

- (NSArray *)wallpaperPalette {
    UIColor *(^c)(int, int, int) = ^UIColor *(int r, int g, int b) {
        return [UIColor colorWithRed:r / 255.0 green:g / 255.0 blue:b / 255.0 alpha:1.0];
    };
    return @[
        @[c(18, 10, 30), c(42, 22, 80), c(75, 46, 131)],
        @[c(4, 18, 31), c(10, 61, 98), c(27, 127, 158)],
        @[c(26, 5, 24), c(107, 31, 78), c(194, 80, 44)],
        @[c(10, 10, 12), c(34, 34, 42), c(58, 58, 68)],
    ];
}

- (NSUInteger)wallpaperIndex {
    return _wallpaper;
}

- (void)setWallpaperIndex:(NSUInteger)index {
    if (index > 3) index = 0;
    _wallpaper = index;
    [[BOSDatabase sharedDatabase] setStateValue:[NSString stringWithFormat:@"%lu", (unsigned long)index] forKey:@"wallpaper"];
    [self notifyChange];
}

- (NSString *)accentHex {
    return _accentHex;
}

- (void)setAccentHex:(NSString *)hex {
    if (!hex.length) return;
    _accentHex = [hex copy];
    [[BOSDatabase sharedDatabase] setStateValue:_accentHex forKey:@"accent"];
    [self notifyChange];
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
