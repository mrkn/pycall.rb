set -ex
if test -n "$ANACONDA"; then
  if test "$PYTHON_VERSION" = "2"; then
    wget https://repo.continuum.io/miniconda/Miniconda2-latest-Linux-x86_64.sh -O miniconda.sh
  elif test "$PYTHON_VERSION" = "3"; then
    wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh
  fi
  bash miniconda.sh -b -p $HOME/miniconda
  export PATH="$HOME/miniconda/bin:$PATH";
  hash -r
  conda config --set always_yes yes --set changeps1 no
  conda update -q conda
  conda info -a
  conda create -q -n test-environment python=$PYTHON_VERSION numpy
  source activate test-environment
else
  if test "$PYTHON_VERSION" = "2"; then
    export PYENV_VERSION=system
    travis_retry pip install --user numpy
  elif test "$PYTHON_VERSION" = "3"; then
    export PYENV_VERSION=3.5.3
    travis_retry pip3 install --user numpy
  fi
fi
set +ex
