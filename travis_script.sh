set -e

echo "== Testing rebloc library on Flutter's $FLUTTER_VERSION channel =="
flutter/bin/flutter analyze
find lib/. test/. | grep "\.dart$" | xargs flutter/bin/flutter format -n
flutter/bin/flutter test

echo "== Testing rebloc example on Flutter's $FLUTTER_VERSION channel =="
pushd example
../flutter/bin/flutter analyze
../find lib/. test/. | grep "\.dart$" | xargs ../flutter/bin/flutter format -n
../flutter/bin/flutter test
popd

echo "== Testing rebloc listexample on Flutter's $FLUTTER_VERSION channel =="
pushd listexample
../flutter/bin/flutter analyze
../find lib/. test/. | grep "\.dart$" | xargs ../flutter/bin/flutter format -n
../flutter/bin/flutter test
popd

echo "-- Success --"
