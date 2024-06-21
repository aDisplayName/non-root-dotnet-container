non-root-dotnet-container
=
Demonstrate how to configure filesystem access for container based on non-root dotnet image

# Summary
From .NET 8, the distroless base runtime images are introduced by Microsoft with reduced size, and better security.

The introduction of non-root user also causing some trouble with existing kubernets container image which requires the write access to volume mount.

This is an example to check the permission of different files and folder created by the [dockerfile](./dockerfile).

# Build
Please run the docker build at the root folder:
```
docker build . -t file-access-test:0.0.1
```

# Test
This is the folder tree after the build, which can be obtained by [`dive`](https://github.com/wagoodman/dive) utility. 

Notice the ownership difference between `/app/bin` (owned by `root`) and `/app/bin2` (owned by `app`). Although none of any existing files under those two folders can be modified, the non-root `app` user can create new files under `/app/bin2` folder, potentially changing .NET app settings, but cannot create new files under `/app/bin` folder at all.

```
Permission     UID:GID       Size  Filetree
drwxr-xr-x   1654:1654     2.0 MB  ├── app
drwxr-xr-x         0:0     1.0 MB  │   ├── bin
-rwxr--r--         0:0     187 kB  │   │   ├── Spectre.Console.Cli.dll
-rwxr--r--         0:0     720 kB  │   │   ├── Spectre.Console.dll
drwxr-xr-x         0:0     5.1 kB  │   │   ├── de
-rwxr--r--         0:0     5.1 kB  │   │   │   └── Spectre.Console.Cli.resources.dll
-rwxr-xr-x         0:0      72 kB  │   │   ├── file-access-test
-rw-r--r--         0:0     2.0 kB  │   │   ├── file-access-test.deps.json
-rwxr-xr-x         0:0     6.7 kB  │   │   ├── file-access-test.dll
-rwxr-xr-x         0:0      11 kB  │   │   ├── file-access-test.pdb
-rw-r--r--         0:0      328 B  │   │   ├── file-access-test.runtimeconfig.json
drwxr-xr-x         0:0     5.1 kB  │   │   ├── fr
-rwxr--r--         0:0     5.1 kB  │   │   │   └── Spectre.Console.Cli.resources.dll
drwxr-xr-x         0:0     5.1 kB  │   │   └── sv
-rwxr--r--         0:0     5.1 kB  │   │       └── Spectre.Console.Cli.resources.dll
drwxr-xr-x   1654:1654     1.0 MB  │   ├── bin2
-rwxr--r--         0:0     187 kB  │   │   ├── Spectre.Console.Cli.dll
-rwxr--r--         0:0     720 kB  │   │   ├── Spectre.Console.dll
drwxr-xr-x         0:0     5.1 kB  │   │   ├── de
-rwxr--r--         0:0     5.1 kB  │   │   │   └── Spectre.Console.Cli.resources.dll
-rwxr-xr-x         0:0      72 kB  │   │   ├── file-access-test
-rw-r--r--         0:0     2.0 kB  │   │   ├── file-access-test.deps.json
-rwxr-xr-x         0:0     6.7 kB  │   │   ├── file-access-test.dll
-rwxr-xr-x         0:0      11 kB  │   │   ├── file-access-test.pdb
-rw-r--r--         0:0      328 B  │   │   ├── file-access-test.runtimeconfig.json
drwxr-xr-x         0:0     5.1 kB  │   │   ├── fr
-rwxr--r--         0:0     5.1 kB  │   │   │   └── Spectre.Console.Cli.resources.dll
drwxr-xr-x         0:0     5.1 kB  │   │   └── sv
-rwxr--r--         0:0     5.1 kB  │   │       └── Spectre.Console.Cli.resources.dll
drwxr-xr-x   1654:1654        0 B  │   └── data
drwxr-xr-x         0:0        0 B  ├── bin
drwxr-xr-x         0:0     209 kB  ├── etc
-rw-r--r--         0:0       13 B  │   ├── debian_version
drwxr-xr-x         0:0      197 B  │   ├── dpkg
drwxr-xr-x         0:0      197 B  │   │   └── origins
-rw-r--r--         0:0       83 B  │   │       ├── debian
-rwxrwxrwx         0:0        0 B  │   │       ├── default → /etc/dpkg/origins/ubuntu
-rw-r--r--         0:0      114 B  │   │       └── ubuntu
```

We have the following result:
* All files can be read
  ```pwsh
  PS > docker run --rm file-access-test:0.0.1 file-access-test.dll /app/bin/Spectre.Console.Cli.dll
  access granted
  PS > docker run --rm file-access-test:0.0.1 file-access-test.dll /app/bin/Spectre.Console.Cli.dll Open Read
  access granted
  PS > docker run --rm file-access-test:0.0.1 file-access-test.dll /etc/debian_version
  access granted
  ```
* Files cannot be modified if their owner is set to `root`
  ```pwsh
  PS > docker run --rm file-access-test:0.0.1 file-access-test.dll /app/bin/Spectre.Console.Cli.dll Open Write
  Error: Access to the path '/app/bin/Spectre.Console.Cli.dll' is denied.
  PS > docker run --rm file-access-test:0.0.1 file-access-test.dll /etc/debian_version Open Write
  Error: Access to the path '/etc/debian_version' is denied.
  ```
* File can be created in folder with owner as `app`
  ```pwsh
  PS > docker run --rm file-access-test:0.0.1 file-access-test.dll /app/data/test1 Create Write
  access granted
  PS > docker run --rm file-access-test:0.0.1 /app/bin/file-access-test.dll /app/bin2/test1 Create Write
  access granted
  ```
* File cannot be created in folder with owner as `root`:
  ```pwsh
  PS > docker run --rm file-access-test:0.0.1 /app/bin/file-access-test.dll /app/bin/test1 Create Write
  Error: Access to the path '/app/bin/test1' is denied
  ```

# Reference
* https://devblogs.microsoft.com/dotnet/securing-containers-with-rootless/
