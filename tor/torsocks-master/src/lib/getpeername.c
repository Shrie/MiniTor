/*
 * Copyright (C) 2013 - David Goulet <dgoulet@ev0ke.net>
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License, version 2 only, as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program; if not, write to the Free Software Foundation, Inc., 51
 * Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

#include <arpa/inet.h>
#include <assert.h>

#include <common/log.h>

#include "torsocks.h"

/* getpeername(2) */
TSOCKS_LIBC_DECL(getpeername, LIBC_GETPEERNAME_RET_TYPE,
		LIBC_GETPEERNAME_SIG)

/*
 * Torsocks call for getpeername(2).
 */
LIBC_GETPEERNAME_RET_TYPE tsocks_getpeername(LIBC_GETPEERNAME_SIG)
{
	int ret = 0;
	struct connection *conn;

	DBG("[getpeername] Requesting address on socket %d", sockfd);

	connection_registry_lock();
	conn = connection_find(sockfd);
	if (!conn) {
		connection_registry_unlock();
		goto libc;
	}

	if (!addrlen || !addr) {
		/* Bad address. */
		errno = EFAULT;
		ret = -1;
		goto end;
	}

	/*
	 * Extra check for addrlen since we are about to copy the connection
	 * content into the given address.
	 */
	if (*addrlen > sizeof(struct sockaddr)) {
		/* Ref to the manpage for the returned value here. */
		errno = EINVAL;
		ret = -1;
		goto end;
	}

	/*
	 * Copy connected destination address into the given addr with only the
	 * given len so we don't overflow on purpose.
	 */
	switch (conn->dest_addr.domain) {
	case CONNECTION_DOMAIN_NAME:
		/*
		 * This domain is only used with onion address which contains a
		 * cookie address of domain INET. Use that since that's the address
		 * that has been returned to the application.
		 */
	case CONNECTION_DOMAIN_INET:
		memcpy(addr, (const struct sockaddr *) &conn->dest_addr.u.sin,
				*addrlen);
		break;
	case CONNECTION_DOMAIN_INET6:
		memcpy(addr, (const struct sockaddr *) &conn->dest_addr.u.sin6,
				*addrlen);
		break;
	}

	/* Success. */
	errno = 0;
	ret = 0;

end:
	connection_registry_unlock();
	return ret;

libc:
	/*
	 * This is clearly not a socket we are handling so it's safe to pass it to
	 * the original libc call.
	 */
	return tsocks_libc_getpeername(LIBC_GETPEERNAME_ARGS);
}

/*
 * Libc hijacked symbol getpeername(2).
 */
LIBC_GETPEERNAME_DECL
{
	if (!tsocks_libc_getpeername) {
		tsocks_libc_getpeername = tsocks_find_libc_symbol(
				LIBC_GETPEERNAME_NAME_STR, TSOCKS_SYM_EXIT_NOT_FOUND);
	}

	return tsocks_getpeername(LIBC_GETPEERNAME_ARGS);
}
