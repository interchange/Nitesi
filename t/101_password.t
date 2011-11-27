#! perl
#
# Tests for Nitesi::Account::Password.

use strict;
use warnings;

use Test::More tests => 4;

use Nitesi::Account::Password;

my ($crypt, $hash, $ret);

$crypt = Nitesi::Account::Password->instance;

$hash = $crypt->password('nevairbe');

# check whether password matches
$ret = $crypt->check($hash, 'nevairbe');
ok($ret);

# check whether password fails
$ret = $crypt->check($hash, 'wrong');
ok(! $ret);

# repeat for md5
$hash = $crypt->password('nevairbe', 'md5');

# check whether password matches
$ret = $crypt->check($hash, 'nevairbe');
ok($ret);

# check whether password fails
$ret = $crypt->check($hash, 'wrong');
ok(! $ret);
