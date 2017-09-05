require 'pycall/import'
include PyCall::Import

require 'benchmark'
pyimport :pandas, as: :pd

# FIXME: MacOSX backend is not usable through pycall.  I want to fix this issue but the reason is unclear.
pyimport 'matplotlib', as: :mp
mp.rcParams[:backend] = 'TkAgg' if mp.rcParams[:backend] == 'MacOSX'

pyimport :seaborn, as: :sns
pyimport 'matplotlib.pyplot', as: :plt

array = Array.new(100_000) { rand }

trials = 100
results = { method: [], runtime: [] }

def while_sum(ary)
  sum, i, n = 0, 0, ary.length
  while i < n
    sum += ary[i]
    i += 1
  end
  sum
end

trials.times do
  # Array#sum
  results[:method] << 'sum'
  results[:runtime] << Benchmark.realtime { array.sum }

  # Array#inject(:+)
  results[:method] << 'inject'
  results[:runtime] << Benchmark.realtime { array.inject(:+) }

  # while
  results[:method] << 'while'
  results[:runtime] << Benchmark.realtime { while_sum(array) }
end

# visualization

df = pd.DataFrame.new(data: results)
sns.barplot(x: 'method', y: 'runtime', data: df)
plt.title("Array summation benchmark (#{trials} trials)")
plt.xlabel('Summation method')
plt.ylabel('Average runtime [sec]')
plt.show()
