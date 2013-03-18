use strict;
use utf8;
use warnings;
use FindBin;
use lib ("$FindBin::Bin/lib");
use AnyEvent::Twitter::Stream;
use AnyEvent::HTTP::Request;
use 5.010;
use Data::Dumper;
use URI::Escape;
use Encode;

my $config = do "$FindBin::Bin/config.pl";
my $fail_limit = 10;

my $done = AnyEvent->condvar;

my $tw_stream_listener;
my $create_listener;
my $listener_timer;
my $set_timer;

my $get_yancha_auth_token;
my $yancha_auth_token;
my $post_yancha_message;

$create_listener = sub{
	$tw_stream_listener = AnyEvent::Twitter::Stream->new(
		consumer_key    => $config->{TwitterToken}->{consumer_key},
		consumer_secret => $config->{TwitterToken}->{consumer_secret},
		token           => $config->{TwitterToken}->{access_token},
		token_secret    => $config->{TwitterToken}->{access_token_secret},
		method          => "filter",
		track           => $config->{track},
		on_tweet        => sub {
			my $tweet = shift;
			say encode_utf8("$tweet->{user}{screen_name}: $tweet->{text}");
			$post_yancha_message->("$tweet->{user}{screen_name}: $tweet->{text}");
	  	},
	    on_error => sub {
	      my $error = shift;
	      warn "ERROR: $error";
	      if(0>$fail_limit--){
	      	warn "FAIL LIMIT OVER "; die;
	      }
	      undef $tw_stream_listener; 
	      $set_timer->(3); 
	    },
		timeout => 60,
	);
};

$set_timer = sub {
	my $after = shift || 0;
	$listener_timer = AnyEvent->timer(
		after    => $after,
		cb => sub {
			say "connecting";
			undef $listener_timer;
			$create_listener->();
		},
	);
};

$get_yancha_auth_token = sub {
  my $req = AnyEvent::HTTP::Request->new({
    method => 'GET',
    uri  => $config->{YanchaUrl}.'/login?nick=yanchabot&token_only=1',
    cb   => sub {
    	my ($body, $headers) = shift;
    	$yancha_auth_token = $body;
    	say "yancha_auth_token: ".$yancha_auth_token;
    	if($yancha_auth_token){
    		$set_timer->(0);
    	}
    }
  });

  my $http_req = $req->to_http_message;
  $req->send();
};

$post_yancha_message = sub {
	my $message = shift;
	$message =~ s/#/＃/g;
	my $req = AnyEvent::HTTP::Request->new({
	    method => 'GET',
	    uri  => $config->{YanchaUrl}.'/api/post?token='.$yancha_auth_token.'&text='.uri_escape_utf8($message),
	    cb   => sub {
	    	my ($body, $headers) = shift;
	    	say encode_utf8("past yancha: \"".$message."\" yancha return-> ".$body);
	    	#TODO TOKEN失効時にTOKENを更新する必要がある。
	    }
  	});
	my $http_req = $req->to_http_message;
	$req->send();
};


say "start server";
$get_yancha_auth_token->();

$done->recv;
