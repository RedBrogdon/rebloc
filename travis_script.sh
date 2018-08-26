set -e

echo "== Testing rebloc library on Flutter's $FLUTTER_VERSION channel =="
flutter/bin/flutter test

echo "== Testing rebloc example on Flutter's $FLUTTER_VERSION channel =="
cd example
../flutter/bin/flutter test

echo "-- Success --"