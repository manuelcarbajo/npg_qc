use strict;
use warnings;
use Test::More tests => 54;
use Test::Exception;
use HTTP::Request::Common;
use t::util;

my $util = t::util->new();
local $ENV{CATALYST_CONFIG} = $util->config_path;
local $ENV{TEST_DIR}        = $util->staging_path;

use_ok 'npg_qc_viewer::Controller::Mqc';
lives_ok { $util->test_env_setup()}  'test db created and populated';
use_ok 'Catalyst::Test', 'npg_qc_viewer';

my $response;
{
  lives_ok { $response = request(HTTP::Request->new('GET', '/mqc/update_outcome' )) }
    'update get request lives';
  ok($response->is_error, q[update response is error]);
  is( $response->code, 405, 'error code is 405' );
  like ($response->content, qr/Only POST requests are allowed/, 'correct error message');
}

{
  my $response;
  lives_ok { $response = request(POST '/mqc/update_outcome' ) } 'post request lives';
  ok( $response->is_error, qq[response is an error] );
  is( $response->code, 401, 'error code is 401' );
  like ($response->content, qr/Login failed/, 'correct error message');

  lives_ok { $response = request(POST '/mqc/update_outcome?user=frog' ) } 'post request lives';
  is( $response->code, 401, 'error code is 401' );
  like ($response->content, qr/Login failed/, 'correct error message');

  lives_ok { $response = request(POST '/mqc/update_outcome?user=tiger&password=secret' ) } 'post request lives';
  is( $response->code, 401, 'error code is 401' );
  like ($response->content, qr/User tiger is not a member of manual_qc/, 'correct error message');

  lives_ok { $response = request(POST '/mqc/update_outcome?user=cat' ) } 'post request lives';
  is( $response->code, 401, 'error code is 401' );
  like ($response->content, qr/Login failed/, 'correct error message');
}

{
  my $url = '/mqc/update_outcome?user=cat&password=secret';
  my $response;

  lives_ok { $response = request(POST $url)}
    'post request without params lives';
  is( $response->code, 400, 'error code is 400' );
  like ($response->content, qr/Run id should be defined/, 'correct error message');

  lives_ok { $response = request(POST $url, ['id_run' => '1234']) }
    'post request lives with body param';
  is( $response->code, 400, 'code is 400' );
  like ($response->content, qr/Position should be defined/, 'correct error message');
 
  lives_ok { $response = request(POST $url, ['id_run' => '1234', 'position' => '4'])  }
    'post request lives with body param';
  is( $response->code, 400, 'error code is 400' );
  like ($response->content, qr/Mqc outcome should be defined/,
   'correct error message');

  lives_ok { $response = request(POST $url,
    ['id_run' => '1234', 'position' => '4', 'new_oc' => 'some'])  }
    'post request lives with body param';
  is( $response->code, 500, 'error code is 500' );
  like ($response->content,
    qr/Error while trying to transit id_run 1234 position 4 to a non-existing outcome/,
    'correct error message for invalid outcome');

  $url = '/mqc/update_outcome?user=pipeline&password=secret';

  lives_ok { $response = request(POST $url,
    ['id_run' => '1234', 'position' => '4', 'new_oc' => 'Accepted final' ])  }
   'post request lives with body param';
  is( $response->code, 200, 'response code is 200' );
  my $content = $response->content;
  like ($content,
    qr/Manual QC Accepted final for run 1234, position 4 saved/,
    'correct confirmation message');
  like ($content,
    qr/Error updating lane status: Failed to get run_lane row for id_run 1234, position 4/,
    'error updating lane status logged');

  lives_ok { $response = request(POST $url,
    ['id_run' => '4025', 'position' => '1', 'new_oc' => 'Accepted final' ])  }
   'post request lives with body param';
  is( $response->code, 200, 'response code is 200' );
  $content = $response->content;
  like ($content,
    qr/Manual QC Accepted final for run 4025, position 1 saved/,
    'correct confirmation message');
  unlike ($content,
    qr/Error updating lane status/,
    'error updating lane status is absent');
}

{
  lives_ok { $response = request(HTTP::Request->new('GET', '/mqc/get_current_outcome')) }
    'get current outcome lives';
  ok($response->is_error, q[get_current_outcome response is error]);
  is( $response->code, 400, 'error code is 400' );
  like ($response->content, qr/Run id should be defined/, 'correct error message');

  lives_ok { $response = request(HTTP::Request->new(
   'GET', '/mqc/get_current_outcome?id_run=1234')) } 'get current outcome lives';
  ok($response->is_error, q[get_current_outcome response is error]);
  is( $response->code, 400, 'error code is 400' );
  like ($response->content, qr/Position should be defined/, 'correct error message');

  lives_ok { $response = request(HTTP::Request->new('GET', '/mqc/get_all_outcomes')) }
   'get all outcomes lives';
  ok($response->is_error, q[get_all_outcomes response is error]);
  is( $response->code, 400, 'error code is 400' );
  like ($response->content, qr/Run id should be defined/, 'correct error message');

  lives_ok { $response = request(HTTP::Request->new(
   'GET', '/mqc/get_all_outcomes?id_run=1234')) }
    'get current outcome lives';
  is( $response->code, 200, 'response code is 200' );
}

1;