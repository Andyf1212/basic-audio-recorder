//
//  Extensions.swift
//  basicRecorder
//
//  Created by Andy Freeman on 3/27/22.
//

import Foundation

extension Date {
    func toString (dateFormat format : String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
}
