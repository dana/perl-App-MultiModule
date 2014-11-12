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

# cut
        if($args{module} and $args{module} eq 'main') {
            $self->{my\_counter} = 0 unless $self->{my\_counter};
            $self->{my\_counter}++;
            open my $fh, '>>', '/tmp/my\_logf';
            print $fh $args{module} . ':' . $self->{my\_counter}, "\\n";
            close $fh;
            exit if $self->{my\_counter} > 60;
        }

## get\_task

# AUTHOR

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

[http://www.perlfoundation.org/artistic\_license\_2\_0](http://www.perlfoundation.org/artistic_license_2_0)

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
