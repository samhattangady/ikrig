package main

import "core:fmt"
import "core:os"

file_path :: "data/Walking_Rig.fbx"

main :: proc() {
    fmt.println("Hellope!")
    data, success := os.read_entire_file_from_filename(filepath);
    fmt.println(len(data))
}
