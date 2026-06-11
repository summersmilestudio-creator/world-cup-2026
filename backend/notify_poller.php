<?php
/**
 * notify_poller.php — Football 2026: Live Score
 * Polls football-data.org for in-play matches, detects events by comparing
 * against the previous snapshot, and pushes FCM notifications to per-match topics.
 *
 * Run from cron every ~60s:  php notify_poller.php   (or hit via HTTP with ?key=)
 *
 * Detected events (free tier — status + score only):
 *   kickoff      SCHEDULED/TIMED -> IN_PLAY
 *   goal         home/away score increased while live
 *   halftime     IN_PLAY -> PAUSED
 *   secondhalf   PAUSED  -> IN_PLAY
 *   fulltime     any live -> FINISHED
 *
 * Cards (yellow/red) are NOT available on the free football-data.org tier.
 */

const TOKEN     = '6ea5792e30074f4d8d59af42f15c479d';      // football-data.org free token
const API_BASE  = 'https://api.football-data.org/v4';
const STATE_FILE = __DIR__ . '/cache/notify_state.json';   // last seen snapshot
const LOG_FILE   = __DIR__ . '/cache/notify_poller.log';
const RUN_KEY    = 'wc2026_poll_9f3k';                      // simple guard for HTTP trigger

// Firebase service-account JSON (set after Firebase project is created).
const FCM_SA_FILE  = __DIR__ . '/fcm-service-account.json';
const FCM_PROJECT  = 'PUT_FIREBASE_PROJECT_ID_HERE';

// Competitions to watch for live matches (free-tier covered).
const COMPS = ['CL', 'PL', 'PD', 'BL1', 'SA', 'FL1', 'EC'];

// ---- guards ----------------------------------------------------------------
if (php_sapi_name() !== 'cli') {
    if (($_GET['key'] ?? '') !== RUN_KEY) { http_response_code(403); exit('forbidden'); }
    header('Content-Type: application/json');
}

function logln($s) { @file_put_contents(LOG_FILE, '[' . gmdate('H:i:s') . '] ' . $s . "\n", FILE_APPEND); }

function fd($path) {
    $ch = curl_init(API_BASE . $path);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_HTTPHEADER     => ['X-Auth-Token: ' . TOKEN],
        CURLOPT_SSL_VERIFYPEER => false,
        CURLOPT_SSL_VERIFYHOST => 0,
        CURLOPT_TIMEOUT        => 25,
    ]);
    $raw = curl_exec($ch);
    $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    if ($code !== 200) return null;
    return json_decode($raw, true);
}

// ---- collect current in-play matches across competitions -------------------
$current = [];   // id => snapshot
foreach (COMPS as $comp) {
    // status filter: matches currently live or just kicked off / just finished
    $data = fd("/competitions/$comp/matches?status=IN_PLAY") ?: ['matches' => []];
    $data2 = fd("/competitions/$comp/matches?status=PAUSED") ?: ['matches' => []];
    // also catch ones that finished or kicked off since last poll: today's matches
    $today = gmdate('Y-m-d');
    $data3 = fd("/competitions/$comp/matches?dateFrom=$today&dateTo=$today") ?: ['matches' => []];
    foreach (array_merge($data['matches'], $data2['matches'], $data3['matches']) as $m) {
        $id = $m['id'];
        $current[$id] = [
            'id'     => $id,
            'comp'   => $comp,
            'status' => $m['status'] ?? 'SCHEDULED',
            'h'      => $m['homeTeam']['shortName'] ?? $m['homeTeam']['name'] ?? '?',
            'a'      => $m['awayTeam']['shortName'] ?? $m['awayTeam']['name'] ?? '?',
            'hg'     => $m['score']['fullTime']['home'] ?? 0,
            'ag'     => $m['score']['fullTime']['away'] ?? 0,
        ];
    }
    usleep(200000); // be gentle with the 10 req/min free limit
}

// ---- load previous snapshot ------------------------------------------------
$prev = [];
if (is_file(STATE_FILE)) $prev = json_decode(@file_get_contents(STATE_FILE), true) ?: [];

// ---- diff & emit events ----------------------------------------------------
$liveStates = ['IN_PLAY', 'PAUSED'];
$events = [];
foreach ($current as $id => $c) {
    $p = $prev[$id] ?? null;
    $title = "{$c['h']} {$c['hg']}-{$c['ag']} {$c['a']}";

    if ($p === null) {
        // first time we see it; only announce kickoff if it just went live
        if ($c['status'] === 'IN_PLAY') $events[] = [$id, 'kickoff', '⚽ Kickoff!', $title];
        continue;
    }

    // kickoff
    if (!in_array($p['status'], $liveStates, true) && $c['status'] === 'IN_PLAY' && $p['status'] !== 'PAUSED') {
        $events[] = [$id, 'kickoff', '⚽ Kickoff!', $title];
    }
    // goal (score increased while live)
    if (in_array($c['status'], $liveStates, true) && ($c['hg'] > $p['hg'] || $c['ag'] > $p['ag'])) {
        $scorer = $c['hg'] > $p['hg'] ? $c['h'] : $c['a'];
        $events[] = [$id, 'goal', "⚽ GOAL — $scorer!", $title];
    }
    // halftime
    if ($p['status'] === 'IN_PLAY' && $c['status'] === 'PAUSED') {
        $events[] = [$id, 'halftime', '⏸️ Half-time', $title];
    }
    // second half
    if ($p['status'] === 'PAUSED' && $c['status'] === 'IN_PLAY') {
        $events[] = [$id, 'secondhalf', '▶️ Second half', $title];
    }
    // full-time
    if (in_array($p['status'], $liveStates, true) && $c['status'] === 'FINISHED') {
        $events[] = [$id, 'fulltime', '🏁 Full-time', $title];
    }
}

// ---- send notifications ----------------------------------------------------
$sent = 0;
foreach ($events as [$id, $type, $heading, $body]) {
    if (fcmSendToTopic("match_$id", $heading, $body, ['matchId' => (string)$id, 'event' => $type])) $sent++;
    logln("EVENT match=$id $type :: $heading | $body");
}

// ---- persist snapshot (keep today's matches only to stay small) ------------
@is_dir(dirname(STATE_FILE)) || @mkdir(dirname(STATE_FILE), 0775, true);
@file_put_contents(STATE_FILE, json_encode($current));

if (php_sapi_name() !== 'cli') {
    echo json_encode(['matches' => count($current), 'events' => count($events), 'sent' => $sent]);
} else {
    logln("poll: " . count($current) . " matches, " . count($events) . " events, $sent sent");
}

// ----------------------------------------------------------------------------
// FCM HTTP v1 — send to a topic. Requires a Firebase service-account JSON.
// ----------------------------------------------------------------------------
function fcmSendToTopic($topic, $title, $body, array $data = []) {
    if (!is_file(FCM_SA_FILE) || FCM_PROJECT === 'PUT_FIREBASE_PROJECT_ID_HERE') {
        logln("FCM not configured yet — would send to $topic: $title / $body");
        return false;
    }
    $token = fcmAccessToken();
    if (!$token) return false;
    $msg = [
        'message' => [
            'topic'        => $topic,
            'notification' => ['title' => $title, 'body' => $body],
            'data'         => array_map('strval', $data),
            'android'      => ['priority' => 'high', 'notification' => ['channel_id' => 'match_events']],
        ],
    ];
    $ch = curl_init('https://fcm.googleapis.com/v1/projects/' . FCM_PROJECT . '/messages:send');
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST           => true,
        CURLOPT_POSTFIELDS     => json_encode($msg),
        CURLOPT_HTTPHEADER     => ['Authorization: Bearer ' . $token, 'Content-Type: application/json'],
        CURLOPT_SSL_VERIFYPEER => false,
        CURLOPT_SSL_VERIFYHOST => 0,
        CURLOPT_TIMEOUT        => 20,
    ]);
    $resp = curl_exec($ch);
    $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    if ($code !== 200) { logln("FCM send fail ($code): " . substr($resp, 0, 200)); return false; }
    return true;
}

// OAuth2 access token from the service account (JWT bearer grant).
function fcmAccessToken() {
    static $cached = null, $exp = 0;
    if ($cached && time() < $exp - 60) return $cached;
    $sa = json_decode(@file_get_contents(FCM_SA_FILE), true);
    if (!$sa) return null;
    $now = time();
    $claim = [
        'iss'   => $sa['client_email'],
        'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
        'aud'   => 'https://oauth2.googleapis.com/token',
        'iat'   => $now,
        'exp'   => $now + 3600,
    ];
    $b64 = fn($d) => rtrim(strtr(base64_encode($d), '+/', '-_'), '=');
    $jwtHeader = $b64(json_encode(['alg' => 'RS256', 'typ' => 'JWT']));
    $jwtClaim  = $b64(json_encode($claim));
    $sig = '';
    openssl_sign("$jwtHeader.$jwtClaim", $sig, $sa['private_key'], 'SHA256');
    $jwt = "$jwtHeader.$jwtClaim." . $b64($sig);
    $ch = curl_init('https://oauth2.googleapis.com/token');
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST           => true,
        CURLOPT_POSTFIELDS     => http_build_query([
            'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
            'assertion'  => $jwt,
        ]),
        CURLOPT_SSL_VERIFYPEER => false,
        CURLOPT_SSL_VERIFYHOST => 0,
        CURLOPT_TIMEOUT        => 20,
    ]);
    $resp = json_decode(curl_exec($ch), true);
    curl_close($ch);
    if (empty($resp['access_token'])) { logln('FCM token fail: ' . json_encode($resp)); return null; }
    $cached = $resp['access_token'];
    $exp = time() + ($resp['expires_in'] ?? 3600);
    return $cached;
}
