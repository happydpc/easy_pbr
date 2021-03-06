#version 430 core

//in
layout(location = 0) in vec3 position_eye_in;
layout(location = 1) in vec3 normal_in; 
layout(location = 2) in vec2 tex_coord_in; 
layout(location = 3) in vec3 color_per_vertex_in; 


//out
//the locations are irrelevant because the link between the frag output and the texture is established at runtime by the shader function draw_into(). They just have to be different locations for each output
// layout(location = 0) out vec4 position_out; 
layout(location = 1) out vec4 diffuse_out;
// layout(location = 3) out vec4 specular_out;
// layout(location = 4) out vec4 shininess_out;
layout(location = 2) out vec3 normal_out;
layout(location = 3) out vec2 metalness_and_roughness_out;

// //uniform
uniform bool using_fat_gbuffer;
uniform vec3 solid_color;
uniform bool enable_solid_color; // whether to use solid color or color per vertex
uniform vec3 specular_color;
uniform float shininess;
uniform float metalness;
uniform float roughness;
uniform bool enable_visibility_test;




float map(float value, float inMin, float inMax, float outMin, float outMax) {
    float value_clamped=clamp(value, inMin, inMax); //so the value doesn't get modified by the clamping, because glsl may pass this by referece
    return outMin + (outMax - outMin) * (value_clamped - inMin) / (inMax - inMin);
}

//smoothstep but with 1st and 2nd derivatives that go more smoothly to zero
float smootherstep( float A, float B, float X ){
//    float t = linearstep( A, B, X );
    // float t= X;
    float t = map(X, A , B, 0.0, 1.0);

   return t * t * t * ( t * ( t * 6 - 15 ) + 10 );
}

// //encode the normal using the equation from Cry Engine 3 "A bit more deferred" https://www.slideshare.net/guest11b095/a-bit-more-deferred-cry-engine3
// vec2 encode_normal(vec3 normal){
//     if(normal==vec3(0)){ //we got a non existant normal, like if you have a point cloud without normals so we just output a zero
//         return vec2(0);
//     }
//     vec2 normal_encoded = normalize(normal.xy) * sqrt(normal.z*0.5+0.5);
//     return normal_encoded;
// }

//encode as xyz https://knarkowicz.wordpress.com/2014/04/16/octahedron-normal-vector-encoding/
vec3 encode_normal(vec3 normal){
    if(using_fat_gbuffer){
        return normal;
    }else{
        return normal * 0.5 + 0.5;
    }
}



void main(){

    //make a circle by discardig stuff around the border of the square patch
    float local_r=dot(tex_coord_in,tex_coord_in);
    if(local_r>1.0){
        discard;
    }

    //if we enable the visibility test then we just render into the depth, and nothing else. then in the second pass we render only the surfels that are visible
    if(!enable_visibility_test){
        // float surface_confidence=map(local_r, 0.0, 1.0, 1.0, 0.01); //decreasing confidence from the middle to the edge of the surfel
        float surface_confidence=smootherstep(0.0, 1.0,  1.0-local_r); //decreasing confidence from the middle to the edge of the surfel

        diffuse_out = vec4(color_per_vertex_in*surface_confidence, surface_confidence );
        normal_out = encode_normal( normal_in );
        metalness_and_roughness_out=vec2(metalness, roughness)*surface_confidence;
        // normal_out = vec4(  encode_normal( normal_eye_in*surface_confidence ), 1.0, 1.0);
        // position_out = vec4(position_eye_in*surface_confidence, 1.0);
    }

   

}