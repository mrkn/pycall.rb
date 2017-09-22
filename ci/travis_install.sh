#! /bin/bash

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

if test "$PYENV_VERSION" = "system"; then
  if test -z "$LIBPYTHON"; then
    echo "ERROR: LIBPYTHON is not provided for PYENV_VERSION=system" >2
    exit 1
  fi
  # NOTE: PYENV_VERSION should be the version of LIBPYTHON during install script
  PYENV_VERSION=$(basename $(dirname $(dirname $LIBPYTHON)))
fi
PYTHON_CONFIGURE_OPTS="--enable-shared" pyenv install -f $PYENV_VERSION

case "$PYENV_VERSION" in
*conda*)
  case "$PYENV_VERSION" in
  *conda2*)
    python_version=2.7
    ;;
  *)
    python_version=3.6
    ;;
  esac
  conda config --set always_yes yes --set changeps1 no
  travis_retry conda update -q conda
  conda info -a
  travis_retry conda create -q -n test-environment python=$python_version numpy
  source $(pyenv prefix)/bin/activate test-environment
  ;;
*)
  travis_retry pip install --user numpy
  ;;
esac

bundle install
