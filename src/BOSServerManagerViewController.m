#import "BOSServerManagerViewController.h"
#import "BOSTheme.h"
#import "BOSProcess.h"

@implementation BOSServerManagerViewController {
    NSMutableArray *_nameLabels;
    NSMutableArray *_statusLabels;
    NSMutableArray *_toggleButtons;
    UILabel *_hintLabel;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _nameLabels = [NSMutableArray array];
    _statusLabels = [NSMutableArray array];
    _toggleButtons = [NSMutableArray array];
    NSArray *names = @[@"HTTP (lighttpd :8080)", @"SSH/SFTP (dropbear :22)", @"Minecraft 1.12.2 (experimental)"];
    for (int i = 0; i < 3; i++) {
        UILabel *nameLabel = [[UILabel alloc] init];
        nameLabel.font = [UIFont boldSystemFontOfSize:15];
        nameLabel.text = names[i];
        [self.view addSubview:nameLabel];
        [_nameLabels addObject:nameLabel];

        UILabel *statusLabel = [[UILabel alloc] init];
        statusLabel.font = [UIFont fontWithName:@"Menlo-Regular" size:12];
        [self.view addSubview:statusLabel];
        [_statusLabels addObject:statusLabel];

        UIButton *button = [[BOSTheme shared] md3FilledButtonWithTitle:@"Start" target:self action:@selector(toggle:)];
        button.tag = i;
        [self.view addSubview:button];
        [_toggleButtons addObject:button];
    }
    _hintLabel = [[UILabel alloc] init];
    _hintLabel.font = [UIFont systemFontOfSize:12];
    _hintLabel.numberOfLines = 2;
    _hintLabel.text = @"minecraft: not implemented yet (TODO)";
    [self.view addSubview:_hintLabel];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self applyTheme];
    [self reloadStatus];
}

- (void)applyTheme {
    self.view.backgroundColor = [[BOSTheme shared] backgroundColor];
    for (int i = 0; i < 3; i++) {
        [_nameLabels[i] setTextColor:[[BOSTheme shared] textColor]];
        if ([[_statusLabels[i] text] hasPrefix:@"Running"]) {
            _statusLabels[i].textColor = [UIColor colorWithRed:0.4 green:0.8 blue:0.4 alpha:1.0];
        } else {
            _statusLabels[i].textColor = [[BOSTheme shared] secondaryTextColor];
        }
    }
    _hintLabel.textColor = [[BOSTheme shared] secondaryTextColor];
}

- (NSString *)scriptPath:(NSString *)name {
    return [[NSBundle mainBundle] pathForResource:name ofType:@"sh" inDirectory:@"services"];
}

- (NSString *)processNameFor:(int)index {
    return index == 0 ? @"lighttpd" : @"dropbear";
}

- (void)reloadStatus {
    for (int i = 0; i < 3; i++) {
        UILabel *statusLabel = _statusLabels[i];
        UIButton *button = _toggleButtons[i];
        if (i == 2) {
            statusLabel.text = @"TODO";
            [button setTitle:@"Start" forState:UIControlStateNormal];
            continue;
        }
        int pid = [BOSProcess pidOfProcessNamed:[self processNameFor:i]];
        if (pid > 0) {
            statusLabel.text = [NSString stringWithFormat:@"Running (pid %d)", pid];
            [button setTitle:@"Stop" forState:UIControlStateNormal];
        } else {
            statusLabel.text = @"Stopped";
            [button setTitle:@"Start" forState:UIControlStateNormal];
        }
    }
    [self applyTheme];
}

- (void)toggle:(UIButton *)button {
    int index = button.tag;
    if (index == 2) return;
    NSString *script = [self scriptPath:(index == 0 ? @"lighttpd" : @"dropbear")];
    if (!script) {
        _hintLabel.text = @"service script not found";
        return;
    }
    int pid = [BOSProcess pidOfProcessNamed:[self processNameFor:index]];
    [BOSProcess outputOfCommand:@"/bin/sh" arguments:@[script, pid > 0 ? @"stop" : @"start"]];
    [self reloadStatus];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat w = self.view.bounds.size.width;
    CGFloat h = self.view.bounds.size.height;
    CGFloat cardY = 16.0;
    for (int i = 0; i < 3; i++) {
        UILabel *nameLabel = _nameLabels[i];
        UILabel *statusLabel = _statusLabels[i];
        UIButton *button = _toggleButtons[i];
        nameLabel.frame = CGRectMake(16.0, cardY, w - 120.0, 22.0);
        statusLabel.frame = CGRectMake(16.0, cardY + 26.0, w - 120.0, 20.0);
        button.frame = CGRectMake(w - 96.0, cardY, 80.0, 40.0);
        cardY += 60.0;
    }
    _hintLabel.frame = CGRectMake(16.0, h - 40.0, w - 32.0, 30.0);
}

@end
