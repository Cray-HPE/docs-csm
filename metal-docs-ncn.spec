# Copyright 2020 Cray Inc. All Rights Reserved.
Name: metal-docs-ncn
License: Cray Proprietary
Summary: Documentation for Non-Compute Nodes on a Metal Cluster
BuildArchitectures: noarch
Version: %(cat .version)
Release: %(echo ${BUILD_METADATA})
Source: %{name}-%{version}.tar.bz2
Vendor: Cray Inc.

%description
This RPM installs documentation into the system for the Shasta Non-compute Nodes.

%prep
%setup -q

%build

%install
install -m 755 -d %{buildroot}/usr/share/doc/metal
cp -pvrR ./*.md ./img ./*example* %{buildroot}/usr/share/doc/metal/ | awk '{print $3}' | sed "s/'//g" | sed "s|$RPM_BUILD_ROOT||g" | tee -a INSTALLED_FILES
cat INSTALLED_FILES | xargs -i sh -c 'test -L {} && exit || test -f $RPM_BUILD_ROOT/{} && echo {} || echo %dir {}' > INSTALLED_FILES_2

%clean

%files -f INSTALLED_FILES_2
%docdir /usr/share/doc/metal
%defattr(-,root,root)
