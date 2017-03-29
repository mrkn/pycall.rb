from distutils.sysconfig import get_config_var
import sys
for var in ('executable', 'exec_prefix', 'prefix'):
  print(var + ': ' + str(getattr(sys, var)))
print('multiarch: ' + str(getattr(getattr(sys, 'implementation', sys), '_multiarch', None)))
for var in ('VERSION', 'INSTSONAME', 'LIBRARY', 'LDLIBRARY', 'LIBDIR', 'PYTHONFRAMEWORKPREFIX', 'MULTIARCH'):
  print(var + ': ' + str(get_config_var(var)))
