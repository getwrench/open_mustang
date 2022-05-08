## 1.0.0

- Initial version, created by Stagehand

## 1.0.1

- Updated pubspec.yaml and README

## 1.0.2
- Updated README, pubspec.yaml

## 1.0.3
- Updated README, pubspec.yaml

## 1.0.4
- Added support for config.yaml to generate custom framework code

## 1.0.5
- Removed flutter dev dependency

## 1.0.6
- Add validation to force fields in the `State` to be models in `src/models` folder

## 1.0.7
- Bug - Caching/Persistence fails when web application is built in release mode

## 1.0.8
- New - Post state change events to Dart VM Client in debug mode, when subscribed

## 1.0.9
- New - Add debug hooks for generated state classes

## 1.0.10
- Fix - Generated state class are not captured in VM client

## 1.0.11
- Model, State and Service are all made abstract

## 1.0.12
- Framework introduced support to consume events

## 1.0.13
- Framework introduced support for `before`, `after`, `around` Aspects

## 1.0.14
- `mustang.yaml` config file should now be in project's home directory

## 1.0.15
- Fix - mustang.yaml is not getting picked up from the project root directory

## 1.0.16
- Aspects can accept arguments

## 1.0.17
- Renamed `WrenchStore` to `MustangStore` and `WrenchCache` to `MustangCache`

## 1.0.18
- Bug - String args for Aspects does not have quotes in the generated file

## 1.0.19
- Bug - Event codegen fails when model filename has `model`

## 1.0.20
- Bug - Codegen for State fails when model does not start with `$`

## 1.0.21
- Fix: lint warnings

## 1.0.22
- Fix: Services are subscribing to event when the eventModel is not used in the state

## 1.0.23
- Fix: Incorrect file name while generating event subscription code

## 1.0.24
- Fix: When a route is popped, event stream subscription is lost

## 1.0.25
- Fix: Notifier is disposed after popping a route

## 1.0.26
- Fix: When a screen is popped very fast, dispose is getting called right after pushing the route
- Lint fixes
- MustangScreen wrapper widget supports fetching data

## 1.0.27
- Fix: Active state instance is getting deleted while disposing the change notifier

## 1.0.28
- Addressed pub.dev issues partially

## 1.0.29
- Added doc comments
- Updated deps

## 1.1.0
- Updated build order for build_runner

## 1.1.1
- Updated all deps

## 1.1.2
- Converted to dart package project

## 1.1.3
- Set min version for `path` package to 1.8.1
