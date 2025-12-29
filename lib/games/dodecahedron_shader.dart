import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:q_master/l10n/l10n.dart';
import 'package:q_master/utils/shared_preferences_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  var _ax = 0.0, _ay = 0.0, _az = 0.0;
  // angular velocities (radians/sec)
  var _vx = 0.0, _vy = 0.0, _vz = 0.0;
  // damping (per second) and thresholds (editable)
  var _damping = 1.0; // larger = faster slow-down
  static const double _velocityEpsilon = 0.001;

  // user-tunable controls
  var _impulseStrength = 2.0; // multiplier for tap impulse
  var _showControls = false; // only show on double-tap by default
  // when angular speed (rad/s) falls below this, we consider spinning stopped and snap
  var _snapVelocityThreshold = 0.001;

  // snapping removed: the object will now simply stop without auto-aligning

  // bookkeeping for per-tick dt
  var _lastTick = 0.0;

  // center label shown when snapping finishes (persists until next tap)
  String? _centerLabel;
  var _centerLabelStart = 0.0;
  final double _centerLabelFadeDuration = 0.18; // fade-in duration

  // label atlas used by shader (rendered once from strings)
  ui.Image? _labelAtlas;

  // spinning state
  var _isSpinning = false; // tracks if we were recently spinning
  // global label size multiplier (3x requested)
  final double _labelSizeMultiplier = 3.0;
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
      if (dt > 0) {
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

        // detect spinning -> slowed below threshold: settle and show a label once
        final currentSpeed = math.max(
          _vx.abs(),
          math.max(_vy.abs(), _vz.abs()),
        );
        final currentlySpinning = currentSpeed > _snapVelocityThreshold;
        if (currentlySpinning) {
          _isSpinning = true;
        } else if (_isSpinning) {
          // we were spinning but now slowed below threshold -> stop motion and show label
          _vx = _vy = _vz = 0.0;
          final idx = math.Random().nextInt(dodFaceExercises.length);
          _centerLabel = dodFaceExercises[idx];
          _centerLabelStart = t;
          _isSpinning = false;
        }
      }

      setState(() {
        _time = t;
      });

      // If we've come to rest (no angular velocity) and any center-label fade-in
      // has completed (or none exists), stop the ticker to save CPU.
      final noVelocities = _vx == 0.0 && _vy == 0.0 && _vz == 0.0;
      final fadeInPending =
          _centerLabel != null &&
          ((t - _centerLabelStart) < _centerLabelFadeDuration);
      if (noVelocities && !fadeInPending && _ticker.isActive) {
        _ticker.stop();
      }
    })..start();

    // load any saved slider defaults for this control
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        _impulseStrength = prefs.dodecahedronImpulse ?? _impulseStrength;
        _damping = prefs.dodecahedronDamping ?? _damping;
      });
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _labelAtlas?.dispose();
    super.dispose();
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            // If a center label is shown, clear it and continue to start a spin.
            if (_centerLabel != null) {
              setState(() {
                _centerLabel = null;
              });
            }

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
              _vx += 6.5 * _impulseStrength;
              _vy += -4.3 * _impulseStrength;
              _vz += 3.2 * _impulseStrength;
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
                        _ax,
                        _ay,
                        _az,
                        dodFaceExercises,
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
                          child: Text(_centerLabel!),
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
                                onPressed: () async {
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  await prefs.setDodecahedronImpulse(
                                    _impulseStrength,
                                  );
                                  await prefs.setDodecahedronDamping(_damping);
                                  if (!mounted) return;
                                },
                                child: const Text(
                                  'Save Defaults',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  setState(() {
                                    _ax = _ay = _az = 0.0;
                                    _vx = _vy = _vz = 0.0;
                                    _centerLabel = null;
                                    _impulseStrength =
                                        prefs.dodecahedronImpulse ?? 1.0;
                                    _damping = prefs.dodecahedronDamping ?? 0.8;
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
  final List<String> faceLabels;
  final double labelSizeMultiplier;
  final ui.Image? labelAtlas; // rendered atlas image containing all labels

  _ShaderPainter(
    this.program,
    this.time,
    this.dpr,
    this.ax,
    this.ay,
    this.az,
    this.faceLabels,
    this.labelSizeMultiplier,
    this.labelAtlas,
  );

  // Rotation helpers (match shader order: Z * Y * X)
  List<double> _rotX(double a) {
    final c = math.cos(a), s = math.sin(a);
    return [1.0, 0.0, 0.0, 0.0, c, -s, 0.0, s, c];
  }

  List<double> _rotY(double a) {
    final c = math.cos(a), s = math.sin(a);
    return [c, 0.0, s, 0.0, 1.0, 0.0, -s, 0.0, c];
  }

  List<double> _rotZ(double a) {
    final c = math.cos(a), s = math.sin(a);
    return [c, -s, 0.0, s, c, 0.0, 0.0, 0.0, 1.0];
  }

  // multiply 3x3 matrix (as flat list) by a vec3
  List<double> _mulMatVec(List<double> m, List<double> v) {
    return [
      m[0] * v[0] + m[1] * v[1] + m[2] * v[2],
      m[3] * v[0] + m[4] * v[1] + m[5] * v[2],
      m[6] * v[0] + m[7] * v[1] + m[8] * v[2],
    ];
  }

  // multiply two 3x3 matrices
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

  double _dot(List<double> a, List<double> b) =>
      a[0] * b[0] + a[1] * b[1] + a[2] * b[2];

  List<double> _normalize(List<double> v) {
    final len = math.sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2]);
    if (len == 0) return [0.0, 0.0, 0.0];
    return [v[0] / len, v[1] / len, v[2] / len];
  }

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

    // Now overlay face labels by computing the screen-space centers of each face
    final resPxX = size.width * dpr;
    final resPxY = size.height * dpr;
    final minResPx = math.min(resPxX, resPxY);

    // build rotation matrix that matches the shader (rotZ * rotY * rotX)
    final rX = _rotX(ax);
    final rY = _rotY(ay);
    final rZ = _rotZ(az);
    final rZY = _mulMatMat(rZ, rY);
    final rot = _mulMatMat(rZY, rX);

    // Dodecahedron face normals (same order as shader)
    final faces = [
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

    // Camera origin in shader space
    final ro = [0.0, 0.0, 4.0];

    // helper: SDF and map to perform a short ray-march for occlusion testing
    double sdDodecahedronPoint(List<double> p) {
      var md = -1e9;
      for (var f in faces) {
        final ni = _normalize(f);
        md = math.max(md, _dot(ni, p));
      }
      return md - 1.0;
    }

    double mapPoint(List<double> p) {
      // apply Euler rotation (rot) then small nodding in X like shader
      var rp = _mulMatVec(rot, p);
      final nodAngle = 0.12 * math.sin(time * 0.9);
      final nod = _rotX(nodAngle);
      rp = _mulMatVec(nod, rp);
      return sdDodecahedronPoint(rp) * 0.9;
    }

    // simple ray-march along rd, limited to maxT; returns hit t or double.infinity if none
    double rayMarch(List<double> rop, List<double> rd, double maxT) {
      double t = 0.0;
      for (var s = 0; s < 96; s++) {
        final p = [rop[0] + rd[0] * t, rop[1] + rd[1] * t, rop[2] + rd[2] * t];
        final d = mapPoint(p);
        if (d < 0.001) return t;
        t += d * 0.7;
        if (t > maxT) break;
      }
      return double.infinity;
    }

    for (var i = 0; i < faces.length && i < faceLabels.length; i++) {
      final n = _normalize(faces[i]); // normalized face normal == face center
      // rotate into world/camera space
      final pWorld = _mulMatVec(rot, n);

      // visibility: face toward camera?
      final camVec = [ro[0] - pWorld[0], ro[1] - pWorld[1], ro[2] - pWorld[2]];
      final camLen = math.sqrt(
        camVec[0] * camVec[0] + camVec[1] * camVec[1] + camVec[2] * camVec[2],
      );
      if (camLen <= 0.0) continue;
      final camDir = [
        camVec[0] / camLen,
        camVec[1] / camLen,
        camVec[2] / camLen,
      ];
      final facingDot = _dot(n, camDir);
      if (facingDot <= 0.0) {
        continue; // skip back faces
      }

      // label position slightly inset on the face surface
      final labelOffset = 0.02; // shader units
      final labelPoint = [
        pWorld[0] - n[0] * labelOffset,
        pWorld[1] - n[1] * labelOffset,
        pWorld[2] - n[2] * labelOffset,
      ];

      // ray to the label point and occlusion test
      final rdVec = [
        labelPoint[0] - ro[0],
        labelPoint[1] - ro[1],
        labelPoint[2] - ro[2],
      ];
      final dist = math.sqrt(_dot(rdVec, rdVec));
      if (dist == 0.0) continue;
      final rd = [rdVec[0] / dist, rdVec[1] / dist, rdVec[2] / dist];
      final hitT = rayMarch(ro, rd, dist + 0.01);
      if (hitT.isFinite && hitT < dist - 0.01) continue; // occluded

      // projection math matching shader using label point
      final vz = labelPoint[2] - ro[2];
      if (vz.abs() < 1e-6) continue;
      final k = -1.8 / vz;
      final uvx = k * (labelPoint[0] - ro[0]);
      final uvy = k * (labelPoint[1] - ro[1]);

      // convert to Flutter logical pixels (shader uses pixel coordinates with origin bottom-left)
      final px = (resPxX / 2.0 + uvx * minResPx) / dpr;
      final py =
          (resPxY / 2.0 - uvy * minResPx) /
          dpr; // invert Y to match Canvas top-left

      // skip if offscreen
      if (px < -50 ||
          px > size.width + 50 ||
          py < -50 ||
          py > size.height + 50) {
        continue;
      }

      // scale font and opacity based on distance and facing angle
      final baseFont = 10.0 * labelSizeMultiplier; // logical pixels
      final distanceScale = 1.0 / (1.0 + dist * 0.25); // farther -> smaller
      final angleScale = (0.5 + 0.5 * facingDot).clamp(
        0.5,
        1.0,
      ); // glancing angles smaller
      final fontSize = (baseFont * angleScale * distanceScale).clamp(6.0, 48.0);
      final opacity = (facingDot.clamp(0.0, 1.0) * 1.2 * distanceScale).clamp(
        0.0,
        1.0,
      );

      final text = faceLabels[i];
      final style = TextStyle(
        color: Color.fromARGB(
          ((opacity * 255).round()).clamp(0, 255),
          255,
          255,
          255,
        ),
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        shadows: const [
          Shadow(blurRadius: 4, color: Colors.black54, offset: Offset(0, 2)),
        ],
      );

      final tp = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      tp.layout(
        maxWidth: size.width * 0.25,
      ); // limit width a bit for long labels

      // center on surface point
      tp.paint(canvas, Offset(px - tp.width / 2, py - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _ShaderPainter old) =>
      old.time != time ||
      old.ax != ax ||
      old.ay != ay ||
      old.az != az ||
      old.faceLabels != faceLabels ||
      old.labelSizeMultiplier != labelSizeMultiplier;
}
