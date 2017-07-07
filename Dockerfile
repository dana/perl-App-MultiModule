FROM centos:7

RUN yum install -y epel-release
RUN yum -y update
RUN yum install -y gcc wget make zlib-devel nacl-devel libsodium libsodium-devel
RUN yum install -y which strace git openssl openssl-devel net-tools

# Perl
RUN wget https://www.cpan.org/src/5.0/perl-5.26.0.tar.gz
RUN tar zxf perl-5.26.0.tar.gz
RUN (cd perl-5.26.0 && ./Configure -d -e && make && make install)

# cpanm, the Perl package manager
RUN curl -L https://cpanmin.us | perl - App::cpanminus

# The final app
RUN cpanm App::MultiModule

# cleanup
RUN (cd /;rm -rf perl-5.26.0* /root/.cpanm/)
