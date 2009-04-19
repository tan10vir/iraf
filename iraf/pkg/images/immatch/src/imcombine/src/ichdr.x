include	<imset.h>


# IC_HDR -- Set output header.

procedure ic_hdr (in, out, nimages)

pointer	in[nimages]		#I Input images
pointer	out[ARB]		#I Output images
int	nimages			#I Number of images

size_t	sz_val
int	i, j
int	imgnfn(), fnroot(), nowhite()
pointer	sp, inkey, key, str, list
pointer	imofnlu()
bool	streq()

begin
	call smark (sp)
	sz_val = SZ_FNAME
	call salloc (inkey, sz_val, TY_CHAR)
	call salloc (key, sz_val, TY_CHAR)
	call salloc (str, sz_val, TY_CHAR)

	call clgstr ("imcmb", Memc[inkey], SZ_FNAME)
	i = nowhite (Memc[inkey], Memc[inkey], SZ_FNAME)

	if (i > 0 && streq (Memc[inkey], "$I")) {
	    # Set new PROCID.
	    call xt_procid (out)

	    # Set input PROCIDs.
	    if (nimages < 100) {
		list = imofnlu (out, "PROCID[0-9][0-9]")
		while (imgnfn (list, Memc[key], SZ_LINE) != EOF)
		    call imdelf (out, Memc[key])
		call imcfnl (list)
		do i = 1, nimages {
		    call sprintf (Memc[key], 8, "PROCID%02d")
			call pargi (i)
		    iferr (call imgstr (in[i], "PROCID", Memc[str], SZ_LINE)) {
			iferr (call imgstr (in[i], "OBSID", Memc[str], SZ_LINE))
			    Memc[str] = EOS
		    }
		    if (Memc[str] != EOS)
			call imastr (out, Memc[key], Memc[str])
		}
	    }
	}

	if (i > 0 && nimages < 1000) {
	    list = imofnlu (out, "IMCMB[0-9][0-9][0-9]")
	    while (imgnfn (list, Memc[key], SZ_LINE) != EOF)
		call imdelf (out, Memc[key])
	    call imcfnl (list)
	    do i = 1, nimages {
	        if (streq (Memc[inkey], "$I")) {
		    call imstats (in[i], IM_IMAGENAME, Memc[str], SZ_LINE)
		    j = fnroot (Memc[str], Memc[str], SZ_LINE)
		} else {
		    iferr (call imgstr (in[i], Memc[inkey], Memc[str], SZ_LINE))
		        Memc[str] = EOS
		}
		if (Memc[str] == EOS)
		    next
		call sprintf (Memc[key], SZ_LINE, "IMCMB%03d")
		    call pargi (i)
		call imastr (out, Memc[key], Memc[str])
	    }
	}

	call sfree (sp)
end
