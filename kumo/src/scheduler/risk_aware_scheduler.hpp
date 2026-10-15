// src/scheduler/risk_aware_scheduler.hpp
#pragma once

#include <algorithm>
#include <random>
#include <vector>

#include "scheduler/scheduler.hpp"
#include "model/platform_state.hpp"
#include "model/app.hpp"
#include "model/sandbox.hpp"

namespace kumo {

/**
 * Tunable parameters for the risk-aware scheduler.
 */
struct RiskSchedulerParams {
    SandboxModel sandbox;

    // Score weights:  score = wR * V + wL * L + wC * C + wS * O
    double wr = 1000.0;   // expected-violation penalty
    double wl = 1.0;      // latency weight (ms)
    double wc = 50.0;     // cost weight (cost units)
    double ws = 1.0;      // sandbox overhead weight (ms)

    // Adaptive risk weight: when the observed rate of *accepted* risky
    // placements exceeds `target_viol_rate`, wR is increased (and decayed
    // back when the system is calm).
    bool   adaptive = true;
    double target_viol_rate = 0.001;
};

/**
 * RiskAwareScheduler (this paper's scheduler):
 *
 * For every invocation it scores *all* (worker, sandbox-level) pairs:
 *
 *     score(w,k) = wR * V(w,k) + wL * L(w,k) + wC * C(k) + wS * O(k)
 *
 * where
 *   - V(w,k) is the expected co-location-violation indicator: 1.0 if the
 *     placement would create a weakest-link violation with an *active*
 *     neighbour, plus a small "sticky" term when the worker holds idle
 *     containers of other tenants;
 *   - L(w,k) estimates end-to-end latency (warm/cold start + service +
 *     contention);
 *   - C(k)   is the sandbox lifetime cost;
 *   - O(k)   is the sandbox per-invocation overhead.
 *
 * The scheduler thus trades off three things it can control: *upgrading*
 * the sandbox level, *segregating* risky tenants onto clean workers, and
 * plain load balancing. The risk weight wR adapts online: it grows when
 * risky placements are accepted and decays when they are not.
 */
class RiskAwareScheduler : public Scheduler {
public:
    explicit RiskAwareScheduler(std::uint64_t seed, RiskSchedulerParams p)
        : sandbox_(p.sandbox)
        , wr_(p.wr)
        , wl_(p.wl)
        , wc_(p.wc)
        , ws_(p.ws)
        , adaptive_(p.adaptive)
        , target_(p.target_viol_rate)
        , rng_(seed)
    {}

    std::string name() const override {
        return "riskaware";
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

        const double risk = func->risk;
        const int    req  = sandbox_.required_level(risk);
        const Duration svc = inv.service_time();

        WorkerId best_w = 0;
        int      best_k = 0;
        double   best_score = 1e18;
        bool     best_unsafe = false;
        bool     found = false;

        std::uniform_real_distribution<double> jitter(0.0, 0.05);

        for (WorkerId wid : workers) {
            if (!state.can_host(wid, *func)) continue;
            const WorkerView& w = state.worker_view(wid);

            for (int k = 0; k <= 2; ++k) {
                const SandboxLevel lvl = static_cast<SandboxLevel>(k);
                const auto& sp = sandbox_.level(lvl);

                // --- V(w,k): expected violation term -------------------
                double V = 0.0;
                for (const auto& act : w.active_tenants) {
                    if (act.tenant == inv.tenant_id()) continue;
                    const int iso  = std::min(k, static_cast<int>(act.level));
                    const int need = std::max(req, act.req);
                    if (iso < need) { V = 1.0; break; }
                }
                if (V == 0.0) {
                    // Sticky hazard: idle containers of other tenants may
                    // be reactivated on this worker later.
                    for (const auto& c : w.containers) {
                        if (!c.is_idle()) continue;
                        const FunctionProfile* cf = state.get_function(c.function_id);
                        if (cf && cf->tenant != inv.tenant_id()) {
                            V += 0.05;
                            break;
                        }
                    }
                }

                // --- warm reuse? ---------------------------------------
                bool warm = false;
                for (const auto& c : w.containers) {
                    if (c.function_id == inv.function_id() &&
                        c.sandbox == lvl && c.is_idle()) {
                        warm = true;
                        break;
                    }
                }

                Duration start_delay;
                if (sandbox_.enabled) {
                    start_delay = warm ? sp.warm_start : sp.cold_start;
                } else {
                    start_delay = warm ? func->warm_start_time : func->cold_start_time;
                }

                // --- L(w,k): latency estimate --------------------------
                const double cpu_ratio = (w.capacity.cpu_cores > 0.0)
                    ? w.used.cpu_cores / w.capacity.cpu_cores : 0.0;
                const double est_lat =
                      start_delay + svc + sp.overhead
                    + 2.0 * static_cast<double>(w.active_invocations)
                    + 40.0 * cpu_ratio;

                // --- C(k), O(k) ----------------------------------------
                const double cost = sp.cost_per_ms * (start_delay + svc + sp.overhead);

                double score = wr_ * V
                             + wl_ * est_lat
                             + wc_ * cost
                             + ws_ * sp.overhead
                             + jitter(rng_);
                if (warm) score -= 0.01;   // break ties towards warm reuse

                if (score < best_score) {
                    best_score = score;
                    best_w = wid;
                    best_k = k;
                    best_unsafe = (V >= 0.5);
                    found = true;
                }
            }
        }

        if (!found) {
            return SchedulingDecision::fail("no worker has enough capacity");
        }

        // --- Adaptive risk weight --------------------------------------
        if (adaptive_) {
            ewma_ = 0.98 * ewma_ + 0.02 * (best_unsafe ? 1.0 : 0.0);
            if (ewma_ > target_) {
                wr_ = std::min(wr_ * 1.05, 10000.0);
            } else {
                wr_ = std::max(wr_ * 0.995, 50.0);
            }
        }

        return SchedulingDecision::ok(best_w,
                                      static_cast<SandboxLevel>(best_k));
    }

    /// Current risk weight (for diagnostics / experiments).
    double risk_weight() const noexcept { return wr_; }

private:
    SandboxModel sandbox_;
    double wr_;
    double wl_;
    double wc_;
    double ws_;
    bool   adaptive_;
    double target_;
    double ewma_ = 0.0;
    std::mt19937_64 rng_;
};

} // namespace kumo
