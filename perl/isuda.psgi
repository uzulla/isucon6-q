#!/usr/bin/env plackup
use 5.014;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use File::Spec;
use Plack::Builder;
use Sereal;
use Cache::Redis;

use Isuda::Web;

my $decoder = Sereal::Decoder->new();
my $encoder = Sereal::Encoder->new();

my $root_dir = $FindBin::Bin;
my $app = Isuda::Web->psgi($root_dir);
builder {
    enable 'ReverseProxy';
    enable 'Static',
        path => qr!^/(?:(?:css|js|img)/|favicon\.ico$)!,
        root => File::Spec->catfile($root_dir, 'public');
    enable 'Session::Simple',
        store => Cache::Redis->new(
            sock => '/tmp/redis.sock',
            namespace => 'isuda_session',
            nowait => 1,
            redis_class => 'Redis::Fast',
            serialize_methods => [ sub { $encoder->encode($_[0]) },
                                   sub { $decoder->decode($_[0]) } ],
        ),
        httponly => 1,
        cookie_name => "tonymoris",
        keep_empty => 0;
    $app;
};
