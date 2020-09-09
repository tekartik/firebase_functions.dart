# Setup

- Follow the [node app setup](https://github.com/tekartik/app_node_utils.dart/tree/master/app_build) instructions
- Add `firebase_functions` dependencies:
  ```yaml
  tekartik_firebase_functions_node:
    git:
      url: git://github.com/tekartik/firebase_functions.dart
      path: firebase_functions_node
      ref: dart2
    version: '>=0.2.1'
  ```