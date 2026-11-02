#import "BOSHomeViewController.h"
#import "BOSTheme.h"
#import "BOSClockViewController.h"
#import "BOSCalendarViewController.h"
#import "BOSNotesViewController.h"
#import "BOSFilesViewController.h"
#import "BOSServerManagerViewController.h"
#import "BOSTerminalViewController.h"
#import "BOSSettingsViewController.h"

@interface BOSHomeViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@end

@implementation BOSHomeViewController {
    UICollectionView *_grid;
    UICollectionViewFlowLayout *_layout;
    UILabel *_clockLabel;
    NSTimer *_ticker;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _layout = [[UICollectionViewFlowLayout alloc] init];
    _layout.minimumInteritemSpacing = 16.0;
    _layout.minimumLineSpacing = 16.0;
    _grid = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:_layout];
    _grid.dataSource = self;
    _grid.delegate = self;
    [_grid registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
    [_grid registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"header"];
    [self.view addSubview:_grid];
    _ticker = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(tick) userInfo:nil repeats:YES];
    [self tick];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
    [self applyTheme];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.navigationBarHidden = NO;
}

- (void)applyTheme {
    _grid.backgroundColor = [[BOSTheme shared] backgroundColor];
    [_grid reloadData];
}

- (void)tick {
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    [fmt setDateFormat:@"HH:mm:ss"];
    _clockLabel.text = [fmt stringFromDate:[NSDate date]];
}

- (CGSize)gridMetrics {
    CGFloat w = self.view.bounds.size.width;
    return CGSizeMake(MAX(1.0, floor((w - 48.0) / 2.0)), 104.0);
}

- (NSInteger)collectionView:(UICollectionView *)cv numberOfItemsInSection:(NSInteger)section {
    return 7;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)cv layout:(UICollectionViewLayout *)l insetForSectionAtIndex:(NSInteger)s {
    return UIEdgeInsetsMake(8.0, 16.0, 16.0, 16.0);
}

- (CGSize)collectionView:(UICollectionView *)cv layout:(UICollectionViewLayout *)l referenceSizeForHeaderInSection:(NSInteger)s {
    return CGSizeMake(self.view.bounds.size.width, 96.0);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)ip {
    UICollectionViewCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:ip];
    NSArray *names = @[@"Clock", @"Calendar", @"Notes", @"Files", @"Servers", @"Terminal", @"Settings"];
    UILabel *label;
    for (UIView *v in cell.contentView.subviews) {
        if ([v isKindOfClass:[UILabel class]]) label = (UILabel *)v;
    }
    if (!label) {
        label = [[UILabel alloc] init];
        label.font = [UIFont systemFontOfSize:17];
        label.tag = 1;
        [cell.contentView addSubview:label];
    }
    label.text = names[ip.item];
    label.frame = CGRectMake(16.0, 0.0, cell.contentView.bounds.size.width - 32.0, cell.contentView.bounds.size.height);
    UIView *card;
    for (UIView *v in cell.contentView.subviews) {
        if (v.tag == 2) card = v;
    }
    if (!card) {
        card = [[UIView alloc] initWithFrame:cell.contentView.bounds];
        card.userInteractionEnabled = NO;
        card.tag = 2;
        [cell.contentView insertSubview:card atIndex:0];
    }
    card.frame = cell.contentView.bounds;
    cell.backgroundColor = [UIColor clearColor];
    card.layer.cornerRadius = 16.0;
    card.backgroundColor = [[BOSTheme shared] cardColor];
    label.textColor = [[BOSTheme shared] textColor];
    cell.layer.cornerRadius = 16.0;
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)cv viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)ip {
    UICollectionReusableView *header = [cv dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"header" forIndexPath:ip];
    if (!_clockLabel) {
        _clockLabel = [[UILabel alloc] init];
        _clockLabel.font = [UIFont fontWithName:@"Menlo-Regular" size:44];
        _clockLabel.textAlignment = NSTextAlignmentCenter;
        [header addSubview:_clockLabel];
    }
    _clockLabel.frame = CGRectMake(16.0, 16.0, header.bounds.size.width - 32.0, 64.0);
    _clockLabel.textColor = [[BOSTheme shared] accentColor];
    return header;
}

- (void)collectionView:(UICollectionView *)cv     didSelectItemAtIndexPath:(NSIndexPath *)ip {
    UINavigationController *nav = self.navigationController;
    NSDictionary *screens = @{
        @0 : [BOSClockViewController class],
        @1 : [BOSCalendarViewController class],
        @2 : [BOSNotesViewController class],
        @3 : [BOSFilesViewController class],
        @4 : [BOSServerManagerViewController class],
        @5 : [BOSTerminalViewController class],
        @6 : [BOSSettingsViewController class],
    };
    Class cls = screens[@(ip.item)];
    if (cls) [nav pushViewController:[[cls alloc] init] animated:YES];
    [cv deselectItemAtIndexPath:ip animated:YES];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGSize size = [self gridMetrics];
    _layout.itemSize = size;
    _grid.frame = CGRectMake(0.0, 0.0, self.view.bounds.size.width, self.view.bounds.size.height);
    [_grid.collectionViewLayout invalidateLayout];
    [self tick];
}

@end
