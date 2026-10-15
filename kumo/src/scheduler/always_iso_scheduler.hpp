// src/scheduler/always_iso_scheduler.hpp
#pragma once

#include <random>
#include <vector>

#include "scheduler/scheduler.hpp"
#include "model/platform_state.hpp"
#include "model/app.hpp"
#include "model/sandbox.hpp"

namespace kumo {

/**
 * AlwaysIsoScheduler (baseline):
 *
 *  - "Always isolate": every invocation runs in the strongest sandbox
 *    (Kata / microVM), regardless of its risk score.
 *  - Worker choice by load: warm container first, then least-loaded.
 *
 * This gives zero co-location violations by construction, but pays the
 * highest cold-start, overhead and cost. It is the security-maximal
 * (and performance-minimal) point of the trade-off curve.
 */
class AlwaysIsoScheduler : public Scheduler {
public:
    explicit AlwaysIsoScheduler(std::uint64_t seed)
        : rng_(seed)
    {}

    std::string name() const override {
        return "alwaysiso";
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

        const SandboxLevel lvl = SandboxLevel::Kata;

        WorkerId best = 0;
        double best_score = 1e18;
        bool found = false;

        std::uniform_real_distribution<double> jitter(0.0, 0.05);

        for (WorkerId wid : workers) {
            if (!state.can_host(wid, *func)) continue;
            const WorkerView& w = state.worker_view(wid);

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
    std::mt19937_64 rng_;
};

} // namespace kumo
