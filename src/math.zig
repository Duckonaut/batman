const std = @import("std");

pub const vec2 = Vec2.new;
pub const vec3 = Vec3.new;
pub const vec4 = Vec4.new;
pub const rect = Rect.new;

pub const Vec2 = packed struct {
    x: f32,
    y: f32,

    pub fn new(x: f32, y: f32) Vec2 {
        return Vec2{ .x = x, .y = y };
    }

    pub fn zero() Vec2 {
        return Vec2{ .x = 0.0, .y = 0.0 };
    }

    pub fn one() Vec2 {
        return Vec2{ .x = 1.0, .y = 1.0 };
    }

    pub fn splat(v: f32) Vec2 {
        return Vec2{ .x = v, .y = v };
    }

    pub fn add(self: Vec2, other: Vec2) Vec2 {
        return Vec2{ .x = self.x + other.x, .y = self.y + other.y };
    }

    pub fn sub(self: Vec2, other: Vec2) Vec2 {
        return Vec2{ .x = self.x - other.x, .y = self.y - other.y };
    }

    pub fn mul(self: Vec2, other: Vec2) Vec2 {
        return Vec2{ .x = self.x * other.x, .y = self.y * other.y };
    }

    pub fn div(self: Vec2, other: Vec2) Vec2 {
        return Vec2{ .x = self.x / other.x, .y = self.y / other.y };
    }

    pub fn adds(self: Vec2, scalar: f32) Vec2 {
        return Vec2{ .x = self.x + scalar, .y = self.y + scalar };
    }

    pub fn subs(self: Vec2, scalar: f32) Vec2 {
        return Vec2{ .x = self.x - scalar, .y = self.y - scalar };
    }

    pub fn muls(self: Vec2, scalar: f32) Vec2 {
        return Vec2{ .x = self.x * scalar, .y = self.y * scalar };
    }

    pub fn divs(self: Vec2, scalar: f32) Vec2 {
        return Vec2{ .x = self.x / scalar, .y = self.y / scalar };
    }

    pub fn dot(self: Vec2, other: Vec2) f32 {
        return self.x * other.x + self.y * other.y;
    }

    pub fn length(self: Vec2) f32 {
        return f32.sqrt(self.dot(self));
    }

    pub fn normalized(self: Vec2) Vec2 {
        return self.divs(self.length());
    }

    pub fn lerp(self: Vec2, other: Vec2, t: f32) Vec2 {
        return self.add(other.sub(self).muls(t));
    }
};

pub const Vec3 = packed struct {
    x: f32,
    y: f32,
    z: f32,

    pub fn new(x: f32, y: f32, z: f32) Vec3 {
        return Vec3{ .x = x, .y = y, .z = z };
    }

    pub fn zero() Vec3 {
        return Vec3{ .x = 0.0, .y = 0.0, .z = 0.0 };
    }

    pub fn one() Vec3 {
        return Vec3{ .x = 1.0, .y = 1.0, .z = 1.0 };
    }

    pub fn splat(v: f32) Vec3 {
        return Vec3{ .x = v, .y = v, .z = v };
    }

    pub fn add(self: Vec3, other: Vec3) Vec3 {
        return Vec3{ .x = self.x + other.x, .y = self.y + other.y, .z = self.z + other.z };
    }

    pub fn sub(self: Vec3, other: Vec3) Vec3 {
        return Vec3{ .x = self.x - other.x, .y = self.y - other.y, .z = self.z - other.z };
    }

    pub fn mul(self: Vec3, other: Vec3) Vec3 {
        return Vec3{ .x = self.x * other.x, .y = self.y * other.y, .z = self.z * other.z };
    }

    pub fn div(self: Vec3, other: Vec3) Vec3 {
        return Vec3{ .x = self.x / other.x, .y = self.y / other.y, .z = self.z / other.z };
    }

    pub fn adds(self: Vec3, scalar: f32) Vec3 {
        return Vec3{ .x = self.x + scalar, .y = self.y + scalar, .z = self.z + scalar };
    }

    pub fn subs(self: Vec3, scalar: f32) Vec3 {
        return Vec3{ .x = self.x - scalar, .y = self.y - scalar, .z = self.z - scalar };
    }

    pub fn muls(self: Vec3, scalar: f32) Vec3 {
        return Vec3{ .x = self.x * scalar, .y = self.y * scalar, .z = self.z * scalar };
    }

    pub fn divs(self: Vec3, scalar: f32) Vec3 {
        return Vec3{ .x = self.x / scalar, .y = self.y / scalar, .z = self.z / scalar };
    }

    pub fn dot(self: Vec3, other: Vec3) f32 {
        return self.x * other.x + self.y * other.y + self.z * other.z;
    }

    pub fn cross(self: Vec3, other: Vec3) Vec3 {
        return Vec3{
            .x = self.y * other.z - self.z * other.y,
            .y = self.z * other.x - self.x * other.z,
            .z = self.x * other.y - self.y * other.x,
        };
    }

    pub fn length(self: Vec3) f32 {
        return f32.sqrt(self.dot(self));
    }

    pub fn normalized(self: Vec3) Vec3 {
        return self.divs(self.length());
    }

    pub fn lerp(self: Vec3, other: Vec3, t: f32) Vec3 {
        return self.add(other.sub(self).muls(t));
    }
};

pub const Vec4 = packed struct {
    x: f32,
    y: f32,
    z: f32,
    w: f32,

    pub fn new(x: f32, y: f32, z: f32, w: f32) Vec4 {
        return Vec4{ .x = x, .y = y, .z = z, .w = w };
    }

    pub fn zero() Vec4 {
        return Vec4{ .x = 0.0, .y = 0.0, .z = 0.0, .w = 0.0 };
    }

    pub fn one() Vec4 {
        return Vec4{ .x = 1.0, .y = 1.0, .z = 1.0, .w = 1.0 };
    }

    pub fn splat(v: f32) Vec4 {
        return Vec4{ .x = v, .y = v, .z = v, .w = v };
    }

    pub fn add(self: Vec4, other: Vec4) Vec4 {
        return Vec4{ .x = self.x + other.x, .y = self.y + other.y, .z = self.z + other.z, .w = self.w + other.w };
    }

    pub fn sub(self: Vec4, other: Vec4) Vec4 {
        return Vec4{ .x = self.x - other.x, .y = self.y - other.y, .z = self.z - other.z, .w = self.w - other.w };
    }

    pub fn mul(self: Vec4, other: Vec4) Vec4 {
        return Vec4{ .x = self.x * other.x, .y = self.y * other.y, .z = self.z * other.z, .w = self.w * other.w };
    }

    pub fn div(self: Vec4, other: Vec4) Vec4 {
        return Vec4{ .x = self.x / other.x, .y = self.y / other.y, .z = self.z / other.z, .w = self.w / other.w };
    }

    pub fn adds(self: Vec4, scalar: f32) Vec4 {
        return Vec4{ .x = self.x + scalar, .y = self.y + scalar, .z = self.z + scalar, .w = self.w + scalar };
    }

    pub fn subs(self: Vec4, scalar: f32) Vec4 {
        return Vec4{ .x = self.x - scalar, .y = self.y - scalar, .z = self.z - scalar, .w = self.w - scalar };
    }

    pub fn muls(self: Vec4, scalar: f32) Vec4 {
        return Vec4{ .x = self.x * scalar, .y = self.y * scalar, .z = self.z * scalar, .w = self.w * scalar };
    }

    pub fn divs(self: Vec4, scalar: f32) Vec4 {
        return Vec4{ .x = self.x / scalar, .y = self.y / scalar, .z = self.z / scalar, .w = self.w / scalar };
    }

    pub fn dot(self: Vec4, other: Vec4) f32 {
        return self.x * other.x + self.y * other.y + self.z * other.z + self.w * other.w;
    }

    pub fn length(self: Vec4) f32 {
        return f32.sqrt(self.dot(self));
    }

    pub fn normalized(self: Vec4) Vec4 {
        return self.divs(self.length());
    }

    pub fn lerp(self: Vec4, other: Vec4, t: f32) Vec4 {
        return self.add(other.sub(self).muls(t));
    }
};

pub const Rect = struct {
    pos: Vec2,
    size: Vec2,

    pub fn new(x: f32, y: f32, w: f32, h: f32) Rect {
        return Rect{ .pos = Vec2.new(x, y), .size = Vec2.new(w, h) };
    }

    pub fn one() Rect {
        return Rect{ .pos = Vec2.zero(), .size = Vec2.one() };
    }
};

pub const Recti = struct {
    minx: i32,
    miny: i32,
    maxx: i32,
    maxy: i32,

    pub fn new(minx: i32, miny: i32, maxx: i32, maxy: i32) Recti {
        return Recti{ .minx = minx, .miny = miny, .maxx = maxx, .maxy = maxy };
    }
};

pub const Mat4 = extern struct {
    fields: [4][4]f32, // [row][col]

    const Real = f32;

    /// zero matrix.
    pub const zero = Mat4{
        .fields = [4][4]Real{
            [4]Real{ 0, 0, 0, 0 },
            [4]Real{ 0, 0, 0, 0 },
            [4]Real{ 0, 0, 0, 0 },
            [4]Real{ 0, 0, 0, 0 },
        },
    };

    /// identitiy matrix
    pub const identity = Mat4{
        .fields = [4][4]Real{
            [4]Real{ 1, 0, 0, 0 },
            [4]Real{ 0, 1, 0, 0 },
            [4]Real{ 0, 0, 1, 0 },
            [4]Real{ 0, 0, 0, 1 },
        },
    };

    /// performs matrix multiplication of a*b
    pub fn mul(a: Mat4, b: Mat4) Mat4 {
        var result: Mat4 = undefined;
        inline for (0..4) |row| {
            inline for (0..4) |col| {
                var sum: Real = 0.0;
                inline for (0..4) |i| {
                    sum += a.fields[row][i] * b.fields[i][col];
                }
                result.fields[row][col] = sum;
            }
        }
        return result;
    }

    /// transposes the matrix.
    /// this will swap columns with rows.
    pub fn transpose(a: Mat4) Mat4 {
        var result: Mat4 = undefined;
        inline for (0..4) |row| {
            inline for (0..4) |col| {
                result.fields[row][col] = a.fields[col][row];
            }
        }
        return result;
    }

    // taken from GLM implementation

    /// Creates a look-at matrix.
    /// The matrix will create a transformation that can be used
    /// as a camera transform.
    /// the camera is located at `eye` and will look into `direction`.
    /// `up` is the direction from the screen center to the upper screen border.
    pub fn createLook(eye: Vec3, direction: Vec3, up: Vec3) Mat4 {
        const f = direction.normalize();
        const s = Vec3.cross(f, up).normalize();
        const u = Vec3.cross(s, f);

        var result = Mat4.identity;
        result.fields[0][0] = s.x;
        result.fields[1][0] = s.y;
        result.fields[2][0] = s.z;
        result.fields[0][1] = u.x;
        result.fields[1][1] = u.y;
        result.fields[2][1] = u.z;
        result.fields[0][2] = -f.x;
        result.fields[1][2] = -f.y;
        result.fields[2][2] = -f.z;
        result.fields[3][0] = -Vec3.dot(s, eye);
        result.fields[3][1] = -Vec3.dot(u, eye);
        result.fields[3][2] = Vec3.dot(f, eye);
        return result;
    }

    /// Creates a look-at matrix.
    /// The matrix will create a transformation that can be used
    /// as a camera transform.
    /// the camera is located at `eye` and will look at `center`.
    /// `up` is the direction from the screen center to the upper screen border.
    pub fn createLookAt(eye: Vec3, center: Vec3, up: Vec3) Mat4 {
        return createLook(eye, Vec3.sub(center, eye), up);
    }

    // taken from GLM implementation

    /// creates a perspective transformation matrix.
    /// `fov` is the field of view in radians,
    /// `aspect` is the screen aspect ratio (width / height)
    /// `near` is the distance of the near clip plane, whereas `far` is the distance to the far clip plane.
    pub fn createPerspective(fov: Real, aspect: Real, near: Real, far: Real) Mat4 {
        std.debug.assert(@abs(aspect - 0.001) > 0);

        const tanHalfFovy = @tan(fov / 2);

        var result = Mat4.zero;
        result.fields[0][0] = 1.0 / (aspect * tanHalfFovy);
        result.fields[1][1] = 1.0 / (tanHalfFovy);
        result.fields[2][2] = -(far + near) / (far - near);
        result.fields[2][3] = -1;
        result.fields[3][2] = -(2 * far * near) / (far - near);
        return result;
    }

    /// creates a rotation matrix around a certain axis.
    pub fn createAngleAxis(axis: Vec3, angle: Real) Mat4 {
        const cos = @cos(angle);
        const sin = @sin(angle);

        const normalized = axis.normalize();
        const x = normalized.x;
        const y = normalized.y;
        const z = normalized.z;

        return Mat4{
            .fields = [4][4]Real{
                [4]Real{ cos + x * x * (1 - cos), x * y * (1 - cos) + z * sin, x * z * (1 - cos) - y * sin, 0 },
                [4]Real{ y * x * (1 - cos) - z * sin, cos + y * y * (1 - cos), y * z * (1 - cos) + x * sin, 0 },
                [4]Real{ z * x * (1 - cos) + y * sin, z * y * (1 - cos) - x * sin, cos + z * z * (1 - cos), 0 },
                [4]Real{ 0, 0, 0, 1 },
            },
        };
    }

    /// creates matrix that will scale a homogeneous matrix.
    pub fn createUniformScale(scale: Real) Mat4 {
        return createScale(scale, scale, scale);
    }

    /// Creates a non-uniform scaling matrix
    pub fn createScale(x: Real, y: Real, z: Real) Mat4 {
        return Mat4{
            .fields = [4][4]Real{
                [4]Real{ x, 0, 0, 0 },
                [4]Real{ 0, y, 0, 0 },
                [4]Real{ 0, 0, z, 0 },
                [4]Real{ 0, 0, 0, 1 },
            },
        };
    }

    /// creates matrix that will translate a homogeneous matrix.
    pub fn createTranslationXYZ(x: Real, y: Real, z: Real) Mat4 {
        return Mat4{
            .fields = [4][4]Real{
                [4]Real{ 1, 0, 0, 0 },
                [4]Real{ 0, 1, 0, 0 },
                [4]Real{ 0, 0, 1, 0 },
                [4]Real{ x, y, z, 1 },
            },
        };
    }

    /// creates matrix that will scale a homogeneous matrix.
    pub fn createTranslation(v: Vec3) Mat4 {
        return Mat4{
            .fields = [4][4]Real{
                [4]Real{ 1, 0, 0, 0 },
                [4]Real{ 0, 1, 0, 0 },
                [4]Real{ 0, 0, 1, 0 },
                [4]Real{ v.x, v.y, v.z, 1 },
            },
        };
    }

    /// creates an orthogonal projection matrix.
    /// `left`, `right`, `bottom` and `top` are the borders of the screen whereas `near` and `far` define the
    /// distance of the near and far clipping planes.
    pub fn createOrthogonal(left: Real, right: Real, bottom: Real, top: Real, near: Real, far: Real) Mat4 {
        var result = Mat4.identity;
        result.fields[0][0] = 2 / (right - left);
        result.fields[1][1] = 2 / (top - bottom);
        result.fields[2][2] = -2 / (far - near);
        result.fields[3][0] = -(right + left) / (right - left);
        result.fields[3][1] = -(top + bottom) / (top - bottom);
        result.fields[3][2] = -(far + near) / (far - near);
        return result;
    }

    /// Batch matrix multiplication. Will multiply all matrices from "first" to "last".
    pub fn batchMul(items: []const Mat4) Mat4 {
        if (items.len == 0)
            return Mat4.identity;
        if (items.len == 1)
            return items[0];
        var value = items[0];
        for (1..items.len) |i| {
            value = value.mul(items[i]);
        }
        return value;
    }

    /// calculates the invert matrix when it's possible (returns null otherwise)
    /// only works on float matrices
    pub fn invert(src: Mat4) ?Mat4 {
        // https://github.com/stackgl/gl-mat4/blob/master/invert.js
        const a: [16]Real = @bitCast(src.fields);

        const a00 = a[0];
        const a01 = a[1];
        const a02 = a[2];
        const a03 = a[3];
        const a10 = a[4];
        const a11 = a[5];
        const a12 = a[6];
        const a13 = a[7];
        const a20 = a[8];
        const a21 = a[9];
        const a22 = a[10];
        const a23 = a[11];
        const a30 = a[12];
        const a31 = a[13];
        const a32 = a[14];
        const a33 = a[15];

        const b00 = a00 * a11 - a01 * a10;
        const b01 = a00 * a12 - a02 * a10;
        const b02 = a00 * a13 - a03 * a10;
        const b03 = a01 * a12 - a02 * a11;
        const b04 = a01 * a13 - a03 * a11;
        const b05 = a02 * a13 - a03 * a12;
        const b06 = a20 * a31 - a21 * a30;
        const b07 = a20 * a32 - a22 * a30;
        const b08 = a20 * a33 - a23 * a30;
        const b09 = a21 * a32 - a22 * a31;
        const b10 = a21 * a33 - a23 * a31;
        const b11 = a22 * a33 - a23 * a32;

        // Calculate the determinant
        var det = b00 * b11 - b01 * b10 + b02 * b09 + b03 * b08 - b04 * b07 + b05 * b06;

        if (std.math.approxEqAbs(Real, det, 0, 1e-8)) {
            return null;
        }
        det = 1.0 / det;

        const out = [16]Real{
            (a11 * b11 - a12 * b10 + a13 * b09) * det, // 0
            (a02 * b10 - a01 * b11 - a03 * b09) * det, // 1
            (a31 * b05 - a32 * b04 + a33 * b03) * det, // 2
            (a22 * b04 - a21 * b05 - a23 * b03) * det, // 3
            (a12 * b08 - a10 * b11 - a13 * b07) * det, // 4
            (a00 * b11 - a02 * b08 + a03 * b07) * det, // 5
            (a32 * b02 - a30 * b05 - a33 * b01) * det, // 6
            (a20 * b05 - a22 * b02 + a23 * b01) * det, // 7
            (a10 * b10 - a11 * b08 + a13 * b06) * det, // 8
            (a01 * b08 - a00 * b10 - a03 * b06) * det, // 9
            (a30 * b04 - a31 * b02 + a33 * b00) * det, // 10
            (a21 * b02 - a20 * b04 - a23 * b00) * det, // 11
            (a11 * b07 - a10 * b09 - a12 * b06) * det, // 12
            (a00 * b09 - a01 * b07 + a02 * b06) * det, // 13
            (a31 * b01 - a30 * b03 - a32 * b00) * det, // 14
            (a20 * b03 - a21 * b01 + a22 * b00) * det, // 15
        };
        return Mat4{
            .fields = @as([4][4]Real, @bitCast(out)),
        };
    }
};
