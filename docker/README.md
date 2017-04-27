# How to use and build docker image

## Use

Execute the following command.

```
rake docker:run [port=<PORT>] [attach_local=<DIRECTORY>]
```

The `port` option is for specifying the port number connecting to iruby notebook.

You can access to a local directory from jupyter notebook in the container by attaching the local directory to `/notebooks/local` in the container using `attach_local` option.  The default value is the current directory, that should be pycall directory.

## Build

You can build your own docker image if you modify pycall.
Execute the following command to build it.

```
rake docker:build
```
