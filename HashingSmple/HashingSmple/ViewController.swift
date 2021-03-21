//
//  ViewController.swift
//  HashingSmple
//
//  Created by venus.janne on 2021/03/20.
//  Copyright © 2021 venus.janne. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func didTapPrepareButton(_ sender: UIButton) {
        self.saveToFile()
    }

    @IBAction func didTapHashButton(_ sender: UIButton) {
        guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {return}
        let fileUrl = dir.appendingPathComponent("file001.txt")
        let data = HashEdit.shared.loadFileAsBlock(number: 1, withBlockSize: 1000, path: fileUrl.absoluteString)
        guard let data2 = data else {return}
        let res = HashEdit.shared.hash(data2, ccType: .md5)
        print("md5 = \(res), data.count=\(data2.count)")

    }

}

extension ViewController {
    private func saveToFile() {
        let file = "file001.txt" // this is the file. we will write to and read from it

        let text = "some text" // just a text

        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {

            let fileURL = dir.appendingPathComponent(file)
            print("fileURL = \(fileURL)")

            // writing
            do {
                try text.write(to: fileURL, atomically: false, encoding: .utf8)
            } catch {/* error handling here */}

            // reading
            do {
                let text2 = try String(contentsOf: fileURL, encoding: .utf8)
            } catch {/* error handling here */}
        }

    }
}
