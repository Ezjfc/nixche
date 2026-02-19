# nixche
A collection of niche Nix utilities that fulfil quite specific tasks.

## Utilities

### NetBeans Java Platform (`netbeans-java-platform.nix`)
Utilities for managing NetBeans Java Platform configurations.

- `mkNetBeansJavaPlatform`: Creates a NetBeans Java Platform XML configuration
- `installNetBeansJavaPlatform`: Generates a shell script to install Java Platform configuration to NetBeans

**Usage example:**
```nix
let
  netbeans-utils = import ./netbeans-java-platform.nix;
in
  netbeans-utils.mkNetBeansJavaPlatform {
    openjdk = pkgs.openjdk17;
    openjdkMajorVersion = "17";
  }
```

**Testing:**
```bash
nix-instantiate --eval --strict test-netbeans-java-platform.nix
```
