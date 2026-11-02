#import "BOSFilesViewController.h"
#import "BOSTheme.h"

@implementation BOSFilesViewController {
    UITableView *_table;
    NSMutableArray *_entries;
    NSString *_currentPath;
}

- (instancetype)initWithPath:(NSString *)path {
    self = [super init];
    if (self) {
        _currentPath = [path copy] ?: @"/var/mobile";
        _entries = [NSMutableArray array];
    }
    return self;
}

- (instancetype)init {
    return [self initWithPath:@"/var/mobile"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _table = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    _table.dataSource = self;
    _table.delegate = self;
    _table.separatorColor = [[BOSTheme shared] strokeColor];
    _table.rowHeight = 40.0;
    [self.view addSubview:_table];
    [self loadDirectory];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.view.backgroundColor = [[BOSTheme shared] backgroundColor];
    _table.backgroundColor = [UIColor clearColor];
    self.title = [_currentPath lastPathComponent] ?: _currentPath;
}

- (void)loadDirectory {
    [_entries removeAllObjects];
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isRootPath = [_currentPath isEqualToString:@"/var/mobile"];
    if (!isRootPath) [_entries addObject:@"../"];
    NSArray *items = [fm contentsOfDirectoryAtPath:_currentPath error:nil];
    for (NSString *item in items) [_entries addObject:item];
    [_table reloadData];
}

- (BOOL)pathIsDirectory:(NSString *)fullPath {
    BOOL isDir = NO;
    [[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&isDir];
    return isDir;
}

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s {
    return (NSInteger)_entries.count;
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    static NSString *id_ = @"file";
    UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:id_];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:id_];
        cell.textLabel.font = [UIFont systemFontOfSize:15];
    }
    NSString *name = _entries[ip.row];
    BOOL dir = [name isEqualToString:@"../"] || [self pathIsDirectory:[_currentPath stringByAppendingPathComponent:name]];
    cell.textLabel.text = dir ? [name stringByAppendingString:@"/"] : name;
    cell.textLabel.textColor = dir ? [[BOSTheme shared] accentColor] : [[BOSTheme shared] textColor];
    cell.backgroundColor = [UIColor clearColor];
    return cell;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)ip {
    [tv deselectRowAtIndexPath:ip animated:YES];
    NSString *name = _entries[ip.row];
    if ([name isEqualToString:@"../"]) {
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    NSString *fullPath = [_currentPath stringByAppendingPathComponent:name];
    if ([self pathIsDirectory:fullPath]) {
        BOSFilesViewController *next = [[BOSFilesViewController alloc] initWithPath:fullPath];
        [self.navigationController pushViewController:next animated:YES];
        return;
    }
    [self previewFileIfNeeded:fullPath name:name];
}

- (void)previewFileIfNeeded:(NSString *)fullPath name:(NSString *)name {
    static NSString *exts[] = { @"txt", @"sh", @"conf", @"log", @"plist", @"xml", @"json", @"m", @"h", @"html", @"css" };
    NSString *ext = [name pathExtension] ?: @"";
    BOOL allowed = NO;
    for (int i = 0; i < (int)(sizeof(exts) / sizeof(exts[0])); i++) {
        if ([ext isEqualToString:exts[i]]) {
            allowed = YES;
            break;
        }
    }
    if (!allowed) return;
    NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:fullPath error:nil];
    unsigned long long size = [attrs fileSize];
    if (size > 262144) return;
    NSString *content = [NSString stringWithContentsOfFile:fullPath encoding:NSUTF8StringEncoding error:NULL];
    if (!content) return;
    UITextView *textView = [[UITextView alloc] init];
    textView.font = [UIFont fontWithName:@"Menlo-Regular" size:12];
    textView.text = content;
    textView.editable = NO;
    UIViewController *vc = [[UIViewController alloc] init];
    vc.title = name;
    vc.view.backgroundColor = [[BOSTheme shared] backgroundColor];
    textView.backgroundColor = [UIColor clearColor];
    textView.textColor = [[BOSTheme shared] textColor];
    textView.frame = vc.view.bounds;
    textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [vc.view addSubview:textView];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
