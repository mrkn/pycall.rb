# How to use and build docker image

## Use

Execute the following command.

```
docker run -it -p 8888:8888 --rm --name jupyter rubydata/pycall
```

You can access to a local directory from jupyter notebook in the container by attaching the local directory to `/notebooks/local` in the container using `-v` option.
For example, the following command attaches the current directory to `/notebooks/local`.

```
docker run -it -p 8888:8888 --rm --name jupyter -v $(pwd):/notebooks/local rubydata/pycall
```

## Build

You can build your own docker image if you modify pycall.
Execute the following command to build it.

```
docker build -f docker/Dockerfile .
```
