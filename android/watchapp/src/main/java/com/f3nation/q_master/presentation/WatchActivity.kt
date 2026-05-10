/* While this template provides a good starting point for using Wear Compose, you can always
 * take a look at https://github.com/android/wear-os-samples/tree/main/ComposeStarter to find the
 * most up-to-date changes to the libraries and their usages.
 */

package com.f3nation.q_master.presentation

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
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
import com.f3nation.q_master.data.Workout
import com.f3nation.q_master.data.WorkoutRepository
import com.f3nation.q_master.data.WorkoutSection
import com.f3nation.q_master.data.toWorkout
import java.io.ByteArrayInputStream
import java.io.ObjectInputStream

class WorkoutsViewModel : ViewModel() {
    val workouts = WorkoutRepository.workouts
    val errorMessage = WorkoutRepository.errorMessage
    val debugInfo = WorkoutRepository.debugInfo
}

class WatchActivity : ComponentActivity() {
    private val viewModel = WorkoutsViewModel()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        WorkoutRepository.init(this)
        setContent {
            WearApp(viewModel)
        }
    }

    override fun onResume() {
        super.onResume()
        // Ensure Repository is initialized (in case service started it first)
        WorkoutRepository.init(this)

        // Get previously-synced data for initial load
        val dataClient = Wearable.getDataClient(this)
        dataClient.dataItems.addOnSuccessListener { dataItemBuffer ->
            try {
                for (i in 0 until dataItemBuffer.count) {
                    val item = dataItemBuffer.get(i)
                    if (item.uri.path == "/watch_connectivity") {
                        parseData(item)
                    }
                }
            } catch (e: Exception) {
                WorkoutRepository.updateError("Error loading buffered data", e.stackTraceToString())
            } finally {
                dataItemBuffer.release()
            }
        }
    }

    private fun parseData(dataItem: DataItem) {
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
                }
            }
        } catch (e: Exception) {
            WorkoutRepository.updateError(e.message ?: "Unknown parsing error", e.stackTraceToString())
        }
    }
}

@Composable
fun WearApp(viewModel: WorkoutsViewModel) {
    val navController = rememberSwipeDismissableNavController()
    val workouts by viewModel.workouts.collectAsState()

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
                    if (index == null || index >= workouts.size) return@composable
                    val workout = workouts[index]

                    WorkoutListScreen(workout, onItemSelected = { section ->
                        navController.navigate("$index/section_list/$section")
                    })
                }

                // Screen 3: The Exercises List
                composable("{index}/section_list/{section}") { backStackEntry ->
                    val index = backStackEntry.arguments?.getString("index")?.toInt()
                    if (index == null || index >= workouts.size) return@composable
                    val workout = workouts[index]

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
    val workouts by viewModel.workouts.collectAsState()
    val errorMessage by viewModel.errorMessage.collectAsState()

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
            if (workouts.isNotEmpty()) {
                workouts.forEachIndexed { index, workout ->
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
                        text = if (errorMessage != null) 
                            "Sync Error: $errorMessage" 
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
    val errorMessage by viewModel.errorMessage.collectAsState()
    val debugInfo by viewModel.debugInfo.collectAsState()

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
                    text = "Error: ${errorMessage ?: "None"}",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.error
                )
            }
            item {
                Text(
                    text = "Details: ${debugInfo ?: "No additional info"}",
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
    WorkoutRepository.updateWorkouts(stockContent)
    val viewModel = WorkoutsViewModel()
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
