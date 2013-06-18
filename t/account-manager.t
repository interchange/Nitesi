#! perl
#
# Tests for Nitesi Account Manager

use strict;
use warnings;

use Test::More tests => 10;
use Nitesi::Account::Manager;

my ($account, $ret, $start_time);

# without account providers
$account = Nitesi::Account::Manager->new;
isa_ok($account, 'Nitesi::Account::Manager');
$ret = $account->login(username => 'racke', password => 'nevairbe');
ok ($ret == 0);

$start_time = time;

# with sample account provider
$account = Nitesi::Account::Manager->new(provider_sub => \&providers);
isa_ok($account, 'Nitesi::Account::Manager');
$ret = $account->login(username => 'racke', password => 'nevairbe');
ok ($ret == 1);
$ret = $account->last_login;
ok ($ret == 0, "Test initial last login value.")
    || diag "Last login is $ret instead of 0.";


my @parr = $account->permissions;
my $pref = $account->permissions;
is_deeply([@parr], ['test']);
is_deeply([keys %$pref], ['test']);

# test last login
$account->logout;
$ret = $account->login(username => 'racke', password => 'nevairbe');
ok ($ret == 1);
$ret = $account->last_login;

ok ($ret >= $start_time, "Test last login value.")
    || diag "Last login $ret is older than $start_time.";

# with bogus password
$ret = $account->login(username => 'racke', password => 'neviarbe');
ok ($ret == 0);

sub providers {
    return [['Nitesi::Account::Provider::Test',
            users => {racke => {password => 'nevairbe',
                               permissions => [qw/test/],
                               }}]];
}
