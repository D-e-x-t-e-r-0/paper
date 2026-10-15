// src/model/sandbox.hpp
#pragma once

#include <algorithm>
#include <cstdint>
#include <string>

#include "common/types.hpp"

namespace kumo {

/**
 * Sandbox levels modelled after real serverless isolation options.
 *
 *  - Container : runc/Docker-style shared-kernel container (weakest).
 *  - GVisor    : user-space kernel with syscall interception (medium).
 *  - Kata      : Kata Containers / microVM with a separate kernel
 *                (strongest, most expensive).
 *
 * The scheduler chooses a sandbox level *jointly* with the host, so a
 * placement decision is a (worker, sandbox) pair.
 */
enum class SandboxLevel : std::uint8_t {
    Container = 0,
    GVisor    = 1,
    Kata      = 2,
};

inline const char* sandbox_name(SandboxLevel l) noexcept {
    switch (l) {
        case SandboxLevel::Container: return "container";
        case SandboxLevel::GVisor:    return "gvisor";
        case SandboxLevel::Kata:      return "kata";
    }
    return "unknown";
}

inline int sandbox_rank(SandboxLevel l) noexcept {
    return static_cast<int>(l);
}

/**
 * Per-level timing / cost / protection parameters.
 *
 * All timings are in the same unit as TimePoint/Duration (we use ms).
 */
struct SandboxLevelParams {
    Duration cold_start  = 100.0;  // cold-start latency
    Duration warm_start  = 1.0;    // warm reuse latency
    Duration overhead    = 0.0;    // extra service time per invocation
    double   cost_per_ms = 0.0;    // cost units per ms of sandbox lifetime
    double   strength    = 0.0;    // 0 = shared kernel, 1 = gVisor, 2 = microVM
};

/**
 * SandboxModel: global parameters shared by the engine and the schedulers.
 *
 * Risk tiers map a per-function risk score to the *minimum* sandbox level
 * the function requires:
 *
 *      risk <  theta1            -> Container (tier 0)
 *      theta1 <= risk < theta2   -> GVisor    (tier 1)
 *      risk >= theta2            -> Kata      (tier 2)
 */
struct SandboxModel {
    bool enabled = false;

    // levels[0] = container, levels[1] = gvisor, levels[2] = kata
    SandboxLevelParams levels[3];

    // Risk-tier thresholds.
    double theta1 = 0.3;
    double theta2 = 0.7;

    const SandboxLevelParams& level(SandboxLevel l) const noexcept {
        return levels[static_cast<int>(l)];
    }
    SandboxLevelParams& level_mut(SandboxLevel l) noexcept {
        return levels[static_cast<int>(l)];
    }

    /// Minimum sandbox level required by a given risk score.
    int required_level(double risk) const noexcept {
        if (risk < theta1) return 0;
        if (risk < theta2) return 1;
        return 2;
    }

    /// Default parameterisation. Cold-start / overhead values roughly
    /// follow published measurements for runc, gVisor and Kata/Firecracker.
    static SandboxModel defaults() {
        SandboxModel m;
        m.enabled = true;
        m.levels[0] = SandboxLevelParams{100.0, 1.0, 0.0, 1.0e-3, 0.0};
        m.levels[1] = SandboxLevelParams{250.0, 5.0, 3.0, 1.4e-3, 1.0};
        m.levels[2] = SandboxLevelParams{400.0, 10.0, 1.0, 2.2e-3, 2.0};
        return m;
    }
};

} // namespace kumo
