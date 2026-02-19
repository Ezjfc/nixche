# nixche
A collection of niche Nix utilities that fulfil quite specific tasks.

## Utilities

### NetBeans Java Platform (`java/create-netbeans-java-platform/`)
Utilities for managing NetBeans Java Platform configurations.

- `mkNetBeansJavaPlatform`: Creates a NetBeans Java Platform XML configuration (string)
- `installNetBeansJavaPlatform`: Generates a shell script (string) to install Java Platform configuration to NetBeans

### Write Cat Script (`sh/write-cat-script/`)
Shell script wrappers that echo the script content before execution.

- `writeCatScript`: Wraps `writeShellScript` to print the script content in color (default: dark purple) before running it
- `writeCatScriptBin`: Wraps `writeShellScriptBin` to print the script content in color (default: dark purple) before running it
