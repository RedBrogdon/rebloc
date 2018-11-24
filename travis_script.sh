set -e

flutter/bin/flutter packages get

echo "== Testing rebloc library on Flutter's $FLUTTER_VERSION channel =="
pushd lib
../flutter/bin/flutter analyze
find . | grep "\.dart$" | xargs ../flutter/bin/flutter format -n
popd

pushd test
../flutter/bin/flutter analyze
find . | grep "\.dart$" | xargs ../flutter/bin/flutter format -n
popd

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
