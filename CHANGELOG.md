# Changelog

## v0.7.1

  * Fixed Elixir v1.6 warnings.

## v0.7.0

  * Added the `Fluxter.start_link/1` callback to support runtime configuration.

__Deprecations:__

  * Passing child specification options to `Fluxter.child_spec/1` is deprecated.

## v0.6.1

  * Fixed a bug in the `Fluxter.child_spec/1` callback.

## v0.6.0

  * Added the `Fluxter.child_spec/1` callback.
  * Started flushing counters synchronously when calling `Fluxter.flush_counter/1`.
