// DESCRIPTION: Verilator: Verilog example module
//
// This file ONLY is placed under the Creative Commons Public Domain, for
// any use, without warranty, 2017 by Wilson Snyder.
// SPDX-License-Identifier: CC0-1.0
//======================================================================

// For std::unique_ptr
#include <memory>
#include <cstdlib>
#include <filesystem>
#include <iostream>
#include <sstream>
#include <stdexcept>
#include <string>
#include <system_error>
#include <vector>
#include <unistd.h>

// Include common routines
#include <verilated.h>

// Include model header, generated from Verilating "top.v"
#include "Vtop.h"

// Legacy function required only so linking works on Cygwin and MSVC++
double sc_time_stamp() { return 0; }

namespace {

namespace fs = std::filesystem;

std::string getEnvVar(const char* name) {
    const char* value = std::getenv(name);
    return value ? std::string(value) : std::string();
}

std::string quote(const fs::path& path) {
    std::ostringstream oss;
    oss << "\"" << path.string() << "\"";
    return oss.str();
}

bool runCommand(const std::string& cmd) {
#ifdef C910_DEBUG_BOOT
    std::cerr << "[sim_main1][BOOT] running: " << cmd << std::endl;
#endif
    int ret = std::system(cmd.c_str());
    if (ret != 0) {
        std::cerr << "[sim_main1] Command failed (" << ret << "): " << cmd << std::endl;
        return false;
    }
#ifdef C910_DEBUG_BOOT
    std::cerr << "[sim_main1][BOOT] ok: " << cmd << std::endl;
#endif
    return true;
}

struct TempDir {
    fs::path path;
    bool keep{false};
    ~TempDir() {
        if (!keep && !path.empty()) {
            std::error_code ec;
            fs::remove_all(path, ec);
            if (ec) {
                std::cerr << "[sim_main1] Warning: failed to remove temp dir " << path << ": " << ec.message() << std::endl;
            }
        }
    }
};

fs::path makeTempDir(const std::string& prefix) {
    fs::path tmpl = fs::temp_directory_path() / (prefix + "XXXXXX");
    std::string tmplStr = tmpl.string();
    std::vector<char> buffer(tmplStr.begin(), tmplStr.end());
    buffer.push_back('\0');
    char* dirName = mkdtemp(buffer.data());
    if (!dirName) {
        throw std::runtime_error("[sim_main1] Failed to create temporary directory");
    }
    return fs::path(dirName);
}

}  // namespace

int main(int argc, char** argv, char** env) {
    // This is a more complicated example, please also see the simpler examples/make_hello_c.

    // Prevent unused variable warnings
    if (false && argc && argv && env) {}

    // Create logs/ directory in case we have traces to put under it
    Verilated::mkdir("logs");

    std::vector<std::string> forwardedArgs;
    forwardedArgs.reserve(argc + 4);
    forwardedArgs.emplace_back(argv[0]);

    std::string elfPath;
    bool keepTemp = getEnvVar("KEEP_C910_TEMP") == "1";

#ifdef C910_DEBUG_BOOT
    std::cerr << "[sim_main1][BOOT] argc=" << argc << std::endl;
#endif
    for (int i = 1; i < argc; ++i) {
        std::string arg(argv[i]);
        if (arg == "--elf" && (i + 1) < argc) {
            elfPath = argv[++i];
        } else if (arg.rfind("--elf=", 0) == 0) {
            elfPath = arg.substr(6);
        } else if (arg == "--keep-temp") {
            keepTemp = true;
        } else {
            forwardedArgs.emplace_back(std::move(arg));
        }
    }

    TempDir tempDir;
    tempDir.keep = keepTemp;

    if (!elfPath.empty()) {
#ifdef C910_DEBUG_BOOT
        std::cerr << "[sim_main1][BOOT] KEEP_C910_TEMP=" << (keepTemp ? "1" : "0") << std::endl;
#endif
        try {
            tempDir.path = makeTempDir("c910_");
        } catch (const std::exception& e) {
            std::cerr << e.what() << std::endl;
            return 1;
        }

#ifdef C910_DEBUG_BOOT
        std::cerr << "[sim_main1][BOOT] temp dir: " << tempDir.path << std::endl;
#endif
        fs::path elf = fs::absolute(elfPath);
        fs::path instHex = tempDir.path / "inst.hex";
        fs::path dataHex = tempDir.path / "data.hex";
        fs::path fileHex = tempDir.path / "case.hex";
        fs::path instPat = tempDir.path / "inst.pat";
        fs::path dataPat = tempDir.path / "data.pat";

        std::string toolExt = getEnvVar("TOOL_EXTENSION");
        fs::path objcopyPath = toolExt.empty()
                                   ? fs::path("riscv64-unknown-elf-objcopy")
                                   : fs::path(toolExt) / "riscv64-unknown-elf-objcopy";

        std::string srec2vmemPath = getEnvVar("SREC2VMEM");
        if (srec2vmemPath.empty()) {
            std::cerr << "[sim_main1] Environment variable SREC2VMEM is not set. "
                      << "Please export it to the Srec2vmem executable path.\n";
            return 1;
        }

#ifdef C910_DEBUG_BOOT
        std::cerr << "[sim_main1][BOOT] elf: " << elf << std::endl;
        std::cerr << "[sim_main1][BOOT] objcopy: " << objcopyPath << std::endl;
        std::cerr << "[sim_main1][BOOT] Srec2vmem: " << srec2vmemPath << std::endl;
        std::cerr << "[sim_main1][BOOT] outputs:\n"
                  << "  instHex=" << instHex << "\n"
                  << "  dataHex=" << dataHex << "\n"
                  << "  fileHex=" << fileHex << "\n"
                  << "  instPat=" << instPat << "\n"
                  << "  dataPat=" << dataPat << std::endl;
#endif
        std::ostringstream cmd;
        cmd << quote(objcopyPath) << " -O srec " << quote(elf) << " " << quote(instHex)
            << " -j .text* -j .rodata* -j .eh_frame*";
        if (!runCommand(cmd.str())) {
            return 1;
        }
        cmd.str("");
        cmd.clear();
        cmd << quote(objcopyPath) << " -O srec " << quote(elf) << " " << quote(dataHex)
            << " -j .data* -j .bss -j .COMMON";
        if (!runCommand(cmd.str())) {
            return 1;
        }
        cmd.str("");
        cmd.clear();
        cmd << quote(objcopyPath) << " -O srec " << quote(elf) << " " << quote(fileHex);
        if (!runCommand(cmd.str())) {
            return 1;
        }

        cmd.str("");
        cmd.clear();
        cmd << quote(fs::path(srec2vmemPath)) << " " << quote(instHex) << " " << quote(instPat);
        if (!runCommand(cmd.str())) {
            return 1;
        }
        cmd.str("");
        cmd.clear();
        cmd << quote(fs::path(srec2vmemPath)) << " " << quote(dataHex) << " " << quote(dataPat);
        if (!runCommand(cmd.str())) {
            return 1;
        }

        forwardedArgs.emplace_back("+INST=" + instPat.string());
        forwardedArgs.emplace_back("+DATA=" + dataPat.string());
#ifdef C910_DEBUG_BOOT
        std::cerr << "[sim_main1][BOOT] plusargs: +INST=" << instPat << " +DATA=" << dataPat << std::endl;
#endif
    }

    std::vector<char*> forwardedArgv;
    forwardedArgv.reserve(forwardedArgs.size());
    for (auto& arg : forwardedArgs) {
        forwardedArgv.push_back(arg.data());
    }

    // Construct a VerilatedContext to hold simulation time, etc.
    // Multiple modules (made later below with Vtop) may share the same
    // context to share time, or modules may have different contexts if
    // they should be independent from each other.

    // Using unique_ptr is similar to
    // "VerilatedContext* contextp = new VerilatedContext" then deleting at end.
    const std::unique_ptr<VerilatedContext> contextp{new VerilatedContext};

    // Set debug level, 0 is off, 9 is highest presently used
    // May be overridden by commandArgs argument parsing
    contextp->debug(0);

    // Randomization reset policy
    // May be overridden by commandArgs argument parsing
    contextp->randReset(2);

    // Verilator must compute traced signals
    contextp->traceEverOn(true);

    // Pass arguments so Verilated code can see them, e.g. $value$plusargs
    // This needs to be called before you create any model
    contextp->commandArgs(static_cast<int>(forwardedArgv.size()), forwardedArgv.data());

    // Construct the Verilated model, from Vtop.h generated from Verilating "top.v".
    // Using unique_ptr is similar to "Vtop* top = new Vtop" then deleting at end.
    // "TOP" will be the hierarchical name of the module.
    const std::unique_ptr<Vtop> top{new Vtop{contextp.get(), "TOP"}};

#ifdef C910_DEBUG_BOOT
    std::cerr << "[sim_main1][BOOT] Vtop constructed, starting main loop..." << std::endl;
#endif
    // Set Vtop's input signals
    top->clk = 0;

    // Simulate until $finish
    while (!contextp->gotFinish()) {
        // Historical note, before Verilator 4.200 Verilated::gotFinish()
        // was used above in place of contextp->gotFinish().
        // Most of the contextp-> calls can use Verilated:: calls instead;
        // the Verilated:: versions simply assume there's a single context
        // being used (per thread).  It's faster and clearer to use the
        // newer contextp-> versions.

        contextp->timeInc(1);  // 1 timeprecision period passes...
        // Historical note, before Verilator 4.200 a sc_time_stamp()
        // function was required instead of using timeInc.  Once timeInc()
        // is called (with non-zero), the Verilated libraries assume the
        // new API, and sc_time_stamp() will no longer work.

        // Toggle a fast (time/2 period) clock
        top->clk = !top->clk;

        // Toggle control signals on an edge that doesn't correspond
        // to where the controls are sampled; in this example we do
        // this only on a negedge of clk, because we know
        // reset is not sampled there.
        //if (!top->clk) {
        //    if (contextp->time() > 1 && contextp->time() < 10) {
        //        top->reset_l = !1;  // Assert reset
        //    } else {
        //        top->reset_l = !0;  // Deassert reset
        //    }
        //    // Assign some other inputs
        //    top->in_quad += 0x12;
        //}

        // Evaluate model
        // (If you have multiple models being simulated in the same
        // timestep then instead of eval(), call eval_step() on each, then
        // eval_end_step() on each. See the manual.)
        top->eval();

        // Read outputs
        //VL_PRINTF("[%" VL_PRI64 "d] clk=%x rstl=%x iquad=%" VL_PRI64 "x"
        //          " -> oquad=%" VL_PRI64 "x owide=%x_%08x_%08x\n",
        //          contextp->time(), top->clk, top->reset_l, top->in_quad, top->out_quad,
        //          top->out_wide[2], top->out_wide[1], top->out_wide[0]);
#ifdef C910_DEBUG_BOOT
        // Heartbeat from C++ every ~1e6 time units
        static vluint64_t last_print_t = 0;
        vluint64_t now_t = contextp->time();
        if (VL_UNLIKELY(now_t - last_print_t >= 1000000)) {
            last_print_t = now_t;
            std::cerr << "[sim_main1][BOOT] t=" << now_t << std::endl;
        }
#endif
    }

#ifdef C910_DEBUG_BOOT
    std::cerr << "[sim_main1][BOOT] main loop finished, calling final()" << std::endl;
#endif
    // Final model cleanup
    top->final();

    // Coverage analysis (calling write only after the test is known to pass)
#if VM_COVERAGE
    Verilated::mkdir("logs");
    contextp->coveragep()->write("logs/coverage.dat");
#endif

    // Return good completion status
    // Don't use exit() or destructor won't get called
    return 0;
}
