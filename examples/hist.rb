require 'pycall/import'
include PyCall::Import

pyimport 'numpy', as: 'np'

# FIXME: MacOSX backend is not usable through pycall.  I want to fix this issue but the reason is unclear.
pyimport 'matplotlib', as: :mp
mp.rcParams[:backend] = 'TkAgg' if mp.rcParams[:backend] == 'MacOSX'

pyimport 'matplotlib.mlab', as: 'mlab'
pyimport 'matplotlib.pyplot', as: 'plt'

np.random.seed(0)

mu = 100
sigma = 15
x = mu + sigma * np.random.randn(437)

num_bins = 50

fig, ax = *plt.subplots

n, bins, patches = *ax.hist(x, num_bins, density: 1)

y = mlab.normpdf(bins, mu, sigma)
ax.plot(bins, y, '--')
ax.set_xlabel('Smarts')
ax.set_ylabel('Probability density')
ax.set_title('Histogram of IQ: $\mu=100$, $\sigma=15$')

fig.tight_layout()
plt.show()
