//
//  TableViewController.m
//  AUGraphPlayDemo
//
//  Created by liumiao on 11/18/14.
//  Copyright (c) 2014 Chang Ba. All rights reserved.
//

#import "TableViewController.h"
#import "ViewController.h"
@interface TableViewController ()
@property (nonatomic,strong)NSMutableArray *dataSource;
@end

@implementation TableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Document目录";
    self.dataSource = [NSMutableArray array];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self loadData];
    [self.tableView reloadData];
}

-(void)loadData
{
    NSFileManager* manager = [NSFileManager defaultManager];
    NSArray* propertyKeys = @[ NSURLNameKey, NSURLIsDirectoryKey, NSURLIsRegularFileKey, NSURLTotalFileSizeKey ];
    NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSDirectoryEnumerator* enumerator = [manager enumeratorAtURL:[NSURL URLWithString:documentsDirectory] includingPropertiesForKeys:propertyKeys options:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsPackageDescendants errorHandler:nil];
    [self.dataSource removeAllObjects];
    for (NSURL* uri in enumerator) {
        [self.dataSource addObject:uri];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
#warning Potentially incomplete method implementation.
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
#warning Incomplete method implementation.
    // Return the number of rows in the section.
    return [self.dataSource count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    NSURL* path = (NSURL*)[self.dataSource objectAtIndex:indexPath.row];
    NSString* filename = nil;
    [path getResourceValue:&filename forKey:NSURLLocalizedNameKey error:nil];
    cell.textLabel.text = filename;
    // Configure the cell...
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSURL* path = (NSURL*)[self.dataSource objectAtIndex:indexPath.row];
    UIStoryboard *mainboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    ViewController *vc = [mainboard instantiateViewControllerWithIdentifier:@"ViewController"];
    vc.fileUrl = path;
    [self.navigationController pushViewController:vc animated:YES];
}
/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
