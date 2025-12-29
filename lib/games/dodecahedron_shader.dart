import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:q_master/l10n/l10n.dart';
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
  var _time = 0.0;

  // rotation state (radians)
  var _ax = 0.0, _ay = 0.0, _az = 0.0;
  // angular velocities (radians/sec)
  var _vx = 0.0, _vy = 0.0, _vz = 0.0;
  // damping (per second) and thresholds (editable)
  var _damping = 0.8; // larger = faster slow-down
  static const double _velocityEpsilon = 0.001;

  // user-tunable controls
  double _impulseStrength = 1.0; // multiplier for tap impulse
  bool _showControls = false; // only show on double-tap by default
  // when angular speed (rad/s) falls below this, we consider spinning stopped and snap
  double _snapVelocityThreshold = 0.001;

  // snapping removed: the object will now simply stop without auto-aligning

  // bookkeeping for per-tick dt
  double _lastTick = 0.0;

  // center label shown when snapping finishes (persists until next tap)
  String? _centerLabel;
  double _centerLabelStart = 0.0;
  final double _centerLabelFadeDuration = 0.18; // fade-in duration

  // spinning state
  bool _isSpinning = false; // tracks if we were recently spinning
  // global label size multiplier (3x requested)
  final double _labelSizeMultiplier = 3.0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerLabel = L10n.of(context)!.dodTapToStartMessage;
    });
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
