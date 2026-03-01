#!/usr/bin/env python3
"""
동국대 컴퓨터·AI학부 공지사항 크롤링 서버
맥북에서 실행: python3 server.py
"""

from urllib.request import urlopen
from urllib.request import Request
from urllib.parse import urljoin
from urllib.error import URLError
from flask import Flask, jsonify
from flask_cors import CORS
from bs4 import BeautifulSoup
from apscheduler.schedulers.background import BackgroundScheduler
import re
import ssl
import time
import json

app = Flask(__name__)
CORS(app)  # iOS 앱에서 접근 가능하도록 CORS 허용

# JSON 응답 시 한글 깨짐 방지 및 정렬 설정
app.config['JSON_AS_ASCII'] = False
app.json.ensure_ascii = False
app.json.sort_keys = False
app.json.compact = False  # 줄바꿈 및 들여쓰기 활성화
app.config['JSONIFY_PRETTYPRINT_REGULAR'] = True

BASE_URL = "https://cs.dongguk.edu"
NOTICE_PATH = "/article/notice/list"
SCHOLARSHIP_PATH = "/article/collegedata/list"
CONTEST_PATH = "/article/etc/list"
JOB_PATH = "/article/job/list"

# 전역 변수로 데이터 캐싱
cached_notices = {
    "items": [],
    "total_count": 0,
    "page": 1,
    "per_page": 1000,
    "has_next": False,
    "last_updated": ""
}

cached_scholarships = {
    "items": [],
    "total_count": 0,
    "page": 1,
    "per_page": 1000,
    "has_next": False,
    "last_updated": ""
}

cached_contests = {
    "items": [],
    "total_count": 0,
    "page": 1,
    "per_page": 1000,
    "has_next": False,
    "last_updated": ""
}

cached_jobs = {
    "items": [],
    "total_count": 0,
    "page": 1,
    "per_page": 1000,
    "has_next": False,
    "last_updated": ""
}


def fetch_notices_generic(path, limit_year=None, max_pages=5):
    """범용 공지사항 크롤러: 지정된 경로에서 데이터를 가져옴"""
    all_items = []
    seen_seq = set()
    
    for page_idx in range(1, max_pages + 1):
        list_url = f"{urljoin(BASE_URL, path)}?pageIndex={page_idx}"
        
        try:
            req = Request(list_url, headers={"User-Agent": "Mozilla/5.0"})
            ctx = ssl._create_unverified_context()
            with urlopen(req, timeout=15, context=ctx) as resp:
                html = resp.read()

            soup = BeautifulSoup(html, "html.parser")
            rows_found = False

            # 테이블 기반 또는 리스트 기반 구조 파악
            # 보통 tr 또는 li 안에 데이터가 있음
            for item_container in soup.select("tr, li"):
                # onclick="goDetail('1234')" 패턴 찾기
                a_tag = item_container.find("a", onclick=True)
                if not a_tag: continue
                
                onclick = a_tag.get("onclick", "")
                m = re.search(r"goDetail\((\d+)\)", onclick)
                if not m: continue

                article_seq = m.group(1)
                if article_seq in seen_seq: continue
                seen_seq.add(article_seq)

                title = " ".join(a_tag.stripped_strings).strip()
                if not title: continue

                # 날짜 추출
                date = ""
                # .date 클래스 우선 검색, 없으면 텍스트에서 정규식 추출
                date_tag = item_container.select_one(".date")
                if date_tag:
                    date = date_tag.get_text(strip=True)
                else:
                    text_content = item_container.get_text(" ", strip=True)
                    dm = re.search(r"\d{4}-\d{2}-\d{2}", text_content)
                    date = dm.group(0) if dm else ""

                if not date: continue
                
                # 년도 제한 확인
                year = int(date.split("-")[0])
                if limit_year and year < limit_year:
                    continue

                detail_url = urljoin(BASE_URL, f"{path.replace('list', 'detail')}/{article_seq}")
                all_items.append({
                    "seq": article_seq,
                    "title": title,
                    "date": date,
                    "url": detail_url,
                    "is_new": False
                })
                rows_found = True

            if not rows_found: break
                
        except Exception as e:
            print(f"[{path}] 페이지 {page_idx} 크롤링 중 오류: {e}")
            break

    # 최신순 정렬
    all_items.sort(key=lambda x: x["date"], reverse=True)

    # [New] 표시: 가장 최근 날짜의 글들에 추가
    if all_items:
        latest_date = all_items[0]["date"]
        for item in all_items:
            if item["date"] == latest_date:
                item["title"] = f"[New] {item['title']}"
                item["is_new"] = True

    return {
        "items": all_items,
        "total_count": len(all_items),
        "page": 1,
        "per_page": 1000,
        "has_next": False
    }


def update_caches():
    """백그라운드 캐시 업데이트"""
    global cached_notices, cached_scholarships, cached_contests, cached_jobs
    print(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] 전체 크롤링 시작...")
    
    # 학부 공지 (2026년 이후만)
    try:
        cached_notices = fetch_notices_generic(NOTICE_PATH, limit_year=2026)
        cached_notices["last_updated"] = time.strftime("%Y-%m-%d %H:%M:%S")
    except Exception as e: print(f"학부공지 크롤링 실패: {e}")
    
    # 장학 정보 (모든 년도)
    try:
        cached_scholarships = fetch_notices_generic(SCHOLARSHIP_PATH, limit_year=None)
        cached_scholarships["last_updated"] = time.strftime("%Y-%m-%d %H:%M:%S")
    except Exception as e: print(f"장학정보 크롤링 실패: {e}")

    # 공모전 정보 (모든 년도)
    try:
        cached_contests = fetch_notices_generic(CONTEST_PATH, limit_year=None)
        cached_contests["last_updated"] = time.strftime("%Y-%m-%d %H:%M:%S")
    except Exception as e: print(f"공모전정보 크롤링 실패: {e}")

    # 채용 정보 (2026년 이후만)
    try:
        cached_jobs = fetch_notices_generic(JOB_PATH, limit_year=2026)
        cached_jobs["last_updated"] = time.strftime("%Y-%m-%d %H:%M:%S")
    except Exception as e: print(f"채용정보 크롤링 실패: {e}")
    
    print(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] 크롤링 완료")


@app.route("/notices", methods=["GET"])
def get_notices():
    if not cached_notices["items"]: update_caches()
    return jsonify(cached_notices)


@app.route("/scholarships", methods=["GET"])
def get_scholarships():
    if not cached_scholarships["items"]: update_caches()
    return jsonify(cached_scholarships)


@app.route("/contests", methods=["GET"])
def get_contests():
    if not cached_contests["items"]: update_caches()
    return jsonify(cached_contests)


@app.route("/jobs", methods=["GET"])
def get_jobs():
    if not cached_jobs["items"]: update_caches()
    return jsonify(cached_jobs)


@app.route("/health", methods=["GET"])
def health():
    """서버 상태 확인"""
    return jsonify({"status": "ok"})


if __name__ == "__main__":
    # 스케줄러 설정
    scheduler = BackgroundScheduler()
    # 5분(300초)마다 update_caches 함수 실행
    scheduler.add_job(func=update_caches, trigger="interval", seconds=300)
    scheduler.start()
    
    # 서버 시작 시 즉시 한 번 크롤링
    update_caches()

    print("서버 시작: http://localhost:5000")
    print("학부 공지 API: http://localhost:5000/notices")
    print("장학 정보 API: http://localhost:5000/scholarships")
    print("상태 확인: http://localhost:5000/health")
    
    try:
        app.run(host="0.0.0.0", port=5000, debug=False, use_reloader=False)
    finally:
        scheduler.shutdown()
