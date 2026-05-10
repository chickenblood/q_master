package com.f3nation.q_master.data

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * A thread-safe singleton repository that holds the current state of synced workouts.
 * This acts as the "Single Source of Truth" for the Wear OS application's UI.
 *
 * It uses [StateFlow] to allow Compose UI and ViewModels to reactively observe
 * updates pushed by the background [WatchDataService].
 */
object WorkoutRepository {
    private val _workouts = MutableStateFlow<List<Workout>>(emptyList())
    /** The current list of synchronized workouts. */
    val workouts: StateFlow<List<Workout>> = _workouts.asStateFlow()

    private val _errorMessage = MutableStateFlow<String?>(null)
    /** Any error message resulting from the last sync attempt. */
    val errorMessage: StateFlow<String?> = _errorMessage.asStateFlow()

    private val _debugInfo = MutableStateFlow<String?>(null)
    /** Detailed technical information/stack traces for debugging sync issues. */
    val debugInfo: StateFlow<String?> = _debugInfo.asStateFlow()

    /**
     * Updates the repository with a new list of workouts and clears any previous errors.
     *
     * @param newList The fresh list of workouts received from the phone.
     */
    fun updateWorkouts(newList: List<Workout>) {
        _workouts.value = newList
        _errorMessage.value = null
        _debugInfo.value = null
    }

    /**
     * Records an error that occurred during data synchronization.
     *
     * @param message A user-friendly error description.
     * @param debug Optional technical details or stack trace.
     */
    fun updateError(message: String?, debug: String? = null) {
        _errorMessage.value = message
        _debugInfo.value = debug
    }
}
