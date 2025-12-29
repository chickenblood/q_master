precision highp float;
uniform vec2 u_resolution; // (px)
uniform float u_time;      // seconds
uniform vec3 u_angles;    // rotation angles (radians) for X, Y, Z provided by host

out vec4 FragColor;

// Golden ratio
const float PHI = 1.61803398875;

// rotation helpers
mat3 rotX(float a) {
  float c = cos(a), s = sin(a);
  return mat3(1.0,0.0,0.0,  0.0,c,-s,  0.0,s,c);
}
mat3 rotY(float a) {
  float c = cos(a), s = sin(a);
  return mat3(c,0.0,s,  0.0,1.0,0.0,  -s,0.0,c);
}
mat3 rotZ(float a) {
  float c = cos(a), s = sin(a);
  return mat3(c,-s,0.0,  s,c,0.0,  0.0,0.0,1.0);
}

mat3 rotateEuler(vec3 a) {
  // apply rotations in Z * Y * X order for a pleasing compound spin
  return rotZ(a.z) * rotY(a.y) * rotX(a.x);
}

// Dodecahedron SDF: max of plane distances (12 faces)
float sdDodecahedron(vec3 p) {
  vec3 n[12];
  n[0] = vec3( 0.0,  1.0,  PHI);
  n[1] = vec3( 0.0, -1.0,  PHI);
  n[2] = vec3( 0.0,  1.0, -PHI);
  n[3] = vec3( 0.0, -1.0, -PHI);
  n[4] = vec3( 1.0,  PHI, 0.0);
  n[5] = vec3(-1.0,  PHI, 0.0);
  n[6] = vec3( 1.0, -PHI, 0.0);
  n[7] = vec3(-1.0, -PHI, 0.0);
  n[8] = vec3( PHI, 0.0, 1.0);
  n[9] = vec3(-PHI, 0.0, 1.0);
  n[10]= vec3( PHI, 0.0, -1.0);
  n[11]= vec3(-PHI, 0.0, -1.0);

  float md = -1e9;
  for(int i = 0; i < 12; i++) {
    vec3 ni = normalize(n[i]);
    md = max(md, dot(ni, p));
  }
  // subtract radius -> negative inside
  return md - 1.0;
}

float map(vec3 p) {
  // apply rotation angles supplied by the host (radians)
  p = rotateEuler(u_angles) * p;
  // small nodding still controlled by time for subtle motion
  p = rotX(0.12 * sin(u_time * 0.9)) * p;
  return sdDodecahedron(p) * 0.9; // scale
}

vec3 estimateNormal(vec3 p) {
  float eps = 0.0008;
  return normalize(vec3(
    map(p + vec3(eps,0,0)) - map(p - vec3(eps,0,0)),
    map(p + vec3(0,eps,0)) - map(p - vec3(0,eps,0)),
    map(p + vec3(0,0,eps)) - map(p - vec3(0,0,eps))
  ));
}

void main() {
  vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution) / min(u_resolution.x, u_resolution.y);
  vec3 ro = vec3(0.0, 0.0, 4.0);
  vec3 rd = normalize(vec3(uv, -1.8));

  float t = 0.0;
  float maxT = 30.0;
  float found = -1.0;
  for (int i = 0; i < 96; i++) {
    vec3 p = ro + rd * t;
    float d = map(p);
    if (d < 0.001) {
      found = t;
      break;
    }
    t += d * 0.7;
    if (t > maxT) break;
  }

  vec3 col = vec3(0.02); // background
  if (found > 0.0) {
    vec3 p = ro + rd * found;
    vec3 n = estimateNormal(p);
    vec3 lightDir = normalize(vec3(0.5, 0.6, -0.7));
    vec3 lightColor = vec3(1.0, 0.95, 0.9);

    float diff = max(dot(n, lightDir), 0.0);
    float spec = pow(max(dot(reflect(-lightDir, n), -rd), 0.0), 64.0);

    // deeper orange material + stronger lighting
    vec3 baseColor = vec3(1.0, 0.45, 0.05);
    float diffuseStrength = 1.35;
    float ambient = 0.18;

    vec3 diffuse = baseColor * diff * diffuseStrength * lightColor;
    vec3 specular = vec3(1.0) * spec * 1.2;

    // combine components (ambient gives a warm base tint)
    col = diffuse + specular + baseColor * ambient * 0.8;

    // rim / fresnel (warmer, stronger)
    float rim = pow(1.0 - max(dot(n, -rd), 0.0), 2.0);
    col += vec3(1.0, 0.5, 0.15) * rim * 0.28;

    // gentle brightness boost and reduce dark vignetting
    col = col * (1.05 + 0.05 * clamp(length(uv), 0.0, 1.0));
    col = clamp(col, 0.0, 1.5);
  }

  FragColor = vec4(col, 1.0);
}
