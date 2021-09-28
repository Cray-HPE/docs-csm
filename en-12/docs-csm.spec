# Copyright 2021-2022 Hewlett Packard Enterprise Development LP
Name: docs-csm
License: MIT License
Summary: Documentation for Cray System Management (CSM) Installation and Upgrade
BuildArchitectures: noarch
Version: %(echo $VERSION)
Release: 1
Source: %{name}-%{version}.tar.bz2
Vendor: Hewlett Packard Enterprise Company

%description
This package contains documentation about how to install or upgrade
the Cray System Management (CSM) software and related supporting
operational procedures to manage HPE Cray EX systems. This documentation
is in Markdown format starting at /usr/share/doc/csm/README.md.

%prep
%setup -q

%build

%install
install -m 755 -d %{buildroot}/usr/share/doc/csm
cp -pvrR ./*.md ./background ./install ./img ./introduction ./operations ./scripts ./troubleshooting ./update_product_stream ./upgrade ./*example* %{buildroot}/usr/share/doc/csm/ | awk '{print $3}' | sed "s/'//g" | sed "s|$RPM_BUILD_ROOT||g" | tee -a INSTALLED_FILES
cat INSTALLED_FILES | xargs -i sh -c 'test -L {} && exit || test -f $RPM_BUILD_ROOT/{} && echo {} || echo %dir {}' > INSTALLED_FILES_2

%clean

%files -f INSTALLED_FILES_2
%docdir /usr/share/doc/csm
%license LICENSE
%defattr(-,root,root)
