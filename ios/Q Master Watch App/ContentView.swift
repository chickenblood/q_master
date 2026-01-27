//
//  ContentView.swift
//  Q Master Watch App
//
//  Created by Ian Wilkinson on 1/26/26.
//
#if os(watchOS)
import SwiftUI
import WatchConnectivity
import Dispatch
internal import Combine

struct Workout: Codable {
  var name: String
  var date: Date
  
  var warmup: [String]
  var thang: [String]
  var mary: [String]
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
      if let workouts = try decoder.decode(Array<Workout>.self, from: applicationContext["workouts"] as! Data) as [Workout]? {
        DispatchQueue.main.async {
          self.workouts = workouts
        }
      } else {
        debugPrint("No workouts")
      }
    } catch {
      debugPrint("Parsing error")
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
      Text(viewModel.workouts.first?.name ?? "")
    }
    .padding()
  }
}

#Preview {
  ContentView()
}
#endif
