package com.f3nation.q_master.data

import android.util.Log
import com.google.android.gms.wearable.DataEvent
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.DataItem
import com.google.android.gms.wearable.WearableListenerService
import java.io.ByteArrayInputStream
import java.io.ObjectInputStream

private const val TAG = "WatchDataService"

/**
 * A background service that listens for data changes from the handheld (phone) app.
 */
class WatchDataService : WearableListenerService() {

    override fun onCreate() {
        super.onCreate()
        // Ensure repository is initialized with context for persistence
        WorkoutRepository.init(this)
        Log.d(TAG, "WatchDataService created")
    }

    override fun onDataChanged(dataEvents: DataEventBuffer) {
        Log.d(TAG, "onDataChanged: ${dataEvents.count} events received")
        try {
            dataEvents.forEach { event ->
                if (event.type == DataEvent.TYPE_CHANGED) {
                    val path = event.dataItem.uri.path
                    Log.d(TAG, "Processing data item with path: $path")
                    if (path == "/watch_connectivity") {
                        parseAndSaveData(event.dataItem)
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error processing data events", e)
            WorkoutRepository.updateError("Sync processing failed", e.stackTraceToString())
        } finally {
            // Releasing the buffer is essential to prevent memory leaks and sync stalls
            dataEvents.release()
        }
    }

    private fun parseAndSaveData(dataItem: DataItem) {
        val data = dataItem.data ?: return
        try {
            val byteArrayInputStream = ByteArrayInputStream(data)
            val objectInputStream = ObjectInputStream(byteArrayInputStream)
            val receivedObject = objectInputStream.readObject()

            if (receivedObject is Map<*, *>) {
                val workoutsMap = receivedObject["workouts"] as? List<*>
                if (workoutsMap != null) {
                    val workouts = workoutsMap
                        .filterIsInstance<Map<*, *>>()
                        .map { it.toWorkout() }
                    Log.d(TAG, "Parsed ${workouts.size} workouts successfully")
                    WorkoutRepository.updateWorkouts(workouts)
                } else {
                    Log.w(TAG, "Received map missing 'workouts' key")
                    WorkoutRepository.updateError("Data missing workouts list")
                }
            } else {
                Log.w(TAG, "Unexpected data format: ${receivedObject?.javaClass?.name}")
                WorkoutRepository.updateError("Invalid sync format")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Parsing error", e)
            WorkoutRepository.updateError("Data parsing failed", e.stackTraceToString())
        }
    }
}
