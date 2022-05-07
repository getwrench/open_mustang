# Mustang

A framework to build Flutter applications. Following features are available out of the box.

- State Management
- Persistence
- Cache
- File layout and naming standards
- Reduces boilerplate with [open_mustang_cli](https://pub.dev/packages/open_mustang_cli)

## Contents
- [Framework Components](#framework-components)
- [Component Communication](#component-communication)
- [Model](#model)
- [State](#state)
- [Service](#service)
- [Screen](#screen)
- [Persistence](#persistence)
- [Cache](#cache)
- [Events](#events)
- [Aspects](#aspects)
- [Project Structure](#project-structure)

## Quick Start

### Framework Components
- **Model** - A Dart class. All models as a whole represent the app state.

- **Screen** - Screen is a reusable widget. It usually represents a screen in an app or a page in a web browser.
Screens can also be used as a widget in another screen.

- **State** - State class provides access to the subset of the app state to the corresponding screen.
It is a Dart class with _1 or more_ `Model` fields.

- **Service** - Coordinates communication between the corresponding screen and a state. Also, async communication and 
application logic goes here.

### Component Communication
- Every `Screen` has a corresponding `Service` and a `State`. All three components work together to continuously
rebuild the UI whenever there is a change in the application state.

    [<img src="https://github.com/getwrench/open_mustang/raw/master/mustang_core/01-components.png"/>](Architecture)

    1. `Screen` reads `State` while building the UI
    2. `Screen` invokes methods in the `Service` as a response to user events (`scroll`, `tap` etc.)
    3. `Service` 
        - reads/updates `Models` in the `MustangStore`
        - makes API calls, when needed
        - informs `State` when `MustangStore` is updated
    4. `State` informs `Screen` to rebuild the UI
    5. Back to Step 1

### Model
- An abstract class annotated with `appModel`
- Model name should start with `$`
- Initialize fields with `InitField` annotation
- Methods/Getters/Setters are `NOT` supported inside `Model` classes
- If a field should be excluded when a `Model` is persisted to disk, annotate that field with `SerializeField(false)`
    
    ```dart
    @appModel
    abstract class $User {
      late String name;
    
      late int age;
    
      @InitField(false)
      late bool admin; 
    
      @InitField(['user', 'default'])
      late BuiltList<String> roles;
      
      late $Address address;  // $Address is another model annotated with @appModel
      
      late BuiltList<$Vehicle> vehicles;  // Use only immutable versions of List/Map as fields inside Model classes
      
      @SerializeField(false)
      late String errorMsg; // errorMsg field will not be included when $User model is persisted 
    }
    ```
  
### State
- An abstract class annotated with `screenState`
- State name should start with `$`
- All fields of the state class must be `Model`s 

    ```dart      
    @screenState
    abstract class $ExampleScreenState {
      late $User user;
      
      late $Vehicle vehicle;
    }
    ```
    
### Service
- An abstract class annotated with `ScreenService`
- Service name should start with `$`
  
    ```dart
    @screenService
    abstract class $ExampleScreenService {
      void getUser() {
        User user = MustangStore.get<User>() ?? User();
          updateState1(user);
        }
    }
    ```
    
- Service has access to the following APIs
    - `updateState` -  Updates app state and re-builds the screen. To update the state without re-building the screen,
  set `reload` argument to `false`.
        - `updateState()`
        - `updateState1(T model1, { reload: false })` // only updates the state, screen will re-build
        - `updateState2(T model1, S model2, { reload: true })`
        - `updateState3(T model1, S model2, U model3, { reload: true })`
        - `updateState4(T model1, S model2, U mode3, V model4, { reload: true })`

    - `memoizeScreen` - Invokes any method passed as argument only once.
        - `T memoizeScreen<T>(T Function() methodName)`
            ```dart
            // In the snippet below, getScreenData method caches the response of getData method, a Future.
            // Even when getData method is called multiple times, method execution happens only once and uses the
            // response received the first time.
            Future<void> getData() async {
              Common common = MustangStore.get<Common>() ?? Common();
              User user;
              Vehicle vehicle;

              ...   
            }

            Future<void> getScreenData() async {
              return memoize(getData);
            }
            ```
    - `clearMemoizedScreen` - Clears the data cached by `memoizeScreen` method.
        - `void clearMemoizedScreen()`
            ```dart
            Future<void> getData() async {
              ...
            }

            Future<void> getScreenData() async {
              return memoizeScreen(getData);
            }

            void resetScreen() {
              // clears Future<void> cached by memoizeScreen()
              clearMemoizedScreen();
            }
            ``` 

### Screen
- Use `StateProvider` widget to re-build the `Screen` when there is a change in `State`
  
    ```dart
    
    Widget build(BuildContext context) {
      return StateProvider<HomeScreenState>(
          state: HomeScreenState(),
          child: Builder(
            builder: (BuildContext context) {
              // state variable provides access to model fields declared in the HomeScreenState class
              HomeScreenState? state = StateConsumer<HomeScreenState>().of(context);
              
              // Even when this widget is built many times, only 1 API call 
              // will be made because the Future from the service is cached
              SchedulerBinding.instance?.addPostFrameCallback(
                (_) => HomeScreenService().getScreenData(),
              );
    
              if (state?.common?.busy ?? false) {
                return Spinner();
              }
    
              if (state?.counter?.errorMsg.isNotEmpty ?? false) {
                return ErrorBody(errorMsg: state.common.errorMsg);
              }
                
              return _body(state, context);
            },
          ),
        );
      }
    ```

### Persistence

[<img src="https://github.com/getwrench/open_mustang/raw/master/mustang_core/02-persistence.png"/>](Persistence)

By default, `app state` is maintained in memory by `MustangStore`. When the app is terminated, the `app state` is lost
permanently. However, there are cases where it is desirable to persist and restore the `app state`. For example,

- Save and restore user's session token to prevent user having to log in everytime
- Save and restore partial changes in a screen so that the work can be resumed from where the user has left off.

Enabling persistence is simple and works transparently.

```dart
import 'package:xxx/src/models/serializers.dart' as app_serializer;

WidgetsFlutterBinding.ensureInitialized();

// In main.dart before calling runApp method,
// 1. Enable persistence like below
MustangStore.config(
  isPersistent: true,
  storeName: 'myapp',
);

// 2. Initialize persistence
Directory dir = await getApplicationDocumentsDirectory();
await MustangStore.initPersistence(dir.path);

// 3. Restore persisted state before the app starts
await MustangStore.restoreState(app_serializer.json2Type, app_serializer.serializerNames);
```

With the above change, `app state` (`MustangStore`) is persisted to the disk and will be restored into `MustangStore` when the app is started.

### Cache

[<img src="https://github.com/getwrench/open_mustang/raw/master/mustang_core/03-cache.png"/>](Cache)

`Cache` feature allows switching between instances of the same type on need basis.

`Persistence` is a snapshot of the `app state` in memory (`MustangStore`). However, there are times when data
need to be persisted but restored only when needed. An example would be a technician working on multiple jobs at the same time i.e, technician switches between jobs.
Since the `MustangStore` allows only one instance of a type, there cannot be two instances of the Job object in the MustangStore.

`Cache` APIs, available in `Service`s, make it easy to restore any instance into memory (`MustangStore`).

- ```
  Future<void> addObjectToCache<T>(String key, T t)
  ```
  Save an instance of type `T` in the cache. `key` is an identifier for one or more cached objects.

- ```
  Future<void> deleteObjectsFromCache(String key)
  ```
  Delete all cached objects having the identifier `key`

- ```
  static Future<void> restoreObjects(
      String key,
      void Function(
          void Function<T>(T t) update,
          String modelName,
          String jsonStr,
      ) callback,
  )
  ```
  Restores all objects in the cache identified by the `key` into memory `MustangStore` and also into the persisted store
  so that the in-memory and persisted app state remain consistent.

- ```
  bool itemExistsInCache(String key)
  ```
  Returns `true` if an identifier `key` exists in the Cache, `false` otherwise.

### Events

[<img src="https://github.com/getwrench/open_mustang/raw/master/mustang_core/04-events.png"/>](Events)

There are use cases where application has to react to external events. An external 
event is any event that is generated *not* as a result of user's interaction with the app.
Following are the examples external events:
- Internet connectivity
- Data update events from the app backend
- Push notifications

Mustang allows the app to subscribe to such events. When subscribed, `Service` of the currently visible `Screen` receives
event notifications and updates them in the MustangStore. `Service` then triggers the `Screen` rebuild.
It is important to keep in mind that every event is an instance of `Model`. And, to use a model as an event, it needs to be
annotated with `@appEvent`. Following is an example of creating of an event inside `models` folder

```dart
Widget build(BuildContext context) {
    return MaterialApp(
      ...
      navigatorObservers: [
        MustangRouteObserver.getInstance(), // this is needed for Events to work
      ],
    );
}

```

```dart
@appModel
@appEvent
abstract class $TimerEvent {
  @InitField(0)
  late int value;
}
```

Create a dart file in your application that can publish events. It is recommended to create these dart files
outside `screens` folder as they are not tied to or related to any specific screen.

```dart
// Create an event 
TimerEvent timerEvent = MustangStore.get<TimerEvent>() ?? TimerEvent();
timerEvent = timerEvent.rebuild((b) => b..value = (b.value ?? 0) + 1);
// Publish the event
EventStream.pushEvent(timerEvent);
```

Visible screen of the app automatically rebuilds itself after consuming the event. It is upto the screen
to show appropriate UI based on the received event.

### Aspects

TODO

### Project Structure
- Project structure of a Flutter application created with Mustang framework looks as below
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
- Every `Screen` needs a `State` and a `Service`. So, `Screen, State, Service` files are grouped inside a directory
- All `Model` classes must be inside `models` directory

## Quick Start

- Install Flutter
  ```bash
    mkdir -p ~/lib && cd ~/lib
    
    git clone https://github.com/flutter/flutter.git -b stable

    # Add PATH in ~/.zshrc 
    export PATH=$PATH:~/lib/flutter/bin
    export PATH=$PATH:~/.pub-cache/bin
  ```
    
- Install Mustang CLI
  ```bash
    dart pub global activate open_mustang_cli
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
    ...
    dependencies:
      ...
      built_collection: ^5.1.1
      built_value: ^8.1.3
      mustang_core: ^1.0.2
      path_provider: ^2.0.6

    dev_dependencies:
      ...
      build_runner: ^2.1.4
      built_value_generator: ^8.1.3
      mustang_codegen: ^1.0.11    
  ```
  
- Install dependencies
  ```bash
    flutter pub get
  ```

- Generate files for a screen called `counter`. Following command creates file representing a `Model`, and also files representing `Screen`, `Service` and `State`.
  ```bash
    omcli -s counter
  ```

- Generate runtime files and watch for changes. 
  ```bash
    omcli -w # omcli -b generates runtime files once
  ```
  
- Update the generated `counter.dart` model
  ```dart
    class $Counter {
      @InitField(0)
      late int value;
    }
  ```
  
- Update `counter_screen.dart` screen
  ```dart
    import 'package:flutter/material.dart';
    import 'package:mustang_core/mustang_widgets.dart';
    
    import 'counter_service.service.dart';
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
              CounterState? state = StateConsumer<CounterState>().of(context);
              return _body(state, context);
            },
          ),
        );
      }
    
      Widget _body(CounterState? state, BuildContext context) {
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
                  child: Text('$counter'),
                ),
                ElevatedButton(
                  onPressed: CounterService().increment,
                  child: const Text('Increment'),
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
        
    @screenService
    class CounterService {
      void increment() {
        Counter counter = MustangStore.get<Counter>() ?? Counter();
        counter = counter.rebuild((b) => b.value = (b.value ?? 0) + 1);
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
