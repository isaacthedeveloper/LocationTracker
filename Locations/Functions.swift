//
//  Functions.swift
//  Locations
//
//  Created by Isaac Ballas on 2019-09-03.
//  Copyright © 2019 Isaacballas. All rights reserved.
//

import Foundation
func afterDelay(_ seconds: Double, run: @escaping () -> Void) {
  DispatchQueue.main.asyncAfter(deadline: .now() + seconds,execute: run)
}
let applicationDocumentsDirectory: URL = {
  let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
  return paths[0]
}()
let CoreDataSaveFailedNotification = Notification.Name(rawValue: "CoreDataSaveFailedNotification")
func fatalCoreDataError(_ error: Error) {
  print(error)
  NotificationCenter.default.post(name: CoreDataSaveFailedNotification, object: nil)
}
