Summary: sme server crontab maanger
%define name smeserver-crontab_manager
Name: %{name}
%define version 2.4
%define release 1%{dist}
Version: %{version}
Release: %{release}
License:   GPL
Group: Service
Source: %{name}-%{version}.tar.gz
#Patch0: smeserver-crontab_manager-2.2-patch0.patch
#Patch1:smeserver-crontab_manager-2.2-locale-2013-07-14.patch 
#Patch1: %{name}-%{version}.patch.yyyymmddnn
Packager: Ap.Muthu <apmuthu@usa.net>
BuildRoot: /var/tmp/e-smith-buildroot
BuildRequires: e-smith-devtools
BuildArchitectures: noarch
Requires: e-smith-base, e-smith-lib, e-smith >= 4.1
AutoReqProv: no

%changelog
* Wed Jun 24 2014 stephane de Labrusse <stephdl@de-labrusse.fr> - 2.4-1
- Initial release to sme9

* Sun Jul 14 2013 JP Pialasse <tests@pialasse.com> 2.2-2.sme
- apply locale 2013-07-14 patch

* Thu Jun 27 2013 Jean-Philippe Pialasse <tests@pialasse.com>  2.2-1.sme
- imported to buildsys
- cleaning spec
- move conf away from spec - patch0 

* Tue Mar 06 2013 Ap.Muthu <apmuthu@usa.net>
- Updated cronmanager.pm for standard SME 8 class display

* Tue Mar 05 2013 Ap.Muthu <apmuthu@usa.net>
- fix Copyright to License in rpm spec file

* Wed May 26 2010 Jean-Philippe Pialasse <tests@pialasse.com>
- fix expand-template /etc/crontab needed for sme7

* Mon Jan 07 2008 Michel van hees <michel@vanhees.cc>
- Thanks t Sylvain Gomez to fix problem with french traduction

* Fri Aug 03 2007 Michel Van hees <michel@vanhees.cc>
- Fix bug with error 403 in panels

* Mon Jul 16 2007 Michel Van hees <michel@vanhees.cc>
- Thanks to Sulvain Gomez that fixes the uninstall procedure.

* Sun Jan 01 2005 Michel Van hees <michel@vanhees.cc>
- Added support of french

* Mon Oct 11 2004 Michel Van hees <michel@vanhees.cc>
- Initial release

%description
sme server administration panel to control crontab

%prep
%setup
#%patch0 -p1
#%patch1 -p1

%build
perl createlinks

%install
rm -rf $RPM_BUILD_ROOT
(cd root   ; find . -depth -print | cpio -dump $RPM_BUILD_ROOT)
rm -f %{name}-%{version}-filelist
/sbin/e-smith/genfilelist $RPM_BUILD_ROOT > %{name}-%{version}-filelist
echo "%doc COPYING"          >> %{name}-%{version}-filelist

%clean 
rm -rf $RPM_BUILD_ROOT


%pre

%preun

%post

%postun

%files -f %{name}-%{version}-filelist
%defattr(-,root,root)
