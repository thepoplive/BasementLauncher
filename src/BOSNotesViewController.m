#import "BOSNotesViewController.h"
#import "BOSTheme.h"
#import "BOSDatabase.h"

@interface BOSNotesViewController () <UITableViewDataSource, UITableViewDelegate>
@end

@interface BOSNotesViewController ()BOSNotesViewController {
    UITextField *_field;
    UITextView *_editor;
    UITableView *_list;
    UIButton *_saveButton;
    UIButton *_newButton;
    NSArray *_rows;
    NSNumber *_currentId;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _field = [[UITextField alloc] init];
    _field.placeholder = @"Title";
    _field.borderStyle = UITextBorderStyleRoundedRect;
    _field.font = [UIFont systemFontOfSize:17];
    [self.view addSubview:_field];

    _editor = [[UITextView alloc] init];
    _editor.font = [UIFont systemFontOfSize:16];
    _editor.layer.cornerRadius = 8.0;
    [self.view addSubview:_editor];

   UIButton *saveButton = [[BOSTheme shared] md3FilledButtonWithTitle:@"Save" target:self action:@selector(saveNote)];
    UIButton *newButton = [[BOSTheme shared] md3FilledButtonWithTitle:@"New" target:self action:@selector(clearEditor)];
    [self.view addSubview:saveButton];
    [self.view addSubview:newButton];
    _saveButton = saveButton;
    _newButton = newButton;

    _list = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    _list.dataSource = self;
    _list.delegate = self;
    _list.separatorColor = [[BOSTheme shared] strokeColor];
    _list.rowHeight = 44.0;
    [self.view addSubview:_list];

    [self loadNotes];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.view.backgroundColor = [[BOSTheme shared] backgroundColor];
    _editor.backgroundColor = [[BOSTheme shared] cardColor];
    _editor.textColor = [[BOSTheme shared] textColor];
    _field.textColor = [[BOSTheme shared] textColor];
    _list.backgroundColor = [UIColor clearColor];
    [self loadNotes];
}

- (void)loadNotes {
    _rows = [[BOSDatabase sharedDatabase] queryWithSQL:@"SELECT id, text FROM notes ORDER BY id DESC LIMIT 100" arguments:nil];
    [_list reloadData];
}

- (void)saveNote {
    NSString *body = _editor.text;
    if (body.length == 0) return;
    if (!_currentId) {
        [[BOSDatabase sharedDatabase] executeWithSQL:@"INSERT INTO notes (text) VALUES (?)" arguments:@[body] insertedId:NULL];
    } else {
        [[BOSDatabase sharedDatabase] executeWithSQL:@"UPDATE notes SET text = ? WHERE id = ?" arguments:@[body, _currentId] insertedId:NULL];
    }
    [self clearEditor];
    [self loadNotes];
}

- (void)clearEditor {
    _field.text = @"";
    _editor.text = @"";
    _currentId = nil;
    [_list reloadData];
}

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s {
    return (NSInteger)_rows.count;
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    static NSString *id_ = @"note";
    UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:id_];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:id_];
    NSString *text = (NSString *)_rows[ip.row][@"text"] ?: @"";
    NSString *title = text;
    NSRange sep = [text rangeOfString:@"\n-\n"];
    if (sep.location != NSNotFound && sep.location > 0) title = [text substringToIndex:sep.location];
    cell.textLabel.text = [title stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
    cell.textLabel.textColor = [[BOSTheme shared] textColor];
    cell.backgroundColor = [UIColor clearColor];
    return cell;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)ip {
    [tv deselectRowAtIndexPath:ip animated:YES];
    NSDictionary *row = _rows[ip.row];
    _currentId = row[@"id"];
    NSString *text = (NSString *)row[@"text"] ?: @"";
    NSRange sep = [text rangeOfString:@"\n-\n"];
    if (sep.location != NSNotFound && sep.location > 0) {
        _field.text = [text substringToIndex:sep.location];
    } else {
        _field.text = @"";
    }
    _editor.text = text;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat w = self.view.bounds.size.width;
    CGFloat h = self.view.bounds.size.height;
    _field.frame = CGRectMake(16.0, 16.0, w - 200.0, 38.0);
    _newButton.frame = CGRectMake(w - 168.0, 16.0, 70.0, 38.0);
    _saveButton.frame = CGRectMake(w - 88.0, 16.0, 72.0, 38.0);
    _editor.frame = CGRectMake(16.0, 64.0, w - 32.0, 180.0);
    _list.frame = CGRectMake(16.0, 254.0, w - 32.0, h - 270.0);
}

@end
