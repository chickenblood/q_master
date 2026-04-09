/* While this template provides a good starting point for using Wear Compose, you can always
 * take a look at https://github.com/android/wear-os-samples/tree/main/ComposeStarter to find the
 * most up-to-date changes to the libraries and their usages.
 */

package com.f3nation.q_master.presentation

import android.annotation.SuppressLint
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.runtime.Composable
import androidx.compose.runtime.mutableStateOf
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
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
    private val _workouts = mutableStateOf(emptyList<Workout>())
    private val _errorMessage = mutableStateOf<String?>(null)

    fun setWorkouts(workouts: List<Workout>) {
        _workouts.value = workouts
    }

    val workouts: List<Workout>
        get() = _workouts.value

    fun setErrorMessage(message: String?) {
        _errorMessage.value = message
    }

    val errorMessage: String?
        get() = _errorMessage.value
}

class WatchActivity : ComponentActivity(), DataClient.OnDataChangedListener {
    val workoutKey = "workouts"
    val viewModel = WorkoutsViewModel()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            WearApp("Q Master", viewModel)
        }
    }

    override fun onResume() {
        super.onResume()
        // Register the listener to start receiving data updates
        val dataClient = Wearable.getDataClient(this);
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
                viewModel.setErrorMessage(e.message)
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
            viewModel.setErrorMessage(e.message)
        } finally {
            // Important: Release the buffer to prevent memory leaks
            dataEvents.release()
        }
    }

    private fun parseData(dataItem: DataItem) {
        if (dataItem.data == null) return;
        try {
            val bytes = dataItem.data!!
            val byteArrayInputStream = ByteArrayInputStream(bytes)
            val objectInputStream = ObjectInputStream(byteArrayInputStream)
            val map = objectInputStream.readObject() as Map<*, *>
            val workouts =
                (map["workouts"] as List<*>).map { it as Map<*, *> }.map { it.toWorkout() }
            viewModel.setWorkouts(workouts)
            viewModel.setErrorMessage(null)
        } catch (e: Exception) {
            println("Error parsing data: $e")
            viewModel.setErrorMessage(e.message)
            viewModel.setWorkouts(emptyList())
        }
    }
}

@Composable
fun WearApp(greetingName: String, viewModel: WorkoutsViewModel = WorkoutsViewModel()) {
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
                    val section = workout.sections[sectionIndex];

                    SectionListScreen(section)
                }
            }
        }
    }
}

@Composable
fun MainListScreen(viewModel: WorkoutsViewModel, onItemSelected: (Int) -> Unit) {
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
            } else if (viewModel.errorMessage != null) {
                item {
                    Text(text = viewModel.errorMessage!!)
                }
            } else {
                item {
                    Text(text = stringResource(R.string.syncInstructionsText),
                        fontWeight = FontWeight.Bold,
                        textAlign = TextAlign.Center)
                }
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

@SuppressLint("ViewModelConstructorInComposable")
@WearPreviewDevices
@WearPreviewFontScales
@Composable
fun DefaultPreview() {
    val viewModel = WorkoutsViewModel()
    viewModel.setWorkouts(stockContent)
    WearApp("Preview Android", viewModel)
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
