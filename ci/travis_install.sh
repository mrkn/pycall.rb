#! /bin/bash

__DIR__=$(cd $(dirname $BASH_SOURCE); pwd)
. $__DIR__/travis_retry.sh

set -ex

if test -z "$PYENV_VERSION"; then
  echo "ERROR: PYENV_VERSION is not provided" >2
  exit 1
fi

pyenv_root=$(pyenv root)

if test -n "$LIBPYTHON"; then
  if test ! -f $LIBPYTHON; then
    if test -f ${pyenv_root}/$LIBPYTHON; then
      export LIBPYTHON=${pyenv_root}/$LIBPYTHON
    else
      echo "Invalid value in LIBPYTHON: ${LIBPYTHON}" >&2
      exit 1
    fi
  fi
fi

(
  cd $(pyenv root)
  if [ -d .git ]; then
    git fetch origin
    git checkout master
    git reset --hard origin/master
  fi
)

case $PYENV_VERSION in
system)
  ;;
*)
  PYTHON_CONFIGURE_OPTS="--enable-shared" pyenv install -f $PYENV_VERSION
  ;;
esac

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
system)
  travis_retry pip install --user numpy
  sudo sh -c "apt-get update && apt-get install --no-install-recommends -y python3-pip"
  travis_retry python3.6 -m pip install --user numpy
  ;;
*)
  travis_retry pip install --user numpy
  ;;
esac

bundle install
