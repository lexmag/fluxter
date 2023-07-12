# Changelog

## v0.11.6

- Remove leading underscores in tag and field keys.

## v0.11.5

- Default `empty` value in fields must be quoted to be valid string field value.

## v0.11.4

- Handle empty strings in tag/field values

## v0.11.3

- Handle nils, atoms, lists and maps in tag/field keys/values

## v0.11.2

- Fix `no cond clause evaluated to a truthy value` in `Fluxter.Packet.encode_value/1`

## v0.11.1

- Make lib releasable on private hex.

### Before fork:

## v0.10.0

- Dropped support for Elixir versions older than 1.5.

## v0.9.1

- Fixed the order when building prefix.

## v0.9.0

- Fixed prefix building when start options provided.
- Dropped support for Elixir v1.2.

## v0.8.1

- Fixed port command for OTP versions that support ancillary data sending.

## v0.8.0

- Added support for module, function, arguments tuple in `measure/4`.

## v0.7.1

- Fixed Elixir v1.6 warnings.

## v0.7.0

- Added the `c:Fluxter.start_link/1` callback to support runtime configuration.

**Deprecations:**

- Passing child specification options to `child_spec/1` is deprecated.

## v0.6.1

- Fixed a bug in the `c:Fluxter.child_spec/1` callback.

## v0.6.0

- Added the `c:Fluxter.child_spec/1` callback.
- Started flushing counters synchronously when calling `Fluxter.flush_counter/1`.
