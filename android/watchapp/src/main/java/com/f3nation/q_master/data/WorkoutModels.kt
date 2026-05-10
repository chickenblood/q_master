package com.f3nation.q_master.data

import java.io.Serializable

/**
 * Represents a section within a workout (e.g., "Warmup", "The Thang").
 * Mirrors the Dart 'WorkoutSection' definition.
 *
 * @property name The display name of the section.
 * @property exercises The list of exercise descriptions in this section.
 */
data class WorkoutSection(val name: String, val exercises: List<String>) : Serializable

/**
 * Represents a full F3 workout routine.
 * Mirrors the Dart 'Workout' definition.
 *
 * @property name The name of the workout.
 * @property date The scheduled date of the workout.
 * @property sections The ordered list of sections that make up this workout.
 */
data class Workout(
    val name: String,
    val date: String,
    val sections: List<WorkoutSection>
) : Serializable

/**
 * Extension function to convert a raw Map received from the phone app (via Wearable Data Layer)
 * into a type-safe [Workout] object.
 *
 * @return A [Workout] instance, using "Bad data" placeholders if required keys are missing.
 */
fun Map<*, *>.toWorkout(): Workout {
    val badData = "Bad data"
    val sections = ((this["sections"] as? List<*>) ?: emptyList<Any>())
        .filterIsInstance<Map<*, *>>()
        .map { sectionMap ->
            WorkoutSection(
                name = sectionMap["name"] as? String ?: "",
                exercises = (sectionMap["exercises"] as? List<*> ?: emptyList<String>())
                    .filterIsInstance<String>(),
            )
        }
    return Workout(
        name = this["name"] as? String ?: badData,
        date = this["date"] as? String ?: badData,
        sections = sections,
    )
}
