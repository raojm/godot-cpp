require cbind/cbind_boost
require daslib/safe_addr
require daslib/strings
require daslib/defer
require daslib/fio


class GodotGen : CppGenBind
    override func_to_stdout = false
    override include_local_parse_file = true
    override generate_constant_decl = true
    
    unique_functions : table<string; bool>

    def GodotGen
        bind_root = "/Users/raojm/projects/godot-cpp/dasGodot/src"
        bind_module = "godot"
        bind_das_module = "godot"
        let pfn = "godot_cpp/classes/input.hpp"
        let pfp = "/Users/raojm/projects/godot-cpp/gen/include/"
        print("dfsfds: {pfp} \n")
        let args <- [{string
            "-xc++-header";
            "-std=c++17";
            "-I{pfp}";
            "-I/Users/raojm/projects/godot-cpp/include";
            "-I/Users/raojm/projects/godot-cpp/gen/include";
            "-I/Users/raojm/projects/godot-cpp/gdextension"
            // "-I/usr/local/opt/llvm/lib/clang/16/include"
        }]

        func_per_chunk = 20
        init_args(pfn,pfp,args)
        setDefaultFiles()
        //init_skip_func()
        openAllFiles()


    def override namespace_name(name:string; dash:string="::") : string
        return AnyGenBind`namespace_name(self, name, dash)

    // def override skip_struct(name : string)
    //     return false
    //     //return AnyGenBind`skip_struct(name)

    def override skip_anyFunction(var c : CXCursor; isMethod:bool) : bool
        let funcname = string(clang_getCursorSpelling(c))
        print("funcname: {funcname} \n")
        if unique_functions |> key_exists(funcname)
            return true
        else
            unique_functions[funcname] = true
            return AnyGenBind`skip_anyFunction(self, c, isMethod)


    // def override skip_file(fname:string) : bool
    //     return true


    def override generateModuleHPrefix
        module_h_file |> fwrite("#include \"godot.hpp\"\n")



[export]
def main
    var cgb = new GodotGen()
    defer <|
        unsafe
            delete cgb
    cgb->generate()
    cgb->genCMakeDecl("DAS_GODOT_BIND")