package com.f3nation.q_master.data

import com.google.android.gms.wearable.DataEvent
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.DataItem
import com.google.android.gms.wearable.WearableListenerService
import java.io.ByteArrayInputStream
import java.io.ObjectInputStream

/**
 * A background service that listens for data changes from the handheld (phone) app.
 * This service is managed by the Wearable system and will be instantiated even if the
 * main UI activity is not running.
 *
 * It filters for the `/watch_connectivity` path and updates the [WorkoutRepository]
 * when new data is received.
 */
class WatchDataService : WearableListenerService() {

    /**
     * Triggered when the Wearable Data Layer detects a change in the data items
     * associated with this app's package.
     */
    override fun onDataChanged(dataEvents: DataEventBuffer) {
        try {
            dataEvents.forEach { event ->
                if (event.type == DataEvent.TYPE_CHANGED) {
                    val path = event.dataItem.uri.path
                    if (path == "/watch_connectivity") {
                        parseAndSaveData(event.dataItem)
                    }
                }
            }
        } catch (e: Exception) {
            WorkoutRepository.updateError("Error in onDataChanged", e.stackTraceToString())
        }
    }

    /**
     * Decodes the binary payload from a [DataItem] into a list of [Workout] objects.
     * The payload is expected to be a serialized Java Map (matching the format sent
     * by the Flutter 'watch_connectivity' plugin).
     */
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
                    WorkoutRepository.updateWorkouts(workouts)
                } else {
                    WorkoutRepository.updateError("Missing 'workouts' key", "Received: $receivedObject")
                }
            } else {
                WorkoutRepository.updateError("Invalid data format", "Expected Map, got: ${receivedObject?.javaClass?.name}")
            }
        } catch (e: Exception) {
            WorkoutRepository.updateError(e.message ?: "Unknown parsing error", e.stackTraceToString())
        }
    }
}
