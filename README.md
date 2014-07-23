EVCloudKitDao
=============

## What is this
EVCloudKitDao.swift is a class for simplified access to Apple's CloudKit

Before running this demo go to AppMessage target settings and fix the iCloud capabilities

This is a work in progress. Both Shift and CloudKit are in beta (this is tested with beta 4)

## Main features:
- simple singleton access to your default database
- You do not have to parse from and to CKRecord (is based on reflection)
- Generic and simplified query handling
- Error handling (seperate completionHandler and errorHandler code blocs)
- Storing CKReference objects
- Storing CKAsset objects
- Organising subscription

## Todo's'
- The object can not have nullable types because of a reflection problem (wait for Shift improvement or figure out a hack/workaround).
- All tests are now executed from the appdelegate. Convert this to a simple app

## How to use this
```swift
class Message : NSObject {
    var From : String = ""
    var To : String = ""
    var Text : String = ""
}

var dao: EVCloudKitDao = EVCloudKitDao.instance

var message = Message()
message.From = "me@me.com"
message.To = "you@me.com"
message.Text = "This is the message text"

dao.saveItem(message, completionHandler: {record in
        createdId = record.recordID.recordName;
        NSLog("saveItem : \(createdId)");
    }, errorHandler: {error in
        NSLog("<--- ERROR saveItem");
    })

dao.query(dao.recordType(Message()), completionHandler: { results in
        NSLog("query : result count = \(results.count)")
    }, errorHandler: { error in
        NSLog("<--- ERROR query Message")
    })
```

## License

MIT License

Copyright (c) 2014 EVICT B.V.

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the
Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.