# Changelog

## v0.2.1

- new features
  - new split_ok_err/2 function

## v0.2.0

- new features
  - new rexult function to replace rexult!

- fixed
  - make unwrap! handle 3 tuple error to give better message

- backwards incompatible
  - remove rexult!, use new rexult

## v0.1.3

- backwards incompatible
  - rename find_err to be all_ok

## v0.1.2

- new features
  - convert {:ok, a, b} tuples into {:ok, {a, b}}, same for :error

- bugs fixed
  - restore correct ok? and err? behavior, fix the test

- backwards incompatible
  - rename rexult to rexult!
  - rename is_result! to is_rexult!
  - rename unbreak to unbreak!

## v0.1.1

- bugs introduced
  - incorrectly made ok? handle all values, not just results

## v0.1.0

- first published version
