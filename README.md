checklist for adding downstream job trigger

1. add TRAVIS_COM_TOKEN to travis job settings
2. be sure that in travis job settings, "build pushed pull requests" is turned on
3. change .travis.yml to include this in script section: (replace SDK=android with appropriate value)
  - git clone https://github.com/juancarlostong/ci.git
  - "SDK=android ci/trigger_build.sh optimizely%2Ffullstack-sdk-compatibility-suite"
