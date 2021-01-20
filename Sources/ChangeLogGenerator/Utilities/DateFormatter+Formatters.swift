//
//  DateFormatter+Formatters.swift
//  
//
//  Created by Mahmood Tahir on 2021-01-19.
//

import Foundation

extension DateFormatter {
    static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "y-MM-dd'T'HH:mm:ss'Z'"
        return formatter
    }()
}
