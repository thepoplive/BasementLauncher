#import "BOSSettingsViewController.h"
#import "BOSTheme.h"

@implementation BOSSettingsViewController {
    UILabel *_layoutTitle;
    UISegmentedControl *_modeControl;

    UILabel *_wallpaperTitle;
    NSMutableArray *_wallpaperButtons;

    UILabel *_accentTitle;
    NSMutableArray *_accentButtons;
    NSArray *_accentHexes;

    UILabel *_themeLabel;
    UISwitch *_themeSwitch;

    UIView *_aboutCard;
    UILabel *_aboutLabel;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Settings";
    _accentHexes = @[@"#B69DF8", @"#F48FB1", @"#80CBC4", @"#90CAF9", @"#A5D6A7", @"#FFCC80"];
    _wallpaperButtons = [NSMutableArray array];
    _accentButtons = [NSMutableArray array];

    _layoutTitle = [[UILabel alloc] init];
    _layoutTitle.font = [UIFont systemFontOfSize:12];
    _layoutTitle.text = @"LAYOUT";
    [self.view addSubview:_layoutTitle];

    _modeControl = [[UISegmentedControl alloc] initWithItems:@[@"Portrait", @"CarPlay (landscape)"]];
    [_modeControl addTarget:self action:@selector(modeChanged:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:_modeControl];

    _wallpaperTitle = [[UILabel alloc] init];
    _wallpaperTitle.font = [UIFont systemFontOfSize:12];
    _wallpaperTitle.text = @"WALLPAPER";
    [self.view addSubview:_wallpaperTitle];

    for (NSUInteger i = 0; i < 4; i++) {
        UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
        b.tag = (NSInteger)i;
        b.layer.cornerRadius = 10.0;
        [b addTarget:self action:@selector(wallpaperTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:b];
        [_wallpaperButtons addObject:b];
    }

    _accentTitle = [[UILabel alloc] init];
    _accentTitle.font = [UIFont systemFontOfSize:12];
    _accentTitle.text = @"ACCENT COLOR";
    [self.view addSubview:_accentTitle];

    for (NSUInteger i = 0; i < _accentHexes.count; i++) {
        UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
        b.tag = (NSInteger)i;
        b.layer.cornerRadius = 18.0;
        [b addTarget:self action:@selector(accentTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:b];
        [_accentButtons addObject:b];
    }

    _themeLabel = [[UILabel alloc] init];
    _themeLabel.font = [UIFont systemFontOfSize:16];
    _themeLabel.text = @"Light theme";
    [self.view addSubview:_themeLabel];

    _themeSwitch = [[UISwitch alloc] init];
    [_themeSwitch addTarget:self action:@selector(themeChanged:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:_themeSwitch];

    _aboutCard = [[UIView alloc] init];
    _aboutCard.layer.cornerRadius = 16.0;
    [self.view addSubview:_aboutCard];

    _aboutLabel = [[UILabel alloc] init];
    _aboutLabel.font = [UIFont fontWithName:@"Menlo-Regular" size:12];
    _aboutLabel.numberOfLines = 0;
    UIDevice *device = [UIDevice currentDevice];
    _aboutLabel.text = [NSString stringWithFormat:@"BasementLauncher 0.2.0\nmodel: %@\niOS: %@\nname: %@", device.model, device.systemVersion, device.name];
    [_aboutCard addSubview:_aboutLabel];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applyTheme) name:BOSThemeDidChangeNotification object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self applyTheme];
}

- (void)applyTheme {
    BOSTheme *t = [BOSTheme shared];
    self.view.backgroundColor = [t backgroundColor];
    _layoutTitle.textColor = [t secondaryTextColor];
    _wallpaperTitle.textColor = [t secondaryTextColor];
    _accentTitle.textColor = [t secondaryTextColor];
    _themeLabel.textColor = [t textColor];
    _aboutCard.backgroundColor = [t cardColor];
    _aboutLabel.textColor = [t textColor];
    _modeControl.tintColor = [t accentColor];
    _themeSwitch.on = t.light;
    _modeControl.selectedSegmentIndex = t.isLandscapeMode ? 1 : 0;

    NSArray *palette = [t wallpaperPalette];
    NSUInteger selectedWall = [t wallpaperIndex];
    for (NSUInteger i = 0; i < _wallpaperButtons.count; i++) {
        UIButton *b = _wallpaperButtons[i];
        b.layer.borderWidth = (i == selectedWall) ? 2.0 : 0.0;
        b.layer.borderColor = [t accentColor].CGColor;
        NSArray *stops = palette[i];
        CAGradientLayer *grad = nil;
        for (CALayer *l in b.layer.sublayers) {
            if ([l isKindOfClass:[CAGradientLayer class]]) grad = (CAGradientLayer *)l;
        }
        if (!grad) {
            grad = [CAGradientLayer layer];
            [b.layer insertSublayer:grad atIndex:0];
        }
        NSMutableArray *cg = [NSMutableArray array];
        for (UIColor *c in stops) [cg addObject:(id)c.CGColor];
        grad.colors = cg;
        grad.frame = b.bounds;
        grad.cornerRadius = 10.0;
    }

    NSString *accent = [t accentHex];
    for (NSUInteger i = 0; i < _accentButtons.count; i++) {
        UIButton *b = _accentButtons[i];
        NSString *hex = _accentHexes[i];
        b.backgroundColor = [self colorFromHex:hex];
        BOOL sel = [hex.lowercaseString isEqualToString:accent.lowercaseString];
        b.layer.borderWidth = sel ? 3.0 : 1.0;
        b.layer.borderColor = (sel ? [UIColor whiteColor] : [UIColor colorWithWhite:1.0 alpha:0.25]).CGColor;
    }
}

- (UIColor *)colorFromHex:(NSString *)hex {
    NSString *clean = [hex stringByReplacingOccurrencesOfString:@"#" withString:@""];
    unsigned int rgb = 0;
    [[NSScanner scannerWithString:clean] scanHexInt:&rgb];
    return [UIColor colorWithRed:((rgb >> 16) & 0xFF) / 255.0
                           green:((rgb >> 8) & 0xFF) / 255.0
                            blue:(rgb & 0xFF) / 255.0
                           alpha:1.0];
}

#pragma mark - actions

- (void)modeChanged:(UISegmentedControl *)seg {
    [[BOSTheme shared] setLandscapeMode:(seg.selectedSegmentIndex == 1)];
    [self applyTheme];
}

- (void)wallpaperTapped:(UIButton *)b {
    [[BOSTheme shared] setWallpaperIndex:(NSUInteger)b.tag];
    [self applyTheme];
}

- (void)accentTapped:(UIButton *)b {
    [[BOSTheme shared] setAccentHex:_accentHexes[(NSUInteger)b.tag]];
    [self applyTheme];
}

- (void)themeChanged:(UISwitch *)sw {
    [[BOSTheme shared] setLightTheme:sw.on];
    [self applyTheme];
}

#pragma mark - layout

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat w = self.view.bounds.size.width;
    CGFloat y = 24.0;

    _layoutTitle.frame = CGRectMake(16.0, y, w - 32.0, 16.0);
    y += 22.0;
    _modeControl.frame = CGRectMake(16.0, y, w - 32.0, 32.0);
    y += 48.0;

    _wallpaperTitle.frame = CGRectMake(16.0, y, w - 32.0, 16.0);
    y += 22.0;
    for (NSUInteger i = 0; i < _wallpaperButtons.count; i++) {
        UIButton *b = _wallpaperButtons[i];
        b.frame = CGRectMake(16.0 + i * 84.0, y, 72.0, 44.0);
    }
    y += 68.0;

    _accentTitle.frame = CGRectMake(16.0, y, w - 32.0, 16.0);
    y += 22.0;
    for (NSUInteger i = 0; i < _accentButtons.count; i++) {
        UIButton *b = _accentButtons[i];
        b.frame = CGRectMake(16.0 + i * 52.0, y, 36.0, 36.0);
    }
    y += 60.0;

    _themeLabel.frame = CGRectMake(16.0, y, w - 100.0, 31.0);
    _themeSwitch.frame = CGRectMake(w - 71.0, y, 51.0, 31.0);
    y += 55.0;

    _aboutCard.frame = CGRectMake(16.0, y, w - 32.0, 110.0);
    _aboutLabel.frame = CGRectMake(16.0, 16.0, w - 64.0, 78.0);

    [self applyTheme];
}

@end
