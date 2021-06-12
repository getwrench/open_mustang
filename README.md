# Mustang

![Logo](./mustang.gif)

A framework to build Flutter applications.

- provides **state management**
- generates source templates using `cli` (https://bitbucket.org/lunchclub/mustang_cli/src/master)
- enables consistent **file layout and naming standards**

## Contents
- [Resources](#markdown-header-resources)
- [Framework Components](#markdown-header-framework-components)
- [Component Communication](#markdown-header-component-communication)
- [Folder Structure](#markdown-header-folder-structure)
- [Model](#markdown-header-model)
- [State](#markdown-header-state)
- [Service](#markdown-header-service)
- [Screen](#markdown-header-screen)
- [Quick Start](#markdown-header-quick-start)

### Resources
- Presentation: https://docs.google.com/presentation/d/19VSU_TsbtzKUtKsblheX399KsqTTjPV_AWZNE2vthqM/edit?usp=sharing
- Video: https://drive.google.com/file/d/1zoTbw5pjLIBxlJD6NquAmHeGVuA4R8co/view?usp=sharing  

### Framework Components
- **Screen** - Flutter widget for the UI. Code can be split into multiple files.

- **Model** - A Dart class representing application data.

- **State** - Encapsulates data needed for a `Screen`. It is a Dart class with _1 or more_ `Model` fields.

- **Service** - A Dart class for async communication and business logic.

### Component Communication
- Every `Screen` has a corresponding `Service` and a `State`. All three components work together to continuously re-build the UI whenever there is a change in the application state.

    1. `Screen` builds itself after reading `State`
    2. `Screen` invokes methods in the `Service` as a response to user events (`scroll`, `tap` etc.,)
    3. `Service` updates `State`
    4. Back to Step 1

                                   +----------------+
                                   |                |
                                   |                |
                     +----------+  |     Screen     |+----------+
                     |             |                |           |
                     |             |                |           |
                     |             +----------------+           |
                     |                                          |
                     |                                          |
                     |calls Service                             |reads State
                     |                                          |
                     |                                          |
                     |                                          |
                     v                                          v
             +--------------------+                   +--------------------+
             |                    |                   |                    |
             |                    |                   |                    |
             |                    |                   |                    |
             |    Service         |+----------------> |       State        |
             |                    |  updates State    |                    |
             |                    |                   |                    |
             +--------------------+                   +--------------------+

- **Uni-directional Data Flow**
    - For a given `State/Screen/Service`, data flow always happens in the same direction i.e. `State -> Screen -> Service -> State -> ...`

                                       +----------------+
                                       |                |
                                       |                |
                         +----------+  |     Screen     | <---------+
                         |             |                |           |
                         |             |                |           |
                         |             +----------------+           |
                         |                                          |
                         |                                          |
                         |                                          |
                         |                                          |
                         |                                          |
                         |                                          |
                         v                                          +
                 +--------------------+                   +--------------------+
                 |                    |                   |                    |
                 |                    |                   |                    |
                 |                    |                   |                    |
                 |    Service         |+----------------> |       State        |
                 |                    |                   |                    |
                 |                    |                   |                    |
                 +--------------------+                   +--------------------+            

### Folder Structure
- Folder structure of a Flutter application created with this framework looks as below
    ```
      lib/
        - main.dart
        - src
          - models/
            - model1.dart
            - model2.dart
          - screens/
            - first/
              - first_screen.dart
              - first_state.dart
              - first_service.dart
            - second/
              - second_screen.dart
              - second_state.dart
              - second_service.dart
    ```
- Every `Screen` needs a `State` and a `Service`. So, `Screen, State, Service` files must be in their own named directory
- All `Model` classes must be inside `models` directory

### Model
- A Class annotated with `appModel`
- Class name should start with `$`
- Initialize fields with `InitField` annotation
- Getters/Setters are `NOT` supported inside `Model` classes. Use regular methods instead.
    
    ```dart
    @appModel
    class $User {
      String name;
    
      int age;
    
      @InitField(false)
      bool admin; 
    
      @InitField(['user', 'default'])
      BuiltList<String> roles;
    
      String fullName() {
        return 'Mr. $name';
      }
    }
    ```
  
### State
- A class annotated with `screenState`
- Class name should start with `$`
- Fields of the class must be `Model` or `BuiltValue` classes
  
    ```dart      
    @screenState
    class $ExampleScreenState {
      $User user;
      $Vehicle vehicle;
    }
    ```
    
### Service
- A class annotated with `ScreenService`
- Provide `State` class as an argument to `ScreenService` annotation, to create an association between `State` and `Service` as shown below.
  
    ```dart
    @ScreenService(screenState: $ExampleScreenState)
    class ExampleScreenService {
      void getUser() {
        User user = WrenchStore.get<User>() ?? User();
          updateState1(user);
        }
    }
    ```
    
- Service also provides following APIs
    - `updateState` -  Updates screen state and/or re-build the screen. To update the `State` without re-building the screen. Set `reload` argument to `false` to update the `State` without re-building the `Screen`.
        - `updateState()`
        - `updateState1(T model1, { reload: true })`
        - `updateState2(T model1, S model2, { reload: true })`
        - `updateState3(T model1, S model2, U model3, { reload: true })`
        - `updateState4(T model1, S model2, U mode3, V model4, { reload: true })`

    - `memoize` - Caches result of an execution for later reuse. Cached data is specific to the screen.
        - `T memoize<T>(T Function() methodName)`
            ```dart
            // In the snippet below, cachedGetData caches the return value of getData, a Future, and re-uses it in all subsequent calls
            Future<void> getData() async {
              Common common = WrenchStore.get<Common>() ?? Common();
              User user;
              Vehicle vehicle;

              ...   
            }

            Future<void> cachedGetData() async {
              return memoize(() => getData());
            }
            ```
    - `clearCache` - Clears data cached by `memoize`
        - `void clearCache()`
            ```dart
            Future<void> getData() async {
            ...
            }

            Future<void> cachedGetData() async {
              return memoize(() => getData());
            }

            // this removes Future<void> cached by memoize()
            void resetCache() {
              clearCache();
            }
            ``` 

### Screen
- Use `ChangeNotifierProvider` to re-build the `Screen` automatically when there is a change in `State`
- When referring to the `State`, omit `$`. Following is a structure of a typical Flutter screen.
  
    ```dart
    ...
    
    Widget build(BuildContext context) {
      return ChangeNotifierProvider<HomeScreenState>(
        create: (context) => HomeScreenState(),
          child: Consumer<HomeScreenState>(
            builder: (
              BuildContext context,
              HomeScreenState state,
              Widget _,
            ) {
              # Even when this widget is built many times, only 1 API call 
              # will be made because the Future from the service is cached
              SchedulerBinding.instance.addPostFrameCallback(
                (_) => HomeScreenService().cachedGetData(),
              );
    
              if (state?.common?.busy ?? false) {
                return Spinner();
              }
    
              if (state.common?.errorMsg != null) {
                return ErrorBody(errorMsg: state.common.errorMsg);
              }
                
              return _body(state, context);
            },
          ),
        );
      }
    ```

### Quick Start

- Install Flutter
    ```dart
    mkdir -p ~/lib && cd ~/lib
    
    git clone https://github.com/flutter/flutter.git -b stable

    export PATH="$PATH:~/lib/flutter/bin"
    ```

- Install Mustang CLI (https://bitbucket.org/lunchclub/mustang_cli/src/master)
    ```bash
    dart pub global activate -sgit git@bitbucket.org:lunchclub/mustang_cli.git
    ```
  
- Create Flutter project
    ```bash
    cd /tmp
    
    flutter create quick_start
    
    cd quick_start
    # Open the project in editor of your choice
    # vscode - code .
    # IntelliJ - idea .
    ```

- Update `pubspec.yaml`
    
    ```yaml
      dependencies:
        flutter:
          sdk: flutter
        built_collection: ^5.0.0
        built_value: ^8.0.0
        mustang_core:
          git:
            url: git@bitbucket.org:lunchclub/mustang.git
            path: mustang_core
            ref: master

      dev_dependencies:
        flutter_test:
          sdk: flutter
        build_runner: ^2.0.0
        mustang_codegen:
          git:
            url: git@bitbucket.org:lunchclub/mustang.git
            path: mustang_codegen
            ref: master
        pedantic: ^1.11.0        
    ```
  
- Get Dependencies
    
    ```bash
    flutter pub get
    ```

- Generate files for a screen
    ```bash
    mcli -s counter
    ```

- Generate runtime files

    ```bash
    mcli -w
    ```
  
- Update `counter.dart` model
    ```dart
    class $Counter {
      @InitField(0)
      int value;
    }
    ```
  
- Update `counter_screen.dart` screen
    ```dart
    import 'package:flutter/material.dart';
    import 'package:mustang_core/mustang_widgets.dart';
    
    import 'counter_service.dart';
    import 'counter_state.state.dart';
    
    class CounterScreen extends StatelessWidget {
      const CounterScreen({
        Key key,
      }) : super(key: key);
        
      @override
      Widget build(BuildContext context) {
        return StateProvider<CounterState>(
          state: CounterState(),
          child: Builder(
            builder: (BuildContext context) {
              CounterState state = StateConsumer<CounterState>().of(context);
              return _body(state, context);
            },
          ),
        );
      }
    
      Widget _body(CounterState state, BuildContext context) {
        int counter = state?.counter?.value ?? 0;
        return Scaffold(
          appBar: AppBar(
            title: Text('Counter'),
          ),
          body: Center(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    child: Text('$counter'),
                  ),
                ),
                ElevatedButton(
                  onPressed: CounterService().increment,
                  child: Text('Increment'),
                ),
              ],
            ),
          ),
        );
      }
    }
    ```
  
- Update `counter_service.dart` service
    ```dart
    import 'package:mustang_core/mustang_core.dart';
    import 'package:quick_start/src/models/counter.model.dart';
        
    import 'counter_service.service.dart';
    import 'counter_state.dart';
        
    @ScreenService(screenState: $CounterState)
    class CounterService {
      void increment() {
        Counter counter = WrenchStore.get<Counter>() ?? Counter();
        counter = counter.rebuild((b) => b.value = b.value + 1);
        updateState1(counter);
      }
    }
    ```
  
- Update `main.dart`
    ```dart
    ...
  
    Widget build(BuildContext context) {
      return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          ...
          primarySwatch: Colors.blue,
        ),
        home: CounterScreen(), // Point to Counter screen
      );
    }
  
    ...  
    ```