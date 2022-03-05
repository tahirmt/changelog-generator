//
//  URL+EquivalentSpec.swift
//  
//
//  Created by Mahmood Tahir on 2022-03-05.
//

import Foundation
import Quick
import Nimble
@testable import ChangeLogGenerator

final class URL_EquivalentSpec: QuickSpec {
    override func spec() {
        super.spec()

        context("a URL") {
            var subject: URL!

            beforeEach {
                subject = URL(string: "https://github.com/owner/repo?hello=world&test=value&other=otherValue")
            }

            it("should equal a copy") {
                let copy = URL(string: "https://github.com/owner/repo?hello=world&test=value&other=otherValue")
                expect(subject == copy) == true
                expect(subject.isEquivalent(to: copy)) == true
            }

            it("should be equivalent if query parameters are in a different order") {
                let other = URL(string: "https://github.com/owner/repo?other=otherValue&hello=world&test=value")
                expect(subject == other) == false
                expect(subject.isEquivalent(to: other)) == true
            }
        }
    }
}
