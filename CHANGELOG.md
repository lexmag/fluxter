# Changelog

## v0.11.0

  * Dropped support for Elixir versions older than 1.10.

## v0.10.0

  * Dropped support for Elixir versions older than 1.5.

## v0.9.1

  * Fixed the order when building prefix.

## v0.9.0

  * Fixed prefix building when start options provided.
  * Dropped support for Elixir v1.2.

## v0.8.1

  * Fixed port command for OTP versions that support ancillary data sending.

## v0.8.0

  * Added support for module, function, arguments tuple in `measure/4`.

## v0.7.1

  * Fixed Elixir v1.6 warnings.

## v0.7.0

  * Added the `c:Fluxter.start_link/1` callback to support runtime configuration.

__Deprecations:__

  * Passing child specification options to `child_spec/1` is deprecated.

## v0.6.1

  * Fixed a bug in the `c:Fluxter.child_spec/1` callback.

## v0.6.0

  * Added the `c:Fluxter.child_spec/1` callback.
  * Started flushing counters synchronously when calling `Fluxter.flush_counter/1`.
