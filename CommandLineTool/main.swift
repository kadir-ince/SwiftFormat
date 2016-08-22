//
//  SwiftFormat
//  main.swift
//
//  Version 0.1
//
//  Created by Nick Lockwood on 12/08/2016.
//  Copyright 2016 Charcoal Design
//
//  Distributed under the permissive zlib license
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/SwiftFormat
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//  claim that you wrote the original software. If you use this software
//  in a product, an acknowledgment in the product documentation would be
//  appreciated but is not required.
//
//  2. Altered source versions must be plainly marked as such, and must not be
//  misrepresented as being the original software.
//
//  3. This notice may not be removed or altered from any source distribution.
//

import Foundation

let version = "0.1"

func processInput(inputURL: NSURL, andWriteToOutput outputURL: NSURL, withOptions options: FormattingOptions) -> Int {
    let manager = NSFileManager.defaultManager()
    var filesWritten = 0
    var isDirectory: ObjCBool = false
    if manager.fileExistsAtPath(inputURL.path!, isDirectory: &isDirectory) {
        if isDirectory {
            if let files = try? manager.contentsOfDirectoryAtURL(inputURL, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions.SkipsHiddenFiles) {
                for url in files {
                    if var path = url.path {
                        let inputDirectory = inputURL.path ?? ""
                        let range = inputDirectory.startIndex ..< inputDirectory.endIndex
                        path.replaceRange(range, with: outputURL.path ?? "")
                        let outputDirectory = path.componentsSeparatedByString("/").dropLast().joinWithSeparator("/")
                        if (try? manager.createDirectoryAtPath(outputDirectory, withIntermediateDirectories: true, attributes: nil)) != nil {
                            filesWritten += processInput(url, andWriteToOutput: NSURL(fileURLWithPath: path), withOptions: options)
                        } else {
                            print("error: failed to create directory at: \(outputDirectory)")
                        }
                    }
                }
            } else {
                print("error: failed to read contents of directory at: \(inputURL.path!)")
            }
        } else if inputURL.pathExtension == "swift" {
            if let input = try? String(contentsOfURL: inputURL) {
                let output = format(input, options: options)
                if output != input {
                    if (try? output.writeToURL(outputURL, atomically: true, encoding: NSUTF8StringEncoding)) != nil {
                        filesWritten += 1
                    } else {
                        print("error: failed to write file: \(outputURL.path!)")
                    }
                }
            } else {
                print("error: failed to read file: \(inputURL.path!)")
            }
        }
    } else {
        print("error: file not found: \(inputURL.path!)")
    }
    return filesWritten
}

func preprocessArguments(args: [String], _ names: [String]) -> [String: String]? {
    var quoted = false
    var anonymousArgs = 0
    var namedArgs: [String: String] = [:]
    var name = ""
    for arg in args {
        if arg.hasPrefix("--") {
            // Long argument names
            let key = arg.substringFromIndex(arg.startIndex.advancedBy(2))
            if !names.contains(key) {
                print("error: unknown argument: \(arg).")
                return nil
            }
            name = key
            namedArgs[name] = ""
        } else if arg.hasPrefix("-") {
            // Short argument names
            let flag = arg.substringFromIndex(arg.startIndex.advancedBy(1))
            let matches = names.filter { $0.hasPrefix(flag) }
            if matches.count > 1 {
                print("error: ambiguous argument: -\(flag).")
                return nil
            } else if matches.count == 0 {
                print("error: unknown argument: -\(flag).")
                return nil
            } else {
                name = matches[0]
                namedArgs[name] = ""
            }
        } else {
            if name == "" {
                // Argument is anonymous
                name = String(anonymousArgs)
                anonymousArgs += 1
            }
            // Handle quotes and spaces
            var arg = arg
            var unterminated = false
            if quoted  {
                if arg.hasSuffix("\"") {
                    arg = arg.substringToIndex(arg.endIndex.advancedBy(-1))
                    unterminated = false
                    quoted = false
                }
            } else if arg.hasPrefix("\"") {
                quoted = true
                unterminated = true
            } else if arg.hasSuffix("\\") {
                arg = arg.substringToIndex(arg.endIndex.advancedBy(-1)) + " "
            }
            if quoted {
                arg = arg.stringByReplacingOccurrencesOfString("\\\"", withString: "\"")
            }
            namedArgs[name] = (namedArgs[name] ?? "") + arg
            if !unterminated {
                name = ""
            }
        }
    }
    return namedArgs
}

func processArguments(args: [String]) {
    guard let args = preprocessArguments(args, [
        "output",
        "indent",
        "help",
        "version",
    ]) else {
        return
    }
    
    // Version
    if args["version"] != nil {
        print("swiftformat, version \(version)")
        return
    }
    
    // Get input / output paths
    let inputPath = args["1"]
    let outputPath = args["output"] ?? inputPath
    
    // Show help if requested specifically or if no arguments are passed
    if args["help"] != nil || inputPath == nil {
        print("swiftformat, version \(version)")
        print("copyright (c) 2016 Nick Lockwood")
        print("")
        print("usage: swiftformat <file> [-o path] [-i spaces]")
        print("")
        print("  <file>         input file or directory path")
        print("  -o, --output   output path (defaults to input path)")
        print("  -i, --indent   number of spaces to indent, or \"tab\" to use tabs")
        print("  -h, --help     this help page")
        print("  -v, --version  version information")
        print("")
        return
    }
    
    print("running swiftformat...")
    
    // Convert paths to file URLs relative to current directory
    let directoryURL = NSURL(fileURLWithPath: NSFileManager.defaultManager().currentDirectoryPath)
    let inputURL = NSURL(fileURLWithPath: inputPath!, relativeToURL: directoryURL)
    let outputURL = NSURL(fileURLWithPath: outputPath!, relativeToURL: directoryURL)
    
    // Get options
    var options = FormattingOptions()
    if let indent = args["indent"] {
        if indent == "tabs" || indent == "tab" {
            options.indent = "\t"
        } else if let spaces = Int(indent) {
            options.indent = String(count: spaces, repeatedValue: (" " as Character))
        } else {
            print("error: unsupported indent value: \(indent).")
            return
        }
    }
    
    // Format the code
    let filesWritten = processInput(inputURL, andWriteToOutput: outputURL, withOptions: options)
    print("swiftformat completed. \(filesWritten) file(s) updated.")
}

processArguments(Process.arguments)
