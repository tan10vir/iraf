#! /bin/csh
# CL.CSH -- Startup the version of the CL executable compiled for the
# architecture or floating point hardware appropriate for the current
# machine.

# Determine IRAF root directory (value set in install script).
if ($?iraf == 0) then
    setenv iraf "/iraf/iraf/"
endif

# Determine platform architecture.
if ($?IRAFARCH) then
    if (-e $iraf/bin.${IRAFARCH}/cl.e) then
	set MACH = $IRAFARCH
    endif
endif

if (! $?MACH) then
    if (-f /etc/redhat-release) then
	set mach = redhat
    else if (-f /etc/SuSE-release) then
	set mach = suse
    else
	set mach = `uname -s | tr '[A-Z]' '[a-z]'`
    endif

    if (-e $iraf/bin.$mach/cl.e) then
	set MACH = $mach
    else if (-e $iraf/bin.freebsd/cl.e) then
	set MACH = freebsd
    else if (-e $iraf/bin.linux/cl.e) then
	set MACH = linux
    else if (-e $iraf/bin.redhat/cl.e) then
	set MACH = redhat
    else if (-e $iraf/bin.suse/cl.e) then
	set MACH = suse
    else if (-e $iraf/bin.sunos/cl.e) then
	set MACH = sunos
    else if (-e $iraf/bin.linuz/cl.e) then
	set MACH = linuz
    else
	echo "cannot find $iraf/bin.xxx/cl.e!"
	exit 1
    endif
endif

# Check for obsolete IRAFBIN definition.
if ($?IRAFBIN && !($?IRAFARCH)) then
    echo "Use IRAFARCH rather than IRAFBIN to specify the machine architecture"
    echo "IRAFARCH, if defined, should be one of ffpa,f68881,i386,sparc, etc."
endif

# Just run the CL if IRAFARCH already defined.
if ($?IRAFARCH) then
    if ($IRAFARCH == "") then
	setenv arch ""
    else
	setenv arch ".$IRAFARCH"
    endif

    setenv IRAFBIN ${iraf}bin$arch/
    set file = ${IRAFBIN}cl.e
    if (-e $file) then
	exec $file
    else
	echo "$file not found"
    endif
endif

# Determine the architecture to be used.
if ("$MACH" == "freebsd") then
    setenv IRAFARCH "freebsd"
else if ("$MACH" == "linux") then
    setenv IRAFARCH "linux"
else if ("$MACH" == "redhat") then
    setenv IRAFARCH "redhat"
else if ("$MACH" == "suse") then
    setenv IRAFARCH "suse"
else if ("$MACH" == "sunos") then
    setenv IRAFARCH "sunos"
else if ("$MACH" == "linuz") then
    setenv IRAFARCH "linuz"
endif

setenv arch .$IRAFARCH
setenv IRAFBIN ${iraf}bin$arch/
set file = ${IRAFBIN}cl.e

# Run the desired CL.
exec $file