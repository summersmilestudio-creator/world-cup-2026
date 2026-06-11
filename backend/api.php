<?php
/**
 * Live Football — backend cache proxy (multi-competition).
 * Deploy to: summer-smile.ro/football/api.php  (Hostico)
 *
 * Data source: football-data.org v4 (free tier). Free tier covers the CURRENT
 * season of major club competitions and leagues — so the app works
 * long-term. The token is hidden here; the app
 * only ever calls THIS proxy, which caches responses to protect the rate limit
 * (free = 10 req/min) across all users.
 *
 * Endpoints (GET):
 *   ?action=competitions               -> available competitions
 *   ?action=live&comp=CL               -> in-play matches for a competition
 *   ?action=matches&comp=CL            -> fixtures (recent + upcoming)
 *   ?action=standings&comp=CL          -> standings table
 *   ?action=news&lang=xx               -> aggregated football news (RSS)
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Cache-Control: public, max-age=30');

// ---- CONFIG (FILL IN) -------------------------------------------------------
const TOKEN    = '6ea5792e30074f4d8d59af42f15c479d'; // football-data.org free token
const API_BASE = 'https://api.football-data.org/v4';
const CACHE_DIR = __DIR__ . '/cache';

// Competitions exposed by the app (free-tier codes). Order = display order.
const COMPETITIONS = [
    ['code' => 'CL',  'name' => 'Champions League'],
    ['code' => 'PL',  'name' => 'Premier League'],
    ['code' => 'PD',  'name' => 'La Liga'],
    ['code' => 'BL1', 'name' => 'Bundesliga'],
    ['code' => 'SA',  'name' => 'Serie A'],
    ['code' => 'FL1', 'name' => 'Ligue 1'],
    ['code' => 'DED', 'name' => 'Eredivisie'],
    ['code' => 'PPL', 'name' => 'Primeira Liga'],
    ['code' => 'ELC', 'name' => 'Championship'],
    ['code' => 'BSA', 'name' => 'Série A (Brazil)'],
    ['code' => 'EC',  'name' => 'European Championship'],
];

const TTL = ['live' => 30, 'matches' => 300, 'standings' => 600, 'news' => 900, 'competitions' => 86400];

// ---- ROUTER -----------------------------------------------------------------
if (!is_dir(CACHE_DIR)) @mkdir(CACHE_DIR, 0775, true);
$action = preg_replace('/[^a-z]/', '', $_GET['action'] ?? '');
$comp   = preg_replace('/[^A-Z0-9]/', '', strtoupper($_GET['comp'] ?? 'CL'));
$lang   = substr(preg_replace('/[^a-zA-Z\-]/', '', $_GET['lang'] ?? 'en'), 0, 2);
if (!in_array($comp, array_column(COMPETITIONS, 'code'), true)) $comp = 'CL';

try {
    switch ($action) {
        case 'competitions': echo json_encode(['competitions' => COMPETITIONS], JSON_UNESCAPED_UNICODE); break;
        case 'live':      echo cached("live_$comp",      fn() => matches($comp, true)); break;
        case 'matches':   echo cached("matches_$comp",   fn() => matches($comp, false)); break;
        case 'standings': echo cached("standings_$comp", fn() => standings($comp)); break;
        case 'news':      echo cached("news_$lang",       fn() => news($lang)); break;
        default:          http_response_code(400); echo json_encode(['error' => 'bad action']);
    }
} catch (Throwable $e) {
    http_response_code(502);
    echo json_encode(['error' => 'upstream', 'detail' => $e->getMessage()]);
}

// ---- CACHE ------------------------------------------------------------------
function cached(string $key, callable $producer): string {
    $ttl = TTL[explode('_', $key)[0]] ?? 120;
    $file = CACHE_DIR . '/' . $key . '.json';
    if (is_file($file) && (time() - filemtime($file)) < $ttl) return file_get_contents($file);
    $json = json_encode($producer(), JSON_UNESCAPED_UNICODE);
    @file_put_contents($file, $json);
    return $json;
}

// ---- football-data.org ------------------------------------------------------
function fd(string $path): array {
    $ch = curl_init(API_BASE . $path);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_HTTPHEADER => ['X-Auth-Token: ' . TOKEN],
        CURLOPT_TIMEOUT => 12,
        CURLOPT_SSL_VERIFYPEER => false,
        CURLOPT_SSL_VERIFYHOST => 0,
    ]);
    $body = curl_exec($ch);
    if ($body === false) throw new RuntimeException(curl_error($ch));
    curl_close($ch);
    $d = json_decode($body, true);
    return is_array($d) ? $d : [];
}

// Map football-data.org status -> app short codes used by the Flutter models.
function mapStatus(string $s): string {
    return [
        'SCHEDULED' => 'NS', 'TIMED' => 'NS', 'IN_PLAY' => '2H', 'PAUSED' => 'HT',
        'FINISHED' => 'FT', 'SUSPENDED' => 'NS', 'POSTPONED' => 'NS', 'CANCELLED' => 'NS',
    ][$s] ?? 'NS';
}

function matches(string $comp, bool $liveOnly): array {
    // Window: last 4 days .. next 30 days — recent results + upcoming fixtures
    // (wide enough to surface tournament group stages like the World Cup).
    $from = gmdate('Y-m-d', time() - 4 * 86400);
    $to   = gmdate('Y-m-d', time() + 30 * 86400);
    $r = fd("/competitions/$comp/matches?dateFrom=$from&dateTo=$to");
    $out = [];
    foreach (($r['matches'] ?? []) as $m) {
        $status = $m['status'] ?? 'SCHEDULED';
        $isLive = in_array($status, ['IN_PLAY', 'PAUSED'], true);
        if ($liveOnly && !$isLive) continue;
        $out[] = [
            'id'        => $m['id'] ?? 0,
            'homeName'  => $m['homeTeam']['shortName'] ?? $m['homeTeam']['name'] ?? 'TBD',
            'awayName'  => $m['awayTeam']['shortName'] ?? $m['awayTeam']['name'] ?? 'TBD',
            'homeLogo'  => $m['homeTeam']['crest'] ?? null,
            'awayLogo'  => $m['awayTeam']['crest'] ?? null,
            'homeGoals' => $m['score']['fullTime']['home'],
            'awayGoals' => $m['score']['fullTime']['away'],
            'status'    => mapStatus($status),
            'elapsed'   => null, // not provided on free tier
            'kickoff'   => $m['utcDate'] ?? null,
            'round'     => $m['stage'] ?? $m['matchday'] ?? null,
        ];
    }
    return ['matches' => $out];
}

function standings(string $comp): array {
    $r = fd("/competitions/$comp/standings");
    $rows = [];
    foreach (($r['standings'] ?? []) as $table) {
        $group = $table['group'] ?? null;
        if (($table['type'] ?? 'TOTAL') !== 'TOTAL') continue;
        foreach (($table['table'] ?? []) as $t) {
            $rows[] = [
                'rank'      => $t['position'] ?? 0,
                'teamName'  => $t['team']['shortName'] ?? $t['team']['name'] ?? '',
                'teamLogo'  => $t['team']['crest'] ?? null,
                'played'    => $t['playedGames'] ?? 0,
                'win'       => $t['won'] ?? 0,
                'draw'      => $t['draw'] ?? 0,
                'lose'      => $t['lost'] ?? 0,
                'goalsDiff' => $t['goalDifference'] ?? 0,
                'points'    => $t['points'] ?? 0,
                'group'     => $group,
            ];
        }
    }
    return ['standings' => $rows];
}

// ---- NEWS (RSS aggregation, no key) -----------------------------------------
function news(string $lang): array {
    $feeds = [
        'en' => 'https://www.theguardian.com/football/rss',
        'es' => 'https://e.marca.com/rss/futbol.xml',
        'fr' => 'https://www.lequipe.fr/rss/actu_rss_Football.xml',
        'pt' => 'https://www.lance.com.br/rss/futebol.xml',
        'de' => 'https://www.kicker.de/news/fussball/rss.xml',
        'it' => 'https://www.gazzetta.it/rss/calcio.xml',
    ];
    $url = $feeds[$lang] ?? $feeds['en'];
    $items = [];
    $ch = curl_init($url);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_FOLLOWLOCATION => true,
        CURLOPT_TIMEOUT => 12,
        CURLOPT_USERAGENT => 'Mozilla/5.0 (LiveFootball/1.0)',
        CURLOPT_SSL_VERIFYPEER => false,
        CURLOPT_SSL_VERIFYHOST => 0,
    ]);
    $raw = curl_exec($ch);
    curl_close($ch);
    $xml = @simplexml_load_string($raw ?: '');
    if ($xml) {
        foreach (($xml->channel->item ?? []) as $it) {
            $img = null;
            foreach ($it->children('media', true) as $m) {
                if (isset($m->attributes()->url)) { $img = (string)$m->attributes()->url; break; }
            }
            $items[] = [
                'title'     => trim((string)$it->title),
                'link'      => trim((string)$it->link),
                'source'    => (string)($xml->channel->title ?? ''),
                'published' => isset($it->pubDate) ? date('c', strtotime((string)$it->pubDate)) : null,
                'image'     => $img,
            ];
            if (count($items) >= 30) break;
        }
    }
    return ['news' => $items];
}
