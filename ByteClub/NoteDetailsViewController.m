//
//  NoteDetailsViewController.m
//  ByteClub
//
//  Created by Charlie Fulton on 7/28/13.
//  Copyright (c) 2013 Razeware. All rights reserved.
//

#import "NoteDetailsViewController.h"
#import "Dropbox.h"
#import "DBFile.h"

@interface NoteDetailsViewController ()
@property (weak, nonatomic) IBOutlet UITextField *filename;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelButton;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@end

@implementation NoteDetailsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self){
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    if (self.note) {
        self.filename.text = [[_note fileNameShowExtension:YES] lowercaseString];
        [self retrieveNoteText];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)retrieveNoteText
{
    NSString *fileApi = @"https://api-content.dropbox.com/1/files/dropbox";
    NSString *escapedPath = [_note.path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *urlStr = [NSString stringWithFormat:@"%@/%@", fileApi, escapedPath];
    NSURL *url = [NSURL URLWithString:urlStr];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [[_session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (!error) {
            NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *) response;
            if (httpResp.statusCode == 200) {
                NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                    self.textView.text = text;
                });
            } else {
                //handle bad response
            }
        } else {
            //always handle errors!
        }
    }] resume];
}

#pragma mark - send messages to delegate

- (IBAction)done:(id)sender
{
    // must contain text in textview
    if (![_textView.text isEqualToString:@""]) {
        
        // check to see if we are adding a new note
        if (!self.note) {
            DBFile *newNote = [[DBFile alloc] init];
            newNote.root = @"dropbox";
            self.note = newNote;
        }
        
        _note.contents = _textView.text;
        _note.path = _filename.text;
        
        NSURL *url = [Dropbox uploadURLForPath:_note.path];
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
        [request setHTTPMethod:@"PUT"];
        
        NSData *noteContents = [_note.contents dataUsingEncoding:NSUTF8StringEncoding];
        NSURLSessionUploadTask *uploadTask = [_session uploadTaskWithRequest:request fromData:noteContents completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *) response;
            if (!error && httpResp.statusCode == 200) {
                [self.delegate noteDetailsViewControllerDoneWithDetails:self];
            } else {
                
            }
        }];
        [uploadTask resume];
        
    } else {
        UIAlertView *noTextAlert = [[UIAlertView alloc] initWithTitle:@"No text"
                                                              message:@"Need to enter text"
                                                             delegate:nil
                                                    cancelButtonTitle:@"Ok"
                                                    otherButtonTitles:nil];
        [noTextAlert show];
    }
}

- (IBAction)cancel:(id)sender
{
    [self.delegate noteDetailsViewControllerDidCancel:self];
}

@end
