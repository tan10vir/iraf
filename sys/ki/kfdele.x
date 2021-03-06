# Copyright(c) 1986 Association of Universities for Research in Astronomy Inc.

include	<mach.h>
include	"ki.h"

# KFDELE -- Delete a file.

procedure kfdele (osfn, status)

char	osfn[ARB]		# packed os filename
int	status			# answer; ok or err

int	server
int	ki_connect(), ki_sendrcv()
include	"kii.com"

begin
	server = ki_connect (osfn)

	if (server == NULL) {
	    call strpak (p_sbuf[p_arg[1]], p_sbuf, SZ_SBUF)
	    call zfdele (p_sbuf, status)

	} else {
	    if (ki_sendrcv (server, KI_ZFDELE, 0) == ERR)
		status = ERR
	    else
		status = p_arg[1]
	}
end
