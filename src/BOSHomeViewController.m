#import "BOSHomeViewController.h"
#import "BOSTheme.h"
#import "BOSDatabase.h"
#import "BOSClockViewController.h"
#import "BOSCalendarViewController.h"
#import "BOSNotesViewController.h"
#import "BOSFilesViewController.h"
#import "BOSServerManagerViewController.h"
#import "BOSTerminalViewController.h"
#import "BOSSettingsViewController.h"
#import <MediaPlayer/MediaPlayer.h>

@interface BOSHomeViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@end

@implementation BOSHomeViewController {
    CAGradientLayer *_gradient;

    NSArray *_appTitles;
    NSArray *_appClasses;
    NSArray *_monograms;

    UICollectionView *_grid;
    UICollectionViewFlowLayout *_layout;

    // portrait widgets
    UIView *_pClockCard; UILabel *_pClockTime; UILabel *_pClockDay;
    UIView *_pCalCard;   UILabel *_pCalLine;
    UIView *_pWxCard;    UILabel *_pWxTitle;  UILabel *_pWxTemp;

    // CarPlay rail
    UIView *_rail;
    NSMutableArray *_railButtons;
    UIButton *_recent1;
    UIButton *_recent2;

    // floating pill (landscape top-right)
    UIView *_pill; UILabel *_pillTime; UILabel *_pillDate;

    // landscape widgets
    UIView *_lWxCard;   UILabel *_lWxTitle;  UILabel *_lWxTemp;
    UIView *_lCalCard;  UILabel *_lCalLine;
    UIView *_lClockCard; UILabel *_lClockTime; UILabel *_lClockDay;
    UIView *_lBatCard;  UILabel *_lBatTitle;  UILabel *_lBatVal;

    UIView *_panel;
    UIButton *_panelCloseButton;
    UIView *_volumePopup;

    NSTimer *_ticker;
    NSTimer *_weatherTimer;
    NSString *_weatherText;
}

#pragma mark - setup

- (void)viewDidLoad {
    [super viewDidLoad];

    _appTitles = @[@"Clock", @"Calendar", @"Notes", @"Files", @"Servers", @"Terminal", @"Settings"];
    _appClasses = @[[BOSClockViewController class], [BOSCalendarViewController class],
                    [BOSNotesViewController class], [BOSFilesViewController class],
                    [BOSServerManagerViewController class], [BOSTerminalViewController class],
                    [BOSSettingsViewController class]];
    _monograms = @[@"Cl", @"Cd", @"No", @"Fl", @"Sv", @"Tm", @"St"];

    _gradient = [CAGradientLayer layer];
    _gradient.frame = self.view.bounds;
    [self.view.layer insertSublayer:_gradient atIndex:0];

    // portrait widgets
    _pClockCard = [self makeCard];
    _pClockTime = [self makeLabel:_pClockCard font:[UIFont fontWithName:@"Menlo-Bold" size:30]];
    _pClockDay  = [self makeLabel:_pClockCard font:[UIFont systemFontOfSize:12]];
    _pCalCard = [self makeCard];
    _pCalLine = [self makeLabel:_pCalCard font:[UIFont systemFontOfSize:15]];
    _pWxCard = [self makeCard];
    _pWxTitle = [self makeLabel:_pWxCard font:[UIFont systemFontOfSize:11]];
    _pWxTemp  = [self makeLabel:_pWxCard font:[UIFont fontWithName:@"Menlo-Bold" size:17]];
    _pWxTitle.text = @"Weather";

    // landscape widgets
    _lWxCard = [self makeCard];
    _lWxTitle = [self makeLabel:_lWxCard font:[UIFont systemFontOfSize:13]];
    _lWxTemp  = [self makeLabel:_lWxCard font:[UIFont fontWithName:@"Menlo-Bold" size:34]];
    _lWxTitle.text = @"Weather";
    _lCalCard = [self makeCard];
    _lCalLine = [self makeLabel:_lCalCard font:[UIFont boldSystemFontOfSize:26]];
    _lClockCard = [self makeCard];
    _lClockTime = [self makeLabel:_lClockCard font:[UIFont fontWithName:@"Menlo-Bold" size:44]];
    _lClockDay  = [self makeLabel:_lClockCard font:[UIFont systemFontOfSize:15]];
    _lBatCard = [self makeCard];
    _lBatTitle = [self makeLabel:_lBatCard font:[UIFont systemFontOfSize:13]];
    _lBatVal   = [self makeLabel:_lBatCard font:[UIFont fontWithName:@"Menlo-Bold" size:44]];
    _lBatTitle.text = @"Battery";
    _lBatVal.text = @"--";

    // rail
    _rail = [[UIView alloc] init];
    [self.view addSubview:_rail];
    _railButtons = [NSMutableArray array];
    [self makeRailButton:@"Apps" action:@selector(appsTapped)];
    _recent1 = [self makeRailButton:@"—" action:@selector(recent1Tapped)];
    _recent2 = [self makeRailButton:@"—" action:@selector(recent2Tapped)];
    [self makeRailButton:@"Volume" action:@selector(volumeTapped)];
    [self makeRailButton:@"Terminal" action:@selector(terminalTapped)];

    // pill
    _pill = [self makeCard];
    _pillTime = [self makeLabel:_pill font:[UIFont fontWithName:@"Menlo-Bold" size:26]];
    _pillDate = [self makeLabel:_pill font:[UIFont systemFontOfSize:11]];

    // app grid (portrait: on desktop, landscape: inside panel)
    _layout = [[UICollectionViewFlowLayout alloc] init];
    _layout.minimumInteritemSpacing = 16.0;
    _layout.minimumLineSpacing = 8.0;
    _grid = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:_layout];
    _grid.dataSource = self;
    _grid.delegate = self;
    _grid.backgroundColor = [UIColor clearColor];
    [_grid registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
    [self.view addSubview:_grid];

    _panel = [[UIView alloc] init];
    _panel.hidden = YES;
    [self.view addSubview:_panel];
    [_panel addSubview:_grid];
    UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
    [close setTitle:@"Close" forState:UIControlStateNormal];
    close.titleLabel.font = [UIFont boldSystemFontOfSize:15];
    close.frame = CGRectMake(0, 0, 90, 40);
    close.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [close addTarget:self action:@selector(appsTapped) forControlEvents:UIControlEventTouchUpInside];
    [_panel addSubview:close];
    _panelCloseButton = close;

    [[UIDevice currentDevice] setBatteryMonitoringEnabled:YES];
    _weatherText = [[BOSDatabase sharedDatabase] stateForKey:@"weather"];
    if (!_weatherText.length) _weatherText = @"--";

    [self applyTheme];
    [self applyMode];
    [self updateRailRecents];
    _pWxTemp.text = _weatherText;
    _lWxTemp.text = _weatherText;
    [self tick];
    [self refreshWeather];

    _ticker = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(tick) userInfo:nil repeats:YES];
    _weatherTimer = [NSTimer scheduledTimerWithTimeInterval:600.0 target:self selector:@selector(refreshWeather) userInfo:nil repeats:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(themeChanged) name:BOSThemeDidChangeNotification object:nil];
}

- (void)dealloc {
    [_ticker invalidate];
    [_weatherTimer invalidate];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)themeChanged {
    [self applyTheme];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
    [self applyTheme];
    [self updateRailRecents];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.navigationBarHidden = NO;
}

#pragma mark - helpers

- (UIView *)makeCard {
    UIView *card = [[UIView alloc] init];
    card.layer.cornerRadius = 16.0;
    [self.view addSubview:card];
    return card;
}

- (UILabel *)makeLabel:(UIView *)parent font:(UIFont *)font {
    UILabel *label = [[UILabel alloc] init];
    label.font = font;
    label.textAlignment = NSTextAlignmentCenter;
    label.adjustsFontSizeToFitWidth = YES;
    label.minimumScaleFactor = 0.5;
    [parent addSubview:label];
    return label;
}

- (UIButton *)makeRailButton:(NSString *)title action:(SEL)action {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    [b setTitle:title forState:UIControlStateNormal];
    b.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    b.titleLabel.numberOfLines = 2;
    b.titleLabel.textAlignment = NSTextAlignmentCenter;
    b.layer.cornerRadius = 18.0;
    [b addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [_rail addSubview:b];
    [_railButtons addObject:b];
    return b;
}

#pragma mark - theme & mode

- (void)applyTheme {
    BOSTheme *t = [BOSTheme shared];
    NSArray *stops = [t wallpaperPalette][[t wallpaperIndex]];
    NSMutableArray *cg = [NSMutableArray array];
    for (UIColor *c in stops) [cg addObject:(id)c.CGColor];
    _gradient.colors = cg;
    _gradient.frame = self.view.bounds;

    NSArray *cards = @[_pClockCard, _pCalCard, _pWxCard, _lWxCard, _lCalCard, _lClockCard, _lBatCard, _pill, _rail];
    for (UIView *c in cards) c.backgroundColor = [t cardColor];
    _panel.backgroundColor = [t backgroundColor];
    if (_volumePopup) _volumePopup.backgroundColor = [t cardColor];

    _pClockTime.textColor = [t textColor];
    _pClockDay.textColor = [t secondaryTextColor];
    _pCalLine.textColor = [t textColor];
    _pWxTitle.textColor = [t secondaryTextColor];
    _pWxTemp.textColor = [t accentColor];

    _lWxTitle.textColor = [t secondaryTextColor];
    _lWxTemp.textColor = [t textColor];
    _lCalLine.textColor = [t textColor];
    _lClockTime.textColor = [t accentColor];
    _lClockDay.textColor = [t secondaryTextColor];
    _lBatTitle.textColor = [t secondaryTextColor];
    _lBatVal.textColor = [t textColor];

    _pillTime.textColor = [t accentColor];
    _pillDate.textColor = [t secondaryTextColor];
    _panelCloseButton.tintColor = [t accentColor];

    for (UIButton *b in _railButtons) {
        [b setTitleColor:[t accentColor] forState:UIControlStateNormal];
        b.backgroundColor = [t cardColor];
    }
    [_grid reloadData];
}

- (void)applyMode {
    BOOL land = [[BOSTheme shared] isLandscapeMode];
    CGFloat w = self.view.bounds.size.width;
    CGFloat h = self.view.bounds.size.height;

    if (land) {
        _pClockCard.hidden = YES;
        _pCalCard.hidden = YES;
        _pWxCard.hidden = YES;
        _rail.hidden = NO;
        _pill.hidden = NO;
        _lWxCard.hidden = NO;
        _lCalCard.hidden = NO;
        _lClockCard.hidden = NO;
        _lBatCard.hidden = NO;
        _panelCloseButton.hidden = NO;

        _rail.frame = CGRectMake(0.0, 0.0, 150.0, h);
        CGFloat by = (h - 5.0 * 96.0 - 4.0 * 12.0) / 2.0;
        if (by < 16.0) by = 16.0;
        for (NSUInteger i = 0; i < _railButtons.count; i++) {
            UIButton *b = _railButtons[i];
            b.frame = CGRectMake(16.0, by + i * (96.0 + 12.0), 118.0, 96.0);
        }
        _pill.frame = CGRectMake(w - 16.0 - 250.0, 16.0, 250.0, 68.0);

        CGFloat ax = 166.0, ay = 100.0;
        CGFloat aw = w - ax - 16.0, ah = h - ay - 16.0;
        CGFloat cw = (aw - 16.0) / 2.0, ch = (ah - 16.0) / 2.0;
        _lWxCard.frame = CGRectMake(ax, ay, cw, ch);
        _lCalCard.frame = CGRectMake(ax + cw + 16.0, ay, cw, ch);
        _lClockCard.frame = CGRectMake(ax, ay + ch + 16.0, cw, ch);
        _lBatCard.frame = CGRectMake(ax + cw + 16.0, ay + ch + 16.0, cw, ch);

        _panel.frame = CGRectMake(150.0, 0.0, w - 150.0, h);
        if (_grid.superview != _panel) {
            [_grid removeFromSuperview];
            [_panel addSubview:_grid];
        }
        _grid.frame = CGRectMake(16.0, 16.0, _panel.bounds.size.width - 32.0, _panel.bounds.size.height - 32.0);
        _layout.itemSize = CGSizeMake((_panel.bounds.size.width - 32.0 - 16.0) / 2.0, 104.0);
        _layout.sectionInset = UIEdgeInsetsZero;

    } else {
        _pClockCard.hidden = NO;
        _pCalCard.hidden = NO;
        _pWxCard.hidden = NO;
        _rail.hidden = YES;
        _pill.hidden = YES;
        _lWxCard.hidden = YES;
        _lCalCard.hidden = YES;
        _lClockCard.hidden = YES;
        _lBatCard.hidden = YES;
        _panel.hidden = YES;
        [self removeVolumePopup];

        _pClockCard.frame = CGRectMake(16.0, 24.0, 170.0, 88.0);
        _pCalCard.frame = CGRectMake(194.0, 24.0, 244.0, 88.0);
        _pWxCard.frame = CGRectMake(446.0, 24.0, 178.0, 88.0);

        if (_grid.superview != self.view) {
            [_grid removeFromSuperview];
            [self.view addSubview:_grid];
        }
        _grid.frame = CGRectMake(0.0, 124.0, w, h - 124.0 - 12.0);
        _layout.itemSize = CGSizeMake((w - 40.0 - 16.0) / 2.0, 104.0);
        _layout.sectionInset = UIEdgeInsetsMake(8.0, 20.0, 8.0, 20.0);
    }
    [_grid.collectionViewLayout invalidateLayout];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    _gradient.frame = self.view.bounds;
    [self applyMode];
}

#pragma mark - clock & weather

- (void)tick {
    static NSDateFormatter *timeFmt;
    static NSDateFormatter *dateFmt;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        timeFmt = [[NSDateFormatter alloc] init];
        timeFmt.dateFormat = @"HH:mm:ss";
        dateFmt = [[NSDateFormatter alloc] init];
        dateFmt.dateFormat = @"dd.MM.yyyy, EEEE";
    });
    NSDate *now = [NSDate date];
    NSString *time = [timeFmt stringFromDate:now];
    NSString *dateLine = [dateFmt stringFromDate:now];

    _pClockTime.text = time;
    _pClockDay.text = dateLine;
    _pCalLine.text = dateLine;
    _pillTime.text = time;
    _pillDate.text = dateLine;
    _lClockTime.text = time;
    _lClockDay.text = dateLine;
    _lCalLine.text = dateLine;

    float level = [[UIDevice currentDevice] batteryLevel];
    if (level >= 0.0) {
        _lBatVal.text = [NSString stringWithFormat:@"%d%%", (int)roundf(level * 100.0f)];
    }
}

- (void)refreshWeather {
    NSURL *url = [NSURL URLWithString:@"http://wttr.in/?format=%t+%C"];
    if (!url) return;
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error || !data) return;
        NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        text = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (text.length == 0 || [text hasPrefix:@"Unknown"]) return;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self applyWeather:text];
        });
    }];
    [task resume];
}

- (void)applyWeather:(NSString *)text {
    _weatherText = text;
    _pWxTemp.text = text;
    _lWxTemp.text = text;
    [[BOSDatabase sharedDatabase] setStateValue:text forKey:@"weather"];
}

#pragma mark - recents & rail

- (NSInteger)indexOfAppClassNamed:(NSString *)name {
    for (NSUInteger i = 0; i < _appClasses.count; i++) {
        if ([NSStringFromClass(_appClasses[i]) isEqualToString:name]) return (NSInteger)i;
    }
    return -1;
}

- (NSArray *)recentClassNames {
    NSString *raw = [[BOSDatabase sharedDatabase] stateForKey:@"recents"];
    if (!raw.length) return @[];
    NSMutableArray *out = [NSMutableArray array];
    for (NSString *part in [raw componentsSeparatedByString:@","]) {
        if (part.length && [self indexOfAppClassNamed:part] >= 0) [out addObject:part];
    }
    return out;
}

- (void)noteRecentClass:(Class)cls {
    NSString *name = NSStringFromClass(cls);
    NSMutableArray *list = [[self recentClassNames] mutableCopy] ?: [NSMutableArray array];
    [list removeObject:name];
    [list insertObject:name atIndex:0];
    while (list.count > 2) [list removeLastObject];
    [[BOSDatabase sharedDatabase] setStateValue:[list componentsJoinedByString:@","] forKey:@"recents"];
    [self updateRailRecents];
}

- (void)updateRailRecents {
    NSArray *r = [self recentClassNames];
    if (r.count > 0) {
        NSInteger i = [self indexOfAppClassNamed:r[0]];
        [_recent1 setTitle:_appTitles[i] forState:UIControlStateNormal];
        _recent1.enabled = YES;
    } else {
        [_recent1 setTitle:@"—" forState:UIControlStateNormal];
        _recent1.enabled = NO;
    }
    if (r.count > 1) {
        NSInteger i = [self indexOfAppClassNamed:r[1]];
        [_recent2 setTitle:_appTitles[i] forState:UIControlStateNormal];
        _recent2.enabled = YES;
    } else {
        [_recent2 setTitle:@"—" forState:UIControlStateNormal];
        _recent2.enabled = NO;
    }
}

- (void)openAppAtIndex:(NSInteger)index {
    if (index < 0 || index >= (NSInteger)_appClasses.count) return;
    [self noteRecentClass:_appClasses[index]];
    _panel.hidden = YES;
    [self removeVolumePopup];
    [self.navigationController pushViewController:[[_appClasses[index] alloc] init] animated:YES];
}

- (void)appsTapped {
    _panel.hidden = !_panel.hidden;
    if (!_panel.hidden) [self.view bringSubviewToFront:_pill];
}

- (void)recent1Tapped {
    NSArray *r = [self recentClassNames];
    if (r.count > 0) [self openAppAtIndex:[self indexOfAppClassNamed:r[0]]];
}

- (void)recent2Tapped {
    NSArray *r = [self recentClassNames];
    if (r.count > 1) [self openAppAtIndex:[self indexOfAppClassNamed:r[1]]];
}

- (void)terminalTapped {
    [self openAppAtIndex:[self indexOfAppClassNamed:NSStringFromClass([BOSTerminalViewController class])]];
}

#pragma mark - volume popup

- (void)volumeTapped {
    if (_volumePopup) {
        [self removeVolumePopup];
        return;
    }
    CGFloat h = self.view.bounds.size.height;
    _volumePopup = [[UIView alloc] initWithFrame:CGRectMake(166.0, (h - 110.0) / 2.0, 320.0, 110.0)];
    _volumePopup.layer.cornerRadius = 20.0;
    _volumePopup.backgroundColor = [[BOSTheme shared] cardColor];
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(16.0, 8.0, 288.0, 24.0)];
    title.text = @"Volume";
    title.font = [UIFont systemFontOfSize:13];
    title.textColor = [[BOSTheme shared] secondaryTextColor];
    [_volumePopup addSubview:title];
    MPVolumeView *vol = [[MPVolumeView alloc] initWithFrame:CGRectMake(16.0, 56.0, 288.0, 36.0)];
    [_volumePopup addSubview:vol];
    [self.view addSubview:_volumePopup];
    [self.view bringSubviewToFront:_volumePopup];
}

- (void)removeVolumePopup {
    [_volumePopup removeFromSuperview];
    _volumePopup = nil;
}

#pragma mark - grid

- (NSInteger)collectionView:(UICollectionView *)cv numberOfItemsInSection:(NSInteger)section {
    return (NSInteger)_appClasses.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)ip {
    UICollectionViewCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:ip];
    cell.backgroundColor = [UIColor clearColor];
    for (UIView *v in [cell.contentView.subviews copy]) [v removeFromSuperview];

    CGFloat cw = cell.contentView.bounds.size.width;
    UIView *icon = [[UIView alloc] initWithFrame:CGRectMake((cw - 64.0) / 2.0, 6.0, 64.0, 64.0)];
    icon.layer.cornerRadius = 15.0;
    icon.backgroundColor = [[BOSTheme shared] accentColor];
    icon.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    UILabel *mono = [[UILabel alloc] initWithFrame:icon.bounds];
    mono.text = _monograms[ip.item];
    mono.font = [UIFont boldSystemFontOfSize:24];
    mono.textColor = [UIColor whiteColor];
    mono.textAlignment = NSTextAlignmentCenter;
    [icon addSubview:mono];

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 76.0, cw, 20.0)];
    title.text = _appTitles[ip.item];
    title.font = [UIFont systemFontOfSize:12];
    title.textColor = [[BOSTheme shared] textColor];
    title.textAlignment = NSTextAlignmentCenter;
    title.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    [cell.contentView addSubview:icon];
    [cell.contentView addSubview:title];
    return cell;
}

- (void)collectionView:(UICollectionView *)cv didSelectItemAtIndexPath:(NSIndexPath *)ip {
    [cv deselectItemAtIndexPath:ip animated:YES];
    [self openAppAtIndex:(NSInteger)ip.item];
}

@end
