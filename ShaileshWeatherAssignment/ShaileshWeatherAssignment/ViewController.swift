//
//  ViewController.swift
//  ShaileshWeatherAssignment
//
//  Created by Shailesh Bachute on 20/12/17.
//  Copyright © 2017 Shailesh Bachute. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var buttonClear: UIButton!
    @IBOutlet weak var buttonStart: UIButton!
    @IBOutlet weak var imageViewUK: UIImageView!
    @IBOutlet weak var imageViewEngland: UIImageView!
    @IBOutlet weak var imageViewWales: UIImageView!
    @IBOutlet weak var imageViewScotland: UIImageView!
    var arrayOfWeatherFactors = ["Tmax", "Tmin", "Tmean", "Sunshine", "Rainfall"]
    var arrayOfWeatherFactorsTitle = ["Max Temp", "Min temp", "Mean temp", "Sunshine", "Rainfall"]
    var arrayOfCountries = ["UK", "England", "Wales", "Scotland"]
    var selectedWeatherFactor = ""
    var selectedCountry = ""
    var indexCountry = 0;
    var indexWeatherFactor = 0;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    @IBAction func clearFilesAndData(sender:UIButton){
        let fileManager = NSFileManager.defaultManager()
        let documentsUrl =  NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first! as NSURL
        let documentsPath = documentsUrl.path
        do {
            if let documentPath = documentsPath
            {
                let fileNames = try fileManager.contentsOfDirectoryAtPath("\(documentPath)")
                for fileName in fileNames {
                    let filePathName = "\(documentPath)/\(fileName)"
                    try fileManager.removeItemAtPath(filePathName)
                }
            }
            imageViewUK.hidden = true
            imageViewEngland.hidden = true
            imageViewWales.hidden = true
            imageViewScotland.hidden = true
            buttonStart.enabled = true
            buttonStart.alpha = 1
            indexCountry = 0
            indexWeatherFactor = 0 
        } catch {
            print("Could not clear temp folder: \(error)")
        }
    }
    
    @IBAction func dowloadFiles(sender: UIButton?) {
        buttonStart.enabled = false
        buttonStart.alpha = 0.6
        var url = NSURL(string: "")
        if indexCountry < arrayOfCountries.count {
            selectedCountry = arrayOfCountries[indexCountry];
            if indexWeatherFactor < arrayOfWeatherFactors.count {
                selectedWeatherFactor = arrayOfWeatherFactors[indexWeatherFactor];
                let stringURL = "https://www.metoffice.gov.uk/pub/data/weather/uk/climate/datasets/" + selectedWeatherFactor + "/date/" + selectedCountry + ".txt"
                url = NSURL.init(string: stringURL)!
                downloadFile(url!)
            }
        }
    }
    
    func downloadFile(url: NSURL) {
        let downloadRequest = NSURLRequest(URL: url)
        NSURLSession.sharedSession().downloadTaskWithRequest(downloadRequest){ (location, response, error) in
            guard  let tempLocation = location where error == nil else { return }
            let documentDirectory = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first
            let fullURL = documentDirectory?.URLByAppendingPathComponent(self.selectedWeatherFactor+self.selectedCountry+".txt")
            do {
                //This will alwas replace old file by new file, we can prompt for Alerts for user inputs like overwrite,cancel,rename,etc.
                try NSFileManager.defaultManager().replaceItemAtURL(fullURL!, withItemAtURL: tempLocation, backupItemName: "", options: NSFileManagerItemReplacementOptions.UsingNewMetadataOnly, resultingItemURL:nil)
            } catch NSCocoaError.FileReadNoSuchFileError {
                print("No such file")
            } catch {
                print("Error downloading file : \(error)")
            }
            self.readData(fullURL!);
            }.resume()
    }
    
    func readData(url: NSURL) {
        do {
            if let dir = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.AllDomainsMask, true).first {
                let path = NSURL(fileURLWithPath: dir).URLByAppendingPathComponent(selectedWeatherFactor+selectedCountry+".txt")
                let fileName = "Weather.csv"
                let pathOfCSVFile = NSURL(fileURLWithPath: dir).URLByAppendingPathComponent(fileName)
                var csvText = ""
                let path2 = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
                let url2 = NSURL(fileURLWithPath: path2)
                let filePath = url2.URLByAppendingPathComponent(fileName).path!
                let fileManager = NSFileManager.defaultManager()
                if fileManager.fileExistsAtPath(filePath) {
                    csvText = try NSString(contentsOfURL: pathOfCSVFile, encoding: NSUTF8StringEncoding) as String!
                }
                var monthNameLine:NSString = ""
                //reading data from .txt file
                let txtFileAsString = try NSString(contentsOfURL: path, encoding: NSUTF8StringEncoding) as NSString!
                let arrayOfLine = txtFileAsString.componentsSeparatedByString("\n")
                var isRecordParsingStarted = false as Bool!
                for line: NSString in arrayOfLine {
                    if line.containsString("Year    JAN    FEB"){
                        isRecordParsingStarted = true
                        monthNameLine = (line as String!).substringToIndex((line as String!).endIndex.predecessor()) as NSString
                        continue;
                    }else{
                        if (isRecordParsingStarted==true && !line.isEqualToString("")) {
                            let truncated = (line as String!).substringToIndex((line as String!).endIndex.predecessor()) as NSString
                            var locationIndex = 0
                            var length = 4
                            var formattedRecord = "" as NSString
                            let yearString = truncated.substringWithRange(NSRange.init(location: locationIndex, length: length)) as String
                            //77 is taken because of output requrment if we need more columns we can add.
                            while locationIndex<77 {
                                locationIndex += length;
                                length = 7;
                                var oneRecord = truncated.substringWithRange(NSRange.init(location: locationIndex, length: length))
                                oneRecord = oneRecord.stringByReplacingOccurrencesOfString(" ", withString: "");
                                if oneRecord.isEmpty {
                                    oneRecord = "N/A"
                                }
                                var monthString = monthNameLine.substringWithRange(NSRange.init(location: locationIndex, length: length))
                                monthString = monthString.stringByReplacingOccurrencesOfString(" ", withString: "");
                                formattedRecord = selectedCountry + ", " + arrayOfWeatherFactorsTitle[arrayOfWeatherFactors.indexOf(selectedWeatherFactor)!] + ", " + yearString + ", " + monthString + ", " + oneRecord + "\n"
                                csvText.appendContentsOf(formattedRecord as String)
                            }
                        }
                    }
                }
                
                do {
                    try csvText.writeToURL(pathOfCSVFile, atomically: true, encoding: NSUTF8StringEncoding)
                } catch {
                    print("Failed to create file")
                    print("\(error)")
                }
            }
            indexWeatherFactor += 1
            if indexWeatherFactor == 5 {
                indexWeatherFactor = 0
                updateUI(indexCountry);
                indexCountry += 1
            }
            dowloadFiles(nil);
        }catch {/* error handling here */}
    }
    
    func updateUI(index:Int){
        dispatch_async(dispatch_get_main_queue()) {
            switch index {
            case 0:
                self.imageViewUK.hidden = false;
            case 1:
                self.imageViewEngland.hidden = false;
            case 2:
                self.imageViewWales.hidden = false;
            case 3:
                self.imageViewScotland.hidden = false;
            default:
                return;
            }
        }
    }
}

