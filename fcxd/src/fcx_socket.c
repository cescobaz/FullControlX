#include "fcx_socket.h"
#include <arpa/inet.h>
#include <errno.h>
#include <fcntl.h>
#include <netdb.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <unistd.h>

int fcx_socket_create() {
  struct addrinfo hints = {0};
  struct addrinfo *result, *rp;
  int sfd, s;

  hints.ai_family = AF_INET;
  hints.ai_socktype = SOCK_STREAM;
  hints.ai_flags = AI_PASSIVE | AI_NUMERICHOST;
  hints.ai_protocol = IPPROTO_TCP;

  s = getaddrinfo(NULL, "9091", &hints, &result);
  if (s != 0) {
    fprintf(stderr, "getaddrinfo: %s\n", gai_strerror(s));
    exit(EXIT_FAILURE);
  }

  for (rp = result; rp != NULL; rp = rp->ai_next) {
    struct in_addr *addr = &((struct sockaddr_in *)rp->ai_addr)->sin_addr;
    char *addr_s = inet_ntoa(*addr);
    printf("ADDRESS: %s %d %d %d\n", addr_s, rp->ai_family, rp->ai_socktype,
           rp->ai_protocol);

    sfd = socket(rp->ai_family, rp->ai_socktype, rp->ai_protocol);
    if (sfd == -1) {
      continue;
    }

    if (bind(sfd, rp->ai_addr, rp->ai_addrlen) == 0) {
      printf("BIND\n");
      break; /* Success */
    }

    close(sfd);
  }

  if (rp == NULL) { /* No address succeeded */
    fprintf(stderr, "Could not bind\n");
    exit(EXIT_FAILURE);
  }

  freeaddrinfo(result); /* No longer needed */

  if (listen(sfd, 10) != 0) {
    fprintf(stderr, "Could not listen\n");
    exit(EXIT_FAILURE);
  }

  while (1) {
    fd_set readfds = {0xFFFF};
    FD_SET(sfd, &readfds);
    FD_SET(0, &readfds);
    fd_set writefds = {0};
    FD_SET(sfd, &writefds);
    fd_set errorfds = {0};
    FD_SET(sfd, &errorfds);
    printf("select %d %d\n", sfd, FD_ISSET(sfd, &readfds));
    int res = select(sfd + 1, &readfds, &writefds, &errorfds, 0);
    if (res == 0) {
      printf("select timeout %d\n", res);
      continue;
    } else if (res == -1) {
      printf("select error %d\n", errno);
      return errno;
    } else {
      printf("something change 0x%x\n", res);
      if (FD_ISSET(sfd, &readfds)) {
        int client = accept(sfd, NULL, 0);
        char salut[] = "ciao";
        write(client, salut, sizeof(salut));
        printf("Client accepted %d\n", client);
      }
    }
  }

  return 0;
}
