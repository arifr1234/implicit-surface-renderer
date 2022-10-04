uniform vec2 resolution;
uniform vec2 angles;

struct scene_params{
    vec3 ray;
    vec3 camera;
};

scene_params get_scene_params(vec2 frag_coord)
{
    vec2 uv = (frag_coord - resolution / 2.) / min(resolution.x, resolution.y);

    vec3 forward = vec3(cos(angles.y) * vec2(cos(angles.x), sin(angles.x)), sin(angles.y));
    vec3 right = vec3(-sin(angles.x), cos(angles.x), 0);
    vec3 up = cross(forward, right);

    vec3 camera = -10. * forward;
        
    float zoom = 1.;
    vec3 ray = mat3x3(right, up, forward) * vec3(uv, zoom);
    ray = normalize(ray);

    return scene_params(ray, camera);
}