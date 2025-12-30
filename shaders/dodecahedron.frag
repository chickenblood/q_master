precision highp float;
uniform vec2 u_resolution; // (px)
uniform float u_time;      // seconds
uniform vec3 u_angles;    // rotation angles (radians) for X, Y, Z provided by host
uniform sampler2D u_labelAtlas; // atlas containing rendered label glyphs

out vec4 FragColor;

// Golden ratio
const float PHI = 1.61803398875;

// label atlas grid
const int LABEL_COLS = 4;
const int LABEL_ROWS = 3;

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

// helper to find face index closest to normal
int findFaceIndex(vec3 n) {
  vec3 f[12];
  f[0] = vec3( 0.0,  1.0,  PHI);
  f[1] = vec3( 0.0, -1.0,  PHI);
  f[2] = vec3( 0.0,  1.0, -PHI);
  f[3] = vec3( 0.0, -1.0, -PHI);
  f[4] = vec3( 1.0,  PHI, 0.0);
  f[5] = vec3(-1.0,  PHI, 0.0);
  f[6] = vec3( 1.0, -PHI, 0.0);
  f[7] = vec3(-1.0, -PHI, 0.0);
  f[8] = vec3( PHI, 0.0, 1.0);
  f[9] = vec3(-PHI, 0.0, 1.0);
  f[10]= vec3( PHI, 0.0, -1.0);
  f[11]= vec3(-PHI, 0.0, -1.0);

  int best = -1;
  float bestDot = -1.0;
  for (int i = 0; i < 12; i++) {
    float d = dot(normalize(f[i]), n);
    if (d > bestDot) {
      bestDot = d;
      best = i;
    }
  }
  return best;
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

    // Back-face culling: skip rendering if normal points away from viewer
    if (dot(n, -rd) < 0.0) {
      FragColor = vec4(col, 1.0);
      return;
    }

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

    // label projection & sampling: determine the face index by argmax of plane dot with rotated point
    // rotate the surface point into the same space used by the SDF
    vec3 pRot = rotateEuler(u_angles) * p;

    int faceIdx = 0;
    float bestDot = -2.0;
    vec3 faces[12];
    faces[0] = vec3( 0.0,  1.0,  PHI);
    faces[1] = vec3( 0.0, -1.0,  PHI);
    faces[2] = vec3( 0.0,  1.0, -PHI);
    faces[3] = vec3( 0.0, -1.0, -PHI);
    faces[4] = vec3( 1.0,  PHI, 0.0);
    faces[5] = vec3(-1.0,  PHI, 0.0);
    faces[6] = vec3( 1.0, -PHI, 0.0);
    faces[7] = vec3(-1.0, -PHI, 0.0);
    faces[8] = vec3( PHI, 0.0, 1.0);
    faces[9] = vec3(-PHI, 0.0, 1.0);
    faces[10]= vec3( PHI, 0.0, -1.0);
    faces[11]= vec3(-PHI, 0.0, -1.0);

    for (int i = 0; i < 12; i++) {
      float dplane = dot(normalize(faces[i]), pRot);
      if (dplane > bestDot) {
        bestDot = dplane;
        faceIdx = i;
      }
    }

    // compute a tangent frame for the selected face (use the face's canonical normal for stability)
    vec3 faceNormal = normalize(faces[faceIdx]);
    vec3 tangent = normalize(cross(faceNormal, vec3(0.0, 1.0, 0.0)));
    if (length(tangent) < 0.1) tangent = normalize(cross(faceNormal, vec3(1.0, 0.0, 0.0)));
    vec3 bitangent = cross(faceNormal, tangent);

    // compute local coords on face plane using the rotated point
    float localX = dot(pRot, tangent);
    float localY = dot(pRot, bitangent);
    // scale to normalized label area (tweak this to control how much face is used)
    float labelScale = 1.3;
    vec2 local = vec2(localX, localY) / labelScale;

    // aspect correction: scale y by screen aspect so label is not stretched
    float aspect = u_resolution.x / u_resolution.y;
    local.y /= aspect;

    // map local (-0.5..0.5) to atlas cell
    float colIdx = float(faceIdx % LABEL_COLS);
    float rowIdx = float(faceIdx / LABEL_COLS);
    vec2 atlasUV = vec2((colIdx + (local.x * 0.5 + 0.5)) / float(LABEL_COLS), (rowIdx + (local.y * 0.5 + 0.5)) / float(LABEL_ROWS));

    // sample atlas and blend on surface when within label bounds
    vec4 lab = texture(u_labelAtlas, atlasUV);
    float a = lab.a;
    if (a > 0.01 && abs(local.x) < 0.5 && abs(local.y) < 0.5) {
      // make label respect lighting slightly by tinting with surface color
      vec3 labelCol = lab.rgb * 1.1;
      col = mix(col, labelCol, a * 0.95);
    }

    // gentle brightness boost and reduce dark vignetting
    col = col * (1.05 + 0.05 * clamp(length(uv), 0.0, 1.0));
    col = clamp(col, 0.0, 1.5);
  }

  FragColor = vec4(col, 1.0);
}
