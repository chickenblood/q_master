package com.f3nation.q_master.data

import android.content.Context
import android.content.SharedPreferences
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
}
