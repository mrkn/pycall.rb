from distutils.sysconfig import get_config_var
import sys

def conda():
    return 'conda' in sys.version or 'Continuum' in sys.version

for var in ('executable', 'exec_prefix', 'prefix'):
  print(var + ': ' + str(getattr(sys, var)))
print('conda: ' + ('true' if conda() else 'false'))
print('multiarch: ' + str(getattr(getattr(sys, 'implementation', sys), '_multiarch', None)))
for var in ('VERSION', 'INSTSONAME', 'LIBRARY', 'LDLIBRARY', 'LIBDIR', 'PYTHONFRAMEWORKPREFIX', 'MULTIARCH'):
  print(var + ': ' + str(get_config_var(var)))
