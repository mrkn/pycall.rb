__DIR__=$(cd $(dirname $BASH_SOURCE); pwd)
. $__DIR__/travis_retry.sh

set -ex

if test -z "$PYENV_VERSION"; then
  echo "ERROR: PYENV_VERSION is not provided" >2
  exit 1
fi

if test -n "$LIBPYTHON"; then
  export LIBPYTHON=$(pyenv root)/$LIBPYTHON
fi

case "$PYENV_VERSION" in
*conda*)
  source $(pyenv prefix)/bin/activate test-environment
  ;;
esac

set +ex
