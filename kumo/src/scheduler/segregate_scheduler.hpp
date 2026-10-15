// src/scheduler/segregate_scheduler.hpp
#pragma once

#include <random>
#include <vector>

#include "scheduler/scheduler.hpp"
#include "model/platform_state.hpp"
#include "model/app.hpp"
#include "model/sandbox.hpp"

namespace kumo {

/**
 * SegregateScheduler (baseline):
 *
 *  - "Segregation only": every invocation runs in a plain container
 *    (cheapest sandbox), but risky functions are placed on *exclusive*
 *    workers so that they are never co-located with another tenant.
 *  - Low-risk (tier-0) invocations pack by load.
 *
 * This gives zero co-location violations without paying for stronger
 * sandboxes, but wastes capacity (risky tenants hold workers alone),
 * which shows up as latency under load.
 */
class SegregateScheduler : public Scheduler {
public:
    explicit SegregateScheduler(std::uint64_t seed,
                                SandboxModel sandbox = SandboxModel{})
        : sandbox_(sandbox)
        , rng_(seed)
    {}

    std::string name() const override {
        return "segregate";
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
        const SandboxLevel lvl = SandboxLevel::Container;

        std::uniform_real_distribution<double> jitter(0.0, 0.05);

        WorkerId best = 0;
        double best_score = 1e18;
        bool found = false;

        for (WorkerId wid : workers) {
            if (!state.can_host(wid, *func)) continue;
            const WorkerView& w = state.worker_view(wid);

            // Count *other* tenants that are currently active here.
            int other_active = 0;
            for (const auto& act : w.active_tenants) {
                if (act.tenant != inv.tenant_id()) {
                    other_active += 1;
                }
            }
            // Idle containers of other tenants are a "sticky" co-location
            // hazard (they may be reactivated).
            int other_warm = 0;
            for (const auto& c : w.containers) {
                if (!c.is_idle()) continue;
                const FunctionProfile* cf = state.get_function(c.function_id);
                if (cf && cf->tenant != inv.tenant_id()) {
                    other_warm += 1;
                    break;
                }
            }

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
                         + 1.0 * static_cast<double>(w.active_invocations);

            if (req > 0) {
                // Risky invocation: strongly prefer exclusive workers.
                score += 10000.0 * other_active;
                score += 200.0 * other_warm;
            } else {
                // Low-risk: pack; but avoid workers held by risky tenants.
                for (const auto& act : w.active_tenants) {
                    if (act.tenant != inv.tenant_id() && act.req > 0) {
                        score += 5000.0;
                        break;
                    }
                }
            }

            score += jitter(rng_);

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
