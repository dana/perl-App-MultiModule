package MultiModuleTest::YetAnotherExternalModule;

use strict;use warnings;
use Data::Dumper;

use parent 'App::MultiModule::Task';


=head2 is_stateful

=cut
sub is_stateful {
    return 'yes!';
}

=head2 message

=cut
sub message {
    my $self = shift;
    my $message = shift;
    my $incr = $self->{config}->{increment_by};
    my $ct = $message->{ct};
    $message->{my_ct} = $ct + $incr;
    $message->{module_pid} = $$;
    $self->debug('YetAnotherExternalModule message: ' . Data::Dumper::Dumper $message) if $self->{debug};
    $self->{state}->{most_recent} = $message->{my_ct};
    $self->emit($message);
}

1;
