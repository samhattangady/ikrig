package main

import "core:fmt"
import "core:os"
import "core:strings"
import "core:strconv"
import "core:encoding"
import "core:encoding/xml"
import rl "vendor:raylib"

draw_3d :: false
file_path :: "data/Walking_Rig.dae"
crop :: len("mixamorig_")
rig_anim_library_index :: 12;
rig_scene_library_index :: 1106;
scene_library_index :: 1270;

Node :: struct {
    position: Vec3,
    name: string,
    depth: int,
}

Mat4 :: distinct matrix[4,4]f32;
mat4_unit := Mat4{
    1,0,0,0,
    0,1,0,0,
    0,0,1,0,
    0,0,0,1,
};
Vec3 :: distinct [3]f32
vec3_to_rl :: proc(v: Vec3) -> rl.Vector3 {
    return rl.Vector3{v[0], v[1], v[2]};
}

node_string_to_mat4 :: proc(data: string) -> Mat4 {
    mat: Mat4;
    vals, _ := strings.split(data, " ");
    for substr, i in vals {
        val, _ := strconv.parse_f32(substr);
        mat[i/4, i%4] = val;
    }
    return mat;
}

node_add_children :: proc(element: xml.Element, doc: ^xml.Document, nodes: ^[dynamic]Node, matrices: ^[dynamic]Mat4, depth: int) {
    assert(len(matrices) == depth+1);
    for i in 0..<depth {
        fmt.printf(" ");
    }
    node: Node;
    for attr in element.attribs {
        if (attr.key == "name") {
            node.name = attr.val[crop:];
            fmt.printf(node.name)
        }
    }
    mat_elem := doc.elements[element.value[0].(u32)]
    assert(mat_elem.ident == "matrix");
    mat := node_string_to_mat4(mat_elem.value[0].(string));
    // node.position = relative_position;
    fmt.println(node.position);
    next := matrices[depth]*mat;
    append(matrices, next);
    pos := next * [4]f32{0,0,0,1};
    node.position = Vec3{pos[0],pos[1],pos[2]};
    node.depth = depth;
    append(nodes, node);
    for idx in element.value[1:] {
        child := doc.elements[idx.(u32)];
        node_add_children(child, doc, nodes, matrices, depth+1);
    }
    pop(matrices);
}


main :: proc() {
    data, success := os.read_entire_file_from_filename(file_path);
    doc, errs := xml.parse(data);
    // fmt.println("Number of elements:", doc.element_count);
    // for element, i in doc.elements {
    //     if element.ident == "visual_scene" {
    //         fmt.println("visual scene at index", i);
    //     }
    // }
    scene := doc.elements[rig_scene_library_index];
    root := doc.elements[scene.value[0].(u32)];
    nodes: [dynamic]Node;
    matrices: [dynamic]Mat4;
    append(&matrices, mat4_unit);
    node_add_children(root, doc, &nodes, &matrices, 0);
    
        // Define the camera to look into our 3d world
        cubePosition := Vec3{0, 1, 0};
        camera := rl.Camera3D{};
        camera.position = rl.Vector3{ 300.0, 300.0, 300.0 };
        camera.target = rl.Vector3{0.91047394, 100.06774199, 1.015365};
        camera.up = rl.Vector3{ 0.0, 1.0, 0.0 };
        camera.fovy = 45.0;
        camera.projection = .PERSPECTIVE;
        rl.InitWindow(1080, 720, "raylib [core] example - basic window")
        for !rl.WindowShouldClose() {
            rl.UpdateCamera(&camera, .ORBITAL);
            rl.BeginDrawing()
            rl.ClearBackground(rl.RAYWHITE)
            rl.BeginMode3D(camera);
                for node, i in nodes {
                    size := 10/(cast(f32)node.depth+1);
                    rl.DrawCube(vec3_to_rl(node.position), size, size, size, rl.RED);
                    rl.DrawCubeWires(vec3_to_rl(node.position), size, size, size, rl.MAROON);
                    // if (node.name == "Head") {
                    //     rl.DrawCube(vec3_to_rl(node.position), 20, 20, 20, rl.RED);
                    // }
                    // if (node.name == "HeadTop_End") {
                    //     rl.DrawCube(vec3_to_rl(node.position), 25, 25, 25, rl.MAROON);
                    // }
                }
            rl.EndMode3D();
            rl.EndDrawing()
        }
        rl.CloseWindow()
}


