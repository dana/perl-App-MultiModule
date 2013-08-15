# NAME

App::MultiModule - Framework to intelligently manage many parallel tasks

# WARNING

This is a very early release.  That means it has a whole pile of
technical debt.  One clear example is that, at this point, this
distribution doesn't even try to function on any OS except Linux.

# SYNOPSIS

Look at the documentation for the MultiModule program proper; it will be
rare to use this module directly.

# EXPORT

none

# SUBROUTINES/METHODS

## new

Constructor

- state\_dir
- qname (required)

    IPC::Transit queue name that controls this module

- module\_prefixes
- module
- debug
- oob

## get\_task
=cut
sub get\_task {
    my $self = shift; my $task\_name = shift;
    my %args = @\_;
    $self->debug("in get\_task($task\_name)") if $self->{debug} > 5;
    $self->debug("get\_task($task\_name)", tasks => $self->{tasks})
        if $self->{debug} > 5;
    return $self->{tasks}->{$task\_name} if $self->{tasks}->{$task\_name};
    $self->debug("get\_task:($task\_name)",
            module\_prefixes => $self->{module\_prefixes})
        if $self->{debug} > 5;

    #first let's find out if this thing is running externally
    my $task_status = $self->{api}->get_task_status($task_name);
#    $self->debug('get_task: ', task_state => $task_state, task_status => $task_status) if $self->{debug} > 5;
    $self->debug('get_task: ', task_status => $task_status) if $self->{debug} > 5;
    if(     $task_status and
            $task_status->{is_running} and
            not $task_status->{is_my_pid}) {
        #this thing is running and it is NOT our PID.  That means it's
        #running externally, so we just leave it alone
        $self->error("($task_name): get_task: already running externally");
        return undef;
        #we do not consider what SHOULD be here; that's left to another function
    }

    #at this point, we need to consider loading a task, either internal or
    #external so we need to concern ourselves with what should be
    my $module_info = $self->{all_modules_info}->{$task_name};
    my $module_config = $module_info->{config} || {};
    my $wants_external = $module_config->{is_external};
    my $task_is_stateful = $module_info->{is_stateful};

    #find some reasons we should not load this module
    #all program instances may load any non-stateful module.
    #The main program instance may load any module (if it's not already loaded)
    #the only stateful module external program instances may load is themselves
    if($self->{module} ne 'main') {
        #I am some external program instance
        if($task_name ne $self->{module}) {
            #I am trying to load a module besides myself
            if($task_is_stateful) {
                #and the task is stateful; not allowed
                $self->error("get_task: external($self->{module}) tried to load stateful task $task_name");
                return undef;
            }
        }
    }

    if($wants_external and not $task_is_stateful) {
        #this is currently not allowed, since non-stateful tasks don't have
        #any way of communicating their PID back
        $self->error("task_name $task_name marked as external but is not stateful; this is not allowed");
        return undef;
    }



    if($wants_external and $self->{module} eq 'main') {
        #in this brave new world, we double fork then exec with the proper
        #arguments to run an external
        #fork..exec...
        $self->bucket({
            task_name => $task_name,
            check_type => 'admin',
            cutoff_age => 300,
            min_points => 3,
            min_bucket_span => 0.5,
            bucket_name => "$task_name:local.admin.start.external",
            bucket_metric => 'local.admin.start.external',
            bucket_type => 'sum',
            value => 1,
        });
        my $pid = fork(); #first fork
        die "first fork failed: $!" if not defined $pid;
        if(not $pid) { #first child
            my $pid = fork(); #second (final) fork
            die "second fork failed: $!" if not defined $pid;
            if($pid) { #middle parent; just exit
                exit;
            }
            #technically, 'grand-child' of the program, but it is init parented
            my $pristine_opts = $self->{pristine_opts};
            my $main_prog = $0;
            my @args = split ' ', $pristine_opts;
            push @args, '-m';
            push @args, $task_name;
            $self->debug("preparing to exec: $main_prog " . (join ' ', @args))
                if $self->{debug} > 1;
            exec $main_prog, @args;
            die "exec failed: $!";
        }
        return undef;
    }

    #at this point, we are loading a module into our process space.
    #we could be in module 'main' and loading our 5th stateful task,
    #or we could be an external loading our single allowed stateful task
    #I want to claim that there is no difference at this point
    #I believe the only conditional should be on $task_is_stateful

    my $module;
    foreach my $module_prefix (@{$self->{module_prefixes}}) {
        my $class_name = $module_prefix . $task_name;
        $self->debug("get_task $task_name - $class_name\n") if $self->{debug} > 5;
        my $eval = "require $class_name;";
        $self->debug("get_task:($task_name): \$eval=$eval")
            if $self->{debug} > 5;
        eval $eval;
        my $err = $@;
        $self->debug("get_task:($task_name): \$err = $err")
            if $err and $self->{debug} > 4;
        if($err) {
            if($err !~ /Can't locate /) {
                $self->error("get_task:($task_name) threw trying to load module: $@");
                my $type = 'internal';
                $type = 'external' if $wants_external;
                print STDERR "bucket: $task_name:local.admin.task_compile_failure.$type\n";
                $self->bucket({
                    task_name => $task_name,
                    check_type => 'admin',
                    cutoff_age => 300,
                    min_points => 1,
                    min_bucket_span => 0.01,
                    bucket_name => "$task_name:local.admin.task_compile_failure.$type",
                    bucket_metric => "local.admin.task_compile_failure.$type",
                    bucket_type => 'sum',
                    value => 1,
                });
            }
            next;
        }
        for ('message') {
            my $function_path = $class_name . '::' . $_;
            if(not $function_exists->($function_path)) {
                die "required function $function_path not found in loaded task";
            }
        }
        #make the module right here
        my $task_state = $self->{api}->get_task_state($task_name);
        $module = {
            config => undef,
            'state' => $task_state,
            status => undef,
            config_is_set => undef,
            debug => $self->{debug},
            root_object => $self,
            task_name => $task_name,
        };
        bless ($module, $class_name);
        $self->debug("get_task:($task_name): made module", module => $module)
            if $self->{debug} > 5;
        last;
    }
    if(not $module) {
        $self->error("get_task:($task_name) failed to load module");
        return undef;
    }
    $self->debug("get_task:($task_name): loaded module", module => $module)
        if $self->{debug} > 5;

    $self->{tasks}->{$task_name} = $module;

    #stateful or not gets the get_task_config() recur
    $self->recur(
        repeat_interval => 1,
        tags => ['get_task_config'],
        work => sub {
            $module->{config_is_set} = 1;
            my $config = $self->{api}->get_task_config($task_name);
            if($config) {
                local $Storable::canonical = 1;
                my $config = Storable::dclone($config);
                my $config_hash = Digest::MD5::md5_base64(Storable::freeze($config));
                $module->{config_hash} = 'none' unless $module->{config_hash};
                if($module->{config_hash} ne $config_hash) {
                    $module->{config_hash} = $config_hash;
                    $module->set_config($config);
                }
            }
        }
    );

    if($task_is_stateful) {
        delete $self->{hold_events_for}->{$task_name};
        $self->recur(
            repeat_interval => 1,
            tags => ['save_task_state'],
            override_repeat_interval => sub {
#                print STDERR "$task_name: " . Data::Dumper::Dumper $self->{all_modules_info}->{$task_name}->{config}->{intervals};
                if(     $self->{all_modules_info} and
                        $self->{all_modules_info}->{$task_name} and
                        $self->{all_modules_info}->{$task_name}->{config} and
                        $self->{all_modules_info}->{$task_name}->{config}->{intervals} and
                        $self->{all_modules_info}->{$task_name}->{config}->{intervals}->{save_state}) {
#                    print STDERR 'override_repeat_interval returned ' . $self->{all_modules_info}->{$task_name}->{config}->{intervals}->{save_state} . "\n";
                    return $self->{all_modules_info}->{$task_name}->{config}->{intervals}->{save_state};
                } else {
#                    print STDERR "override_repeat_interval returned undef\n";
                    return undef;
                }
            },
            work => sub {
                #see comments in the App::MultiModule constructor
                return if $self->{hold_events_for}->{$task_name};
                $self->debug("saving state and status for $task_name") if $self->{debug} > 2;
                eval {
                    $self->{api}->save_task_status($task_name, $module->{'status'});
                };
                eval {
                    $self->{api}->save_task_state($task_name, $module->{'state'});
                };
            }
        );
    }
}
}
=head1 AUTHOR

Dana M. Diederich, `diederich@gmail.com`

# BUGS

Please report any bugs or feature requests at
    https://github.com/dana/perl-App-MultiModule/issues



# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::MultiModule



You can also look for information at:

- Github bug tracker:

    [https://github.com/dana/perl-App-MultiModule/issues](https://github.com/dana/perl-App-MultiModule/issues)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/App-MultiModule](http://annocpan.org/dist/App-MultiModule)

- CPAN Ratings

    [http://cpanratings.perl.org/d/App-MultiModule](http://cpanratings.perl.org/d/App-MultiModule)

- Search CPAN

    [http://search.cpan.org/dist/App-MultiModule/](http://search.cpan.org/dist/App-MultiModule/)



# ACKNOWLEDGEMENTS



# LICENSE AND COPYRIGHT

Copyright 2013 Dana M. Diederich.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

[http://www.perlfoundation.org/artistic\_license\_2\_0](http://www.perlfoundation.org/artistic\_license\_2\_0)

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


