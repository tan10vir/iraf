# Copyright(c) 1986 Association of Universities for Research in Astronomy Inc.

include	<imhdr.h>
include	<imio.h>
include	<mach.h>
include	"stf.h"

# STF_RGPB -- Read the group data block into the first few cards of the user
# area of the IMIO image header.  The GPB is stored as a binary data structure
# in the STF pixfile.  The values of the standard GPB parameters DATAMIN and
# DATAMAX are returned as output arguments.
#
# DLB--11/03/87: Made changes to allow i*2 and i*4 integer parameters in GPB.
# DLB--11/11/87: Changed calculation of character string length in GPB to
# avoid integer truncation error by using P_PSIZE directly.

procedure stf_rgpb (im, group, acmode, datamin, datamax)

pointer	im			# IMIO image descriptor
int	group			# group to be accessed
int	acmode			# image access mode
real	datamin, datamax	# min,max pixel values from GPB

size_t	sz_val
real	rval
double	dval
short	sval
long	lval, offset
int	ival
bool	bval, newgroup
pointer	sp, stf, gpb, lbuf, pp
int	pfd, pn, sz_param
size_t	sz_gpb, c_1
errchk	imaddb, imadds, imaddl, imaddr, imaddd, imastr
errchk	imputd, impstr, open, read
int	open(), imaccf()
long	read()
real	imgetr()

string	readerr "cannot read group data block - no such group?"
string	badtype "illegal group data parameter datatype"
string	nogroup "group index out of range"
define	minmax_ 91

begin
	c_1 = 1

	call smark (sp)
	sz_val = SZ_LINE
	call salloc (lbuf, sz_val, TY_CHAR)

	stf = IM_KDES(im)
	pfd = STF_PFD(stf)

	# Verify that the given group exists.
	if (group < 1 || group > STF_GCOUNT(stf))
	    call error (1, nogroup)

	# Skip ahead if there is no group parameter block.
	if (STF_PSIZE(stf) == 0)
	    goto minmax_

	# Open the pixel file if not already open.
	if (pfd == NULL) {
	    iferr {
		if (IM_ACMODE(im) == READ_ONLY)
		    pfd = open (IM_PIXFILE(im), READ_ONLY, BINARY_FILE)
		else
		    pfd = open (IM_PIXFILE(im), READ_WRITE, BINARY_FILE)
		STF_PFD(stf) = pfd
	    } then {
		call eprintf ("Warning: Cannot open pixfile to read GPB (%s)\n")
		    call pargstr (IM_NAME(im))
		pfd = NULL
	    }
	}

	# Allocate a buffer for the GPB.
	sz_gpb = STF_PSIZE(stf) / NBITS_BYTE / SZB_CHAR
	call salloc (gpb, sz_gpb, TY_CHAR)

	# Read the GPB into a buffer.  The GPB is located at the very end of
	# the data storage area for the group.  If we are opening a new,
	# uninitialized group (acmode = new_image or new_copy), do not
	# physically read the GPB as it is will be uninitialized data.

	newgroup = (acmode == NEW_IMAGE || acmode == NEW_COPY || pfd == NULL)
	if (newgroup)
	    call aclrc (Memc[gpb], sz_gpb)
	else {
	    offset = (group * STF_SZGROUP(stf) + 1) - sz_gpb
	    call seek (pfd, offset)
	    if (read (pfd, Memc[gpb], sz_gpb) != sz_gpb)
		call error (1, readerr)
	}

	# Extract the binary value of each parameter in the GPB and encode it
	# in FITS format in the IMIO user area.

	offset = 0
	for (pn=1;  pn <= STF_PCOUNT(stf);  pn=pn+1) {
	    pp = STF_PDES(stf,pn)
		
	    # Fill in the unitialized fields of the GPB parameter descriptor.
	    P_OFFSET(pp) = offset
	    sz_param = P_PSIZE(pp) / NBITS_BYTE / SZB_CHAR

	    switch (P_PDTYPE(pp)) {
	    # changed case for int to short and long--dlb 11/3/87
	    case 'I':
		if (sz_param == SZ_SHORT) {
		    P_SPPTYPE(pp) = TY_SHORT
		} else if (sz_param == SZ_INT) {
		    P_SPPTYPE(pp) = TY_INT
		} else if (sz_param == SZ_LONG) {
		    P_SPPTYPE(pp) = TY_LONG
		} else {
		    call error (1, badtype)
		}
		P_LEN(pp) = 1
	    case 'R':
		if (sz_param == SZ_REAL)
		    P_SPPTYPE(pp) = TY_REAL
		else
		    P_SPPTYPE(pp) = TY_DOUBLE
		P_LEN(pp) = 1
	    case 'C':
		P_SPPTYPE(pp) = TY_CHAR
		# calculate length directly from PSIZE to avoid truncation error
		P_LEN(pp) = min (SZ_LINE, P_PSIZE(pp) / NBITS_BYTE)
	    case 'L':
		P_SPPTYPE(pp) = TY_BOOL
		P_LEN(pp) = 1
	    default:
		call error (1, badtype)
	    }

	    # Extract the binary parameter value and add a FITS encoded card
	    # to the IMIO user area.  In the case of a new copy image, the
	    # GPB values will already be in the image header, do not modify
	    # the parameter value, but add the parameter if it was not
	    # inherited from the old image.

	    if (acmode != NEW_COPY || imaccf (im, P_PTYPE(pp)) == NO) {
		switch (P_SPPTYPE(pp)) {
		case TY_BOOL:
		    sz_val = SZ_BOOL
		    # arg2: incompatible pointer
		    call amovc (Memc[gpb+offset], bval, sz_val)
		    call imaddb (im, P_PTYPE(pp), bval)
		case TY_SHORT:
		    sz_val = SZ_SHORT
		    call amovc (Memc[gpb+offset], sval, sz_val)
		    call imadds (im, P_PTYPE(pp), sval)
		case TY_INT:
		    sz_val = SZ_INT
		    # arg2: incompatible pointer
		    call amovc (Memc[gpb+offset], ival, sz_val)
		    call imaddi (im, P_PTYPE(pp), ival)
		case TY_LONG:
		    sz_val = SZ_LONG
		    # arg2: incompatible pointer
		    call amovc (Memc[gpb+offset], lval, sz_val)
		    call imaddl (im, P_PTYPE(pp), lval)
		case TY_REAL:
		    sz_val = SZ_REAL
		    # arg2: incompatible pointer
		    call amovc (Memc[gpb+offset], rval, sz_val)
		    call imaddr (im, P_PTYPE(pp), rval)
		case TY_DOUBLE:
		    sz_val = SZ_DOUBLE
		    # arg2: incompatible pointer
		    call amovc (Memc[gpb+offset], dval, sz_val)
		    call imaddd (im, P_PTYPE(pp), dval)
		case TY_CHAR:
		    sz_val = P_LEN(pp)
		    call chrupk (Memc[gpb+offset], c_1, Memc[lbuf], c_1, sz_val)
		    Memc[lbuf+P_LEN(pp)] = EOS
		    call imastr (im, P_PTYPE(pp), Memc[lbuf])
		default:
		    call error (1, badtype)
		}
	    }

	    offset = offset + sz_param
	}

minmax_
	# Return DATAMIN, DATAMAX.  This is done by searching the user area so
	# that ordinary keywords may be used to set datamin and datamax if the
	# GPB is not used.

	datamin = 0.0; datamax = 0.0
	if (imaccf (im, "DATAMIN") == YES)
	    datamin = imgetr (im, "DATAMIN")
	if (imaccf (im, "DATAMAX") == YES)
	    datamax = imgetr (im, "DATAMAX")

	call sfree (sp)
end
