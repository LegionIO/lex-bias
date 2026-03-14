# lex-bias

**Level 3 Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Grandparent**: `/Users/miverso2/rubymine/legion/CLAUDE.md`

## Purpose

Cognitive bias detection and correction for brain-modeled agentic AI. Detects five types of cognitive bias (anchoring, confirmation, availability, recency, sunk cost) in decision contexts and computes correction factors. Tracks susceptibility to each bias type via EMA, building a bias profile that reflects the agent's current vulnerability patterns.

## Gem Info

- **Gem name**: `lex-bias`
- **Version**: `0.1.0`
- **Module**: `Legion::Extensions::Bias`
- **Ruby**: `>= 3.4`
- **License**: MIT

## File Structure

```
lib/legion/extensions/bias/
  bias.rb                   # Main extension module
  version.rb                # VERSION = '0.1.0'
  client.rb                 # Client wrapper
  actors/
    update.rb               # Periodic bias decay actor
  helpers/
    constants.rb            # Bias types, thresholds, weights, EMA alpha
    bias_event.rb           # BiasEvent value object
    bias_detector.rb        # BiasDetector — per-bias detection algorithms
    bias_store.rb           # BiasStore — event history, anchor storage
  runners/
    bias.rb                 # Runner module with 6 public methods
spec/
  (spec files)
```

## Key Constants

```ruby
BIAS_TYPES                  = %i[anchoring confirmation availability recency sunk_cost]
DETECTION_THRESHOLD         = 0.3    # above this = bias likely influencing decision
CORRECTION_FACTOR           = 0.5    # how much to correct when bias detected
DEFAULT_SUSCEPTIBILITY      = 0.5    # starting susceptibility per bias
SUSCEPTIBILITY_ALPHA        = 0.1    # EMA alpha for susceptibility updates
DECAY_RATE                  = 0.02   # how fast bias activation decays per tick
MAX_BIAS_EVENTS             = 200
MAX_ANCHORS                 = 50
ANCHOR_DECAY                = 0.05   # anchor influence decay rate
CONFIRMATION_WEIGHT         = 0.7    # weight of confirming vs disconfirming evidence
AVAILABILITY_RECENCY_WINDOW = 10     # recent events window for availability heuristic
```

## Runners

### `Runners::Bias`

Methods split across `@bias_detector` (`Helpers::BiasDetector`) and `@bias_store` (`Helpers::BiasStore`).

- `check_for_bias(domain:, decision_context: {})` — run all five bias detectors against the decision context; returns `detected` (above threshold) and `all` (every detection result)
- `record_anchor(domain:, value:)` — register an anchor value for anchoring bias detection
- `update_bias` — decay all anchor influences
- `bias_report(domain: nil)` — recent bias events, optionally filtered by domain
- `susceptibility_profile` — current susceptibility scores by bias type
- `bias_stats` — total events, breakdown by type

**Decision context keys used by each detector:**
- Anchoring: `current_value:`, `anchor_value:` (from stored anchors)
- Confirmation: `evidence_direction:`, `hypothesis_direction:`
- Availability: `recent_events:` (array)
- Recency: `data_points:` (array, most recent last)
- Sunk cost: `invested:`, `expected_return:`

## Helpers

### `Helpers::BiasDetector`
Per-bias detection algorithms. `detect_anchoring` measures proximity of current value to anchor. `detect_confirmation` checks for over-weighting confirming evidence vs `CONFIRMATION_WEIGHT`. `detect_availability` measures distortion from recent events window. `detect_recency` measures over-weighting of recent data points. `detect_sunk_cost` detects throwing good resources after bad based on `invested:` vs `expected_return:`. `correction_for(magnitude)` returns the correction delta to apply.

### `Helpers::BiasStore`
Stores `@events` (BiasEvent array) and `@anchors` (domain → anchor value hashes). `by_domain` and `recent` filter event history. `stats` aggregates by bias type.

### `Helpers::BiasEvent`
Value object: bias_type, domain, magnitude, corrected (bool), correction_applied, context, timestamp.

## Actors

### `Actors::Update`
Periodic actor. Calls `update_bias` to decay anchor influences automatically.

## Integration Points

This extension is the meta-cognitive bias monitor. It should be called in lex-tick's decision phases before high-stakes actions. Pairs with lex-anchoring (provides anchor values to detect against), lex-appraisal (appraisal context provides confirmation/availability inputs), and lex-anosognosia (bias blind spots are cognitive deficits of the `:judgment` type). `susceptibility_profile` informs governance about systematic decision-making vulnerabilities.

## Development Notes

- `check_for_bias` only runs a detector if the required context keys are present — missing keys result in empty detection arrays for that bias type
- BiasEvent is only created when magnitude exceeds `DETECTION_THRESHOLD` — below-threshold detections are reported but not stored
- Susceptibility EMA is updated on each detection call, not each check — the profile reflects recent bias activation patterns, not just raw frequencies
