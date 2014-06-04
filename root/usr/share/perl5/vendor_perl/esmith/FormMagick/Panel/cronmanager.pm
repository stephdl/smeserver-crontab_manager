#----------------------------------------------------------------------
# $Id: portforwarding.pm,v 1.31 2003/04/08 15:28:55 mvanhees Exp $
# vim: ft=perl ts=4 sw=4 et:
#----------------------------------------------------------------------
# copyright (C) 2004 Pascal Schirrmann
# copyright (C) 2002 Mitel Networks Corporation
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307  USA
#----------------------------------------------------------------------

package esmith::FormMagick::Panel::cronmanager;

use strict;
use esmith::FormMagick;
use esmith::cgi;
use esmith::util;
use esmith::config;
use esmith::db;
use esmith::event;
use esmith::AccountsDB;

use File::Basename;
use Carp;
use Exporter;

use constant TRUE => 1;
use constant FALSE => 0;

our @ISA = qw(esmith::FormMagick Exporter);

our @EXPORT = qw(
     main
     display_button
     display_cron_entry
     change_cron_entry
     delete_cron_entry
     fill_minute
     give_numeric
     give_month
     give_dayweek
     give_bool
     give_all_user
    );

our $VERSION = sprintf '%d.%03d', q$Revision: 0.01 $ =~ /: (\d+).(\d+)/;
# our $db = esmith::ConfigDB->open
#         or die "Can't open the Config database : $!\n" ;
# our $accountsdb = esmith::AccountsDB->open_ro
#        or die "Can't open the Accounts database : $!\n" ;

=head1 NAME

esmith::FormMagick::Panels::cronmanager - useful panel functions

=head1 SYNOPSIS

    use esmith::FormMagick::Panels::cronmanager

    my $panel = esmith::FormMagick::Panel::cronmanager->new();
    $panel->display();

=head1 DESCRIPTION

This module is the backend to the cronmanager panel, responsible for
supplying all functions used by that panel. It is a subclass of
esmith::FormMagick itself, so it inherits the functionality of a FormMagick
object.

=head2 new

This is the class constructor.

=cut
     
sub new {
    shift;
    my $self = esmith::FormMagick->new();
    $self->{calling_package} = (caller)[0];
    bless $self;
    return $self;
}

=head2 main

Main methode select correct action

=cut

sub main {
    my ($fm) = @_;
    my $action = $fm->{cgi}->param('action') || '';
    my $wherenext = $fm->{cgi}->param('wherenext');

    if( $action eq 'cron_modify') {
    	$fm->update_cron_table();
    }
    elsif( $action eq 'delete_entry') {
    	$fm->delete_one_cron_entry();
    }
    elsif( $action eq 'create_cron') {
    	$fm->create_one_cron_entry();
    }
    $fm->wherenext($wherenext);
}

=head2 display_cron_entry

Display all crontab entry entred using this web interface

=cut
    
sub display_cron_entry {
    my $self = shift ;
    my $q = $self->cgi ;
    my $script = basename($0);

    my $test = $self->cgi->param('id');
    
    print "<table class=\"sme-border\">";
    print "<tr>";
    print "<th class=\"sme-border\">" . $self->localise('MINUTE' ) . "</th><th class=\"sme-border\">" . $self->localise('EVERY_MINUTE' ) . "</th><th class=\"sme-border\">" . $self->localise('HOURS' ) . "</th><th class=\"sme-border\">" . $self->localise('EVERY_HOURS' ) . "</th><th class=\"sme-border\">" . $self->localise('DAY' ) . "</th><th class=\"sme-border\">" . $self->localise('EVERY_DAY' ) . "</th><th class=\"sme-border\">" . $self->localise('MONTH' ) . "</th><th class=\"sme-border\">" . $self->localise('DAY_WEEK' ) . "</th><th class=\"sme-border\">" . $self->localise('USER_RUN_CRON' ) . "</th><th class=\"sme-border\">" . $self->localise('COMMAND' ) . "</th><th class=\"sme-border\" colspan=\"2\">Action</th>";
    print "</tr>";
    
    my %conf;
    tie %conf, "esmith::config";
    
    my $index = 1;
    my $value;
    my @cron_entry;
    my $cron_entry;
    my $small_index;
    
    $value=db_get_prop(\%conf, "cronmanager","task$index") || "";
    while ($value) {
       @cron_entry=split(/,/, $value);
       print "<tr>";
       $small_index=0;
       foreach $cron_entry (@cron_entry) {
            if ($small_index eq '6') {
                if ($cron_entry eq '*') {
                    print "<td class=\"sme-border\">".$self->localise('EVERY_MONTH_TEXT')."</td>";
                } else {
                    print "<td class=\"sme-border\">".$self->localise(convert_month($cron_entry))."</td>";
                }
            } elsif ($small_index eq '7') {
                if ($cron_entry eq '*') {
                    print "<td class=\"sme-border\">".$self->localise('EVERY_DAY_OF_WEEK')."</td>";
                } else {
                    print "<td class=\"sme-border\">".$self->localise(convert_dayweek($cron_entry))."</td>";    
                }
            } else {
                print "<td class=\"sme-border\">$cron_entry</td>";
            }
            $small_index++;
       }
       print "<td class=\"sme-border\"><a href=\"$script?page=0&action2=cron_modify&wherenext=change_entry&id=$index\">" . $self->localise('MODIFY' ) . "</a></td>";
       print "<td class=\"sme-border\"><a href=\"$script?page=0&wherenext=delete_entry&id=$index\">" . $self->localise('REMOVE' ) . "</a></td>"; 
       print "</tr>";
       $index++;
       $value=db_get_prop(\%conf, "cronmanager","task$index") || "";
    }

    print "</table>";

    return "";

}

=head2 display_button

This method is used to display a button on the right place.

=cut

sub display_button {
    my ($self, $fld) = @_;
    my $id = $self->cgi->param('id');

    my $q = $self->cgi ;
    print "<form>";
    print "<input type=\"hidden\" name=\"wherenext\" value=\"change_entry\">";
    print "<input type=\"hidden\" name=\"page\" value=\"1\">";
    print "<input type=\"hidden\" name=\"action2\" value=\"create_cron\">";
    print "<input type=\"submit\" value=\"" . $self->localise($fld) . "\">";
    print "</form>";
    return undef;
}
    
=head2 display_form
 
This method is used to start a new display.

=cut

sub display_form {
    my $self = shift ;
    my $q = $self->cgi ;

    $self->debug_msg("'display_form' begins.") ;
    $self->debug_msg("\$self->wherenext(\"First\");") ;
    $self->wherenext("First") ;
}
    
=head2 change_cron_entry

define action in html page

=cut

sub change_cron_entry {
    my ($self) = @_;
    my $name = $self->cgi->param('name');
    my $id = $self->cgi->param('id');
    my $action = $self->cgi->param('action2');
    
    $self->wherenext('First');
    print qq(
       <input type="hidden" name="id" value="$id">
       <input type="hidden" name="wherenext" value="First">
       <input type="hidden" name="action" value="$action">    
            );
    return "";
}

=head2 delete_cron_entry

define action in html page

=cut

sub delete_cron_entry {
    my ($self) = @_;
    my $name = $self->cgi->param('name');
    my $id = $self->cgi->param('id');

    $self->wherenext('First');
    print qq(
       <input type="hidden" name="id" value="$id">
       <input type="hidden" name="wherenext" value="First">
       <input type="hidden" name="action" value="delete_entry">    
            );
    
    return "";
}

=head2 update_cron_table

Update crontab propeties in the database

=cut

sub update_cron_table {
	my ($self) = @_;
	my $fm = shift;
    my $id = $self->cgi->param('id');
    my $min = check_every($self->cgi->param('min'));
    my $every_min = $self->cgi->param('every_min');
    my $hour = check_every($self->cgi->param('hour'));
    my $every_hour = $self->cgi->param('every_hour');
    my $day = check_every($self->cgi->param('day'));
    my $every_day = $self->cgi->param('every_day');
    my $month = check_every($self->cgi->param('month'));
    my $day_week = check_every($self->cgi->param('day_week'));
    my $user = $self->cgi->param('user');
    my $command = $self->cgi->param('command');
    my $month2;
    my $day_week2;
    
    if ($min eq '*') {
        $every_min="";
    }
    if ($hour eq '*') {
        $every_hour="";
    }
    if ($day eq '*') {
        $every_day="";
    }
    if ($month eq '*') {
        $month2 = $month;	
    } else {
        $month2 = reverse_month($month);
    }
    if ($day_week eq '*') {
        $day_week2 = $day_week;
    } else {
        $day_week2 = reverse_dayweek($day_week);
    }
    my $pr = $min.",".$every_min.",".$hour.",".$every_hour.",".$day.",".$every_day.",".$month2.",".$day_week2.",".$user.",".$command;
    
    #print "$pr";

    my %conf;
    tie %conf, 'esmith::config';

    my $cron_prop = db_get(\%conf, "cronmanager");

    db_set_prop(\%conf, "cronmanager", "task$id",$pr);
    
    if (system ("/sbin/e-smith/expand-template", "/etc/crontab") == 0) {
        $fm->success("SUCCESSFULLY_MODIFY_CRON_ENTRY");    
    } else {
        $fm->error("ERROR_MODIFY_CRON_ENTRY");
    }
}

=head2 create_one_cron_entry

=cut 

sub create_one_cron_entry {
    my ($self) = @_;
    my $fm = shift;
        my $min = check_every($self->cgi->param('min'));
    my $every_min = $self->cgi->param('every_min');
    my $hour = check_every($self->cgi->param('hour'));
    my $every_hour = $self->cgi->param('every_hour');
    my $day = check_every($self->cgi->param('day'));
    my $every_day = $self->cgi->param('every_day');
    my $month = check_every($self->cgi->param('month'));
    my $day_week = check_every($self->cgi->param('day_week'));
    my $user = $self->cgi->param('user');
    my $command = $self->cgi->param('command');
    my $month2;
    my $day_week2;
    
    if ($min eq '*') {
        $every_min="";
    }
    if ($hour eq '*') {
        $every_hour="";
    }
    if ($day eq '*') {
        $every_day="";
    }
    if ($month eq '*') {
        $month2 = $month;	
    } else {
        $month2 = reverse_month($month);
    }
    if ($day_week eq '*') {
        $day_week2 = $day_week;
    } else {
        $day_week2 = reverse_dayweek($day_week);
    }
    my $pr = $min.",".$every_min.",".$hour.",".$every_hour.",".$day.",".$every_day.",".$month2.",".$day_week2.",".$user.",".$command;

    my $id=give_lastindex();

    my %conf;
    tie %conf, 'esmith::config';

    my $cron_prop = db_get(\%conf, "cronmanager");

    db_set_prop(\%conf, "cronmanager", "task$id",$pr);

    if (system ("/sbin/e-smith/expand-template", "/etc/crontab") == 0) {
        $fm->success("SUCCESSFULLY_CREATE_CRON_ENTRY");    
    } else {
        $fm->error("ERROR_CREATE_CRON_ENTRY");
    }
    
}

=head2 check_every

Check sting caractere if it start with EVERY, thus change to "*"

=cut

sub check_every {
    my ($to_check) = @_;
    
    my @val=split(/_/,$to_check);
    my $ret;
    
    if ($val[0] eq 'EVERY') {
        $ret="*";
    } else {
        $ret=$to_check;
    }
    return($ret);
}

=head2 delete_one_cron_entry

delete one crontab entry in the list

=cut 

sub delete_one_cron_entry {
    my ($self) = @_;
    my $fm = shift;
    my $id = $self->cgi->param('id');

    my %conf;
    tie %conf, 'esmith::config';


    my $cron_prop = db_get(\%conf, "cronmanager");

    my $index = 1;
    my $sec_index=1;
    my @cron_entry;
    my $cron_entry;
    my $small_index;
    my %new_prop=();
    
    
    my $value=db_get_prop(\%conf, "cronmanager","task$index") || "";
    
    while ($value) {
       if ($index ne $id) {
            $new_prop{$sec_index}=$value;
            $sec_index++;
       }
       db_delete_prop(\%conf,"cronmanager","task$index");
       $index++;
       $value=db_get_prop(\%conf, "cronmanager","task$index") || "";
    }
    for my $pro ( keys %new_prop ) {
        db_set_prop(\%conf, "cronmanager", "task$pro", $new_prop{$pro});
    }

    if (system ("/sbin/e-smith/expand-template", "/etc/crontab") == 0) {
        $fm->success("SUCCESSFULLY_DELETE_CRON_ENTRY");    
    } else {
        $fm->error("ERROR_DELETE_CRON_ENTRY");
    }
}

=head2 give_numeric(field)

Look for specific field in the list

=cut

sub give_numeric {
    my ($self, $fld) = @_;
    my $id = $self->cgi->param('id');

    my %conf;
    tie %conf, 'esmith::config';

    my $cron_prop = db_get(\%conf, "cronmanager");

    my $value;
    my $fld_value;
    my @cron_entry;
    my $cron_entry;
    
    $value=db_get_prop(\%conf, "cronmanager","task$id") || "";
    @cron_entry=split(/,/, $value);
    
    my $ret;
    $fld_value=$cron_entry[$fld] || "";

    if ($fld_value eq '*') {
        $ret=""
    } else {
        $ret=$fld_value;
    }
    return($ret);
        
}

=head2 convert_month

Convert numeric month to complete month

=cut

sub convert_month {
    my ($month) = @_;
    my $ret;
    
    if ($month eq '') {
        $ret = "EVERY_MONTH_TEXT";
    } else {
        my @month2 = (
                    'JANUARY',
                    'FEBRUARY',
                    'MARCH',
                    'APRIL',
                    'MAY',
                    'JUNE',
                    'JULY',
                    'AUGUST',
                    'SEPTEMBER',
                    'OCTOBER',
                    'NOVEMBER',
                    'DECEMBER'
        );    
        $ret=$month2[$month-1];
    }
    return ($ret);
}

=head2 reverse_month

Convert complete month to numeric month

=cut

sub reverse_month {
    my ($month) = @_;

    my %month2 = (
                JANUARY=>'1',
                FEBRUARY=>'2',
                MARCH=>'3',
                APRIL=>'4',
                MAY=>'5',
                JUNE=>'6',
                JULY=>'7',
                AUGUST=>'8',
                SEPTEMBER=>'9',
                OCTOBER=>'10',
                NOVEMBER=>'11',
                DECEMBER=>'12'
    );    
    my $ret=$month2{$month};

    return ($ret);
}

=head2 convert_dayweek

Convert numeric day of week to literal day of week

=cut

sub convert_dayweek {
    my ($day) = @_;
    my $ret;
    
    if ($day eq '') {
        $ret="EVERY_DAY_OF_WEEK";
    } else {
        my @day2 = (
                    'MONDAY',
                    'TUESDAY',
                    'WEDNESDAY',
                    'THURSDAY',
                    'FRIDAY',
                    'SATERDAY',
                    'SUNDAY'
        );    
        $ret=$day2[$day-1];
    }

    return ($ret);
}

=head2 reverse_dayweek

Convert literal day of week to numerical day of week

=cut

sub reverse_dayweek {
    my ($day) = @_;

    my %day2 = (
                MONDAY=>'1',
                TUESDAY=>'2',
                WEDNESDAY=>'3',
                THURSDAY=>'4',
                FRIDAY=>'5',
                SATERDAY=>'6',
                SUNDAY=>'7'
    );    

    my $ret=$day2{$day};

    return ($ret);
}

=head2 give_month

Public method that return month for current crontab entry

=cut

sub give_month {
    my ($self) = @_;
    my $id = $self->cgi->param('id');

    my $month = give_numeric($self,6);

    return (convert_month($month));
}

=head2 give_dayweek

Public method that return day of the week for current crontab entry

=cut

sub give_dayweek {
    my ($self) = @_;
    my $id = $self->cgi->param('id');

    my $dayweek = give_numeric($self,7);

    return (convert_dayweek($dayweek));
}

=head2 give_bool

return boolean value of one of the propreties for current crontab entry

=cut

sub give_bool {
    my ($self, $fld) = @_;
    my $id = $self->cgi->param('id');

    my %conf;
    tie %conf, 'esmith::config';

    my $cron_prop = db_get(\%conf, "cronmanager");

    my $value;
    my @cron_entry;
    my $cron_entry;
    my $ret;
    
    $value=db_get_prop(\%conf, "cronmanager","task$id") || "";
    @cron_entry=split(/,/, $value);

    if ($cron_entry[$fld] eq 'YES') {
        $ret="YES";
    } else {
        $ret="NO";
    }
    return($ret);
        
}

=head2 give_lastindex

return the next index number of crontab entry

=cut 

sub give_lastindex {
    my %conf;
    tie %conf, 'esmith::config';

    my $cron_prop = db_get(\%conf, "cronmanager");

    my $index = 1;
    my $value;
    my @cron_entry;
    my $cron_entry;
    my $small_index;
    
    $value=db_get_prop(\%conf, "cronmanager","task$index") || "";
    while ($value) {
       $index++;
       $value=db_get_prop(\%conf, "cronmanager","task$index") || "";
    }
    
    return ($index);
}

=head2 give_all_user

Return All user recorded in AccoundDB

=cut

sub give_all_user {
    my $fm = shift;
    my $accounts = esmith::AccountsDB->open;

    my %existingAccounts = ('root' => "Administrator" );

    foreach my $account ($accounts->get_all) {
        if ($account->prop('type') =~ /(user)/) {
            $existingAccounts{$account->key} = $account->key;
        }
    }
    return(\%existingAccounts);
}

# never forget the final 1 ;-)
1;
