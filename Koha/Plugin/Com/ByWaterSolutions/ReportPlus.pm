package Koha::Plugin::Com::ByWaterSolutions::ReportPlus;

## It's good practive to use Modern::Perl
use Modern::Perl;

## Required for all plugins
use base qw(Koha::Plugins::Base);

## We will also need to include any Koha libraries we want to access
use C4::Context;
use C4::Members;
use C4::Auth;
use Koha::Libraries;
use Koha::Patron::Categories;
use MARC::Record;

## Here we set our plugin version
our $VERSION = "{VERSION}";

## Here is our metadata, some keys are required, some are optional
our $metadata = {
    name   => 'Report+',
    author => 'Nick Clemens',
    description =>
'This plugin adds some enhancements to the reports from Koha. Notably the ability to enter a list of data as a parameter',
    date_authored   => '2017-01-01',
    date_updated    => '2017-12-18',
    minimum_version => '17.05.00.000',
    maximum_version => undef,
    version         => $VERSION,
};

## This is the minimum code required for a plugin's 'new' method
## More can be added, but none should be removed
sub new {
    my ( $class, $args ) = @_;

    ## We need to add our metadata here so our base class can access it
    $args->{'metadata'} = $metadata;
    $args->{'metadata'}->{'class'} = $class;

    ## Here, we call the 'new' method for our base class
    ## This runs some additional magic and checking
    ## and returns our actual $self
    my $self = $class->SUPER::new($args);

    return $self;
}

## The existance of a 'report' subroutine means the plugin is capable
## of running a report. This example report can output a list of patrons
## either as HTML or as a CSV file. Technically, you could put all your code
## in the report method, but that would be a really poor way to write code
## for all but the simplest reports
sub report {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    unless ( $cgi->param('next') ) {
        $self->report_step1();
    }
    elsif ( $cgi->param('next') == 2 ) {
        $self->report_step2();
    }
    elsif ( $cgi->param('next') == 3 ){
        $self->report_step3();
    }
    else {
        $self->report_step4();
    }
}

## This is the 'install' method. Any database tables or other setup that should
## be done when the plugin if first installed should be executed in this method.
## The installation method should always return true if the installation succeeded
## or false if it failed.
sub install() {
    my ( $self, $args ) = @_;

#    We don't have any extra setup

}

## This method will be run just before the plugin files are deleted
## when a plugin is uninstalled. It is good practice to clean up
## after ourselves!
sub uninstall() {
    my ( $self, $args ) = @_;
#   Nothing to clean up

}

## These are helper functions that are specific to this plugin
## You can manage the control flow of your plugin any
## way you wish, but I find this is a good approach
sub report_step1 {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    my $template = $self->get_template({ file => 'report-step1.tt' });

    print $cgi->header();
    print $template->output();
}

sub report_step2 {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    my $dbh = C4::Context->dbh;

    my $report    = $cgi->param('report_id');
    my $output    = $cgi->param('output') || "";

    my $query = "
        SELECT savedsql FROM saved_sql WHERE id=?
    ";

    my $sth = $dbh->prepare($query);
    $sth->execute($report);

    my $count = 0;
    my @results;
    while ( my $row = $sth->fetchrow_hashref() ) {
#        $row->{params}  = [split /(<<[^>>]+>>)/,$row->{savedsql}];
        my @split_parms  = split /(<<[^>>]+>>)/,$row->{savedsql};
        my @parms = grep { $_ =~ s/(<<)([^>>]+)(>>)/$2/g } @split_parms;
        $row->{params} = \@parms;
        warn Data::Dumper::Dumper( $row);
        push( @results, $row );
        $count++;
    }

    my $template;
    if ( $count ) {

        $template =  $self->get_template({ file => 'report-step2.tt' });
        $template->param(
            results_loop => \@results,
            report_id => $report,
        );
    } else {
        $template = $self->get_template({ file => 'report-step1.tt' });
        $template->param(
            invalid_report => $report,
        );
    }

    print $cgi->header();
    print $template->output();
}

sub report_step3 {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    my $report  = $cgi->param('report_id');

    my $template = $self->get_template({ file => 'report-step3.tt' });
    
    my @params;
    for (my $i=0; $i < $cgi->param('param_count'); $i++ ){
        my $param;
        $param->{type} = $cgi->param('param'.$i);
        $param->{name} = $cgi->param('param'.$i.'name');
        push( @params, $param );
    }


    $template->param(
            param_loop => \@params,
            report_id => $report,
            param_count => $cgi->param('param_count'),
    );
    print $cgi->header();
    print $template->output();
}

sub report_step4 {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    my $report = $cgi->param('report_id');
    my $output = $cgi->param('output');

    my $query = "SELECT savedsql FROM saved_sql WHERE id=?";
    my $dbh = C4::Context->dbh;
    my $sth = $dbh->prepare($query);
    $sth->execute($report);

    $query  = $sth->fetchrow_hashref()->{savedsql};
    my @split_parms = split /(<<[^>>]+>>)/, $query ;
    my @query_params = grep { $_ =~ s/(<<)([^>>]+)(>>)/$2/g } @split_parms;
    
#    my @query_params = ( $query =~ /<<(.*?)>>/ );

    my @params;
    for (my $i=0; $i < $cgi->param('param_count'); $i++ ){
        my $param;
        if ( $cgi->param('param'.$i.".type") eq 'textarea' ) {
            $param = "(";
            my @arr_par = split /\n/, $cgi->param('param'.$i);
            my $param_placeholder = ( '?,' ) x @arr_par;
            $param_placeholder =~ s/,$/)/;
            $param_placeholder = '('.$param_placeholder;
            $query =~ s/<<$query_params[$i]>>/$param_placeholder/;
            foreach  my $par ( @arr_par ) {
                $par =~ s/\r$//;
                push( @params, $par );
            }
        }
        else { $param = $cgi->param('param'.$i);
        $query =~ s/<<$query_params[$i]>>/?/;
        push( @params, $param );
        }
    }

    $sth = $dbh->prepare($query);

    my @results;

    $sth->execute(@params);
    while ( my $row = $sth->fetchrow_hashref() ) {
        push( @results, $row );
    }


    my $filename;
    if ( $output eq "csv" ) {
        print $cgi->header( -attachment => 'borrowers.csv' );
        $filename = 'report-step4-csv.tt';
    }
    else {
        print $cgi->header();
        $filename = 'report-step4-html.tt';
    }

    my $template = $self->get_template({ file => $filename });
    $template->param(
            result_loop => \@results,
    );
    print $template->output();
}

1;
