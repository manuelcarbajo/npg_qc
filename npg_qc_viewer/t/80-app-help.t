use strict;
use warnings;
use Test::More tests => 6;
use Test::Exception;
use Test::WWW::Mechanize::Catalyst;

use t::util;

my $util = t::util->new();
local $ENV{CATALYST_CONFIG} = $util->config_path;

my $mech;

{
  lives_ok { $util->test_env_setup()}  'test db created and populated';
  use_ok 'Test::WWW::Mechanize::Catalyst', 'npg_qc_viewer';
  $mech = Test::WWW::Mechanize::Catalyst->new;
}

{
  my $url = qq[http://localhost/checks];
  $mech->get_ok($url);
  $mech->title_is(q[NPG SeqQC - visualization and datamining for sequence quality control]);
}

{
  my $url = qq[http://localhost/checks/about];
  $mech->get_ok($url);
  $mech->title_is(q[NPG SeqQC: about QC checks]);
}

1;
