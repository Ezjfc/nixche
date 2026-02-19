# Test file for netbeans-java-platform.nix
# Run with: nix-instantiate --eval --strict test-netbeans-java-platform.nix

let
  # Mock pkgs for testing
  mockPkgs = {
    openjdk17 = "/nix/store/mock-openjdk17";
    openjdk21 = "/nix/store/mock-openjdk21";
  };

  netbeans-utils = import ./netbeans-java-platform.nix;

  # Test mkNetBeansJavaPlatform
  test1 = netbeans-utils.mkNetBeansJavaPlatform {
    openjdk = mockPkgs.openjdk17;
    openjdkMajorVersion = "17";
  };

  # Test mkNetBeansJavaPlatform with custom label
  test2 = netbeans-utils.mkNetBeansJavaPlatform {
    openjdk = mockPkgs.openjdk21;
    openjdkMajorVersion = "21";
    label = "Custom JDK 21";
  };

  # Test installNetBeansJavaPlatform
  test3 = netbeans-utils.installNetBeansJavaPlatform {
    openjdk = mockPkgs.openjdk17;
    openjdkMajorVersion = "17";
    netBeansMajorVersion = "20";
  };

  # Test installNetBeansJavaPlatform with custom parameters
  test4 = netbeans-utils.installNetBeansJavaPlatform {
    openjdk = mockPkgs.openjdk21;
    openjdkMajorVersion = "21";
    netBeansMajorVersion = "21";
    label = "Custom JDK 21";
    dir = "/custom/path";
    file = "custom-jdk-21.xml";
  };

in {
  inherit test1 test2 test3 test4;
  
  # Simple assertion tests
  assertions = {
    test1ContainsJDK17 = builtins.match ".*JDK 17.*" test1 != null;
    test2ContainsCustomLabel = builtins.match ".*Custom JDK 21.*" test2 != null;
    test3ContainsInstallScript = builtins.match ".*Installing Java Platforms config.*" test3 != null;
    test4ContainsCustomPath = builtins.match ".*/custom/path.*" test4 != null;
  };
}
