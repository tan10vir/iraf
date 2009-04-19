# Copyright(c) 1986 Association of Universities for Research in Astronomy Inc.

include	<imhdr.h>
include	<imset.h>
include	"icombine.h"


# IC_SCALE -- Get and set the scaling factors.
#
# If the scaling parameters have been set earlier then this routine
# just normalizes the factors and writes the log output.
# When dealing with individual images using image statistics for scaling
# factors this routine determines the image statistics rather than being
# done earlier since the input images have all been mapped at this stage.

procedure ic_scale (in, out, offsets, scales, zeros, wts, nimages)

pointer	in[nimages]		# Input images
pointer	out[ARB]		# Output images
long	offsets[nimages,ARB]	# Image offsets
real	scales[nimages]		# Scale factors
real	zeros[nimages]		# Zero or sky levels
real	wts[nimages]		# Weights
int	nimages			# Number of images

size_t	sz_val
int	stype, ztype, wtype
int	i, j, nout
long	k, l
real	mode, median, mean, sumwts
pointer	sp, ncombine, exptime, modes, medians, means
pointer	section, str, sname, zname, wname, im, imref
bool	domode, domedian, domean, dozero, dos, doz, dow, snorm, znorm, wflag

int	imgeti(), strdic(), ic_gscale()
real	imgetr(), asumr(), asumi(), aabs()
pointer	xt_opix()
errchk	ic_gscale, xt_opix, ic_statr

include	"icombine.com"

begin
	call smark (sp)
	sz_val = nimages
	call salloc (ncombine, sz_val, TY_INT)
	call salloc (exptime, sz_val, TY_REAL)
	call salloc (modes, sz_val, TY_REAL)
	call salloc (medians, sz_val, TY_REAL)
	call salloc (means, sz_val, TY_REAL)
	sz_val = SZ_LINE
	call salloc (section, sz_val, TY_CHAR)
	call salloc (str, sz_val, TY_CHAR)
	sz_val = SZ_FNAME
	call salloc (sname, sz_val, TY_CHAR)
	call salloc (zname, sz_val, TY_CHAR)
	call salloc (wname, sz_val, TY_CHAR)

	# Get the number of images previously combined and the exposure times.
	# The default combine number is 1 and the default exposure is 0.

	do i = 1, nimages {
	    iferr (Memi[ncombine+i-1] = imgeti (in[i], "ncombine"))
		Memi[ncombine+i-1] = 1
	    if (Memc[expkeyword] != EOS) {
	        iferr (Memr[exptime+i-1] = imgetr (in[i], Memc[expkeyword]))
		    Memr[exptime+i-1] = 0.
	    } else
		Memr[exptime+i-1] = 0.
	    if (project) {
		sz_val = nimages
		call amovki (Memi[ncombine], Memi[ncombine], sz_val)
		call amovkr (Memr[exptime], Memr[exptime], sz_val)
		break
	    }
	}

	# Set scaling type and factors.
	stype = ic_gscale ("scale", Memc[sname], STYPES, in, Memr[exptime],
	    scales, nimages)
	ztype = ic_gscale ("zero", Memc[zname], ZTYPES, in, Memr[exptime],
	    zeros, nimages)
	wtype = ic_gscale ("weight", Memc[wname], WTYPES, in, Memr[exptime],
	    wts, nimages)

	# Get image statistics if needed.
	dos = ((stype==S_MODE)||(stype==S_MEDIAN)||(stype==S_MEAN))
	doz = ((ztype==S_MODE)||(ztype==S_MEDIAN)||(ztype==S_MEAN))
	dow = ((wtype==S_MODE)||(wtype==S_MEDIAN)||(wtype==S_MEAN))
	if (dos) {
	    dos = false
	    do i = 1, nimages
		if (IS_INDEFR(scales[i])) {
		    dos = true
		    break
		}
	}
	if (doz) {
	    doz = false
	    do i = 1, nimages
		if (IS_INDEFR(zeros[i])) {
		    doz = true
		    break
		}
	}
	if (dow) {
	    dow = false
	    do i = 1, nimages
		if (IS_INDEFR(wts[i])) {
		    dow = true
		    break
		}
	}

	if (dos || doz || dow) {
	    domode = ((stype==S_MODE)||(ztype==S_MODE)||(wtype==S_MODE))
	    domedian = ((stype==S_MEDIAN)||(ztype==S_MEDIAN)||(wtype==S_MEDIAN))
	    domean = ((stype==S_MEAN)||(ztype==S_MEAN)||(wtype==S_MEAN))

	    Memc[section] = EOS
	    Memc[str] = EOS
	    call sscan (Memc[statsec])
	    call gargwrd (Memc[section], SZ_FNAME)
	    call  gargwrd (Memc[str], SZ_LINE)

	    i = strdic (Memc[section], Memc[section], SZ_FNAME, S_SECTION)
	    switch (i) {
	    case S_INPUT:
		call strcpy (Memc[str], Memc[section], SZ_FNAME)
		imref = NULL
	    case S_OUTPUT:
		call strcpy (Memc[str], Memc[section], SZ_FNAME)
		imref = out[1]
	    case S_OVERLAP:
		call strcpy ("[", Memc[section], SZ_FNAME)
		do i = 1, IM_NDIM(out[1]) {
		    k = offsets[1,i] + 1
		    l = offsets[1,i] + IM_LEN(in[1],i)
		    do j = 2, nimages {
			k = max (k, offsets[j,i]+1)
			l = min (l, offsets[j,i]+IM_LEN(in[j],i))
		    }
		    if (i < IM_NDIM(out[1]))
			call sprintf (Memc[str], SZ_LINE, "%d:%d,")
		    else
			call sprintf (Memc[str], SZ_LINE, "%d:%d]")
			    call pargl (k)
			    call pargl (l)
		    call strcat (Memc[str], Memc[section], SZ_FNAME)
		}
		imref = out[1]
	    default:
		imref = NULL
	    }

	    do i = 1, nimages {
		im = xt_opix (in[i], i, 0)
		if (imref != out[1])
		    imref = im
		if ((dos && IS_INDEFR(scales[i])) ||
		    (doz && IS_INDEFR(zeros[i])) ||
		    (dow && IS_INDEFR(wts[i]))) {
		    call ic_statr (im, imref, Memc[section], offsets, i,
			nimages, domode, domedian, domean, mode, median, mean)
		    if (domode) {
			if (stype == S_MODE && IS_INDEFR(scales[i]))
			    scales[i] = mode
			if (ztype == S_MODE && IS_INDEFR(zeros[i]))
			    zeros[i] = mode
			if (wtype == S_MODE && IS_INDEFR(wts[i]))
			    wts[i] = mode
		    }
		    if (domedian) {
			if (stype == S_MEDIAN && IS_INDEFR(scales[i]))
			    scales[i] = median
			if (ztype == S_MEDIAN && IS_INDEFR(zeros[i]))
			    zeros[i] = median
			if (wtype == S_MEDIAN && IS_INDEFR(wts[i]))
			    wts[i] = median
		    }
		    if (domean) {
			if (stype == S_MEAN && IS_INDEFR(scales[i]))
			    scales[i] = mean
			if (ztype == S_MEAN && IS_INDEFR(zeros[i]))
			    zeros[i] = mean
			if (wtype == S_MEAN && IS_INDEFR(wts[i]))
			    wts[i] = mean
		    }
		}
	    }
	}

	# Save the image statistics if computed.
	sz_val = nimages
	call amovkr (INDEFR, Memr[modes], sz_val)
	call amovkr (INDEFR, Memr[medians], sz_val)
	call amovkr (INDEFR, Memr[means], sz_val)
	if (stype == S_MODE)
	    call amovr (scales, Memr[modes], sz_val)
	if (stype == S_MEDIAN)
	    call amovr (scales, Memr[medians], sz_val)
	if (stype == S_MEAN)
	    call amovr (scales, Memr[means], sz_val)
	if (ztype == S_MODE)
	    call amovr (zeros, Memr[modes], sz_val)
	if (ztype == S_MEDIAN)
	    call amovr (zeros, Memr[medians], sz_val)
	if (ztype == S_MEAN)
	    call amovr (zeros, Memr[means], sz_val)
	if (wtype == S_MODE)
	    call amovr (wts, Memr[modes], sz_val)
	if (wtype == S_MEDIAN)
	    call amovr (wts, Memr[medians], sz_val)
	if (wtype == S_MEAN)
	    call amovr (wts, Memr[means], sz_val)

	# If nothing else has set the scaling factors set them to defaults.
	do i = 1, nimages {
	    if (IS_INDEFR(scales[i]))
		scales[i] = 1.
	    if (IS_INDEFR(zeros[i]))
		zeros[i] = 0.
	    if (IS_INDEFR(wts[i]))
		wts[i] = 1.
	}

	do i = 1, nimages
	    if (scales[i] <= 0.) {
		call eprintf ("WARNING: Negative scale factors")
		call eprintf (" -- ignoring scaling\n")
		sz_val = nimages
		call amovkr (1., scales, sz_val)
		break
	    }

	# Convert to factors relative to the first image.
	snorm = (stype == S_FILE || stype == S_KEYWORD)
	znorm = (ztype == S_FILE || ztype == S_KEYWORD)
	wflag = (wtype == S_FILE || wtype == S_KEYWORD)
	if (snorm) {
	    sz_val = nimages
	    call arcpr (1., scales, scales, sz_val)
	}
	mean = scales[1]
	sz_val = nimages
	call adivkr (scales, mean, scales, sz_val)
	call adivr (zeros, scales, zeros, sz_val)

	if (wtype != S_NONE) {
	    do i = 1, nimages {
		if (wts[i] < 0.) {
		    call eprintf ("WARNING: Negative weights")
		    call eprintf (" -- using only NCOMBINE weights\n")
		    do j = 1, nimages
			wts[j] = Memi[ncombine+j-1]
		    break
		}
		if (ztype == S_NONE || znorm || wflag)
	            wts[i] = Memi[ncombine+i-1] * wts[i]
		else {
		    if (zeros[i] <= 0.) {
			call eprintf ("WARNING: Negative zero offsets")
			call eprintf (" -- ignoring zero weight adjustments\n")
			do j = 1, nimages
			    wts[j] = Memi[ncombine+j-1] * wts[j]
			break
		    }
		    wts[i] = Memi[ncombine+i-1] * wts[i] * zeros[1] / zeros[i]
		}
	    }
	}

	if (znorm) {
	    sz_val = nimages
	    call anegr (zeros, zeros, sz_val)
	} else {
	    # Because of finite arithmetic it is possible for the zero offsets
	    # to be nonzero even when they are all equal.  Just for the sake of
	    # a nice log set the zero offsets in this case.

	    mean = zeros[1]
	    sz_val = nimages
	    call asubkr (zeros, mean, zeros, sz_val)
	    for (i=2; (i<=nimages)&&(zeros[i]==zeros[1]); i=i+1)
		;
	    if (i > nimages) {
		sz_val = nimages
		call aclrr (zeros, sz_val)
	    }
	}
	sz_val = nimages
	mean = asumr (wts, sz_val)
	if (mean > 0.) {
	    sz_val = nimages
	    call adivkr (wts, mean, wts, sz_val)
	} else {
	    call eprintf ("WARNING: Mean weight is zero -- using no weights\n")
	    sz_val = nimages
	    call amovkr (1., wts, sz_val)
	    mean = 1.
	}

	# Set flags for scaling, zero offsets, sigma scaling, weights.
	# Sigma scaling may be suppressed if the scales or zeros are
	# different by a specified tolerance.

	doscale = false
	dozero = false
	doscale1 = false
	dowts = false
	do i = 2, nimages {
	    if (snorm || scales[i] != scales[1])
		doscale = true
	    if (znorm || zeros[i] != zeros[1])
		dozero = true
	    if (wts[i] != wts[1])
		dowts = true
	}
	if (doscale && sigscale != 0.) {
	    do i = 1, nimages {
		if (aabs(scales[i] - 1) > sigscale) {
		    doscale1 = true
		    break
		}
	    }
	}
		    
	# Set the output header parameters.
	sz_val = nimages
	nout = asumi (Memi[ncombine], sz_val)
	call imaddi (out[1], "ncombine", nout)
	mean = 0.
	sumwts = 0.
	do i = 1, nimages {
	    ifnoerr (mode = imgetr (in[i], "ccdmean")) {
		mean = mean + wts[i] * mode / scales[i]
		sumwts = sumwts + wts[i]
	    }
	}
	if (sumwts > 0.) {
	    mean = mean / sumwts
	    ifnoerr (mode = imgetr (out[1], "ccdmean")) {
		call imaddr (out[1], "ccdmean", mean)
		iferr (call imdelf (out[1], "ccdmeant"))
		    ;
	    }
	}
	if (out[2] != NULL) {
	    call imstats (out[2], IM_IMAGENAME, Memc[str], SZ_FNAME)
	    call imastr (out[1], "BPM", Memc[str])
	}

	# Start the log here since much of the info is only available here.
	if (verbose) {
	    i = logfd
	    logfd = STDOUT
	    call ic_log (in, out, Memi[ncombine], Memr[exptime], Memc[sname],
		Memc[zname], Memc[wname], Memr[modes], Memr[medians],
		Memr[means], scales, zeros, wts, offsets, nimages, dozero,
		nout)

	    logfd = i
	}
	call ic_log (in, out, Memi[ncombine], Memr[exptime], Memc[sname],
	    Memc[zname], Memc[wname], Memr[modes], Memr[medians], Memr[means],
	    scales, zeros, wts, offsets, nimages, dozero, nout)

	doscale = (doscale || dozero)

	call sfree (sp)
end
