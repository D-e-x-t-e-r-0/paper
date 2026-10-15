#import "@preview/clean-acmart:0.0.1": acmart, acmart-ccs, acmart-keywords, acmart-ref, to-string
#import "@preview/cetz:0.3.4": canvas, draw

#let title = [
  Risk-Aware Sandbox Scheduling
]

#let authors = (
  (
    name: [Jayesh Puri],
    // `email` sets the mailto target of the name link in the template.
    email: [jayeshkrishan.puri.min24\@iitbhu.ac.in],
    // Extra keys render as centered lines under the name.
    contact: [jayeshkrishan.puri.min24\@iitbhu.ac.in],
  ),
)

#let conference = (
  // TODO: adjust or remove the course line if this is not submitted for the course.
  name:  [CSE-574 Cloud Computing],
  short: [CSE-574],
  year:  [2026],
  date:  [Fall],
  venue: [Course Project],
)

#let doi = "https://doi.org/10.1145/0000000000"

#let ccs = (
  (
    generic: [Security and privacy],
    specific: ([Distributed systems security], ),
  ),
  (
    generic: [Computer systems organization],
    specific: ([Cloud computing], ),
  ),
)

#let keywords = (
  "serverless computing",
  "cloud security",
  "sandbox scheduling",
  "co-location attacks",
  "microVM isolation",
)

#show: acmart.with(
  title: title,
  authors: authors,
  conference: conference,
  doi: doi,
  copyright: "cc",
)

#set math.equation(numbering: "(1)")
#show figure.where(kind: table): set figure.caption(position: top)

// Diagrams, drawn with cetz in the style of the reference papers.
#let d-blue    = rgb("#3B6EA5")
#let d-bluel   = rgb("#DCE9F7")
#let d-yellow  = rgb("#C98A00")
#let d-yellowl = rgb("#FBF0D2")
#let d-green   = rgb("#4E8C4E")
#let d-greenl  = rgb("#E1F0E1")
#let d-red     = rgb("#C9483F")
#let d-redl    = rgb("#F9DEDC")
#let d-orange  = rgb("#D97E2B")
#let d-gray    = rgb("#6E6E6E")
#let d-grayl   = rgb("#F1F1F1")

#let diagram-architecture = canvas({
  import draw: *
  set-style(content: (padding: 0.06))

  let badge(pos, n) = {
    circle(pos, radius: .16, fill: d-blue, stroke: none)
    content(pos, text(6.5pt, fill: white, weight: "bold")[#n])
  }

  // Tenants panel
  rect((0, 2.4), (3.0, 5.4), radius: .12, fill: d-grayl, stroke: .8pt + d-gray)
  content((1.5, 5.3), text(7pt, weight: "bold")[Tenants], anchor: "north")
  rect((0.25, 3.9), (2.75, 4.3), radius: .06, fill: d-redl, stroke: .7pt + d-red)
  content((1.5, 4.1), text(6.5pt)[high-risk functions])
  rect((0.25, 3.3), (2.75, 3.7), radius: .06, fill: d-yellowl, stroke: .7pt + d-yellow)
  content((1.5, 3.5), text(6.5pt)[mid-risk functions])
  rect((0.25, 2.7), (2.75, 3.1), radius: .06, fill: d-bluel, stroke: .7pt + d-blue)
  content((1.5, 2.9), text(6.5pt)[low-risk functions])

  line((3.0, 3.9), (4.4, 3.9), mark: (end: "stealth"), stroke: 1pt)
  content((3.7, 4.0), text(6pt)[invocations], anchor: "south")

  // Scheduler box
  rect((4.4, 2.4), (11.6, 5.4), radius: .12, fill: none, stroke: 1pt + d-blue)
  content((8.0, 5.3), text(7pt, weight: "bold", fill: d-blue)[Risk-aware scheduler], anchor: "north")

  rect((4.7, 4.4), (11.3, 4.9), radius: .08, fill: d-bluel, stroke: .7pt + d-blue)
  badge((4.98, 4.65), 1)
  content((5.3, 4.65), text(6.5pt)[map risk score $r_i$ to tier $"req"(r_i)$], anchor: "west")

  rect((4.7, 3.6), (11.3, 4.1), radius: .08, fill: d-yellowl, stroke: .7pt + d-yellow)
  badge((4.98, 3.85), 2)
  content((5.3, 3.85), text(6.5pt)[score $(j, k) = w_R V + w_L L + w_C C + w_S O$], anchor: "west")

  rect((4.7, 2.8), (11.3, 3.3), radius: .08, fill: d-greenl, stroke: .7pt + d-green)
  badge((4.98, 3.05), 3)
  content((5.3, 3.05), text(6.5pt)[place on $(j, k)$, choose warm or cold start], anchor: "west")

  line((11.6, 3.9), (12.9, 3.9), mark: (end: "stealth"), stroke: 1pt)
  content((12.25, 4.0), text(6pt)[placement], anchor: "south")

  // Workers panel
  rect((12.9, 2.4), (16.9, 5.4), radius: .12, fill: d-grayl, stroke: .8pt + d-gray)
  content((14.9, 5.3), text(7pt, weight: "bold")[Workers], anchor: "north")

  let host(y) = {
    rect((13.15, y - .27), (16.65, y + .27), radius: .06, fill: white, stroke: .7pt + d-gray)
    circle((14.0, y), radius: .17, stroke: 1pt + d-gray)
    circle((14.7, y), radius: .17, stroke: 1pt + d-green)
    circle((15.4, y), radius: .17, stroke: 1pt + d-orange)
    content((16.35, y), text(5.5pt)[host], anchor: "east")
  }
  host(4.7)
  host(3.95)
  host(3.2)

  circle((13.5, 2.7), radius: .13, stroke: .9pt + d-gray)
  content((13.72, 2.7), text(5.5pt)[container], anchor: "west")
  circle((14.9, 2.7), radius: .13, stroke: .9pt + d-green)
  content((15.12, 2.7), text(5.5pt)[gVisor], anchor: "west")
  circle((16.1, 2.7), radius: .13, stroke: .9pt + d-orange)
  content((16.32, 2.7), text(5.5pt)[Kata], anchor: "west")

  // feedback loop
  line((14.9, 2.4), (14.9, 1.3), (8.0, 1.3), (8.0, 2.4),
    stroke: (paint: d-red, thickness: 1pt, dash: "dashed"), mark: (end: "stealth"))
  content((11.5, 1.42), text(6pt, fill: d-red)[observed violations, latency, cost; update $w_R$], anchor: "south")
})

#let diagram-violation = canvas({
  import draw: *
  set-style(content: (padding: 0.06))

  let chip(pos, label, c) = {
    rect((pos.at(0) - .55, pos.at(1) - .12), (pos.at(0) + .55, pos.at(1) + .12), radius: .05, fill: c, stroke: none)
    content(pos, text(5.5pt, fill: white)[#label])
  }
  let panel(x0, title, tcol) = {
    rect((x0, 0.35), (x0 + 5.2, 4.15), radius: .12, fill: d-grayl, stroke: .8pt + d-gray)
    content((x0 + 2.6, 4.05), text(7pt, weight: "bold", fill: tcol)[#title], anchor: "north")
  }
  let okbadge(pos, mark, c) = {
    circle(pos, radius: .19, fill: c, stroke: none)
    content(pos, text(8pt, fill: white, weight: "bold")[#mark])
  }

  // panel (a): violation
  panel(0, "violation", d-red)
  rect((0.35, 1.5), (2.5, 2.9), radius: .1, fill: d-redl, stroke: .8pt + d-red)
  content((1.425, 2.2), text(6.5pt)[high-risk \ (req 2)])
  chip((1.425, 1.25), "container", d-gray)
  rect((2.85, 1.5), (5.0, 2.9), radius: .1, fill: d-bluel, stroke: .8pt + d-blue)
  content((3.925, 2.2), text(6.5pt)[low-risk \ (req 0)])
  chip((3.925, 1.25), "container", d-gray)
  okbadge((2.6, 3.6), [×], d-red)
  content((2.6, 0.85), text(6pt)[$min(0, 0) < max(2, 0)$: violates], anchor: "center")

  // panel (b): upgrade
  panel(5.8, "protected by upgrade", d-green)
  rect((6.15, 1.5), (8.3, 2.9), radius: .1, fill: d-redl, stroke: .8pt + d-red)
  content((7.225, 2.2), text(6.5pt)[high-risk \ (req 2)])
  chip((7.225, 1.25), "Kata", d-orange)
  rect((8.65, 1.5), (10.8, 2.9), radius: .1, fill: d-bluel, stroke: .8pt + d-blue)
  content((9.725, 2.2), text(6.5pt)[low-risk \ (req 0)])
  chip((9.725, 1.25), "Kata", d-orange)
  okbadge((8.4, 3.6), [✓], d-green)
  content((8.4, 0.85), text(6pt)[$min(2, 2) < max(2, 0)$ false: safe], anchor: "center")

  // panel (c): segregation
  panel(11.6, "protected by segregation", d-green)
  rect((13.55, 1.5), (15.7, 2.9), radius: .1, fill: d-redl, stroke: .8pt + d-red)
  content((14.625, 2.2), text(6.5pt)[high-risk \ (req 2)])
  chip((14.625, 1.25), "container", d-gray)
  okbadge((14.2, 3.6), [✓], d-green)
  content((14.2, 0.85), text(6pt)[no co-tenant: no pair, no violation], anchor: "center")
})

#let diagram-timeline = canvas({
  import draw: *
  set-style(content: (padding: 0.06))

  let x(t) = 1.2 + t * 0.0265
  let row(y, name, parts) = {
    content((1.05, y), text(6.5pt)[#name], anchor: "east")
    for (t0, t1, c) in parts {
      rect((x(t0), y - .21), (x(t1), y + .21), radius: .04, fill: c, stroke: none)
    }
    content((x(parts.last().at(1)) + .12, y), text(5.8pt)[#calc.round(parts.last().at(1)) ms], anchor: "west")
  }

  line((1.05, 0.55), (16.6, 0.55), mark: (end: "stealth"), stroke: .8pt)
  for t in (0, 100, 200, 300, 400, 500) {
    line((x(t), 0.5), (x(t), 0.6), stroke: .6pt)
    content((x(t), 0.38), text(5.5pt)[#t], anchor: "north")
  }
  content((15.2, 0.75), text(6pt)[time (ms)], anchor: "south")

  row(3.8, [warm], ((0, 2, d-blue), (2, 22, d-blue)))
  row(3.0, [container], ((0, 100, rgb("#F5C97B")), (100, 120, d-blue)))
  row(2.2, [gVisor], ((0, 250, rgb("#E8A13C")), (250, 270, d-blue)))
  row(1.4, [Kata], ((0, 400, d-red), (400, 420, d-blue)))

  content((x(50), 3.0), text(5.5pt)[cold start])
  content((x(200), 2.2), text(5.5pt)[cold start])
  content((x(200), 1.4), text(5.5pt, fill: white)[cold start])

  line((x(300), 0.55), (x(300), 4.15), stroke: (paint: d-red, thickness: .9pt, dash: "dashed"))
  content((x(300), 4.2), text(6pt, fill: d-red)[SLO 300 ms], anchor: "south")

  rect((12.6, 3.6), (13.0, 3.78), radius: .03, fill: rgb("#E8A13C"), stroke: none)
  content((13.1, 3.69), text(6pt)[cold start], anchor: "west")
  rect((14.6, 3.6), (15.0, 3.78), radius: .03, fill: d-blue, stroke: none)
  content((15.1, 3.69), text(6pt)[service], anchor: "west")

  content((x(340), 1.75), text(5.8pt, fill: d-red)[misses SLO], anchor: "south")
})

= Abstract

Serverless platforms pack many tenants' functions onto shared workers, and the
container sandboxes that make this packing efficient also put tenants within
reach of each other. An attacker who lands on the same host as a victim can
probe shared kernel interfaces and timing behaviour. Stronger sandboxes such as
gVisor and microVMs reduce that exposure, at the price of longer cold starts,
higher per-invocation overhead and lower host density. This paper develops
risk-aware sandbox scheduling, in which the scheduler decides the host, the
sandbox level and the warm-or-cold path for every invocation using a
per-function risk score. Placement is scored against a co-location model in
which a shared host is only as safe as its weakest sandbox, so the scheduler
can protect a risky function either by upgrading its isolation or by keeping it
away from weakly isolated tenants. We plan to implement the scheduler in Kumo,
a security-focused serverless simulator, and to compare it with container-only
schedulers, static risk-tier assignment, predictive cold-start policies,
always-isolate and segregation-only placement. The evaluation will measure
co-location violations, tail latency, SLO misses, cold-start rate, sandbox
overhead and cost across attacker intensities and cluster sizes. The target is
the violation profile of an always-isolate policy at a latency and cost close
to container-only scheduling. No experimental results are claimed yet; this
document is the design and evaluation blueprint.

#acmart-ccs(ccs)
#acmart-keywords(keywords)
#acmart-ref(to-string(title), authors, conference, doi)

= Introduction

Serverless platforms execute each function invocation inside a sandbox on a
shared cluster. Providers keep sandboxes warm and reuse them to avoid
provisioning delays, and they pack many tenants' functions onto the same
physical hosts to raise utilization. The packing is what makes the model
economical for both sides.

The same packing creates attack surface. Close Talker shows that an attacker
can fingerprint a scheduler and steer invocations until they land on the same
host as a victim, and the Kumo study shows that the choice of placement policy
changes measured co-location rates by orders of magnitude
@closetalker @kumo. Kumo's threat model assumes the attacker issues only valid
invocations; microarchitectural side channels and network-level flooding are
outside its scope, and we adopt the same boundary for the scheduler.

Isolation is available in several strengths. Shared-kernel containers are the
default and the cheapest option. gVisor interposes a user-space kernel between
the workload and the host, and its measured cost on syscall-heavy workloads is
substantial @gvisor. MicroVM sandboxes such as Firecracker and Kata Containers
give each workload a separate kernel; Firecracker was built to make this
affordable for serverless, but a microVM still starts slower than a container
@firecracker @kata. Cold starts are a known pain point even without stronger
isolation: the Azure Functions workload study describes bursty, heavily skewed
arrivals that make warm reuse hard @serverlesswild, and MPC-style predictive
policies pre-warm containers to cut tail latency @mpc.

Placement policies, however, treat isolation as fixed. OpenWhisk-style bin
packing, helper and spread policies in Kumo choose hosts and ignore the sandbox
@kumo. Double-Dip lowers co-location by preferring hosts where the same user
already runs, but it reasons about user counts and a single isolation level
@closetalker. MPC forecasts load and reuses containers without asking who else
shares the host @mpc. Security studies show that placement decides exposure,
and the schedulers that decide placement do not optimize for it. We ask whether
the scheduler can treat the sandbox level as a decision variable alongside the
host and the warm-or-cold path.

Our design assigns each function a risk score from tenant distrust, data
sensitivity and co-location history, and maps the score to a required isolation
tier. A placement is a (host, sandbox level) pair. Candidates are scored by a
weighted sum of expected co-location violation, latency, cost and sandbox
overhead, and the risk weight adapts online: it grows while risky placements
are being accepted and decays when the system is calm. A risky function can be
protected by upgrading its sandbox, by segregating it from weakly isolated
tenants, or by both, depending on what capacity allows.

This document is a blueprint. It fixes the model and the design, and lays out
the evaluation; no results are claimed. The implementation in Kumo and the
baseline port are in progress, and measured results will be added in a later
revision. The contributions we plan to deliver are:

- A joint formulation of host choice, sandbox level and warm reuse with
  per-function risk tiers and a weakest-link co-location violation metric
  (Section 3).
- A scoring scheduler with an adaptive risk weight and two protection paths,
  isolation and segregation (Section 4).
- An evaluation plan with baselines ported from the three reference papers and
  falsifiable hypotheses (Section 5).

= Background and related work

== Serverless execution and cold starts

OpenWhisk runs each invocation in a container and keeps containers alive for a
bounded idle time; the keep-alive policy trades memory against cold-start
frequency @openwhisk. The serverless execution model also raises systems
questions that predate the current platforms @hellerstein. The Serverless in
the Wild study of Azure Functions reports bursty, heavily skewed workloads
where a small fraction of functions receives most of the traffic, which is why
warm reuse and pre-warming matter @serverlesswild. MPC models arrivals with a
forecast, then solves a receding-horizon problem that decides when to pre-warm,
dispatch and reclaim containers, and reports large reductions in tail latency
@mpc. These systems optimize the reuse decision under the assumption that reuse
is safe for everyone sharing the host. Our scheduler keeps the reuse decision
and adds the isolation level to it.

== Co-location attacks and the Kumo simulator

Close Talker describes a practical recipe for forcing attacker-victim
co-location in serverless clouds: fingerprint the scheduler, then issue
invocations that steer placement. The paper also evaluates Double-Dip, a soft
isolation policy that prefers a host where the same user is already active and
otherwise picks the host with the fewest users. In their setup, Double-Dip cuts
co-location from 1.0 with Helper to 0.306 at 50 attackers @closetalker. The
policy works with user counts and a single sandbox type.

Kumo is a C++ discrete-event simulator built for this threat model, with
attacker and victim as first-class entities and metrics for co-location
probability, time to first co-location, drops and tail latency. It ships with
Random, Double-Dip, Helper and OpenWhisk schedulers, and shows that policy
choice moves co-location by orders of magnitude @kumo. Kumo measures the
problem; we add a policy that optimizes it, and we extend its metrics with
sandbox strength and risk tiers.

== Isolation mechanisms

A shared-kernel container gives the weakest boundary: every tenant on a host
reaches the same kernel surface. gVisor reduces that surface with a user-space
kernel that intercepts syscalls, at a cost measured by Young et al. on real
workloads @gvisor. Firecracker is a microVM designed for serverless with low
per-VM memory and boot overhead @firecracker, and Kata Containers packages the
same idea behind container tooling @kata. We model the three options as levels
with different protection strength, cold-start latency, per-invocation
overhead and cost. The parameters are simulator inputs; we calibrate them
against published measurements and check sensitivity.

== Placement policies

Kumo's built-in schedulers optimize packing and warm reuse with the sandbox
fixed @kumo. Double-Dip's affinity rule is the closest existing policy to ours,
but it is binary (same user or not) and has no cost or risk model
@closetalker. MPC is latency- and resource-optimal and risk-blind @mpc. Our
scoring function subsumes a tier filter at a high risk weight, and the sandbox
choice is orthogonal to forecasting: a forecast could feed the same scorer.

= System model and problem formulation

== Platform

Consider a cluster of hosts $j in J$, each with CPU and memory capacity.
Tenants submit invocations of functions $i in I$. Function $i$ has resource
demands, a service-time distribution, an idle timeout and a latency SLO
(deadline) $d_i$. A sandbox is created on demand (cold start) or reused from an
idle one (warm start). The main experiments use homogeneous hosts; we treat
heterogeneity as an extension.

== Sandbox levels and risk tiers

The platform offers three levels, $K = { "shared", "isolated", "dedicated" }$:
shared-kernel containers, gVisor and Kata/microVM. Level $k$ has isolation
strength $s_k$, cold-start latency $c_k$, warm-start latency $h_k$,
per-invocation overhead $o_k$ and cost per unit time $gamma_k$ (@fig:timeline
shows the cold-start gap between the levels under the initial settings). Each
function carries a risk score $r_i in [0, 1]$ that aggregates tenant distrust,
data sensitivity and co-location history:

$ r_i = w_1 dot "distrust"_i + w_2 dot "sensitivity"_i + w_3 dot "history"_i $ <eq:risk>

The score maps to a required tier:

$ "req"(r) = cases(
  0 & "if" r < theta_1,
  1 & "if" theta_1 <= r < theta_2,
  2 & "otherwise",
) $ <eq:tier>

with initial thresholds $theta_1 = 0.3$ and $theta_2 = 0.7$ to be calibrated in
the evaluation.

#figure(
  diagram-timeline,
  placement: top,
  scope: "parent",
  caption: [Cold starts under the initial simulator settings (100, 250 and 400 ms for the shared, isolated and dedicated levels) against a 300 ms SLO. The Kata cold start alone exceeds the SLO, while warm reuse stays far below it.],
) <fig:timeline>

== Co-location violations

An invocation $i$ starting on host $j$ at level $k$ co-locates with every
invocation $i'$ of another tenant active on $j$ at level $k'$. The pair
violates the risk policy when the weakest sandbox in the pair is below the
stronger requirement:

$ "viol"(i, i') <=> min(k_i, k_(i')) < max("req"(r_i), "req"(r_(i'))) $ <eq:viol>

The rationale: a host is as safe as its weakest boundary, so certifying a
tier-$t$ function requires every co-tenant to sit at tier $t$ or above, or the
function to run without co-tenants (@fig:violation). We count each overlapping
pair once, when the second invocation starts. This extends Kumo's co-location
counts with sandbox levels and risk tiers.

#figure(
  diagram-violation,
  placement: top,
  scope: "parent",
  caption: [Weakest-link violation rule. A shared host is only as safe as its weakest sandbox, so protecting a high-risk function requires upgrading every co-tenant (b) or running it alone (c).],
) <fig:violation>

== Objective

For each invocation, choose $(j, k)$ to minimize the expected cost

$ min alpha dot "Risk" + beta dot "Latency" + gamma dot "Overhead" + delta dot "Cost" $ <eq:obj>

subject to host capacity, with risky functions expected to reach their tier or
be isolated by placement. The problem is online: future arrivals, loads and
reuse states are unknown, so we use one-step scoring with online weight
adaptation rather than a horizon optimizer.

#figure(
  table(
    columns: (auto, 1fr),
    align: (left, left),
    inset: (x: 6pt, y: 3pt),
    stroke: (x, y) => if y <= 1 { (top: 0.5pt) },
    table.header([Symbol], [Meaning]),
    [$i, j$], [a function and a host],
    [$I, J$], [set of functions, set of hosts],
    [$K$], [sandbox levels: shared, isolated, dedicated],
    [$k$], [sandbox level chosen for an invocation],
    [$r_i$], [risk score of function $i$, in $[0, 1]$],
    [$"req"(r)$], [minimum isolation tier for risk $r$],
    [$c_k, h_k$], [cold-start and warm-start latency of level $k$],
    [$o_k, gamma_k$], [per-invocation overhead and cost of level $k$],
    [$d_i$], [deadline (SLO) of function $i$],
    [$x_(i,j,k)$], [placement decision],
  ),
  caption: [Notation used in the model.],
) <tab:notation>

= Risk-aware sandbox scheduling

== Decision procedure

For an invocation $i$, the scheduler computes $r_i$ and $"req"(r_i)$,
enumerates feasible $(j, k)$ pairs that pass the capacity check, scores each
with @eq:score, and places the invocation on the argmin. If no
candidate exists, the invocation is queued or falls back to the least-loaded
host. Scoring costs $O(|J| dot |K|)$ per invocation with $|K| = 3$.
@fig:arch shows where the procedure sits in the platform, and
@alg:schedule states it.

$ "score"(j,k) = w_R V + w_L L + w_C C + w_S O $ <eq:score>

#figure(
  text(size: 8pt, raw(
    lang: "python",
    block: true,
    "def schedule(i, J, K, r_i):
    req = required_level(r_i)
    best = (None, None, inf)
    for j in J:
        if capacity(j) < demand(i): continue
        for k in K:
            v = expected_violation(j, k, req)
            lat = start_latency(k, j) + service(i)
            lat += overhead(k) + congestion(j)
            c = cost(k) * lifetime(i)
            s = w_R*v + w_L*lat + w_C*c + w_S*o(k)
            if s < best[2]: best = (j, k, s)
    if best[0] is None: return fallback(i)
    j, k, _ = best
    update_risk_weight(w_R, best)
    return (j, k)
",
  )),
  kind: "algorithm",
  supplement: [Algorithm],
  caption: [Risk-aware scheduling for one invocation. $V$ is the expected-violation indicator from @eq:viol; the weight update follows Section 4.4.],
) <alg:schedule>

#figure(
  diagram-architecture,
  placement: top,
  scope: "parent",
  caption: [The risk-aware scheduler scores (worker, level) candidates, the actuators place the invocation and choose the warm or cold path, and observed violations, latency and cost feed back into the risk weight.],
) <fig:arch>

== Scoring terms

$V(j, k)$ is the expected-violation indicator: 1 when the placement violates
@eq:viol with an active co-tenant, plus a small sticky term (we use
0.05) when the host holds idle containers of other tenants that could be
reactivated. $L(j, k)$ estimates end-to-end latency: the warm- or cold-start
latency of level $k$, the service time, the sandbox overhead and a congestion
term from current utilization. $C(k)$ is the sandbox cost over the invocation
lifetime, and $O(k)$ is the per-invocation overhead. The weights start from
configured values ($w_L = 1$, $w_C = 50$, $w_S = 1$ and $w_R = 1000$ in our
initial setup, all relative) and the risk weight adapts.

== Protection paths

Under the weakest-link rule, matching a function's own tier is not enough on a
mixed host: a mid-risk function in gVisor still violates when a neighbour runs
in a plain container. The scheduler has two ways to avoid the penalty. It can
upgrade the neighbourhood, placing the function where every co-tenant meets the
tier, which builds tiered pools over time. Or it can segregate: place the
function where it has no weak co-tenants, and rely on the scoring to steer
later arrivals away, since those arrivals see the risky tenant in their own
$V$ term. Low-risk functions pack freely.

== Adaptive risk weight

The risk weight $w_R$ starts at a configured value and tracks an exponentially
weighted moving average of accepted risky placements. When the observed rate
exceeds a target (0.001 in our initial setup), the weight grows by 5% per
decision; otherwise it decays by 0.5% per decision, within bounds. The intent:
keep cheap placements available in steady state, and let the weight rise when
the scheduler is being pushed to accept risk, for example during bursts. A
large $w_R$ reproduces a strict tier filter, so the scoring form is a superset
of the filter used in our initial formulation.

== Baselines

#figure(
  table(
    columns: (1fr, 0.9fr, 1.1fr),
    align: (left, left, left),
    inset: (x: 5pt, y: 3pt),
    stroke: (x, y) => if y <= 1 { (top: 0.5pt) },
    table.header([Policy], [Sandbox and placement], [Expected character]),
    [Container-only (Helper, OpenWhisk)], [shared; load, warm reuse], [violations grow with attacker intensity],
    [Static tiers], [$k = "req"(r)$; load balancing], [upgrades sandboxes; mixed hosts still violate],
    [Always-isolate], [dedicated; load balancing], [zero violations; worst latency and cost],
    [Segregation-only], [shared; risky tenants exclusive], [zero violations; wasted capacity under pressure],
    [Ours], [scored level and host], [protects via upgrade or segregation; adaptive weight],
    [Double-Dip-style (planned)], [shared; user affinity], [reference baseline from the attack literature],
    [MPC-style (planned)], [shared; forecast, prewarm], [latency-optimal, risk-blind],
  ),
  caption: [Scheduling policies compared in the evaluation.],
) <tab:baselines>

= Evaluation plan

== Setup

We extend Kumo with a sandbox field on containers and scheduling decisions,
per-function risk tags, violation, cost, overhead and SLO accounting, and the
scheduler described above. Initial settings use a 300 ms latency SLO, cold
starts of 100, 250 and 400 ms, and per-invocation overheads of 0, 3 and 1 ms
for the shared, isolated and dedicated levels (@fig:timeline); cost rates are
set per level and E5 sweeps all of these parameters. Workloads come from
Kumo's generators: uniform, Poisson and burst. Tenants carry a mix of risk scores (low, mid, high). An
optional attacker workload follows victim invocations at intensities from 0 to
10 attacks per benign invocation, as in Kumo's attack studies @kumo. We sweep
cluster size and random seeds, and report means with dispersion.

== Metrics

Violation rate per 1,000 invocations and exposed invocations; co-location rate
and time to first co-location (Kumo's metrics); mean and p95 end-to-end
latency; SLO miss rate; cold-start rate per level; sandbox overhead; and cost
per invocation.

== Hypotheses

- H1: Container-only policies show the highest violation rate, and it grows
  with attacker intensity.
- H2: Always-isolate eliminates violations but has the worst latency and cost;
  the gap widens as the microVM cold-start cost grows.
- H3: Static risk tiers reduce violations relative to container-only policies
  but do not eliminate them, because mixed hosts still violate under the
  weakest-link rule.
- H4: Ours approaches zero violations while keeping p95 latency and cost close
  to container-only scheduling; segregation carries the load at moderate
  cluster sizes, and upgrades take over under pressure.
- H5: The adaptive risk weight traces a trade-off front between violations and
  latency/cost as its target rate and bounds change; a static weight does not
  adapt across regimes.

== Experiments

#figure(
  table(
    columns: (0.9fr, 1fr, 1.1fr),
    align: (left, left, left),
    inset: (x: 5pt, y: 3pt),
    stroke: (x, y) => if y <= 1 { (top: 0.5pt) },
    table.header([Experiment], [Factor], [Question]),
    [E1 Scheduler comparison], [fixed workload; 1 attack per benign invocation], [violations vs latency vs cost across policies],
    [E2 Attacker sweep], [0 to 10 attacks per benign invocation], [how the violation rate scales for each policy],
    [E3 Cluster sweep], [number of workers], [whether segregation degrades faster than upgrading as capacity tightens],
    [E4 Weight sweep], [static $w_R$ values and adaptive], [shape of the violation/latency trade-off],
    [E5 Parameter sensitivity], [cold-start and overhead of gVisor and Kata], [robustness of the ranking to parameter error],
  ),
  caption: [Planned experiments.],
) <tab:experiments>

== Threats to validity

The evaluation runs in a simulator, and the sandbox parameters are inputs
rather than measurements, so we calibrate them from published data and test
sensitivity. The threat model excludes microarchitectural channels and
network-level attacks, following Kumo @kumo; the violation metric is a
policy-level proxy, not an attack-success model. Risk scores are assumed to
come from platform telemetry or tenant declarations, and score quality is
outside our scope.

= Roadmap and open questions

- Port the Double-Dip-style and MPC-style baselines into the sandbox model so
  that comparisons follow the reference implementations.
- Calibrate level parameters from published gVisor, Firecracker and Kata
  numbers, and run a sensitivity analysis on cold-start and overhead.
- Decide violation accounting under bursts: pair counting at start time is
  simple but undercounts long-lived exposure; an interval-based measure is the
  alternative.
- Study risk score provenance: declared versus observed, and how stable the
  history term is over time.
- Consider explicit reserved pools per tier as an alternative to segregation
  emerging from scoring, and admission control as a complement to placement.
- Stretch goal: validate the scheduler on a small k3s/OpenWhisk deployment with
  gVisor and Kata available.

= Conclusion

We have presented the model and design of risk-aware sandbox scheduling and the
evaluation plan to test it. The question is whether a single scoring function
can reach the violation profile of always-isolate placement while keeping the
latency and cost of container-only scheduling. The Kumo extension and the
baseline port are the next step; measured results will follow.

#bibliography("refs.bib", title: "References", style: "association-for-computing-machinery")
