import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:q_master/utils/shared_preferences_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'faces_constants.dart';

class DodecahedronShader extends StatefulWidget {
  const DodecahedronShader({super.key});
  @override
  State<DodecahedronShader> createState() => _DodecahedronShaderState();
}

class _DodecahedronShaderState extends State<DodecahedronShader>
    with SingleTickerProviderStateMixin {
  ui.FragmentProgram? _program;
  late final Ticker _ticker;
  double _time = 0.0;

  // rotation state (radians)
  double _ax = 0.0, _ay = 0.0, _az = 0.0;
  // angular velocities (radians/sec)
  double _vx = 0.0, _vy = 0.0, _vz = 0.0;
  // damping (per second) and thresholds (editable)
  double _damping = 0.8; // larger = faster slow-down
  static const double _velocityEpsilon = 0.001;

  // user-tunable controls
  double _impulseStrength = 1.0; // multiplier for tap impulse
  bool _showControls = false; // only show on double-tap by default

  // dodecahedron face normals (same basis as shader)
  static const double _phi = 1.61803398875;
  final List<List<double>> _faces = const [
    [0.0, 1.0, _phi],
    [0.0, -1.0, _phi],
    [0.0, 1.0, -_phi],
    [0.0, -1.0, -_phi],
    [1.0, _phi, 0.0],
    [-1.0, _phi, 0.0],
    [1.0, -_phi, 0.0],
    [-1.0, -_phi, 0.0],
    [_phi, 0.0, 1.0],
    [-_phi, 0.0, 1.0],
    [_phi, 0.0, -1.0],
    [-_phi, 0.0, -1.0],
  ];

  // snapping removed: the object will now simply stop without auto-aligning

  // bookkeeping for per-tick dt
  double _lastTick = 0.0;

  // selected face index and snap target
  int? _selectedFaceIdx;

  // center label shown when snapping finishes (persists until next tap)
  String? _centerLabel;
  double _centerLabelStart = 0.0;
  final double _centerLabelFadeDuration = 0.18; // fade-in duration

  // snapping state
  bool _isSpinning = false; // tracks if we were recently spinning
  bool _isSnapping = false;
  double _snapStartTime = 0.0;
  final double _snapDuration = 0.01; // 10 ms
  List<double>? _snapStartQuat;
  List<double>? _snapTargetQuat;
  // global label size multiplier (3x requested)
  final double _labelSizeMultiplier = 3.0;
  @override
  void initState() {
    super.initState();
    ui.FragmentProgram.fromAsset('shaders/dodecahedron.frag').then((p) {
      setState(() => _program = p);
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

        // if currently snapping, we override angles later using slerp
        if (!_isSnapping) {
          _ax += _vx * dt;
          _ay += _vy * dt;
          _az += _vz * dt;
        }

        final vxWasZero = _vx.abs() < _velocityEpsilon;
        final vyWasZero = _vy.abs() < _velocityEpsilon;
        final vzWasZero = _vz.abs() < _velocityEpsilon;
        if (vxWasZero) {
          _vx = 0.0;
        }
        if (vyWasZero) {
          _vy = 0.0;
        }
        if (vzWasZero) {
          _vz = 0.0;
        }

        // detect spinning -> stopped transition and kick off a short snap
        final currentlySpinning =
            _vx.abs() > 0.0 || _vy.abs() > 0.0 || _vz.abs() > 0.0;
        if (currentlySpinning) {
          _isSpinning = true;
        } else if (_isSpinning && !_isSnapping) {
          // we were spinning but now stopped -> start snap to nearest face
          _startSnap(t);
          _isSpinning = false;
        }
      }

      // advance snap animation if active
      if (_isSnapping && _snapStartQuat != null && _snapTargetQuat != null) {
        final progress = ((t - _snapStartTime) / _snapDuration).clamp(0.0, 1.0);
        final q = _quatSlerp(_snapStartQuat!, _snapTargetQuat!, progress);
        final e = _quatToEuler(q);
        _ax = e[0];
        _ay = e[1];
        _az = e[2];

        if (progress >= 1.0) {
          // finalize snap: stop motion and show a random exercise label
          _isSnapping = false;
          _vx = _vy = _vz = 0.0;
          // pick a random exercise to display in the center
          final idx = math.Random().nextInt(dodFaceExercises.length);
          _centerLabel = dodFaceExercises[idx];
          _centerLabelStart = t;
        }
      }

      setState(() {
        _time = t;
      });
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
    super.dispose();
  }

  // --- math helpers --------------------------------------------------------
  double _lerp(double a, double b, double t) => a + (b - a) * t;

  List<double> _normalize(List<double> v) {
    final len = math.sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2]);
    if (len == 0.0) return [0.0, 0.0, 0.0];
    return [v[0] / len, v[1] / len, v[2] / len];
  }

  double _dot(List<double> a, List<double> b) =>
      a[0] * b[0] + a[1] * b[1] + a[2] * b[2];

  List<double> _cross(List<double> a, List<double> b) => [
    a[1] * b[2] - a[2] * b[1],
    a[2] * b[0] - a[0] * b[2],
    a[0] * b[1] - a[1] * b[0],
  ];

  // quaternions represented as List<double> [w, x, y, z]
  List<double> _quatFromEuler(double ax, double ay, double az) {
    final c1 = math.cos(ax * 0.5);
    final s1 = math.sin(ax * 0.5);
    final c2 = math.cos(ay * 0.5);
    final s2 = math.sin(ay * 0.5);
    final c3 = math.cos(az * 0.5);
    final s3 = math.sin(az * 0.5);

    // qx
    final qx = [c1, s1, 0.0, 0.0];
    // qy
    final qy = [c2, 0.0, s2, 0.0];
    // qz
    final qz = [c3, 0.0, 0.0, s3];

    return _quatMultiply(_quatMultiply(qz, qy), qx);
  }

  List<double> _quatMultiply(List<double> a, List<double> b) {
    final w1 = a[0], x1 = a[1], y1 = a[2], z1 = a[3];
    final w2 = b[0], x2 = b[1], y2 = b[2], z2 = b[3];
    final w = w1 * w2 - x1 * x2 - y1 * y2 - z1 * z2;
    final x = w1 * x2 + x1 * w2 + y1 * z2 - z1 * y2;
    final y = w1 * y2 - x1 * z2 + y1 * w2 + z1 * x2;
    final z = w1 * z2 + x1 * y2 - y1 * x2 + z1 * w2;
    return [w, x, y, z];
  }

  List<double> _quatFromAxisAngle(List<double> axis, double angle) {
    final na = _normalize(axis);
    final s = math.sin(angle * 0.5);
    final w = math.cos(angle * 0.5);
    return [w, na[0] * s, na[1] * s, na[2] * s];
  }

  void _startSnap(double t) {
    // compute current orientation quaternion
    final q = _quatFromEuler(_ax, _ay, _az);

    // world screen normal
    const screen = [0.0, 0.0, 1.0];

    // find face whose world-space normal is closest to the screen
    double bestDot = -1.0;
    int bestIdx = -1;
    List<double>? bestWorldNormal;
    for (var i = 0; i < _faces.length; i++) {
      final f = _faces[i];
      final world = _quatRotateVector(q, f);
      final ndot = _dot(_normalize(world), screen);
      if (ndot > bestDot) {
        bestDot = ndot;
        bestIdx = i;
        bestWorldNormal = world;
      }
    }

    if (bestIdx < 0 || bestWorldNormal == null) return;

    // compute rotation that brings bestWorldNormal -> screen
    final v = _normalize(bestWorldNormal);
    var dot = _dot(v, screen).clamp(-1.0, 1.0);
    var angle = math.acos(dot);

    List<double> targetQ;
    if (angle.abs() < 1e-6) {
      // already aligned
      targetQ = q;
    } else {
      var axis = _cross(v, screen);
      final axisLen = math.sqrt(
        axis[0] * axis[0] + axis[1] * axis[1] + axis[2] * axis[2],
      );
      if (axisLen < 1e-6) {
        // v is opposite to screen; pick an arbitrary orthogonal axis
        axis = _cross(v, [1.0, 0.0, 0.0]);
        if (_dot(axis, axis) < 1e-6) axis = _cross(v, [0.0, 1.0, 0.0]);
      }
      targetQ = _quatMultiply(_quatFromAxisAngle(axis, angle), q);
    }

    _snapStartQuat = q;
    _snapTargetQuat = targetQ;
    _snapStartTime = t;
    _isSnapping = true;
    _selectedFaceIdx = bestIdx;
  }

  // rotate vector v by quaternion q
  List<double> _quatRotateVector(List<double> q, List<double> v) {
    final qx = q[1], qy = q[2], qz = q[3], qw = q[0];
    final t = _cross([qx, qy, qz], v);
    final tt = [2 * t[0], 2 * t[1], 2 * t[2]];
    final t2 = _cross([qx, qy, qz], tt);
    return [
      v[0] + qw * tt[0] + t2[0],
      v[1] + qw * tt[1] + t2[1],
      v[2] + qw * tt[2] + t2[2],
    ];
  }

  List<double> _quatToEuler(List<double> q) {
    final w = q[0], x = q[1], y = q[2], z = q[3];
    final t0 = 2 * (w * x + y * z);
    final t1 = 1 - 2 * (x * x + y * y);
    final X = math.atan2(t0, t1);

    var t2 = 2 * (w * y - z * x);
    if (t2 > 1.0) t2 = 1.0;
    if (t2 < -1.0) t2 = -1.0;
    final Y = math.asin(t2);

    final t3 = 2 * (w * z + x * y);
    final t4 = 1 - 2 * (y * y + z * z);
    final Z = math.atan2(t3, t4);

    return [X, Y, Z];
  }

  // spherical linear interpolation for quaternions
  List<double> _quatSlerp(List<double> a, List<double> b, double t) {
    var cosOmega = a[0] * b[0] + a[1] * b[1] + a[2] * b[2] + a[3] * b[3];
    var b0 = b[0], b1 = b[1], b2 = b[2], b3 = b[3];

    // if dot < 0, negate b to take shortest path
    if (cosOmega < 0.0) {
      cosOmega = -cosOmega;
      b0 = -b0;
      b1 = -b1;
      b2 = -b2;
      b3 = -b3;
    }

    const double kThreshold = 0.9995;
    if (cosOmega > kThreshold) {
      // linear interpolation for very close orientations
      final res = [
        _lerp(a[0], b0, t),
        _lerp(a[1], b1, t),
        _lerp(a[2], b2, t),
        _lerp(a[3], b3, t),
      ];
      final len = math.sqrt(
        res[0] * res[0] + res[1] * res[1] + res[2] * res[2] + res[3] * res[3],
      );
      return [res[0] / len, res[1] / len, res[2] / len, res[3] / len];
    }

    final omega = math.acos(cosOmega);
    final sinOmega = math.sin(omega);
    final s0 = math.sin((1 - t) * omega) / sinOmega;
    final s1 = math.sin(t * omega) / sinOmega;

    final res = [
      a[0] * s0 + b0 * s1,
      a[1] * s0 + b1 * s1,
      a[2] * s0 + b2 * s1,
      a[3] * s0 + b3 * s1,
    ];
    return res;
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
                _selectedFaceIdx = null;
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
              _selectedFaceIdx = null;
              _centerLabel = null;
              _vx += 6.5 * _impulseStrength;
              _vy += -4.3 * _impulseStrength;
              _vz += 3.2 * _impulseStrength;
            });
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
                      ),
              ),

              // face labels rendered as Flutter widgets for better contrast
              ..._buildFaceLabels(
                constraints.biggest,
                MediaQuery.of(context).devicePixelRatio,
              ),

              // centered overlay label (shown when a face is selected)
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

                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () async {
                                  final messenger = ScaffoldMessenger.of(
                                    context,
                                  );
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  await prefs.setDodecahedronImpulse(
                                    _impulseStrength,
                                  );
                                  await prefs.setDodecahedronDamping(_damping);
                                  if (!mounted) return;
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text('Defaults saved'),
                                    ),
                                  );
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
                                    _selectedFaceIdx = null;
                                    _centerLabel = null;
                                    _impulseStrength =
                                        prefs.dodecahedronImpulse ?? 1.0;
                                    _damping = prefs.dodecahedronDamping ?? 0.8;
                                  });
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

              // centered overlay label (stacked on top of shader, centered)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _centerLabel != null ? 1.0 : 0.0,
                    child: Center(
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
                          child: Text(_centerLabel ?? ''),
                        ),
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

  // Build positioned face label widgets (one per face). Shows if face is somewhat facing camera
  List<Widget> _buildFaceLabels(Size size, double dpr) {
    final widgets = <Widget>[];
    final resW = size.width * dpr;
    final resH = size.height * dpr;
    final minRes = math.min(resW, resH);

    // camera and projection constants used by shader
    final ro = [0.0, 0.0, 4.0];
    const double focalZ = -1.8; // shader uses vec3(uv, -1.8)

    final q = _quatFromEuler(_ax, _ay, _az);

    // Show only the selected face label (persist until next spin). If none selected, return empty
    if (_selectedFaceIdx == null) return widgets;
    final i = _selectedFaceIdx!;

    final fn = _normalize(_faces[i]);
    final world = _quatRotateVector(q, fn);
    final p = [world[0], world[1], world[2]];

    final vx = p[0] - ro[0];
    final vy = p[1] - ro[1];
    final vz = p[2] - ro[2];
    if (vz >= -0.001) return widgets;

    final ux = vx * (focalZ / vz);
    final uy = vy * (focalZ / vz);

    final deviceX = ux * minRes + 0.5 * resW;
    final deviceY = uy * minRes + 0.5 * resH;

    final logicalX = deviceX / dpr;
    final logicalY = deviceY / dpr;

    final facing = world[2];
    final scale = 0.9 + 0.4 * facing.clamp(0.0, 1.0);
    final fontSize = (16.0 * scale * _labelSizeMultiplier).clamp(
      12.0,
      36.0 * _labelSizeMultiplier,
    );

    widgets.add(
      Positioned(
        left: logicalX - 70 * scale * _labelSizeMultiplier,
        top: logicalY - 18 * scale * _labelSizeMultiplier,
        child: Opacity(
          opacity: 1.0,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 8 * scale * _labelSizeMultiplier,
              vertical: 6 * scale * _labelSizeMultiplier,
            ),
            decoration: BoxDecoration(
              color: Color.fromRGBO(0, 0, 0, 0.95),
              borderRadius: BorderRadius.circular(
                8 * scale * _labelSizeMultiplier,
              ),
              border: Border.all(color: Color.fromRGBO(255, 255, 255, 0.12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 6 * _labelSizeMultiplier,
                ),
              ],
            ),
            child: Text(
              dodFaceExercises[i],
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );

    return widgets;
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
  _ShaderPainter(this.program, this.time, this.dpr, this.ax, this.ay, this.az);

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

    final paint = Paint()..shader = shader;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _ShaderPainter old) =>
      old.time != time || old.ax != ax || old.ay != ay || old.az != az;
}
