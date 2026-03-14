# lex-bias

Cognitive bias detection and correction for brain-modeled agentic AI.

## What It Does

Detects five cognitive biases in the agent's decision-making contexts and computes correction factors. Tracks per-bias susceptibility over time via EMA. The five biases modeled are: **anchoring** (initial values distorting estimates), **confirmation** (over-weighting supporting evidence), **availability** (distortion from memorable recent events), **recency** (over-weighting the most recent data), and **sunk cost** (continuing failing investments to justify past costs).

## Core Concept: Bias Detection Against Decision Context

```ruby
# Provide context for bias detection
result = client.check_for_bias(
  domain: :budget,
  decision_context: {
    current_value: 150_000,
    evidence_direction: :positive,
    hypothesis_direction: :positive,  # same direction → confirmation bias check
    recent_events: [:cost_overrun, :cost_overrun, :minor_savings],  # availability
    data_points: [0.9, 0.8, 0.7, 0.3, 0.2],  # recency (0.2/0.3 most recent)
    invested: 500_000,
    expected_return: 0.1  # low ROI → sunk cost check
  }
)
# => { detected: [{ bias_type: :sunk_cost, magnitude: 0.7, correction_applied: 0.35 }] }
```

## Usage

```ruby
client = Legion::Extensions::Bias::Client.new

# Record anchors for anchoring bias detection
client.record_anchor(domain: :performance, value: 100.0)

# Check for active biases before a decision
client.check_for_bias(domain: :performance, decision_context: { current_value: 95.0 })

# View susceptibility profile
client.susceptibility_profile
# => { anchoring: 0.6, confirmation: 0.4, availability: 0.5, recency: 0.3, sunk_cost: 0.4 }

# Maintenance (anchor decay runs automatically via Update actor)
client.update_bias
```

## Integration

Call `check_for_bias` before high-stakes decisions in lex-tick's action_selection phase. Pairs with lex-anchoring (shares anchor data), lex-appraisal (provides emotional/relevance context for confirmation bias), and lex-anosognosia (bias susceptibility as judgment deficits).

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
