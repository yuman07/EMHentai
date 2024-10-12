//
//  AFSession+Tools.swift
//  EMHenTai
//
//  Created by yuman on 2024/7/29.
//

import Alamofire
import Foundation

let emSession: Session = {
    let configuration = URLSessionConfiguration.af.default
    configuration.timeoutIntervalForRequest = 10
    return Session(configuration: configuration)
}()
