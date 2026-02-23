import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shake/shake.dart';

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
  // damping (per second) and thresholds
  static const _damping = 1.5;
  static const _impulseStrength = 3.0;
  static const _stopVelocityThreshold = 0.1;
  static const _velocityEpsilon = 0.001;

  ui.FragmentProgram? _program;
  late final Ticker _ticker;
  var _time = 0.0;
  Orientation? _lastOrientation;
  bool _isReloadingShader = false;

  // rotation state (radians)
  // Initial rotation aligns face 0's normal [0, 1, phi] with camera direction [0, 0, 1]
  var _ax = -math.atan(1 / phi), _ay = 0.0, _az = 0.0;
  // view offset angles (animated during snap to align face)
  var _viewAx = 0.0, _viewAy = 0.0, _viewAz = 0.0;
  // angular velocities (radians/sec)
  var _vx = 0.0, _vy = 0.0, _vz = 0.0;

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

  // highlight state (momentary red flash on selected face)
  int _highlightFaceIndex = -1; // -1 = no highlight
  var _highlightStartTime = 0.0;
  final _highlightDuration = 0.4; // seconds

  // snap-to-face animation state
  int _snapFaceIndex = -1; // which face to snap to (-1 = not snapping)
  var _snapStartTime = 0.0;
  final _snapDuration = 0.5; // seconds to animate to face alignment
  // Target rotation angles to align selected face
  var _snapTargetAx = 0.0, _snapTargetAy = 0.0, _snapTargetAz = 0.0;

  late final ShakeDetector _shakeDetector;

  @override
  void initState() {
    super.initState();
    _initShader();
    _ticker = createTicker(_onTick)..start();

    _shakeDetector = ShakeDetector.autoStart(
      onPhoneShake: (_) => _initiateSpin(),
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    _labelAtlas?.dispose();
    _shakeDetector.stopListening();
    super.dispose();
  }

  void _initiateSpin() {
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
      // Randomize impulse direction and magnitude for highly varied results
      final rng = math.Random();
      // Wider ranges for more variation (3.0 to 9.0 range per axis)
      final baseX = 3.0 + rng.nextDouble() * 6.0;
      final baseY = 3.0 + rng.nextDouble() * 6.0;
      final baseZ = 3.0 + rng.nextDouble() * 6.0;
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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final orientation = MediaQuery.of(context).orientation;
    if (_lastOrientation != orientation) {
      _lastOrientation = orientation;
      _reloadForAspect();
    }
  }

  Future<void> _initShader() async {
    final p = await ui.FragmentProgram.fromAsset('shaders/dodecahedron.frag');
    final atlas = await _buildLabelAtlas(dodFaceExercises);
    if (mounted) {
      setState(() {
        _program = p;
        _labelAtlas = atlas;
      });
    }
  }

  Future<void> _reloadForAspect() async {
    if (_isReloadingShader) return;
    _isReloadingShader = true;
    // Dispose old atlas to free memory; shader will be reloaded too.
    _labelAtlas?.dispose();
    _labelAtlas = null;
    _program = null;
    setState(() {});
    try {
      await _initShader();
    } finally {
      _isReloadingShader = false;
    }
  }

  void _onTick(Duration d) {
    final t = d.inMilliseconds / 1000.0;
    final dt = _lastTick == 0.0 ? (t - _time) : (t - _lastTick);
    _lastTick = t;

    // Clear highlight after duration expires
    if (_highlightFaceIndex >= 0 &&
        (t - _highlightStartTime) >= _highlightDuration) {
      _highlightFaceIndex = -1;
    }

    // integrate velocities -> angles with exponential damping
    if (dt > 0) {
      final decay = math.exp(-_damping * dt);
      _vx *= decay;
      _vy *= decay;
      _vz *= decay;

      // clamp small velocities to zero to avoid floating drift
      if (_vx.abs() < _stopVelocityThreshold) _vx = 0.0;
      if (_vy.abs() < _stopVelocityThreshold) _vy = 0.0;
      if (_vz.abs() < _stopVelocityThreshold) _vz = 0.0;

      // update angles when there's meaningful motion
      final hasMotion = _vx != 0.0 || _vy != 0.0 || _vz != 0.0;
      if (hasMotion) {
        _ax += _vx * dt;
        _ay += _vy * dt;
        _az += _vz * dt;
      }

      // Animate snap-to-face if active
      if (_snapFaceIndex >= 0) {
        final elapsed = t - _snapStartTime;
        if (elapsed < _snapDuration) {
          // Progress: 0 at start, 1 at end (eased with smooth curve)
          final progress = (elapsed / _snapDuration).clamp(0.0, 1.0);
          // Ease-out cubic for smooth deceleration
          final easeProgress = 1.0 - math.pow(1.0 - progress, 3.0);

          // Interpolate from current rotation to target
          _ax = _ax + (_snapTargetAx - _ax) * easeProgress;
          _ay = _ay + (_snapTargetAy - _ay) * easeProgress;
          _az = _az + (_snapTargetAz - _az) * easeProgress;
        } else {
          // Snap complete: set exactly to target
          _ax = _snapTargetAx;
          _ay = _snapTargetAy;
          _az = _snapTargetAz;
          _snapFaceIndex = -1;
        }
      }

      // detect spinning -> slowed below threshold: show label for aligned face
      final currentSpeed = math.max(_vx.abs(), math.max(_vy.abs(), _vz.abs()));
      final currentlySpinning = currentSpeed > _stopVelocityThreshold;
      if (currentlySpinning) {
        _isSpinning = true;
      } else if (_isSpinning) {
        // we were spinning but now slowed below threshold
        // Clear all inertia
        _vx = _vy = _vz = 0.0;
        _isSpinning = false;

        // Determine which face is most aligned and show its label
        final faceIdx = _findFrontFaceIndex();
        _centerLabel = dodFaceExercises[faceIdx];
        _centerLabelStart = t;

        // Highlight the selected face momentarily
        _highlightFaceIndex = faceIdx;
        _highlightStartTime = t;

        // Start snap-to-face animation
        _snapFaceIndex = faceIdx;
        _snapStartTime = t;
        _calculateSnapTarget(faceIdx);
      }
    }

    if (mounted) {
      setState(() {
        _time = t;
      });
    }

    // If we've come to rest (no angular velocity), snap is done, and any center-label fade-in
    // has completed (or none exists), and highlight has finished, stop the ticker to save CPU.
    final noVelocities = _vx == 0.0 && _vy == 0.0 && _vz == 0.0;
    final fadeInPending =
        _centerLabel != null &&
        ((t - _centerLabelStart) < _centerLabelFadeDuration);
    final highlightPending = _highlightFaceIndex >= 0;
    final snapPending = _snapFaceIndex >= 0;
    if (noVelocities &&
        !fadeInPending &&
        !highlightPending &&
        !snapPending &&
        _ticker.isActive) {
      _ticker.stop();
    }
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

  // Transpose a 3x3 matrix (also gives inverse for rotation matrices)
  List<double> _transpose(List<double> m) {
    return [m[0], m[3], m[6], m[1], m[4], m[7], m[2], m[5], m[8]];
  }

  // Dot product
  double _dot(List<double> a, List<double> b) =>
      a[0] * b[0] + a[1] * b[1] + a[2] * b[2];

  // Find the front-facing face index closest to the viewer
  // Must match shader logic: shader rotates point by R, which inverts object rotation,
  // so we need to use R^T (inverse rotation) on normals to match.
  int _findFrontFaceIndex() {
    const zAxis = [0.0, 0.0, 1.0];

    final combinedAx = _ax + _viewAx;
    final combinedAy = _ay + _viewAy;
    final combinedAz = _az + _viewAz;

    final rX = _rotX(combinedAx);
    final rY = _rotY(combinedAy);
    final rZ = _rotZ(combinedAz);
    final rZY = _mulMatMat(rZ, rY);
    final rot = _mulMatMat(rZY, rX);

    // Use transpose (inverse) to match shader's point rotation
    final rotInv = _transpose(rot);

    int bestFaceIndex = 0;
    double bestDot = -2.0;
    for (int i = 0; i < _faceNormals.length; i++) {
      final nLocal = _normalize(_faceNormals[i]);
      final nWorld = _mulMatVec(rotInv, nLocal);
      final d = _dot(nWorld, zAxis);
      if (d > bestDot) {
        bestDot = d;
        bestFaceIndex = i;
      }
    }
    return bestFaceIndex;
  }

  // Calculate target rotation angles to align a specific face perpendicular to camera
  void _calculateSnapTarget(int faceIndex) {
    final targetNormal = _normalize(_faceNormals[faceIndex]);
    // We want this normal to point toward camera [0, 0, 1] after inverse rotation
    // That is: R^T * normal = [0, 0, 1], so R * [0, 0, 1] = normal
    //
    // We use an iterative approach: search for rotation angles that minimize error
    // between current normal direction and target [0, 0, 1] direction.

    // Start from current rotation
    var bestAx = _ax, bestAy = _ay, bestAz = _az;
    var minError = double.infinity;

    // Search nearby angles (±π/2 to allow flipping)
    const searchSteps = 9;
    const searchRange = math.pi / 2;

    for (int xi = 0; xi < searchSteps; xi++) {
      for (int yi = 0; yi < searchSteps; yi++) {
        for (int zi = 0; zi < searchSteps; zi++) {
          final testAx =
              _ax + (xi - (searchSteps ~/ 2)) * searchRange / (searchSteps / 2);
          final testAy =
              _ay + (yi - (searchSteps ~/ 2)) * searchRange / (searchSteps / 2);
          final testAz =
              _az + (zi - (searchSteps ~/ 2)) * searchRange / (searchSteps / 2);

          // Build rotation and transform normal
          final rX = _rotX(testAx);
          final rY = _rotY(testAy);
          final rZ = _rotZ(testAz);
          final rZY = _mulMatMat(rZ, rY);
          final rot = _mulMatMat(rZY, rX);
          final rotInv = _transpose(rot);

          // Apply inverse rotation to normal
          final nWorld = _mulMatVec(rotInv, targetNormal);

          // Target is [0, 0, 1]
          const zAxis = [0.0, 0.0, 1.0];
          final error =
              (nWorld[0] - zAxis[0]) * (nWorld[0] - zAxis[0]) +
              (nWorld[1] - zAxis[1]) * (nWorld[1] - zAxis[1]) +
              (nWorld[2] - zAxis[2]) * (nWorld[2] - zAxis[2]);

          if (error < minError) {
            minError = error;
            bestAx = testAx;
            bestAy = testAy;
            bestAz = testAz;
          }
        }
      }
    }

    _snapTargetAx = bestAx;
    _snapTargetAy = bestAy;
    _snapTargetAz = bestAz;
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

    // Increase label font size by 1.5x while keeping high DPI rendering
    final fontSize = 21 * atlasScale;

    // stroke paint for crisp outline
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (atlasScale * 1.6)
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
      strokeTp.layout(maxWidth: cellW - 24.0);
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
      fillTp.layout(maxWidth: cellW - 24.0);
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
  Widget build(BuildContext context) => Stack(
    children: [
      _buildShaderPainter(context),
      if (_centerLabel != null) _buildCenterLabel(),
    ],
  );

  Widget _buildShaderPainter(BuildContext context) {
    // Calculate highlight progress (0 at start, 1 when done)
    final highlightProgress = _highlightFaceIndex >= 0
        ? ((_time - _highlightStartTime) / _highlightDuration).clamp(0.0, 1.0)
        : 1.0;

    return GestureDetector(
      onTap: _initiateSpin,
      child: CustomPaint(
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
                _highlightFaceIndex,
                highlightProgress,
              ),
      ),
    );
  }

  Widget _buildCenterLabel() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: IgnorePointer(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: ((_time - _centerLabelStart) / _centerLabelFadeDuration)
                  .clamp(0.0, 1.0),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 28 * _labelSizeMultiplier,
                  vertical: 14 * _labelSizeMultiplier,
                ),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(0, 0, 0, 0.92),
                  borderRadius: BorderRadius.circular(8 * _labelSizeMultiplier),
                ),
                child: DefaultTextStyle(
                  style:
                      Theme.of(context).textTheme.headlineLarge?.copyWith(
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
                  child: Text(_centerLabel!, textAlign: TextAlign.center),
                ),
              ),
            ),
          ),
        ),
      ),
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
  final int highlightFace; // -1 = no highlight
  final double highlightProgress; // 0..1 fade-out progress

  _ShaderPainter(
    this.program,
    this.time,
    this.dpr,
    this.ax,
    this.ay,
    this.az,
    this.labelSizeMultiplier,
    this.labelAtlas,
    this.highlightFace,
    this.highlightProgress,
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
    shader.setFloat(6, highlightFace.toDouble()); // u_highlightFace
    shader.setFloat(7, highlightProgress); // u_highlightProgress

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
      old.labelSizeMultiplier != labelSizeMultiplier ||
      old.highlightFace != highlightFace ||
      old.highlightProgress != highlightProgress;
}
