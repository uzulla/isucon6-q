#!/usr/bin/env perl
use 5.014;
use strict;
use warnings;
use utf8;

use Encode qw/encode_utf8 decode_utf8/;

use FindBin;
use File::Spec;
use lib File::Spec->join($FindBin::Bin, '..', 'local', 'lib', 'perl5');
use lib File::Spec->join($FindBin::Bin, '..', 'lib');
use Isuda::Web;

my ($uri_base, @keywords) = @ARGV;

my $keyword = decode_utf8(join ' ', @keywords);

sub config {
    state $conf = {
        dsn           => $ENV{ISUDA_DSN}         // 'dbi:mysql:db=isuda',
        db_user       => $ENV{ISUDA_DB_USER}     // 'root',
        db_password   => $ENV{ISUDA_DB_PASSWORD} // '',
        isutar_origin => $ENV{ISUTAR_ORIGIN}     // 'http://localhost:5001',
        isupam_origin => $ENV{ISUPAM_ORIGIN}     // 'http://localhost:5050',
    };
    my $key = shift;
    my $v = $conf->{$key};
    unless (defined $v) {
        die "config value of $key undefined";
    }
    return $v;
}

my $dbh = DBIx::Sunny->connect(config('dsn'), config('db_user'), config('db_password'), {
    Callbacks => {
        connected => sub {
            my $dbh = shift;
            $dbh->do(q[SET SESSION sql_mode='TRADITIONAL,NO_AUTO_VALUE_ON_ZERO,ONLY_FULL_GROUP_BY']);
            $dbh->do('SET NAMES utf8mb4');
            return;
        },
    },
});

my $redis = Redis::Fast->new(
    sock => '/tmp/redis.sock',
    name => 'isucon',
);


# 正規表現つくりなおし
my $keywords = $dbh->select_all(qq[
   SELECT keyword FROM entry ORDER BY keyword_length DESC
]);
my $re = join '|', map { quotemeta $_->{keyword} } @$keywords;

# entry全部みるぞ
my $entries = $dbh->select_all(qq[
    SELECT id, description FROM entry
    ORDER BY updated_at DESC
]);
for my $entry (@$entries) {
    # 含まれてるやつだけ更新
    if ($entry->{description} =~ /$keyword/) {
        $redis->set('htmlify|' . $entry->{id}, encode_utf8(htmlify($entry->{description})));
    }
}


sub htmlify {
    my ($content) = @_;
    return '' unless defined $content;

    my %kw2sha;
    $content =~ s{($re)}{
        my $kw = $1;
        $kw2sha{$kw} = "isuda_" . sha1_hex(encode_utf8($kw));
    }eg;
    $content = html_escape($content);
    while (my ($kw, $hash) = each %kw2sha) {
        my $url = $uri_base . '/keyword/' . uri_escape_utf8($kw);
        my $link = sprintf '<a href="%s">%s</a>', $url, html_escape($kw);
        $content =~ s/$hash/$link/g;
    }
    $content =~ s{\n}{<br \/>\n}gr;
}
