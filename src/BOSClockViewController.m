#import "BOSClockViewController.h"
#import "BOSTheme.h"

@interface BOSClockViewController () <UITableViewDataSource>
@end

@interface BOSClockViewController ()BOSClockViewController {
    UILabel *_timeLabel;
    UILabel *_swLabel;
    UIButton *_startButton;
    UIButton *_lapButton;
    UIButton *_clearButton;
    UITableView *_lapsTable;
    NSMutableArray *_laps;
    BOOL _running;
    CFAbsoluteTime _startedAt;
    CFAbsoluteTime _saved;
    NSTimer *_ticker;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _laps = [NSMutableArray array];
    _timeLabel = [[UILabel alloc] init];
    _timeLabel.font = [UIFont fontWithName:@"Menlo-Regular" size:56];
    _timeLabel.textAlignment = NSTextAlignmentCenter;
    _swLabel = [[UILabel alloc] init];
    _swLabel.font = [UIFont fontWithName:@"Menlo-Regular" size:28];
    _swLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_timeLabel];
    [self.view addSubview:_swLabel];
    _startButton = [[BOSTheme shared] md3FilledButtonWithTitle:@"Start" target:self action:@selector(toggleStartStop)];
    _lapButton = [[BOSTheme shared] md3FilledButtonWithTitle:@"Lap" target:self action:@selector(takeLap)];
    _clearButton = [[BOSTheme shared] md3FilledButtonWithTitle:@"Clear" target:self action:@selector(clearLaps)];
    [self.view addSubview:_startButton];
    [self.view addSubview:_lapButton];
    [self.view addSubview:_clearButton];
    _lapsTable = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    _lapsTable.dataSource = self;
    _lapsTable.separatorColor = [[BOSTheme shared] strokeColor];
    _lapsTable.rowHeight = 34.0;
    [self.view addSubview:_lapsTable];
    _ticker = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(tick) userInfo:nil repeats:YES];
    [self tick];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.view.backgroundColor = [[BOSTheme shared] backgroundColor];
    _timeLabel.textColor = [[BOSTheme shared] textColor];
    _swLabel.textColor = [[BOSTheme shared] secondaryTextColor];
    _lapsTable.backgroundColor = [UIColor clearColor];
    [_lapsTable reloadData];
}

- (void)tick {
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    [fmt setDateFormat:@"HH:mm:ss"];
    _timeLabel.text = [fmt stringFromDate:[NSDate date]];
    [self refreshStopwatchLabel];
}

- (CFAbsoluteTime)stopwatchValue {
    CFAbsoluteTime value = _saved;
    if (_running) {
        value += (CFAbsoluteTime)([NSDate timeIntervalSinceReferenceDate] - _startedAt);
    }
    return value;
}

- (void)refreshStopwatchLabel {
    CFAbsoluteTime value = [self stopwatchValue];
    int whole = (int)value;
    int hundredths = (int)((value - whole) * 100.0);
    _swLabel.text = [NSString stringWithFormat:@"%02d:%02d.%02d", whole / 60, whole % 60, hundredths];
}

- (void)toggleStartStop {
    if (!_running) {
        _startedAt = [NSDate timeIntervalSinceReferenceDate];
        _running = YES;
        [_startButton setTitle:@"Stop" forState:UIControlStateNormal];
        _lapsTable.hidden = NO;

    } else {
        _saved = [self stopwatchValue];
        _running = NO;
        [_startButton setTitle:@"Start" forState:UIControlStateNormal];
    }
}

- (void)takeLap {
    [_laps addObject:_swLabel.text];
    [_lapsTable reloadData];
}

- (void)clearLaps {
    _saved = 0;
    _running = NO;
    [_startButton setTitle:@"Start" forState:UIControlStateNormal];
    [_laps removeAllObjects];
    [_lapsTable reloadData];
    [_swLabel setText:@"00:00.00"];
}

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s {
    return (NSInteger)_laps.count;
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    static NSString *id_ = @"lap";
    UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:id_];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:id_];
    cell.textLabel.text = [NSString stringWithFormat:@"Lap %lu", (unsigned long)ip.row + 1];
    cell.detailTextLabel.text = _laps[ip.row];
    cell.backgroundColor = [UIColor clearColor];
    cell.textLabel.textColor = [[BOSTheme shared] secondaryTextColor];
    cell.detailTextLabel.textColor = [[BOSTheme shared] accentColor];
    cell.textLabel.font = [UIFont fontWithName:@"Menlo-Regular" size:14];
    cell.detailTextLabel.font = [UIFont fontWithName:@"Menlo-Regular" size:14];
    return cell;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat w = self.view.bounds.size.width;
    CGFloat h = self.view.bounds.size.height;
    _timeLabel.frame = CGRectMake(16.0, 16.0, w - 32.0, 80.0);
    _swLabel.frame = CGRectMake(16.0, 100.0, w - 32.0, 44.0);
    CGFloat buttonY = 152.0;
    CGFloat buttonW = (w - 64.0) / 3.0;
    _startButton.frame = CGRectMake(16.0, buttonY, buttonW, 40.0);
    _lapButton.frame = CGRectMake(16.0 + buttonW + 16.0, buttonY, buttonW, 40.0);
    _clearButton.frame = CGRectMake(16.0 + (buttonW + 16.0) * 2.0, buttonY, buttonW, 40.0);
    _lapsTable.frame = CGRectMake(16.0, 208.0, w - 32.0, h - 224.0);
}

@end
