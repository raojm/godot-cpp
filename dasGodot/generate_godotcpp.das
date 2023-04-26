require cbind/cbind_boost
require fio
require daslib/defer
require daslib/strings_boost

class GodotGen : CppGenBind
    override include_parse_file = true
    override include_local_parse_file = true
    override func_to_stdout = false
    override generate_lsp = false
    override generate_constant_decl = false


    godot_skip_func : table<string; bool>
    def GodotGen(mod_name,das_mod_name,pfn,pfp:string)
        bind_root = "{get_das_root()}/../godot-cpp/dasGodot/src"
        bind_module = mod_name
        bind_das_module = das_mod_name
        let i_godot = "{get_das_root()}/../godot-cpp/include/"
        let i_godot_platform = "{get_das_root()}/../godot-cpp/gen/include/"
        let i_godot_editor = "{get_das_root()}/../godot/editor/"
        let dddd = get_full_file_name(i_godot)
        print("get_full_file_name(i_godot): {dddd} \n")
        let args <- [{string
            "-xc++-header";
            "-std=c++17";
            "-I{i_godot}";
            "-I{i_godot_platform}"
            // "-I{get_full_file_name(i_godot_editor)}"
            // "-DIMGUI_DISABLE_OBSOLETE_FUNCTIONS"
        }]
        func_per_chunk = 50
        init_args(pfn,pfp,args)
        init_rename()
        setDefaultFiles()
        openAllFiles()
    def init_rename
        aot_alias <- {{
            "ImVec2"    =>  true
            // "ImVec4"    =>  true;
            // "ImColor"   =>  true
        }}
        alias2type <- {{
            // "Variant"                  => "Variant_"
            "ImGuiCond"                 => "ImGuiCond_"
            // "ImGuiDataType"             => "ImGuiDataType_";
            // "ImGuiDir"                  => "ImGuiDir_";
            // "ImGuiKey"                  => "ImGuiKey_";
            // "ImGuiNavInput"             => "ImGuiNavInput_";
            // "ImGuiMouseButton"          => "ImGuiMouseButton_";
            // "ImGuiMouseCursor"          => "ImGuiMouseCursor_";
            // "ImGuiSortDirection"        => "ImGuiSortDirection_";
            // "ImGuiStyleVar"             => "ImGuiStyleVar_";
            // "ImGuiTableBgTarget"        => "ImGuiTableBgTarget_";
            // "ImDrawFlags"               => "ImDrawFlags_";
            // "ImDrawListFlags"           => "ImDrawListFlags_";
            // "ImFontAtlasFlags"          => "ImFontAtlasFlags_";
            // "ImGuiBackendFlags"         => "ImGuiBackendFlags_";
            // "ImGuiButtonFlags"          => "ImGuiButtonFlags_";
            // "ImGuiColorEditFlags"       => "ImGuiColorEditFlags_";
            // "ImGuiConfigFlags"          => "ImGuiConfigFlags_";
            // "ImGuiComboFlags"           => "ImGuiComboFlags_";
            // "ImGuiDragDropFlags"        => "ImGuiDragDropFlags_";
            // "ImGuiFocusedFlags"         => "ImGuiFocusedFlags_";
            // "ImGuiHoveredFlags"         => "ImGuiHoveredFlags_";
            // "ImGuiInputTextFlags"       => "ImGuiInputTextFlags_";
            // "ImGuiKeyModFlags"          => "ImGuiKeyModFlags_";
            // "ImGuiPopupFlags"           => "ImGuiPopupFlags_";
            // "ImGuiSelectableFlags"      => "ImGuiSelectableFlags_";
            // "ImGuiSliderFlags"          => "ImGuiSliderFlags_";
            // "ImGuiTabBarFlags"          => "ImGuiTabBarFlags_";
            // "ImGuiTabItemFlags"         => "ImGuiTabItemFlags_";
            // "ImGuiTableFlags"           => "ImGuiTableFlags_";
            // "ImGuiTableColumnFlags"     => "ImGuiTableColumnFlags_";
            // "ImGuiTableRowFlags"        => "ImGuiTableRowFlags_";
            // "ImGuiTreeNodeFlags"        => "ImGuiTreeNodeFlags_";
            // "ImGuiViewportFlags"        => "ImGuiViewportFlags_";
            // "ImGuiWindowFlags"          => "ImGuiWindowFlags_"
        }}
        godot_skip_func <- {{
            "ImGui::TextUnformatted" => true
        }}
        for v in values(alias2type)
            enums_with_flags[v] = true
    def override skip_anyFunction ( var c : CXCursor; isMethod : bool )
        // return false;
        if AnyGenBind`skip_anyFunction(self, c, isMethod)
            return true
        let function_name = namespace_name(string(clang_getCursorSpelling(c)))
        if godot_skip_func |> key_exists(function_name)
            to_log(LOG_INFO, "skipping Godot blocked function {function_name} at {clang_getCursorLocationDescription(c)}")
            return true
        return false
    def override skip_file ( fname:string ) : bool
        print("\n skip_file1: {fname} \n")
        if(fname == "")
            return true
        if find(fname, "input.h") != -1
            return false
        if find(fname, "/usr/include") != -1
            print("\n contian /usr/include fname:{fname} \n ")
            return true
        // print("\n skip_file end \n")
        return false
    def override skip_alias ( var c : CXCursor )
        return false
    def override skip_enum ( ns_en, en : string )
        if(find(ns_en, "unnamed enum") >=0)
            return true
        return false
    def override skip_struct ( sn:string )
        print("\n skip_struct sn: {sn}\n")
        if(find(sn, "unnamed") >=0 || find(sn, "anonymous") >=0 || starts_with(sn, "__"))
            return true
        return false
    // def override skip_function ( var c : CXCursor ) : bool
    //     return false
    // def override isArgByValue ( name:string )
    //     return true
    def override generateModuleHPrefix
        module_h_file |> fwrite("#include \"godot_all.h\"\n")


class GodotSubmoduleGen : GodotGen
    cb_extra : string = ""
    def GodotSubmoduleGen(mod_name,das_mod_name,pfn,pfp:string)
        GodotGen`GodotGen(self,mod_name,das_mod_name,pfn,pfp)
    def override generateModuleHPrefix
        // module_h_file |> fwrite("#include \"cb_dasIMGUI.h\"\n")
        if cb_extra != ""
            module_h_file |> fwrite(cb_extra)
        module_h_file |> fwrite("#include \"need_core.h\"\n")

[export]
def main
    if true
        var cgb = new GodotGen("core","godot_core","input.hpp","{get_das_root()}/../godot-cpp/gen/include/godot_cpp/classes/")
        defer <|
            unsafe
                delete cgb
        cgb->generate()
        cgb->genCMakeDecl("DAS_CORE_BIND")
    if false
        var cgb = new GodotSubmoduleGen("classdb","godot::classdb","core/object/class_db.h","{get_das_root()}/../godot/")
        defer <|
            unsafe
                delete cgb
        // cgb.require_modules <- [{auto "imgui"}]
        // cgb.already_defined <- {{
        //     "ImGuiContext" => true
        // }}
        // cgb.cb_extra = "#include \"cb_dasIMNODES.h\"\n"
        cgb->generate()
        cgb->genCMakeDecl("DAS_classdb_BIND")
    // if true
    //     var cgb = new GodotSubmoduleGen("dasIMGUI_NODE_EDITOR","imgui_node_editor","imgui_node_editor.h","{get_das_root()}/Modules/dasImgui/imgui-node-editor/")
    //     defer <|
    //         unsafe
    //             delete cgb
    //     cgb.require_modules <- [{auto "imgui"}]
    //     cgb.already_defined <- {{
    //         "ImGuiContext" => true
    //     }}
    //     cgb.aot_alias["ax::NodeEditor::NodeId"] = true
    //     cgb.aot_alias["ax::NodeEditor::LinkId"] = true
    //     cgb.aot_alias["ax::NodeEditor::PinId"] = true
    //     cgb.cb_extra = "#include \"cb_dasIMGUI_NODE_EDITOR.h\"\n"
    //     cgb->generate()
    //     cgb->genCMakeDecl("DAS_IMGUI_NODE_EDITOR_BIND")
