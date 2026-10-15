// src/scheduler/risk_static_scheduler.hpp
#pragma once

#include <random>
#include <vector>

#include "scheduler/scheduler.hpp"
#include "model/platform_state.hpp"
#include "model/app.hpp"
#include "model/sandbox.hpp"

namespace kumo {

/**
 * RiskStaticScheduler (baseline):
 *
 *  - Ignores co-location entirely.
 *  - Pins the sandbox level to the *static* risk tier of the function:
 *      k = required_level(risk).
 *  - Picks a worker by load: warm container first, otherwise the
 *    least-loaded worker (cpu ratio), with random tie-breaking.
 *
 * This is the "sandbox upgrade only" strategy: every risky function gets
 * its tier-matched sandbox, but risky functions may still share a host
 * with weakly-isolated neighbours (a weakest-link violation).
 */
class RiskStaticScheduler : public Scheduler {
public:
    explicit RiskStaticScheduler(std::uint64_t seed,
                                 SandboxModel sandbox = SandboxModel{})
        : sandbox_(sandbox)
        , rng_(seed)
    {}

    std::string name() const override {
        return "riskstatic";
    }

    SchedulingDecision schedule(const Invocation& inv,
                                const PlatformState& state) override
    {
        const FunctionProfile* func = state.get_function(inv.function_id());
        if (!func) {
            return SchedulingDecision::fail("unknown function id");
        }

        const auto workers = state.workers();
        if (workers.empty()) {
            return SchedulingDecision::fail("no workers");
        }

        const int req = sandbox_.required_level(func->risk);
        const SandboxLevel lvl = static_cast<SandboxLevel>(req);

        WorkerId best = 0;
        double best_score = 1e18;
        bool found = false;

        std::uniform_real_distribution<double> jitter(0.0, 0.05);

        for (WorkerId wid : workers) {
            if (!state.can_host(wid, *func)) continue;
            const WorkerView& w = state.worker_view(wid);

            // Warm container of (function, level) => strong preference.
            bool warm = false;
            for (const auto& c : w.containers) {
                if (c.function_id == inv.function_id() &&
                    c.sandbox == lvl && c.is_idle()) {
                    warm = true;
                    break;
                }
            }

            double cpu_ratio = (w.capacity.cpu_cores > 0.0)
                ? w.used.cpu_cores / w.capacity.cpu_cores : 0.0;

            double score = (warm ? 0.0 : 1000.0)
                         + 100.0 * cpu_ratio
                         + 1.0 * static_cast<double>(w.active_invocations)
                         + jitter(rng_);

            if (score < best_score) {
                best_score = score;
                best = wid;
                found = true;
            }
        }

        if (!found) {
            return SchedulingDecision::fail("no worker has enough capacity");
        }
        return SchedulingDecision::ok(best, lvl);
    }

private:
    SandboxModel sandbox_;
    std::mt19937_64 rng_;
};

} // namespace kumo
