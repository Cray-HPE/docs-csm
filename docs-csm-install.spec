# Copyright 2020 Cray Inc. All Rights Reserved.
Name: docs-csm-install
License: MIT License
Summary: Documentation for Cray System Management Installation and Upgrade
BuildArchitectures: noarch
Version: %(cat .version)
Release: %(echo ${BUILD_METADATA})
Source: %{name}-%{version}.tar.bz2
Vendor: Cray Inc.

%description

%prep
%setup -q

%build

%install
install -m 755 -d %{buildroot}/usr/share/doc/csm
cp -pvrR ./*.md ./background ./install ./img ./introduction ./operations ./update_product_stream ./upgrade ./*example* %{buildroot}/usr/share/doc/csm/ | awk '{print $3}' | sed "s/'//g" | sed "s|$RPM_BUILD_ROOT||g" | tee -a INSTALLED_FILES
cat INSTALLED_FILES | xargs -i sh -c 'test -L {} && exit || test -f $RPM_BUILD_ROOT/{} && echo {} || echo %dir {}' > INSTALLED_FILES_2

%clean

%files -f INSTALLED_FILES_2
%docdir /usr/share/doc/csm
%license LICENSE
%defattr(-,root,root)
