/* While this template provides a good starting point for using Wear Compose, you can always
 * take a look at https://github.com/android/wear-os-samples/tree/main/ComposeStarter to find the
 * most up-to-date changes to the libraries and their usages.
 */

package com.f3nation.q_master.presentation

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
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

class WorkoutsViewModel : ViewModel() {
    val workouts = WorkoutRepository.workouts
    val errorMessage = WorkoutRepository.errorMessage
    val debugInfo = WorkoutRepository.debugInfo
}

class WatchActivity : ComponentActivity() {
    private val viewModel = WorkoutsViewModel()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Enable edge-to-edge support for Android 15+
        enableEdgeToEdge()
        WorkoutRepository.init(this)

        setContent {
            WearApp(viewModel)
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
                    }, onUseSampleData = {
                        WorkoutRepository.useSampleData()
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
private fun AppNameEdgeButton() {
    EdgeButton(
        onClick = {},
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

@Composable
fun MainListScreen(
    viewModel: WorkoutsViewModel,
    onItemSelected: (Int) -> Unit,
    onShowDebug: () -> Unit,
    onUseSampleData: () -> Unit
) {
    val listState = rememberTransformingLazyColumnState()
    val transformationSpec = rememberTransformationSpec()
    val workouts by viewModel.workouts.collectAsState()
    val errorMessage by viewModel.errorMessage.collectAsState()
    val currentErrorMessage = errorMessage

    ScreenScaffold(
        scrollState = listState,
        edgeButton = {
            AppNameEdgeButton()
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
                        text = if (currentErrorMessage != null)
                            stringResource(R.string.syncErrorText, currentErrorMessage)
                        else
                            stringResource(R.string.syncInstructionsText),
                        style = MaterialTheme.typography.bodySmall,
                        fontWeight = FontWeight.Bold,
                        textAlign = TextAlign.Center,
                        modifier = Modifier.padding(horizontal = 8.dp)
                    )
                }
                item {
                    Button(
                        onClick = onUseSampleData,
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(40.dp)
                            .padding(top = 4.dp)
                    ) {
                        Text(
                            text = stringResource(R.string.sampleBeatdownsButton),
                            style = MaterialTheme.typography.labelSmall
                        )
                    }
                }
            }
            if (currentErrorMessage != null) {
                item {
                    Button(
                        onClick = onShowDebug,
                        modifier = Modifier.fillMaxWidth().padding(top = 8.dp),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = MaterialTheme.colorScheme.errorContainer
                        )
                    ) {
                        Text(stringResource(R.string.showDebugInfoButton))
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
                    text = stringResource(R.string.debugInfoTitle),
                    style = MaterialTheme.typography.titleMedium,
                    modifier = Modifier.fillMaxWidth(),
                    textAlign = TextAlign.Center
                )
            }
            item {
                Text(
                    text = stringResource(
                        R.string.debugErrorText,
                        errorMessage ?: stringResource(R.string.noneLabel)
                    ),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.error
                )
            }
            item {
                Text(
                    text = stringResource(
                        R.string.debugDetailsText,
                        debugInfo ?: stringResource(R.string.noAdditionalInfoLabel)
                    ),
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
            AppNameEdgeButton()
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
            AppNameEdgeButton()
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
    val viewModel = androidx.compose.runtime.remember { WorkoutsViewModel() }
    WearApp(viewModel)
}
