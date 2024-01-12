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
    name: string,
    depth: int,
    // the indexes of all the childs
    childs: [dynamic]int,
    transforms: [32]Mat4,
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

node_parse_scene :: proc(element: xml.Element, doc: ^xml.Document, nodes: ^[dynamic]Node, depth: int, parent: int) {
    own_index := len(nodes);
    node: Node;
    for attr in element.attribs {
        if (attr.key == "name") {
            node.name = attr.val[crop:];
            // fmt.printf(node.name)
        }
    }
    node.depth = depth;
    append(nodes, node);
    if (depth > 0) {
        append(&nodes[parent].childs, own_index);
    }
    for idx in element.value[1:] {
        child := doc.elements[idx.(u32)];
        node_parse_scene(child, doc, nodes, depth+1, own_index);
    }
}

node_print :: proc(node: Node, nodes: ^[dynamic]Node, depth:int) {
    for _ in 0..<depth {
        fmt.printf(" ");
    }
    fmt.println(node.name);
    for child in node.childs {
        cnode := nodes[child];
        node_print(cnode, nodes, depth+1);
    }
}

// first pass, just add the raw transforms into the node_list
node_add_animation_data :: proc(element: xml.Element, doc: ^xml.Document, nodes: ^[dynamic]Node) {
    for value, vi in element.value {
        anim := doc.elements[value.(u32)];
        // fmt.println(anim.attribs[0].val);
        node_i : int
        found := false
        for node, i in nodes {
            current_name := anim.attribs[0].val;
            if len(current_name) < crop+len(node.name) {
                continue;
            }
            if node.name == anim.attribs[0].val[crop:crop+len(node.name)] {
                node_i = i;
                found = true;
            }
        }
        assert(found);
        source := doc.elements[anim.value[1].(u32)];
        array := doc.elements[source.value[0].(u32)];
        rows, _ := strings.split(array.value[0].(string), "\n");
        assert(len(rows) == 32);
        for row, i in rows {
            nodes[node_i].transforms[i] = node_string_to_mat4(row)
        }
    }
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
    anims := doc.elements[rig_anim_library_index];
    nodes: [dynamic]Node;
    node_parse_scene(root, doc, &nodes, 0, 0);
    node_add_animation_data(anims, doc, &nodes);

    /*
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
            if rl.IsKeyPressed(.BACKSPACE) { break; }
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
    */
}


