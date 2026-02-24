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

/// A workout to mirror the definition  in workout.dart
struct Workout: Codable {
  var name: String
  var date: String
  
  struct Exercise: Codable {
    var name: String
  }
  
  var warmup: [Exercise]
  var thang: [Exercise]
  var mary: [Exercise]
  
  /// Create Workout from a map of values (synced from device).
  static func fromDict(dict: Dictionary<String, Any>) -> Workout {
    let badData = "Bad data"
    let name = dict["name"] as? String ?? badData
    let date = dict["date"] as? String ?? badData
    let warmup = dict["warmup"] as? [[String : String]] ?? []
    let thang = dict["thang"] as? [[String : String]] ?? []
    let mary = dict["mary"] as? [[String : String]] ?? []
    return Workout(
      name: name, date: date,
      warmup: warmup.map { Workout.Exercise(name: $0["name"] ?? badData) },
      thang: thang.map { Workout.Exercise(name: $0["name"] ?? badData) },
      mary: mary.map { Workout.Exercise(name: $0["name"] ?? badData) }
    )
  }
}

extension Workout: Identifiable {
  var id: UUID { get { UUID() } }
}

extension String : @retroactive Identifiable {
  public var id: UUID { get { UUID() } }
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
  
  private func parseApplicationContext(applicationContext: [String : Any]) {
    guard let workoutsData = applicationContext["workouts"] as? Array<Dictionary<String, Any>> else { return }
    var workouts = Array<Workout>()
    for workoutData in workoutsData {
      let workout = Workout.fromDict(dict: workoutData)
      workouts.append(workout)
    }
    DispatchQueue.main.async {
      self.workouts = workouts
    }
  }
}

extension WorkoutListViewModel: WCSessionDelegate {
  internal func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
    parseApplicationContext(applicationContext: applicationContext)
  }
  
  internal func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {
    if activationState == .activated {
      parseApplicationContext(applicationContext: WCSession.default.receivedApplicationContext)
    }
  }
}

// Main view for the watch app.
struct ContentView: View {
  @StateObject var viewModel = WorkoutListViewModel()
  
  var body: some View {
    if !viewModel.workouts.isEmpty {
      NavigationStack {
        List(viewModel.workouts) { workout in
          NavigationLink(destination: DetailView(workout: workout)) {
            Text(workout.name)
          }
        }
        .font(.title2)
        .listStyle(.carousel)
        .navigationTitle(.workoutsTitle) // Set the title for the list view
      }
    } else {
      Text(.syncInstructionsText)
        .font(.callout .bold())
        .multilineTextAlignment(.center)
    }
  }
}

struct DetailView: View {
  let workout: Workout
  
  var workouts: [String] {
    get {
      let warmups = workout.warmup.compactMap { $0.name }
      let thangs = workout.thang.compactMap { $0.name }
      let marys = workout.mary.compactMap { $0.name }
      return warmups + thangs + marys
    }
  }
  
  var body: some View {
      List {
        ForEach(workouts) { exercise in
          Text(exercise)
        }
        .font(.title2)
        .listStyle(.carousel)
        .navigationTitle(workout.name)
      }
  }
}

#Preview {
  ContentView()
}

