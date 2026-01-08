import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:q_master/l10n/l10n.dart';
import 'package:q_master/utils/shared_app_prefs.dart';

import 'faces_constants.dart';

// Golden ratio (matches shader)
const double phi = 1.61803398875;

class DodecahedronShader extends StatefulWidget {
  const DodecahedronShader({super.key});
  @override
  State<DodecahedronShader> createState() => _DodecahedronShaderState();
}

class _DodecahedronShaderState extends State<DodecahedronShader>
    with SingleTickerProviderStateMixin {
  ui.FragmentProgram? _program;
  late final Ticker _ticker;
  var _time = 0.0;

  // rotation state (radians)
  // Initial rotation aligns face 0's normal [0, 1, phi] with camera direction [0, 0, 1]
  var _ax = -math.atan(1 / phi), _ay = 0.0, _az = 0.0;
  // view offset angles (animated during snap to align face)
  var _viewAx = 0.0, _viewAy = 0.0, _viewAz = 0.0;
  // angular velocities (radians/sec)
  var _vx = 0.0, _vy = 0.0, _vz = 0.0;
  // damping (per second) and thresholds (editable)
  var _damping = 1.0;
  static const double _velocityEpsilon = 0.001;

  // user-tunable controls
  var _impulseStrength = 2.0;
  var _showControls = false;
  var _snapVelocityThreshold = 0.01;

  // bookkeeping for per-tick dt
  var _lastTick = 0.0;

  // center label shown when face is selected (persists until next tap)
  String? _centerLabel;
  var _centerLabelStart = 0.0;
  final double _centerLabelFadeDuration = 0.18;

  // label atlas used by shader (rendered once from strings)
  ui.Image? _labelAtlas;

  // spinning state
  var _isSpinning = false;
  final double _labelSizeMultiplier = 3.0;

  // snap animation state
  final bool _isSnapping = false;
  int _snapFaceIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerLabel = L10n.of(context)!.dodTapToStartMessage;
    });
    ui.FragmentProgram.fromAsset('shaders/dodecahedron.frag').then((p) async {
      // build a label atlas once the program is loaded
      final atlas = await _buildLabelAtlas(dodFaceExercises);
      setState(() {
        _program = p;
        _labelAtlas = atlas;
      });
    });
    _ticker = createTicker((d) {
      final t = d.inMilliseconds / 1000.0;
      final dt = _lastTick == 0.0 ? (t - _time) : (t - _lastTick);
      _lastTick = t;

      // integrate velocities -> angles with exponential damping
      if (dt > 0 && !_isSnapping) {
        final decay = math.exp(-_damping * dt);
        _vx *= decay;
        _vy *= decay;
        _vz *= decay;

        // clamp small velocities to zero to avoid floating drift
        if (_vx.abs() < _snapVelocityThreshold) _vx = 0.0;
        if (_vy.abs() < _snapVelocityThreshold) _vy = 0.0;
        if (_vz.abs() < _snapVelocityThreshold) _vz = 0.0;

        // update angles when there's meaningful motion
        final hasMotion = _vx != 0.0 || _vy != 0.0 || _vz != 0.0;
        if (hasMotion) {
          _ax += _vx * dt;
          _ay += _vy * dt;
          _az += _vz * dt;
        }

        // detect spinning -> slowed below threshold: show label for aligned face
        final currentSpeed = math.max(
          _vx.abs(),
          math.max(_vy.abs(), _vz.abs()),
        );
        final currentlySpinning = currentSpeed > _snapVelocityThreshold;
        if (currentlySpinning) {
          _isSpinning = true;
        } else if (_isSpinning) {
          // we were spinning but now slowed below threshold
          // Clear all inertia
          _vx = _vy = _vz = 0.0;
          _isSpinning = false;

          // Calculate which face is most aligned and show its label
          final snapResult = _calculateSnapTarget();
          _snapFaceIndex = snapResult.faceIndex;
          _centerLabel = dodFaceExercises[_snapFaceIndex];
          _centerLabelStart = t;
        }
      }

      setState(() {
        _time = t;
      });

      // If we've come to rest (no angular velocity, not snapping) and any center-label fade-in
      // has completed (or none exists), stop the ticker to save CPU.
      final noVelocities = _vx == 0.0 && _vy == 0.0 && _vz == 0.0;
      final fadeInPending =
          _centerLabel != null &&
          ((t - _centerLabelStart) < _centerLabelFadeDuration);
      if (noVelocities && !_isSnapping && !fadeInPending && _ticker.isActive) {
        _ticker.stop();
      }
    })..start();

    // load any saved slider defaults for this control
    final prefs = SharedAppPrefs.instance;
    setState(() {
      _impulseStrength = prefs.dodecahedronImpulse.value;
      _damping = prefs.dodecahedronDamping.value;
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _labelAtlas?.dispose();
    super.dispose();
  }

  // Dodecahedron face normals (same as in shader)
  static final List<List<double>> _faceNormals = [
    [0.0, 1.0, phi],
    [0.0, -1.0, phi],
    [0.0, 1.0, -phi],
    [0.0, -1.0, -phi],
    [1.0, phi, 0.0],
    [-1.0, phi, 0.0],
    [1.0, -phi, 0.0],
    [-1.0, -phi, 0.0],
    [phi, 0.0, 1.0],
    [-phi, 0.0, 1.0],
    [phi, 0.0, -1.0],
    [-phi, 0.0, -1.0],
  ];

  // Helper to normalize a 3D vector
  List<double> _normalize(List<double> v) {
    final len = math.sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2]);
    if (len == 0) return [0.0, 0.0, 0.0];
    return [v[0] / len, v[1] / len, v[2] / len];
  }

  // 3x3 rotation matrix builders
  // GLSL mat3(a,b,c,d,e,f,g,h,i) fills column-by-column: col0=(a,b,c), col1=(d,e,f), col2=(g,h,i)
  // We store row-major, so we need to transpose the GLSL definition.
  // GLSL rotX: mat3(1,0,0, 0,c,-s, 0,s,c) -> cols: (1,0,0), (0,c,-s), (0,s,c)
  // As row-major: rows are (1,0,0), (0,c,s), (0,-s,c)
  List<double> _rotX(double a) {
    final c = math.cos(a), s = math.sin(a);
    return [1.0, 0.0, 0.0, 0.0, c, s, 0.0, -s, c];
  }

  // GLSL rotY: mat3(c,0,s, 0,1,0, -s,0,c) -> cols: (c,0,s), (0,1,0), (-s,0,c)
  // As row-major: rows are (c,0,-s), (0,1,0), (s,0,c)
  List<double> _rotY(double a) {
    final c = math.cos(a), s = math.sin(a);
    return [c, 0.0, -s, 0.0, 1.0, 0.0, s, 0.0, c];
  }

  // GLSL rotZ: mat3(c,-s,0, s,c,0, 0,0,1) -> cols: (c,-s,0), (s,c,0), (0,0,1)
  // As row-major: rows are (c,s,0), (-s,c,0), (0,0,1)
  List<double> _rotZ(double a) {
    final c = math.cos(a), s = math.sin(a);
    return [c, s, 0.0, -s, c, 0.0, 0.0, 0.0, 1.0];
  }

  // Multiply 3x3 matrices
  List<double> _mulMatMat(List<double> a, List<double> b) {
    return [
      a[0] * b[0] + a[1] * b[3] + a[2] * b[6],
      a[0] * b[1] + a[1] * b[4] + a[2] * b[7],
      a[0] * b[2] + a[1] * b[5] + a[2] * b[8],
      a[3] * b[0] + a[4] * b[3] + a[5] * b[6],
      a[3] * b[1] + a[4] * b[4] + a[5] * b[7],
      a[3] * b[2] + a[4] * b[5] + a[5] * b[8],
      a[6] * b[0] + a[7] * b[3] + a[8] * b[6],
      a[6] * b[1] + a[7] * b[4] + a[8] * b[7],
      a[6] * b[2] + a[7] * b[5] + a[8] * b[8],
    ];
  }

  // Multiply 3x3 matrix by vec3
  List<double> _mulMatVec(List<double> m, List<double> v) {
    return [
      m[0] * v[0] + m[1] * v[1] + m[2] * v[2],
      m[3] * v[0] + m[4] * v[1] + m[5] * v[2],
      m[6] * v[0] + m[7] * v[1] + m[8] * v[2],
    ];
  }

  // Dot product
  double _dot(List<double> a, List<double> b) =>
      a[0] * b[0] + a[1] * b[1] + a[2] * b[2];

  // Cross product
  List<double> _cross(List<double> a, List<double> b) => [
    a[1] * b[2] - a[2] * b[1],
    a[2] * b[0] - a[0] * b[2],
    a[0] * b[1] - a[1] * b[0],
  ];

  // Calculate snap target: find the face most aligned with camera and snap to it
  ({int faceIndex, double deltaAx, double deltaAy, double deltaAz})
  _calculateSnapTarget() {
    // The shader does: pRot = R * p, then finds argmax_i dot(n_i, pRot)
    // For center of screen, p ≈ [0, 0, 1] (front surface point)
    // So face at center = argmax_i dot(n_i, R * [0,0,1])
    const frontPoint = [0.0, 0.0, 1.0];

    final combinedAx = _ax + _viewAx;
    final combinedAy = _ay + _viewAy;
    final combinedAz = _az + _viewAz;

    final rX = _rotX(combinedAx);
    final rY = _rotY(combinedAy);
    final rZ = _rotZ(combinedAz);
    final rZY = _mulMatMat(rZ, rY);
    final rot = _mulMatMat(rZY, rX);

    final rotatedFrontPoint = _mulMatVec(rot, frontPoint);

    // Find face most aligned with the rotated front point (same as shader)
    int bestFaceIndex = 0;
    double bestDot = -2.0;
    for (int i = 0; i < _faceNormals.length; i++) {
      final normal = _normalize(_faceNormals[i]);
      final d = _dot(normal, rotatedFrontPoint);
      if (d > bestDot) {
        bestDot = d;
        bestFaceIndex = i;
      }
    }

    // Now compute the rotation to perfectly align this face
    // We want: n_bestFace = R_new * [0,0,1]
    // Currently: n_bestFace ≈ R * [0,0,1] (approximately)
    // We need to find additional rotation to make it exact

    final targetNormal = _normalize(_faceNormals[bestFaceIndex]);

    // Compute rotation from rotatedFrontPoint to targetNormal
    final axis = _cross(rotatedFrontPoint, targetNormal);
    final axisLen = math.sqrt(_dot(axis, axis));
    final cosAngle = _dot(rotatedFrontPoint, targetNormal).clamp(-1.0, 1.0);
    final angle = math.acos(cosAngle);

    if (axisLen < 1e-6 || angle < 1e-6) {
      // Already aligned
      return (
        faceIndex: bestFaceIndex,
        deltaAx: 0.0,
        deltaAy: 0.0,
        deltaAz: 0.0,
      );
    }

    // Build Rodrigues rotation matrix
    final k = [axis[0] / axisLen, axis[1] / axisLen, axis[2] / axisLen];
    final c = math.cos(angle);
    final s = math.sin(angle);
    final t = 1.0 - c;

    final alignRot = [
      c + k[0] * k[0] * t,
      k[0] * k[1] * t - k[2] * s,
      k[0] * k[2] * t + k[1] * s,
      k[1] * k[0] * t + k[2] * s,
      c + k[1] * k[1] * t,
      k[1] * k[2] * t - k[0] * s,
      k[2] * k[0] * t - k[1] * s,
      k[2] * k[1] * t + k[0] * s,
      c + k[2] * k[2] * t,
    ];

    // New rotation = alignRot * rot
    final targetRot = _mulMatMat(alignRot, rot);

    // Extract Euler angles from targetRot
    final sinAy = (-targetRot[6]).clamp(-1.0, 1.0);
    var ay = math.asin(sinAy);
    final cosAy = math.cos(ay);

    double ax, az;
    if (cosAy.abs() > 1e-6) {
      ax = math.atan2(targetRot[7], targetRot[8]);
      az = math.atan2(targetRot[3], targetRot[0]);
    } else {
      az = 0.0;
      ax = math.atan2(-targetRot[5], targetRot[4]);
    }

    // Normalize to be close to current angles
    while (ax - combinedAx > math.pi) {
      ax -= 2 * math.pi;
    }
    while (ax - combinedAx < -math.pi) {
      ax += 2 * math.pi;
    }
    while (ay - combinedAy > math.pi) {
      ay -= 2 * math.pi;
    }
    while (ay - combinedAy < -math.pi) {
      ay += 2 * math.pi;
    }
    while (az - combinedAz > math.pi) {
      az -= 2 * math.pi;
    }
    while (az - combinedAz < -math.pi) {
      az += 2 * math.pi;
    }

    return (
      faceIndex: bestFaceIndex,
      deltaAx: ax - combinedAx,
      deltaAy: ay - combinedAy,
      deltaAz: az - combinedAz,
    );
  }

  // build a label atlas texture containing each label rendered into a grid cell
  Future<ui.Image> _buildLabelAtlas(List<String> labels) async {
    const cols = 4;
    const rows = 3;
    const int atlasScale = 3; // higher = higher DPI atlas -> crisper text
    const baseCellW = 320; // logical pixels per cell at scale=1
    const baseCellH = 96;
    final cellW = baseCellW * atlasScale;
    final cellH = baseCellH * atlasScale;
    final width = cols * cellW;
    final height = rows * cellH;

    final recorder = ui.PictureRecorder();
    final c = Canvas(recorder);

    // clear
    final bgPaint = Paint()..color = const Color(0x00000000);
    c.drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      bgPaint,
    );

    final fontSize =
        14 * atlasScale; // keep visible size but render at higher DPI

    // stroke paint for crisp outline
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (atlasScale * 1.2)
      ..color = Colors.black;

    final fillStyle = TextStyle(
      color: Colors.white,
      fontSize: fontSize.toDouble(),
      fontWeight: FontWeight.bold,
    );

    final strokeStyle = TextStyle(
      foreground: strokePaint,
      fontSize: fontSize.toDouble(),
      fontWeight: FontWeight.bold,
    );

    for (var i = 0; i < labels.length && i < cols * rows; i++) {
      final col = i % cols;
      final row = i ~/ cols;
      final dx = (col * cellW).toDouble();
      final dy = (row * cellH).toDouble();

      // draw stroke first for crisp edges
      final strokeTp = TextPainter(
        text: TextSpan(text: labels[i], style: strokeStyle),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      strokeTp.layout(maxWidth: cellW - 28.0);
      strokeTp.paint(
        c,
        Offset(
          dx + (cellW - strokeTp.width) / 2,
          dy + (cellH - strokeTp.height) / 2,
        ),
      );

      final fillTp = TextPainter(
        text: TextSpan(text: labels[i], style: fillStyle),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      fillTp.layout(maxWidth: cellW - 28.0);
      fillTp.paint(
        c,
        Offset(
          dx + (cellW - fillTp.width) / 2,
          dy + (cellH - fillTp.height) / 2,
        ),
      );
    }

    final pic = recorder.endRecording();
    final img = await pic.toImage(width, height);
    return img;
  }

  @override
  Widget build(BuildContext context) {
    final prefs = SharedAppPrefs.instance;
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            // If a center label is shown, clear it and continue to start a spin.
            setState(() {
              _centerLabel = null;
            });

            // ignore taps while spinning
            if (_vx.abs() > _velocityEpsilon ||
                _vy.abs() > _velocityEpsilon ||
                _vz.abs() > _velocityEpsilon) {
              return;
            }

            // add an impulse to angular velocity to kick off a spin scaled by user control
            setState(() {
              // clear any previous selection when we start a new spin
              _centerLabel = null;
              // Fold view offset into object rotation before starting new spin
              _ax += _viewAx;
              _ay += _viewAy;
              _az += _viewAz;
              _viewAx = _viewAy = _viewAz = 0.0;
              // Randomize impulse direction for varied results
              final rng = math.Random();
              final baseX = 5.5 + rng.nextDouble() * 2.0; // 5.5 to 7.5
              final baseY = 3.5 + rng.nextDouble() * 2.0; // 3.5 to 5.5
              final baseZ = 2.5 + rng.nextDouble() * 2.0; // 2.5 to 4.5
              final signX = rng.nextBool() ? 1.0 : -1.0;
              final signY = rng.nextBool() ? 1.0 : -1.0;
              final signZ = rng.nextBool() ? 1.0 : -1.0;
              _vx += signX * baseX * _impulseStrength;
              _vy += signY * baseY * _impulseStrength;
              _vz += signZ * baseZ * _impulseStrength;
            });

            // reset tick bookkeeping and ensure the ticker is running so animation resumes
            _lastTick = 0.0;
            if (!_ticker.isActive) _ticker.start();
          },

          // double-tap toggles the controls overlay
          onDoubleTap: () => setState(() => _showControls = !_showControls),

          child: Stack(
            children: [
              CustomPaint(
                size: Size.infinite,
                painter: _program == null
                    ? _LoadingPainter()
                    : _ShaderPainter(
                        _program!,
                        _time,
                        MediaQuery.of(context).devicePixelRatio,
                        _ax + _viewAx,
                        _ay + _viewAy,
                        _az + _viewAz,
                        _labelSizeMultiplier,
                        _labelAtlas,
                      ),
              ),

              // centered overlay label (shown when a face is selected). Keep this in addition to the on-surface labels.
              if (_centerLabel != null)
                Center(
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity:
                          ((_time - _centerLabelStart) /
                                  _centerLabelFadeDuration)
                              .clamp(0.0, 1.0),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 28 * _labelSizeMultiplier,
                          vertical: 14 * _labelSizeMultiplier,
                        ),
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(0, 0, 0, 0.92),
                          borderRadius: BorderRadius.circular(
                            8 * _labelSizeMultiplier,
                          ),
                        ),
                        child: DefaultTextStyle(
                          style:
                              Theme.of(
                                context,
                              ).textTheme.headlineLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                shadows: const [
                                  Shadow(
                                    blurRadius: 8,
                                    color: Colors.black54,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ) ??
                              const TextStyle(
                                color: Colors.white,
                                fontSize: 44,
                                fontWeight: FontWeight.bold,
                              ),
                          child: Text(_centerLabel!, textAlign: .center),
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _showControls ? 1.0 : 0.0,
                  child: Card(
                    color: Colors.black.withAlpha(153),
                    elevation: 6,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Controls',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Impulse',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              SizedBox(
                                width: 120,
                                child: Slider(
                                  value: _impulseStrength,
                                  min: 0.0,
                                  max: 2.0,
                                  divisions: 20,
                                  label: _impulseStrength.toStringAsFixed(2),
                                  onChanged: (v) =>
                                      setState(() => _impulseStrength = v),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _impulseStrength.toStringAsFixed(2),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Damping',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              SizedBox(
                                width: 120,
                                child: Slider(
                                  value: _damping,
                                  min: 0.05,
                                  max: 3.0,
                                  divisions: 59,
                                  label: _damping.toStringAsFixed(2),
                                  onChanged: (v) =>
                                      setState(() => _damping = v),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _damping.toStringAsFixed(2),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),

                          // snap threshold control
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Snap threshold',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              SizedBox(
                                width: 120,
                                child: Slider(
                                  value: _snapVelocityThreshold,
                                  min: 0.0001,
                                  max: 0.01,
                                  divisions: 99,
                                  label: _snapVelocityThreshold.toStringAsFixed(
                                    4,
                                  ),
                                  onChanged: (v) => setState(
                                    () => _snapVelocityThreshold = v,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _snapVelocityThreshold.toStringAsFixed(4),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  prefs.dodecahedronImpulse.value =
                                      _impulseStrength;
                                  prefs.dodecahedronDamping.value = _damping;
                                  if (!mounted) return;
                                },
                                child: const Text(
                                  'Save Defaults',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  setState(() {
                                    _ax = _ay = _az = 0.0;
                                    _viewAx = _viewAy = _viewAz = 0.0;
                                    _vx = _vy = _vz = 0.0;
                                    _centerLabel = null;
                                    _impulseStrength =
                                        prefs.dodecahedronImpulse.value;
                                    _damping = prefs.dodecahedronDamping.value;
                                  });
                                  // stop the ticker since there's no motion or label to animate
                                  if (_ticker.isActive) _ticker.stop();
                                },
                                child: const Text(
                                  'Reset',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LoadingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final tp = TextPainter(
      text: const TextSpan(
        text: 'Loading shader…',
        style: TextStyle(color: Colors.white),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(
      canvas,
      Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ShaderPainter extends CustomPainter {
  final ui.FragmentProgram program;
  final double time;
  final double dpr;
  final double ax, ay, az;
  final double labelSizeMultiplier;
  final ui.Image? labelAtlas; // rendered atlas image containing all labels

  _ShaderPainter(
    this.program,
    this.time,
    this.dpr,
    this.ax,
    this.ay,
    this.az,
    this.labelSizeMultiplier,
    this.labelAtlas,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final shader = program.fragmentShader();
    // uniforms order must match appearance in shader
    shader.setFloat(0, size.width * dpr); // u_resolution.x
    shader.setFloat(1, size.height * dpr); // u_resolution.y
    shader.setFloat(2, time); // u_time
    shader.setFloat(3, ax); // u_angles.x
    shader.setFloat(4, ay); // u_angles.y
    shader.setFloat(5, az); // u_angles.z

    // set label atlas sampler if available (sampler index 0)
    if (labelAtlas != null) {
      shader.setImageSampler(0, labelAtlas!);
    }

    final paint = Paint()..shader = shader;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _ShaderPainter old) =>
      old.time != time ||
      old.ax != ax ||
      old.ay != ay ||
      old.az != az ||
      old.labelSizeMultiplier != labelSizeMultiplier;
}
