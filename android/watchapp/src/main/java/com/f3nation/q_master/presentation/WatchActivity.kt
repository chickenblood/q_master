/* While this template provides a good starting point for using Wear Compose, you can always
 * take a look at https://github.com/android/wear-os-samples/tree/main/ComposeStarter to find the
 * most up-to-date changes to the libraries and their usages.
 */

package com.f3nation.q_master.presentation

import android.annotation.SuppressLint
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.google.android.gms.wearable.DataClient
import com.google.android.gms.wearable.DataEvent
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.DataItem
import com.google.android.gms.wearable.Wearable
import androidx.wear.compose.foundation.lazy.TransformingLazyColumn
import androidx.wear.compose.foundation.lazy.rememberTransformingLazyColumnState
import androidx.wear.compose.material3.AppScaffold
import androidx.wear.compose.material3.Button
import androidx.wear.compose.material3.ButtonDefaults
import androidx.wear.compose.material3.EdgeButton
import androidx.wear.compose.material3.ListHeader
import androidx.wear.compose.material3.MaterialTheme
import androidx.wear.compose.material3.ScreenScaffold
import androidx.wear.compose.material3.SurfaceTransformation
import androidx.wear.compose.material3.Text
import androidx.wear.compose.material3.lazy.rememberTransformationSpec
import androidx.wear.compose.material3.lazy.transformedHeight
import androidx.wear.compose.ui.tooling.preview.WearPreviewDevices
import androidx.wear.compose.ui.tooling.preview.WearPreviewFontScales
import com.f3nation.q_master.R
import com.f3nation.q_master.presentation.theme.AndroidTheme
import androidx.lifecycle.ViewModel
import androidx.wear.compose.navigation.SwipeDismissableNavHost
import androidx.wear.compose.navigation.composable
import androidx.wear.compose.navigation.rememberSwipeDismissableNavController
import java.io.ByteArrayInputStream
import java.io.ObjectInputStream

/// A workout to mirror the definition  in workout.dart
/// An ordered section of a workout with its exercises.
data class WorkoutSection(val name: String, val exercises: List<String>)

/// A workout to mirror the definition  in workout.dart
data class Workout(
    val name: String,
    val date: String,
    val sections: List<WorkoutSection>
)

/// Converts a map to a workout.
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

class WorkoutsViewModel : ViewModel() {
    var workouts by mutableStateOf(emptyList<Workout>())
        private set

    var errorMessage by mutableStateOf<String?>(null)
        private set

    var debugInfo by mutableStateOf<String?>(null)
        private set

    fun setWorkoutsData(newWorkouts: List<Workout>) {
        workouts = newWorkouts
    }

    fun updateError(message: String?, debug: String? = null) {
        errorMessage = message
        debugInfo = debug
    }
}

class WatchActivity : ComponentActivity(), DataClient.OnDataChangedListener {
    val viewModel = WorkoutsViewModel()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            WearApp(viewModel)
        }
    }

    override fun onResume() {
        super.onResume()
        // Register the listener to start receiving data updates
        val dataClient = Wearable.getDataClient(this)
        dataClient.addListener(this)

        // Get previously-synced data
        dataClient.dataItems.addOnSuccessListener { dataItemBuffer ->
            try {
                for (i in 0 until dataItemBuffer.count) {
                    val item = dataItemBuffer.get(i)

                    // Check for your specific path
                    if (item.uri.path == "/watch_connectivity") {
                        parseData(item)
                    }
                }
            } catch (e: Exception) {
                viewModel.updateError("Error loading buffered data", e.stackTraceToString())
            } finally {
                // Important: Release the buffer to prevent memory leaks
                dataItemBuffer.release()
            }
        }
    }

    override fun onPause() {
        super.onPause()
        // Unregister the listener to save resources
        Wearable.getDataClient(this).removeListener(this)
    }

    override fun onDataChanged(dataEvents: DataEventBuffer) {
        println("DATA CHANGED")
        try {
            dataEvents.forEach { event ->
                // Check if data was changed (rather than deleted)
                if (event.type == DataEvent.TYPE_CHANGED) {
                    val path = event.dataItem.uri.path
                    if (path == "/watch_connectivity") {
                        parseData(event.dataItem)
                    }
                }
            }
        } catch (e: Exception) {
            viewModel.updateError("Error in onDataChanged", e.stackTraceToString())
        } finally {
            // Important: Release the buffer to prevent memory leaks
            dataEvents.release()
        }
    }

    private fun parseData(dataItem: DataItem) {
        val data = dataItem.data ?: return
        try {
            val bytes = data
            val byteArrayInputStream = ByteArrayInputStream(bytes)
            val objectInputStream = ObjectInputStream(byteArrayInputStream)
            val receivedObject = objectInputStream.readObject()
            
            if (receivedObject is Map<*, *>) {
                val workoutsMap = receivedObject["workouts"] as? List<*>
                if (workoutsMap != null) {
                    val workouts = workoutsMap
                        .filterIsInstance<Map<*, *>>()
                        .map { it.toWorkout() }
                    viewModel.setWorkoutsData(workouts)
                    viewModel.updateError(null)
                } else {
                    viewModel.updateError("Missing 'workouts' key", "Received: $receivedObject")
                }
            } else {
                viewModel.updateError("Invalid data format", "Expected Map, got: ${receivedObject?.javaClass?.name}")
            }
        } catch (e: Exception) {
            println("Error parsing data: $e")
            viewModel.updateError(e.message ?: "Unknown parsing error", e.stackTraceToString())
            viewModel.setWorkoutsData(emptyList())
        }
    }
}

@Composable
fun WearApp(viewModel: WorkoutsViewModel) {
    val navController = rememberSwipeDismissableNavController()

    AndroidTheme {
        AppScaffold {
            SwipeDismissableNavHost(
                navController = navController,
                startDestination = "main_list"
            ) {
                // Screen 1: The Workouts List
                composable("main_list") {
                    MainListScreen(viewModel, onItemSelected = { index ->
                        navController.navigate("workout_list/$index")
                    }, onShowDebug = {
                        navController.navigate("debug_info")
                    })
                }

                // Screen 2: The Section List
                composable("workout_list/{index}") { backStackEntry ->
                    val index = backStackEntry.arguments?.getString("index")?.toInt()
                    if (index == null || index >= viewModel.workouts.size) return@composable
                    val workout = viewModel.workouts[index]

                    WorkoutListScreen(workout, onItemSelected = { section ->
                        navController.navigate("$index/section_list/$section")
                    })
                }

                // Screen 3: The Exercises List
                composable("{index}/section_list/{section}") { backStackEntry ->
                    val index = backStackEntry.arguments?.getString("index")?.toInt()
                    if (index == null || index >= viewModel.workouts.size) return@composable
                    val workout = viewModel.workouts[index]

                    val sectionIndex = backStackEntry.arguments?.getString("section")?.toInt()
                    if (sectionIndex == null || sectionIndex >= workout.sections.size) return@composable
                    val section = workout.sections[sectionIndex]

                    SectionListScreen(section)
                }

                // Debug Screen
                composable("debug_info") {
                    DebugInfoScreen(viewModel)
                }
            }
        }
    }
}

@Composable
fun MainListScreen(
    viewModel: WorkoutsViewModel, 
    onItemSelected: (Int) -> Unit,
    onShowDebug: () -> Unit
) {
    val listState = rememberTransformingLazyColumnState()
    val transformationSpec = rememberTransformationSpec()
    ScreenScaffold(
        scrollState = listState,
        edgeButton = {
            EdgeButton(
                onClick = { /*TODO*/ },
                enabled = false,
                colors =
                    ButtonDefaults.buttonColors(
                        containerColor = MaterialTheme.colorScheme.secondaryContainer,
                        contentColor = MaterialTheme.colorScheme.onSecondaryContainer,
                    ),

                ) {
                Text(text = stringResource(R.string.app_name))
            }
        },
    ) { contentPadding ->
        TransformingLazyColumn(contentPadding = contentPadding, state = listState) {
            item {
                ListHeader(
                    modifier =
                        Modifier
                            .fillMaxWidth()
                            .transformedHeight(this, transformationSpec),
                    transformation = SurfaceTransformation(transformationSpec),
                ) {
                    Text(text = stringResource(R.string.workoutsTitle))
                }
            }
            if (viewModel.workouts.isNotEmpty()) {
                viewModel.workouts.forEachIndexed { index, workout ->
                    item {
                        Button(
                            onClick = { onItemSelected(index) },
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Text(text = workout.name)
                        }
                    }
                }
            } else {
                item {
                    Text(
                        text = if (viewModel.errorMessage != null) 
                            "Sync Error: ${viewModel.errorMessage}" 
                        else 
                            stringResource(R.string.syncInstructionsText),
                        fontWeight = FontWeight.Bold,
                        textAlign = TextAlign.Center,
                        modifier = Modifier.padding(horizontal = 8.dp)
                    )
                }
                item {
                    Button(
                        onClick = onShowDebug,
                        modifier = Modifier.fillMaxWidth().padding(top = 8.dp),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = MaterialTheme.colorScheme.errorContainer
                        )
                    ) {
                        Text("Show Debug Info")
                    }
                }
            }
        }
    }
}

@Composable
fun DebugInfoScreen(viewModel: WorkoutsViewModel) {
    val listState = rememberTransformingLazyColumnState()
    ScreenScaffold(scrollState = listState) { contentPadding ->
        TransformingLazyColumn(contentPadding = contentPadding, state = listState) {
            item {
                Text(
                    text = "Debug Info",
                    style = MaterialTheme.typography.titleMedium,
                    modifier = Modifier.fillMaxWidth(),
                    textAlign = TextAlign.Center
                )
            }
            item {
                Text(
                    text = "Error: ${viewModel.errorMessage ?: "None"}",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.error
                )
            }
            item {
                Text(
                    text = "Details: ${viewModel.debugInfo ?: "No additional info"}",
                    style = MaterialTheme.typography.labelSmall,
                    modifier = Modifier.padding(top = 4.dp)
                )
            }
        }
    }
}

@Composable
fun WorkoutListScreen(workout: Workout, onItemSelected: (Int) -> Unit) {
    val listState = rememberTransformingLazyColumnState()
    val transformationSpec = rememberTransformationSpec()
    ScreenScaffold(
        scrollState = listState,
        edgeButton = {
            EdgeButton(
                onClick = { /*TODO*/ },
                enabled = false,
                colors =
                    ButtonDefaults.buttonColors(
                        containerColor = MaterialTheme.colorScheme.secondaryContainer,
                        contentColor = MaterialTheme.colorScheme.onSecondaryContainer,
                    ),

                ) {
                Text(text = stringResource(R.string.app_name))
            }
        }
    ) { contentPadding -> // ScreenScaffold provides default padding; adjust as needed
        TransformingLazyColumn(contentPadding = contentPadding, state = listState) {
            item {
                ListHeader(
                    modifier =
                        Modifier
                            .fillMaxWidth()
                            .transformedHeight(this, transformationSpec),
                    transformation = SurfaceTransformation(transformationSpec),
                ) {
                    Text(text = workout.name)
                }
            }
            workout.sections.forEachIndexed { index, section ->
                item {
                    Button(
                        onClick = { onItemSelected(index) },
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text(text = section.name)
                    }
                }
            }
        }
    }
}

@Composable
fun SectionListScreen(section: WorkoutSection) {
    val listState = rememberTransformingLazyColumnState()
    val transformationSpec = rememberTransformationSpec()
    ScreenScaffold(
        scrollState = listState,
        edgeButton = {
            EdgeButton(
                onClick = { /*TODO*/ },
                enabled = false,
                colors =
                    ButtonDefaults.buttonColors(
                        containerColor = MaterialTheme.colorScheme.secondaryContainer,
                        contentColor = MaterialTheme.colorScheme.onSecondaryContainer,
                    ),

                ) {
                Text(text = stringResource(R.string.app_name))
            }
        }
    ) { contentPadding -> // ScreenScaffold provides default padding; adjust as needed
        TransformingLazyColumn(contentPadding = contentPadding, state = listState) {
            item {
                ListHeader(
                    modifier =
                        Modifier
                            .fillMaxWidth()
                            .transformedHeight(this, transformationSpec),
                    transformation = SurfaceTransformation(transformationSpec),
                ) {
                    Text(text = section.name)
                }
            }
            section.exercises.forEach { exercise ->
                item {
                    Button(
                        onClick = { },
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text(text = exercise)
                    }
                }
            }
        }
    }
}

@WearPreviewDevices
@WearPreviewFontScales
@Composable
fun DefaultPreview() {
    val viewModel = WorkoutsViewModel()
    viewModel.setWorkoutsData(stockContent)
    WearApp(viewModel)
}

val sampleExercises = listOf("30 high knees", "10 Bonnie Blairs", "20 side-shuttle hops")
val sampleSections = listOf(
    WorkoutSection("warmup", sampleExercises),
    WorkoutSection("thang", sampleExercises),
    WorkoutSection("mary", sampleExercises),
)
val stockContent = listOf(
    Workout("Workout 1", "Date 1", sampleSections),
    Workout("Workout 2", "Date 2", sampleSections),
    Workout("Workout 3", "Date 3", sampleSections),
    Workout("Workout 4", "Date 4", sampleSections),
    Workout("Workout 5", "Date 5", sampleSections),
)
