import jwt, time, json, sys, urllib.request, urllib.error

KEY_ID = "X7MXAWBL42"
ISSUER = "00048ee3-397d-4241-aff0-291a343c10a8"
P8 = r"D:\apple-keys\AuthKey_X7MXAWBL42.p8"
APP_ID = "6775846030"
BASE = "https://api.appstoreconnect.apple.com"

with open(P8) as f:
    private_key = f.read()

def token():
    now = int(time.time())
    payload = {"iss": ISSUER, "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"}
    return jwt.encode(payload, private_key, algorithm="ES256", headers={"kid": KEY_ID, "typ": "JWT"})

def api(method, path, body=None):
    url = path if path.startswith("http") else BASE + path
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header("Authorization", "Bearer " + token())
    req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req) as r:
            txt = r.read().decode()
            return r.status, (json.loads(txt) if txt else {})
    except urllib.error.HTTPError as e:
        txt = e.read().decode()
        try:
            return e.code, json.loads(txt)
        except Exception:
            return e.code, {"raw": txt}

def cmd_state():
    out = {}
    s, app = api("GET", f"/v1/apps/{APP_ID}?include=appStoreVersions&fields[appStoreVersions]=versionString,appStoreState,platform")
    out["app_status"] = s
    vers = []
    for v in app.get("included", []):
        if v["type"] == "appStoreVersions":
            vers.append({"id": v["id"], **v["attributes"]})
    out["versions"] = vers
    # review submissions
    s2, rs = api("GET", f"/v1/reviewSubmissions?filter[app]={APP_ID}&filter[state]=READY_FOR_REVIEW,WAITING_FOR_REVIEW,IN_REVIEW,UNRESOLVED_ISSUES")
    out["reviewSubmissions_status"] = s2
    out["reviewSubmissions"] = [{"id": r["id"], **r["attributes"]} for r in rs.get("data", [])]
    # app info localizations (for name)
    s3, infos = api("GET", f"/v1/apps/{APP_ID}/appInfos")
    out["appInfos"] = [{"id": i["id"], **i["attributes"]} for i in infos.get("data", [])]
    print(json.dumps(out, indent=2, ensure_ascii=False))

def cmd_cancel():
    # cancel all active review submissions (WAITING/IN_REVIEW/READY/UNRESOLVED)
    s, rs = api("GET", f"/v1/reviewSubmissions?filter[app]={APP_ID}&filter[state]=READY_FOR_REVIEW,WAITING_FOR_REVIEW,IN_REVIEW,UNRESOLVED_ISSUES")
    for r in rs.get("data", []):
        rid = r["id"]
        st = r["attributes"]["state"]
        code, resp = api("PATCH", f"/v1/reviewSubmissions/{rid}", {
            "data": {"type": "reviewSubmissions", "id": rid, "attributes": {"canceled": True}}
        })
        print(f"cancel {rid} (was {st}) -> {code} {resp.get('data',{}).get('attributes',{}).get('state', resp)}")

def cmd_rename():
    new_name = sys.argv[2]
    s, infos = api("GET", f"/v1/apps/{APP_ID}/appInfos")
    for i in infos.get("data", []):
        info_id = i["id"]
        st = i["attributes"]["state"]
        # get localizations for this appInfo
        s2, locs = api("GET", f"/v1/appInfos/{info_id}/appInfoLocalizations")
        for loc in locs.get("data", []):
            lid = loc["id"]
            locale = loc["attributes"]["locale"]
            cur = loc["attributes"].get("name")
            code, resp = api("PATCH", f"/v1/appInfoLocalizations/{lid}", {
                "data": {"type": "appInfoLocalizations", "id": lid, "attributes": {"name": new_name}}
            })
            newv = resp.get("data", {}).get("attributes", {}).get("name", resp)
            print(f"appInfo {info_id}({st}) loc {locale}: '{cur}' -> {code} '{newv}'")

def cmd_tryname():
    candidates = sys.argv[2:]
    s, infos = api("GET", f"/v1/apps/{APP_ID}/appInfos")
    info = infos["data"][0]
    info_id = info["id"]
    s2, locs = api("GET", f"/v1/appInfos/{info_id}/appInfoLocalizations")
    loc = locs["data"][0]
    lid = loc["id"]
    for name in candidates:
        code, resp = api("PATCH", f"/v1/appInfoLocalizations/{lid}", {
            "data": {"type": "appInfoLocalizations", "id": lid, "attributes": {"name": name}}
        })
        if code == 200:
            print(f"AVAILABLE & SET: '{name}'")
            return
        else:
            errs = resp.get("errors", [{}])[0]
            print(f"taken/err: '{name}' -> {code} {errs.get('code','')}")
    print("NONE available")

def cmd_setversion():
    newv = sys.argv[2]
    s, app = api("GET", f"/v1/apps/{APP_ID}/appStoreVersions?filter[appStoreState]=DEVELOPER_REJECTED,PREPARE_FOR_SUBMISSION,REJECTED,METADATA_REJECTED&limit=1")
    vid = app["data"][0]["id"]
    code, resp = api("PATCH", f"/v1/appStoreVersions/{vid}", {
        "data": {"type": "appStoreVersions", "id": vid, "attributes": {"versionString": newv}}
    })
    print(f"set versionString={newv} on {vid}: {code} {resp.get('data',{}).get('attributes',{}).get('versionString', resp if code>=400 else '')}")

def cmd_builds():
    s, b = api("GET", f"/v1/builds?filter[app]={APP_ID}&sort=-uploadedDate&limit=8&include=preReleaseVersion&fields[builds]=version,processingState,uploadedDate")
    incl = {x['id']: x for x in b.get('included', [])}
    for x in b.get("data", []):
        a = x["attributes"]
        pv = x.get("relationships", {}).get("preReleaseVersion", {}).get("data")
        vs = incl.get(pv["id"], {}).get("attributes", {}).get("version") if pv else "?"
        print(f"build {x['id']} v{vs} build#{a.get('version')} state={a.get('processingState')} uploaded={a.get('uploadedDate')}")

def cmd_attach():
    build_id = sys.argv[2]
    s, app = api("GET", f"/v1/apps/{APP_ID}/appStoreVersions?filter[appStoreState]=DEVELOPER_REJECTED,PREPARE_FOR_SUBMISSION,REJECTED,METADATA_REJECTED&limit=1")
    vid = app["data"][0]["id"]
    code, resp = api("PATCH", f"/v1/appStoreVersions/{vid}", {
        "data": {"type": "appStoreVersions", "id": vid,
                 "relationships": {"build": {"data": {"type": "builds", "id": build_id}}}}
    })
    print(f"attach build {build_id} -> version {vid}: {code}")
    if code >= 400: print(resp)

def cmd_submit():
    # find editable version
    s, app = api("GET", f"/v1/apps/{APP_ID}/appStoreVersions?filter[appStoreState]=DEVELOPER_REJECTED,PREPARE_FOR_SUBMISSION,REJECTED,METADATA_REJECTED&limit=1")
    vid = app["data"][0]["id"]
    # reuse an existing open reviewSubmission or create one
    s2, rs = api("GET", f"/v1/reviewSubmissions?filter[app]={APP_ID}&filter[state]=READY_FOR_REVIEW")
    if rs.get("data"):
        sub_id = rs["data"][0]["id"]
        print(f"reusing reviewSubmission {sub_id}")
    else:
        code, resp = api("POST", "/v1/reviewSubmissions", {
            "data": {"type": "reviewSubmissions", "attributes": {"platform": "IOS"},
                     "relationships": {"app": {"data": {"type": "apps", "id": APP_ID}}}}
        })
        sub_id = resp["data"]["id"]
        print(f"created reviewSubmission {sub_id}: {code}")
    # check items
    si, items = api("GET", f"/v1/reviewSubmissions/{sub_id}/items")
    has = any(it.get("relationships", {}).get("appStoreVersion", {}).get("data", {}).get("id") == vid for it in items.get("data", []))
    if not has:
        code, resp = api("POST", "/v1/reviewSubmissionItems", {
            "data": {"type": "reviewSubmissionItems",
                     "relationships": {"reviewSubmission": {"data": {"type": "reviewSubmissions", "id": sub_id}},
                                       "appStoreVersion": {"data": {"type": "appStoreVersions", "id": vid}}}}
        })
        print(f"add item version {vid}: {code}")
        if code >= 400: print(resp); return
    else:
        print("version already an item")
    # submit
    code, resp = api("PATCH", f"/v1/reviewSubmissions/{sub_id}", {
        "data": {"type": "reviewSubmissions", "id": sub_id, "attributes": {"submitted": True}}
    })
    print(f"SUBMIT -> {code} {resp.get('data',{}).get('attributes',{}).get('state', resp)}")

if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "state"
    {"state": cmd_state, "cancel": cmd_cancel, "rename": cmd_rename, "tryname": cmd_tryname,
     "setversion": cmd_setversion, "builds": cmd_builds, "attach": cmd_attach, "submit": cmd_submit}[cmd]()
