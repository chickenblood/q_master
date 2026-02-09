//
//  ContentView.swift
//  Q Master Watch App
//
//  Created by Ian Wilkinson on 1/26/26.
//
import SwiftUI
import WatchConnectivity
import Dispatch
internal import Combine

struct Workout: Codable {
  var name: String
  var date: String
  
  var warmup: [[String:String]]
  var thang: [[String:String]]
  var mary: [[String:String]]
}

class WorkoutListViewModel: NSObject, ObservableObject {
  @Published var workouts: [Workout] = []
  
  override init() {
    super.init()
    if WCSession.isSupported() {
      WCSession.default.delegate = self
      WCSession.default.activate()
    }
  }
}

extension WorkoutListViewModel: WCSessionDelegate {
  internal func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
    let decoder = JSONDecoder()
    do {
      let data = Data((applicationContext["workouts"] as! String).utf8)
      let workouts = try decoder.decode(Array<Workout>.self, from:data)
      if !workouts.isEmpty {
        DispatchQueue.main.async {
          self.workouts = workouts
        }
      } else {
        debugPrint("No workouts")
      }
    } catch {
      debugPrint("Parsing error \(error)")
    }
  }
  
  internal func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {}
}

// Main view for the watch app.
struct ContentView: View {
  @StateObject var viewModel = WorkoutListViewModel()
  
  var body: some View {
    VStack {
      Image(systemName: "globe")
        .imageScale(.large)
        .foregroundStyle(.tint)
      Text(viewModel.workouts.first?.name ?? "No workouts")
    }
    .padding()
  }
}

#Preview {
  ContentView()
}

