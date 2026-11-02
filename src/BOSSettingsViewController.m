#import "BOSSettingsViewController.h"
#import "BOSTheme.h"

@implementation BOSSettingsViewController {
    UILabel *_themeLabel;
    UISwitch *_themeSwitch;
    UIView *_aboutCard;
    UILabel *_aboutLabel;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _themeLabel = [[UILabel alloc] init];
    _themeLabel.font = [UIFont systemFontOfSize:16];
    _themeLabel.text = @"Light theme";
    _themeSwitch = [[UISwitch alloc] init];
    [_themeSwitch addTarget:self action:@selector(themeChanged:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:_themeLabel];
    [self.view addSubview:_themeSwitch];

    _aboutCard = [[UIView alloc] init];
    _aboutCard.layer.cornerRadius = 16.0;
    [self.view addSubview:_aboutCard];

    _aboutLabel = [[UILabel alloc] init];
    _aboutLabel.font = [UIFont fontWithName:@"Menlo-Regular" size:12];
    _aboutLabel.numberOfLines = 0;
    UIDevice *device = [UIDevice currentDevice];
    _aboutLabel.text = [NSString stringWithFormat:@"BasementOS 0.1.0\nmodel: %@\niOS: %@\nname: %@", device.model, device.systemVersion, device.name];
    [_aboutCard addSubview:_aboutLabel];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self applyTheme];
    [_themeSwitch setOn:[[BOSTheme shared] light] animated:NO];
}

- (void)applyTheme {
    self.view.backgroundColor = [[BOSTheme shared] backgroundColor];
    _themeLabel.textColor = [[BOSTheme shared] textColor];
    _aboutCard.backgroundColor = [[BOSTheme shared] cardColor];
    _aboutLabel.textColor = [[BOSTheme shared] textColor];
}

- (void)themeChanged:(UISwitch *)sw {
    [[BOSTheme shared] setLightTheme:sw.on];
    [self applyTheme];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat w = self.view.bounds.size.width;
    _themeLabel.frame = CGRectMake(16.0, 24.0, w - 100.0, 24.0);
    _themeSwitch.frame = CGRectMake(w - 72.0, 18.0, 51.0, 31.0);
    _aboutCard.frame = CGRectMake(16.0, 72.0, w - 32.0, 120.0);
    _aboutLabel.frame = CGRectMake(16.0, 16.0, w - 64.0, 88.0);
}

@end
