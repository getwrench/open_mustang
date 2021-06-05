[Mustang](https://tenor.com/4A2P.gif)

# Mustang

A framework to build Flutter applications.

- provides **state management**
- reduces boilerplate
- generates source templates using **cli**
- enables consistent **directory and file layout and naming standards**

### Framework Components
- **Screen** - Flutter widget class for the UI. Code can be split into multiple dart files.

- **Model** - A Dart class representing application data.

- **State** - Encapsulates data needed for a `Screen`. It is a Dart class with _1 or more_ `Model` fields.

- **Service** - A Dart class housing code for async communication and business logic.

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
            - screen_one/
              - screen_one_screen.dart
              - screen_one_state.dart
              - screen_one_service.dart
            - screen_two/
              - screen_two_screen.dart
              - screen_two_state.dart
              - screen_two_service.dart
    ```
- Every `Screen` needs a `State` and a `Service`. So, `Screen, State, Service` files must be in their own named directory
- All `Model` classes must be inside `models` directory

### Model
- A Class annotated with `appModel`
- Class name should start with `$`
- Initialize fields with `InitField` annotation
- Getters/Setters are `NOT` supported inside `Model` classes. Use regular methods instead.
    <br></br>
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
    <br></br>
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
    <br></br>
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
                    ..
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
    <br></br>
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
    
                      if (state?.common?.busy ?? false) return Spinner();
    
                      if (state.common?.errorMsg != null)
                          return ErrorBody(errorMsg: state.common.errorMsg);
    
                      return _body(state, context);
                  },
                ),
              );
          }
    ```

### Mustang CLI

After adding framework dependencies to a Flutter project, `mustang_cli` tool helps in generating shell files
for all framework components.

- To generate files for new screen in `lib/src/screens/routes/screen3`
    <br></br>
    ```bash
        flutter pub run mustang_cli -s routes/screen3

        // Output
        Created lib/src/screens/routes/screen3
        Created lib/src/screens/routes/screen3/screen3_state.dart
        Created lib/src/screens/routes/screen3/screen3_service.dart
        Created lib/src/screens/routes/screen3/screen3_screen.dart
    ```

- To generate a model in `lib/src/models/user.dart`
    <br></br>
    ```bash
        flutter pub run mustang_cli -m user 

        // Output
        Created lib/src/models
        Created lib/src/models/user.dart
    ```

- To generate runtime files
    <br></br>
    ```bash
        flutter pub run mustang_cli -b
    ```

- To generate runtime files in watch mode
    <br></br>
    ```bash
        flutter pub run wrench_cli -w
    ```

- To clean generated files
    <br></br>
    ```bash
        flutter pub run mustang_cli -d
    ```

### Setup
- Configure Flutter
    <br></br>
    ```dart
        mkdir -p ~/software && cd ~/software
    
        curl -O https://storage.googleapis.com/flutter_infra/releases/stable/macos/flutter_macos_2.x.x-stable.zip

        unzip flutter_macos_x.0.x-stable.zip
    
        export PATH="$PATH:`pwd`/flutter/bin
    ```

### Dependencies
- Update `pubspec.yaml` as below
    <br></br>
    ```yaml
    dependencies:
        flutter:
          sdk: flutter
        built_collection: ^5.0.0
        built_value: ^8.0.0
        provider: ^5.0.0
        wrench_widgets:
          git:
            url: git@bitbucket.org:lunchclub/wrench_widgets.git
            ref: master
        wrench_flutter_common:
          git:
            url: git@bitbucket.org:lunchclub/wrench_flutter_common.git
            ref: master
        mustang_core:
          git:
            url: git@bitbucket.org:lunchclub/mustang.git
            path: mustang_core
            ref: master

      dev_dependencies:
        flutter_test:
          sdk: flutter
        build_runner: ^1.11.5
        pedantic: ^1.11.0
        test: ^1.16.5
        mustang_cli:
          git:
            url: git@bitbucket.org:lunchclub/mustang.git
            path: mustang_cli
            ref: master
        mustang_codegen:
          git:
            url: git@bitbucket.org:lunchclub/mustang.git
            path: mustang_codegen
            ref: master
    ```
    
- Get Dependencies
    <br></br>
    ```bash
        flutter pub get
    ```
  
