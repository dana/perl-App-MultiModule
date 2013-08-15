package MultiModuleTest::Example2;

use strict;use warnings;

use parent 'App::MultiModule::Task';

sub message {
    my $self = shift;
    my $message = shift;
    print STDERR "Example2: received a message: $message->{ct} ($message->{outstr})\n"
        if $message->{ct} and $message->{outstr};
}

=head1 some pod
=cut

1;
