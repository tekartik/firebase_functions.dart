## Test setup

    User dart2 and set env variable
    
    dartsdkdev ; fbfree
    
    npm install
    
## Test

    pub run test -p vm,node
    
    nodetest test/admin_node_test.dart -v
    nodetest test/firestore_node_test.dart -v
    nodetest test/storage_node_test.dart -v

## Firebase setup

    firebase use
    
    # Choose a project and set the alias to 'dev'
    firebase use --add