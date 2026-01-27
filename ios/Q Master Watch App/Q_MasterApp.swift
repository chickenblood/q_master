//
//  Q_MasterApp.swift
//  Q Master Watch App
//
//  Created by Ian Wilkinson on 1/26/26.
//
import SwiftUI

@main
struct Q_Master_Watch_AppApp: App {
  var body: some Scene {
    WindowGroup {
#if os(watchOS)
      ContentView()
#else
      EmptyView()
#endif
    }
  }
}
