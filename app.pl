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
use Yancha::Bot;

my $config = do "$FindBin::Bin/config.pl";
my $fail_limit = 10;
my $bot = Yancha::Bot->new($config, \&create_listener);

my $done = AnyEvent->condvar;

say "start server";
$bot->get_yancha_auth_token();

$done->recv;

sub create_listener {
    my $tw_stream_listener; $tw_stream_listener = AnyEvent::Twitter::Stream->new(
        consumer_key    => $config->{TwitterToken}->{consumer_key},
        consumer_secret => $config->{TwitterToken}->{consumer_secret},
        token           => $config->{TwitterToken}->{access_token},
        token_secret    => $config->{TwitterToken}->{access_token_secret},
        method          => "filter",
        track           => $config->{track},
        on_tweet        => sub {
            my $tweet = shift;
            my $tweet_str = "$tweet->{user}{screen_name}: $tweet->{text}";
            say encode_utf8($tweet_str);
            $bot->post_yancha_message($tweet_str);
        },
        on_error => sub {
            my $error = shift;
            warn "ERROR: $error";
            if(0>$fail_limit--){
                warn "FAIL LIMIT OVER "; die;
            }
            undef $tw_stream_listener;
            $bot->set_timer(3);
        },
        timeout => 60,
    );
}
