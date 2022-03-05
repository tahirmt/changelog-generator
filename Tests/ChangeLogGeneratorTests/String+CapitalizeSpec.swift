//
//  String+CapitalizeSpec.swift
//  
//
//  Created by Mahmood Tahir on 2021-09-09.
//

import Foundation
import Quick
import Nimble
@testable import ChangeLogGenerator

final class String_CapitalizeSpec: QuickSpec {
    override func spec() {
        super.spec()

        context("a String") {
            var subject: String!

            context("when empty") {
                beforeEach {
                    subject = ""
                }

                it("should remain empty") {
                    expect(subject.firstLetterCapitalized) == ""
                }
            }

            context("when lowercased") {
                beforeEach {
                    subject = "hello world"
                }

                it("should capitalize first letter of each word") {
                    expect(subject.firstLetterCapitalized) == "Hello World"
                }
            }

            context("when it has extra spaces") {
                beforeEach {
                    subject = "hello    world"
                }

                it("should ignore extra whitespaces") {
                    expect(subject.firstLetterCapitalized) == "Hello World"
                }
            }

            context("when it has capital letters") {
                beforeEach {
                    subject = "heLLO WORLD"
                }

                it("should keep capital letters intact") {
                    expect(subject.firstLetterCapitalized) == "HeLLO WORLD"
                }
            }
        }
    }
}
