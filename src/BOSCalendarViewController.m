#import "BOSCalendarViewController.h"
#import "BOSTheme.h"
#import "BOSDatabase.h"

@implementation BOSCalendarViewController {
    UITableView *_table;
    NSArray *_rows;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    UIButton *addButton = [[BOSTheme shared] md3FilledButtonWithTitle:@"+ Add event" target:self action:@selector(addEvent)];
    addButton.frame = CGRectMake(16.0, 16.0, 150.0, 40.0);
    [self.view addSubview:addButton];
    _table = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    _table.dataSource = self;
    _table.delegate = self;
    _table.rowHeight = 48.0;
    _table.separatorColor = [[BOSTheme shared] strokeColor];
    [self.view addSubview:_table];
    [self loadEvents];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.view.backgroundColor = [[BOSTheme shared] backgroundColor];
    _table.backgroundColor = [UIColor clearColor];
    [self loadEvents];
}

- (void)addEvent {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"New event" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
        field.placeholder = @"Title";
    }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
        field.placeholder = @"YYYY-MM-DD";
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSString *title = alert.textFields[0].text;
        NSString *date = alert.textFields[1].text;
        if (!title.length || !date.length) return;
        [[BOSDatabase sharedDatabase] executeWithSQL:@"INSERT INTO events (event_date, title) VALUES (?, ?)" arguments:@[date, title] insertedId:NULL];
        [self loadEvents];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)loadEvents {
    _rows = [[BOSDatabase sharedDatabase] queryWithSQL:@"SELECT id, event_date, title FROM events ORDER BY event_date DESC LIMIT 200" arguments:nil];
    [_table reloadData];
}

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s {
    return (NSInteger)_rows.count;
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    static NSString *id_ = @"event";
    UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:id_];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:id_];
    NSDictionary *row = _rows[ip.row];
    cell.textLabel.text = row[@"event_date"];
    cell.detailTextLabel.text = row[@"title"];
    cell.textLabel.textColor = [[BOSTheme shared] secondaryTextColor];
    cell.detailTextLabel.textColor = [[BOSTheme shared] textColor];
    cell.backgroundColor = [UIColor clearColor];
    return cell;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)ip {
    [tv deselectRowAtIndexPath:ip animated:YES];
    NSNumber *eventId = _rows[ip.row][@"id"];
    [[BOSDatabase sharedDatabase] executeWithSQL:@"DELETE FROM events WHERE id = ?" arguments:@[eventId] insertedId:NULL];
    [self loadEvents];
}

@end
