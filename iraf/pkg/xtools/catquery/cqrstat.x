include "cqdef.h"
include "cq.h"


# CQ_RSTATI -- Get an integer results parameter.

int procedure cq_rstati (res, param)

pointer res                     #I pointer to the results descriptor
int     param                   #I the integer parameter to be retrieved

long	cq_rstatl()

begin
	return (cq_rstatl(res,param))
end


# CQ_RSTATL -- Get a long integer results parameter.

long procedure cq_rstatl (res, param)

pointer res                     #I pointer to the results descriptor
int     param                   #I the integer parameter to be retrieved

begin
        switch (param) {
        case CQRNQPARS:
            return (CQ_RNQPARS(res))
	case CQRTYPE:
            return (CQ_RTYPE(res))
        case CQRNRECS:
            return (CQ_RNRECS(res))
        case CQRECSIZE:
            return (CQ_RECSIZE(res))
        case CQRHSKIP:
            return (CQ_RHSKIP(res))
        case CQRTSKIP:
            return (CQ_RTSKIP(res))
        case CQRTRIML:
            return (CQ_RTRIML(res))
        case CQRTRIMR:
            return (CQ_RTRIMR(res))
	case CQNHEADER:
            return (CQ_NHEADER(res))
	case CQNFIELDS:
            return (CQ_NFIELDS(res))
	case CQRECPTR:
            return (CQ_RECPTR(res))
        default:
            call error (0, "Error fetching integer results parameter")
        }
end


# CQ_RSTATR -- Get a real results parameter.

real procedure cq_rstatr (res, param)

pointer res                     #I pointer to the results descriptor
int     param                   #I the real parameter to be retrieved

begin
        switch (param) {
        default:
            call error (0, "Error fetching real results parameter")
        }
end


# CQ_RSTATD -- Get a double precision results parameter.

double procedure cq_rstatd (res, param)

pointer res                     #I pointer to the results descriptor
int     param                   #I the double parameter to be retrieved

begin
        switch (param) {
        default:
            call error (0, "Error fetching double results parameter")
        }
end


# CQ_RSTATS -- Get a string results parameter.

procedure cq_rstats (res, param, str, maxch)

pointer res                     #I pointer to the results descriptor
int     param                   #I the string parameter to be retrieved
char    str[ARB]                #O the output string parameter
int     maxch                   #I the maximum size of the string parameter

begin
        switch (param) {
        case CQRCATDB:
            call strcpy (CQ_RCATDB(res), str, maxch)
        case CQRCATNAME:
            call strcpy (CQ_RCATNAME(res), str, maxch)
        case CQRADDRESS:
            call strcpy (CQ_RADDRESS(res), str, maxch)
        case CQRQUERY:
            call strcpy (CQ_RQUERY(res), str, maxch)
        case CQRQPNAMES:
            call strcpy (Memc[CQ_RQPNAMES(res)], str, maxch)
        case CQRQPVALUES:
            call strcpy (Memc[CQ_RQPVALUES(res)], str, maxch)
        case CQRQPUNITS:
            call strcpy (Memc[CQ_RQPUNITS(res)], str, maxch)
        default:
            call error (0, "Error fetching string results parameter")
        }
end


# CQ_RSTATT -- Get a text list results parameter. A text list is a
# string with items separated from each other by newlines.

int procedure cq_rstatt (res, param, str, maxch)

pointer res                     #I pointer to the results descriptor
int     param                   #I the list parameter to be retrieved
char    str[ARB]                #O the output string parameter
int     maxch                   #I the maximum size of the string parameter

size_t	sz_val
pointer	sp, tstr
int     i, fd
int     stropen(), cq_wrdstr()

begin
        switch (param) {

        case CQRQPNAMES:
	    call smark (sp)
	    sz_val = CQ_SZ_QPNAME
	    call salloc (tstr, sz_val, TY_CHAR)
            fd = stropen (str, maxch, NEW_FILE)
	    str[1] = EOS
            do i = 1, CQ_RNQPARS(res) {
		if (cq_wrdstr (i, Memc[tstr], CQ_SZ_QPNAME,
		    Memc[CQ_RQPNAMES(res)]) > 0) {
                    call fprintf (fd, "%s\n")
                        call pargstr (Memc[tstr])
		}
            }
            call close (fd)
	    call sfree (sp)
            return (CQ_RNQPARS(res))

        case CQRQPVALUES:
	    call smark (sp)
	    sz_val = CQ_SZ_QPVALUE
	    call salloc (tstr, sz_val, TY_CHAR)
            fd = stropen (str, maxch, NEW_FILE)
	    str[1] = EOS
            do i = 1, CQ_RNQPARS(res) {
		if (cq_wrdstr (i, Memc[tstr], CQ_SZ_QPVALUE,
		    Memc[CQ_RQPVALUES(res)]) > 0) {
                    call fprintf (fd, "%s\n")
                        call pargstr (Memc[tstr])
		}
            }
            call close (fd)
	    call sfree (sp)
            return (CQ_RNQPARS(res))

        case CQRQPUNITS:
	    call smark (sp)
	    sz_val = CQ_SZ_QPUNITS
	    call salloc (tstr, sz_val, TY_CHAR)
            fd = stropen (str, maxch, NEW_FILE)
	    str[1] = EOS
            do i = 1, CQ_RNQPARS(res) {
		if (cq_wrdstr (i, Memc[tstr], CQ_SZ_QPUNITS,
		    Memc[CQ_RQPUNITS(res)]) > 0) {
                    call fprintf (fd, "%s\n")
                        call pargstr (Memc[tstr])
		}
            }
            call close (fd)
	    call sfree (sp)
            return (CQ_RNQPARS(res))

        default:
            call error (0, "Error fetching list results parameter")
        }
end
