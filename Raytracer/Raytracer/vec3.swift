import Foundation

struct vec3 {
    var x = 0.0
    var y = 0.0
    var z = 0.0
}

func * (left: Double, right: vec3) -> vec3 {
    return vec3(x: left * right.x, y: left * right.y, z: left * right.z)
}

func + (left: vec3, right: vec3) -> vec3 {
    return vec3(x: left.x + right.x, y: left.y + right.y, z: left.z + right.z)
}

func - (left: vec3, right: vec3) -> vec3 {
    return vec3(x: left.x - right.x, y: left.y - right.y, z: left.z - right.z)
}

func dot (left: vec3, _ right: vec3) -> Double {
    return left.x * right.x + left.y * right.y + left.z * right.z
}

func unit_vector(v: vec3) -> vec3 {
    let length : Double = sqrt(dot(left: v, v))
    return vec3(x: v.x/length, y: v.y/length, z: v.z/length)
}


struct ray {
    var origin: vec3
    var direction: vec3
    
    func point_at_parameter(t: Double) -> vec3 {
        return origin + t * direction
    }
}

func color(r: ray) -> vec3 {
    let minusZ = vec3(x: 0, y: 0, z: -1.0)
    var t = hit_sphere(center: minusZ, 0.5, r)
    if t > 0.0 {
        let norm = unit_vector(v: r.point_at_parameter(t: t) - minusZ)
        return 0.5 * vec3(x: norm.x + 1.0, y: norm.y + 1.0, z: norm.z + 1.0)
    }
    let unit_direction = unit_vector(v: r.direction)
    t = 0.5 * (unit_direction.y + 1.0)
    return (1.0 - t) * vec3(x: 1.0, y: 1.0, z: 1.0) + t * vec3(x: 0.5, y: 0.7, z: 1.0)
}

func hit_sphere(center: vec3, _ radius: Double, _ r: ray) -> Double {
    let oc = r.origin - center
    let a = dot(left: r.direction, r.direction)
    let b = 2.0 * dot(left: oc, r.direction)
    let c = dot(left: oc, oc) - radius * radius
    let discriminant = b * b - 4 * a * c
    if discriminant < 0 {
        return -1.0
    } else {
        return (-b - sqrt(discriminant)) / (2.0 * a)
    }
}
