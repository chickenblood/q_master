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

/// An ordered section of a workout with its exercises.
struct WorkoutSection: Codable {
  var name: String
  var exercises: [String]
}

/// A workout to mirror the definition  in workout.dart
struct Workout: Codable {
  var name: String
  var date: String
  var sections: [WorkoutSection]

  /// Create Workout from a map of values (synced from device).
  static func fromDict(dict: Dictionary<String, Any>) -> Workout {
    let badData = "Bad data"
    let name = dict["name"] as? String ?? badData
    let date = dict["date"] as? String ?? badData
    let sectionsData = (dict["sections"] as? [[String: Any]]) ?? []

    let sections = sectionsData.compactMap { sectionDict -> WorkoutSection? in
      guard let sectionName = sectionDict["name"] as? String,
            let items = sectionDict["exercises"] as? [String] else { return nil }
      return WorkoutSection(name: sectionName, exercises: items)
    }
    return Workout(name: name, date: date, sections: sections)
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
      workout.sections.flatMap { $0.exercises }
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

