//
//  FormatterTests.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 30/08/2016.
//  Copyright 2016 Nick Lockwood
//
//  Distributed under the permissive MIT license
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/SwiftFormat
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import SwiftFormat
import XCTest

class FormatterTests: XCTestCase {
    func testRemoveCurrentTokenWhileEnumerating() {
        let input: [Token] = [
            .identifier("foo"),
            .identifier("bar"),
            .identifier("baz"),
        ]
        var output: [Token] = []
        let formatter = Formatter(input, options: .default)
        formatter.forEachToken { i, token in
            output.append(token)
            if i == 1 {
                formatter.removeToken(at: i)
            }
        }
        XCTAssertEqual(output, input)
    }

    func testRemovePreviousTokenWhileEnumerating() {
        let input: [Token] = [
            .identifier("foo"),
            .identifier("bar"),
            .identifier("baz"),
        ]
        var output: [Token] = []
        let formatter = Formatter(input, options: .default)
        formatter.forEachToken { i, token in
            output.append(token)
            if i == 1 {
                formatter.removeToken(at: i - 1)
            }
        }
        XCTAssertEqual(output, input)
    }

    func testRemoveNextTokenWhileEnumerating() {
        let input: [Token] = [
            .identifier("foo"),
            .identifier("bar"),
            .identifier("baz"),
        ]
        var output: [Token] = []
        let formatter = Formatter(input, options: .default)
        formatter.forEachToken { i, token in
            output.append(token)
            if i == 1 {
                formatter.removeToken(at: i + 1)
            }
        }
        XCTAssertEqual(output, [Token](input.dropLast()))
    }

    func testIndexBeforeComment() {
        let input: [Token] = [
            .identifier("foo"),
            .startOfScope("//"),
            .space(" "),
            .commentBody("bar"),
            .linebreak("\n"),
        ]
        let formatter = Formatter(input, options: .default)
        let index = formatter.index(before: 4, where: { !$0.isSpaceOrComment })
        XCTAssertEqual(index, 0)
    }

    func testIndexBeforeMultilineComment() {
        let input: [Token] = [
            .identifier("foo"),
            .startOfScope("/*"),
            .space(" "),
            .commentBody("bar"),
            .space(" "),
            .endOfScope("*/"),
            .linebreak("\n"),
        ]
        let formatter = Formatter(input, options: .default)
        let index = formatter.index(before: 6, where: { !$0.isSpaceOrComment })
        XCTAssertEqual(index, 0)
    }

    // MARK: enable/disable directives

    func testDisableRule() {
        let input = "//swiftformat:disable spaceAroundOperators\nlet foo : Int=5;"
        let output = "// swiftformat:disable spaceAroundOperators\nlet foo : Int=5\n"
        XCTAssertEqual(try format(input, rules: FormatRules.default), output)
    }

    func testDisableAndReEnableRules() {
        let input = """
        // swiftformat:disable indent blankLinesBetweenScopes redundantSelf
        class Foo {
        let _foo = "foo"
        func foo() {
        print(self._foo)
        }
        }
        // swiftformat:enable indent redundantSelf
        class Bar {
        let _bar = "bar"
        func bar() {
        print(_bar)
        }
        }
        """
        let output = """
        // swiftformat:disable indent blankLinesBetweenScopes redundantSelf
        class Foo {
        let _foo = "foo"
        func foo() {
        print(self._foo)
        }
        }
        // swiftformat:enable indent redundantSelf
        class Bar {
            let _bar = "bar"
            func bar() {
                print(_bar)
            }
        }
        """
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testDisableAllRules() {
        let input = "//swiftformat:disable all\nlet foo : Int=5;"
        let output = "// swiftformat:disable all\nlet foo : Int=5;"
        XCTAssertEqual(try format(input, rules: FormatRules.default), output)
    }

    func testDisableAndReEnableAllRules() {
        let input = """
        // swiftformat:disable all
        class Foo {
        let _foo = "foo"
        func foo() {
        print(self._foo)
        }
        }
        // swiftformat:enable all
        class Bar {
        let _bar = "bar"
        func bar() {
        print(_bar)
        }
        }
        """
        let output = """
        // swiftformat:disable all
        class Foo {
        let _foo = "foo"
        func foo() {
        print(self._foo)
        }
        }
        // swiftformat:enable all
        class Bar {
            let _bar = "bar"
            func bar() {
                print(_bar)
            }
        }
        """
        XCTAssertEqual(try format(input + "\n", rules: FormatRules.default), output + "\n")
    }

    func testDisableAllRulesAndReEnableOneRule() {
        let input = "//swiftformat:disable all\nlet foo : Int=5;\n//swiftformat:enable linebreakAtEndOfFile"
        let output = "// swiftformat:disable all\nlet foo : Int=5;\n//swiftformat:enable linebreakAtEndOfFile\n"
        XCTAssertEqual(try format(input, rules: FormatRules.default), output)
    }
}
