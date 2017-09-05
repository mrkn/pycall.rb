require 'pycall/import'

include PyCall::Import

pyimport 'numpy', as: 'np'

# FIXME: MacOSX backend is not usable through pycall.  I want to fix this issue but the reason is unclear.
pyimport 'matplotlib', as: :mp
mp.rcParams[:backend] = 'TkAgg' if mp.rcParams[:backend] == 'MacOSX'

pyimport 'matplotlib.pyplot', as: 'plt'

pyfrom 'sklearn.datasets', import: 'fetch_olivetti_faces'
pyfrom 'sklearn.ensemble', import: 'ExtraTreesClassifier'

# Number of cores to use to perform parallel fitting of the forest model
n_jobs = 1

# Load the faces datasets
data = fetch_olivetti_faces()
x = data.images.reshape([PyCall.len(data.images), -1])
y = data.target

mask = y < 5  # Limit to 5 classes
x = x[mask]
y = y[mask]

# Build a forest and compute the pixel importances
puts "Fitting ExtraTreesClassifier on faces data with #{n_jobs} cores..."
t0 = Time.now
forest = ExtraTreesClassifier.new(
  n_estimators: 1_000,
  max_features: 128,
  n_jobs: n_jobs,
  random_state: 0
)

forest = forest.fit(x, y)
puts "done in %0.3fs" % (Time.now - t0)
importances = forest.feature_importances_
importances = importances.reshape(data.images[0].shape)

# Plot pixel importances
plt.matshow(importances, cmap: plt.cm.__dict__[:hot])
plt.title("Pixel importances with forests of trees")
plt.show()
