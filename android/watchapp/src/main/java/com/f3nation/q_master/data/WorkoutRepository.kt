package com.f3nation.q_master.data

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.ObjectInputStream
import java.io.ObjectOutputStream
import java.util.Base64

/**
 * A thread-safe singleton repository that holds the current state of synced workouts.
 * This acts as the "Single Source of Truth" for the Wear OS application's UI.
 *
 * Includes disk persistence to ensure workouts are available even after process death.
 */
object WorkoutRepository {
    private const val PREFS_NAME = "workout_prefs"
    private const val KEY_WORKOUTS = "saved_workouts"
    private const val TAG = "WorkoutRepository"

    private val _workouts = MutableStateFlow<List<Workout>>(emptyList())
    val workouts: StateFlow<List<Workout>> = _workouts.asStateFlow()

    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessage: StateFlow<String?> = _errorMessage.asStateFlow()

    private val _debugInfo = MutableStateFlow<String?>(null)
    val debugInfo: StateFlow<String?> = _debugInfo.asStateFlow()

    private var prefs: SharedPreferences? = null

    /** Initializes the repository with a context to enable disk persistence. */
    fun init(context: Context) {
        if (prefs != null) return
        prefs = context.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        loadFromDisk()
    }

    /** Updates the repository and persists the new list to disk. */
    fun updateWorkouts(newList: List<Workout>) {
        _workouts.value = newList
        _errorMessage.value = null
        _debugInfo.value = null
        saveToDisk(newList)
    }

    /** Populates the repository with stock/sample data. Does NOT persist to disk to allow future syncs to be 'clean'. */
    fun useSampleData() {
        Log.d(TAG, "Populating UI with sample data (disconnected and empty)")
        _workouts.value = stockContent
    }

    fun updateError(message: String?, debug: String? = null) {
        _errorMessage.value = message
        _debugInfo.value = debug
    }

    private fun saveToDisk(workouts: List<Workout>) {
        try {
            val baos = ByteArrayOutputStream()
            val oos = ObjectOutputStream(baos)
            oos.writeObject(ArrayList(workouts))
            val encoded = Base64.getEncoder().encodeToString(baos.toByteArray())
            prefs?.edit()?.putString(KEY_WORKOUTS, encoded)?.apply()
        } catch (e: Exception) {
            // Silently fail disk persistence; memory state is still updated
        }
    }

    private fun loadFromDisk() {
        val encoded = prefs?.getString(KEY_WORKOUTS, null) ?: return
        try {
            val bytes = Base64.getDecoder().decode(encoded)
            val bis = ByteArrayInputStream(bytes)
            val ois = ObjectInputStream(bis)
            @Suppress("UNCHECKED_CAST")
            val saved = ois.readObject() as? List<Workout>
            if (saved != null) {
                _workouts.value = saved
            }
        } catch (e: Exception) {
            _errorMessage.value = "Failed to load cached workouts"
        }
    }

    private val warmupExercises = listOf(
        "20 Side Straddle Hops (IC)",
        "15 Imperial Walkers (IC)",
        "10 Weed Pickers (IC)",
        "15 Copperhead Squats",
        "10 Michael Phelps"
    )
    private val thangExercises = listOf(
        "20 Merkins",
        "15 Burpees",
        "20 Carolina Dry Docks",
        "30 Big Boy Sit-ups",
        "20 Mountain Climbers",
        "15 Diamond Merkins",
        "20 Bonnie Blairs",
        "15 Curb Dips",
        "20 Lunges"
    )
    private val maryExercises = listOf(
        "20 Little Baby Crunches (IC)",
        "20 Flutter Kicks (IC)",
        "15 Freddy Mercurys (IC)",
        "20 American Hammers (IC)",
        "15 Hello Dollys",
        "20 Rosalitas",
        "1 min Plank"
    )

    private val sampleSections = listOf(
        WorkoutSection("Warmup", warmupExercises),
        WorkoutSection("The Thang", thangExercises),
        WorkoutSection("Mary", maryExercises),
    )

    private val stockContent = listOf(
        Workout("The Gloom @ The Swamp", "Sun 06 Jun 2026 · 05:30", sampleSections),
        Workout("Iron Horse Beatdown", "Tue 08 Jun 2026 · 05:30", sampleSections),
        Workout("Shark Tank Sufferfest", "Wed 10 Jun 2026 · 05:30", sampleSections),
        Workout("The Forge", "Fri 12 Jun 2026 · 05:30", sampleSections),
        Workout("Sunday Ruck", "Sun 14 Jun 2026 · 06:00", sampleSections),
    )
}
