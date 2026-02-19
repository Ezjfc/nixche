# Author: Endermanbugzjfc
# License: Unlicense

let
  mkNetBeansJavaPlatform = {
    openjdk,
    openjdkMajorVersion,
    label ? "JDK ${openjdkMajorVersion} (Nix)",
  }: ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE platform PUBLIC "-//NetBeans//DTD Java PlatformDefinition 1.0//EN" "http://www.netbeans.org/dtds/java-platformdefinition-1_0.dtd">
    <platform default="no" name="${label}">
        <jdkhome>
            <resource>file:${openjdk}/lib/openjdk/</resource>
        </jdkhome>
        <properties>
            <property name="platform.ant.name" value="JDK_${openjdkMajorVersion}"/>
        </properties>
        <sysproperties>
            <property name="java.specification.version" value="${openjdkMajorVersion}"/>
        </sysproperties>
    </platform>
  '';

  dirPrefix = "/home/$(whoami)/.netbeans";
  dirSuffix = "config/Services/Platforms/org-netbeans-api-java-Platform";
  installNetBeansJavaPlatform = {
    openjdk,
    openjdkMajorVersion,
    netBeansMajorVersion,
    label ? "JDK ${openjdkMajorVersion} (Nix)",
    dir ? "${dirPrefix}/${netBeansMajorVersion}/${dirSuffix}",
    file ? "JDK_${openjdkMajorVersion}_Nix.xml",
  }: let
    config = mkNetBeansJavaPlatform { inherit openjdk openjdkMajorVersion label; };
  in ''
    echo "Installing Java Platforms config to \"${dir}/${file}\""
    mkdir -p "${dir}"
    cat << 'EOF' > "${dir}/${file}"
    ${config}
    EOF
  '';
in {
  inherit mkNetBeansJavaPlatform installNetBeansJavaPlatform;
}
