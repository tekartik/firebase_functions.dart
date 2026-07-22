/// Default mixin implementations for the interfaces exported by
/// `functions_call.dart`.
///
/// These mixins provide every member of their corresponding interface with
/// a default body that throws [UnimplementedError]. Concrete
/// implementations mix them in and override only the members they support,
/// so that adding a new member to an interface later does not break
/// existing implementations that have not been updated yet.
library;

export 'functions_call.dart';
export 'src/functions_call.dart'
    show
        FirebaseFunctionsCallDefaultMixin,
        FirebaseFunctionsCallableDefaultMixin,
        FirebaseFunctionsCallableResultDefaultMixin;
export 'src/functions_call_service.dart'
    show FirebaseFunctionsCallServiceDefaultMixin;
