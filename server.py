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

# 전역 변수로 데이터 캐싱
cached_notices = {
    "items": [],
    "total_count": 0,
    "page": 1,
    "per_page": 1000,
    "has_next": False,
    "last_updated": ""
}


def fetch_notice_latest(page: int = 1, per_page: int = 10):
    """학부 공지 게시판에서 2026년 이후의 모든 글을 여러 페이지에 걸쳐 가져와 페이지별로 반환"""
    all_items = []
    seen_seq = set()
    
    # 2026년 게시글이 계속 나오는 한 최대 100페이지까지 탐색
    for page_idx in range(1, 101):
        list_url = f"{urljoin(BASE_URL, NOTICE_PATH)}?pageIndex={page_idx}"
        
        try:
            req = Request(list_url, headers={"User-Agent": "Mozilla/5.0"})
            try:
                with urlopen(req, timeout=15) as resp:
                    html = resp.read()
            except URLError as e:
                if isinstance(getattr(e, "reason", None), ssl.SSLCertVerificationError):
                    ctx = ssl._create_unverified_context()
                    with urlopen(req, timeout=15, context=ctx) as resp:
                        html = resp.read()
                else:
                    raise

            soup = BeautifulSoup(html, "html.parser")
            page_has_2026 = False

            for a_tag in soup.find_all("a", onclick=True):
                onclick = a_tag.get("onclick", "")
                m = re.search(r"goDetail\((\d+)\)", onclick)
                if not m:
                    continue

                article_seq = m.group(1)
                if article_seq in seen_seq:
                    continue
                seen_seq.add(article_seq)

                title = " ".join(a_tag.stripped_strings)
                title = re.sub(r"\s+", " ", title).strip()
                if not title:
                    continue

                container = a_tag.find_parent("li") or a_tag.parent
                date = ""
                if container:
                    date_tag = container.select_one("li.date")
                    if date_tag:
                        date = date_tag.get_text(strip=True)
                    else:
                        text_block = container.get_text(" ", strip=True)
                        dm = re.search(r"\d{4}-\d{2}-\d{2}", text_block)
                        date = dm.group(0) if dm else ""

                # 날짜 조건 확인 (2026년 이후 게시글)
                if date:
                    year = int(date.split("-")[0])
                    if year >= 2026:
                        page_has_2026 = True
                        detail_url = urljoin(BASE_URL, f"/article/notice/detail/{article_seq}")
                        all_items.append({"title": title, "date": date, "url": detail_url})
                    else:
                        # 2026년 미만 글이 발견되면 더 이상 다음 페이지를 볼 필요가 없음 (최신순 게시판 가정)
                        pass

            # 해당 페이지에 2026년 글이 하나도 없었다면 탐색 중단
            if not page_has_2026:
                break
                
        except Exception as e:
            print(f"페이지 {page_idx} 크롤링 오류: {e}")
            break

    # 날짜 내림차순 정렬 (최신순)
    all_items.sort(key=lambda x: x["date"] if x["date"] else "0000-00-00", reverse=True)

    # 가장 최근 날짜의 게시글에 "New" 표시 추가
    if all_items:
        latest_date = all_items[0]["date"]
        for item in all_items:
            if item["date"] == latest_date:
                item["title"] = f"[New] {item['title']}"
                item["is_new"] = True
            else:
                item["is_new"] = False

    # 페이징 처리
    total_count = len(all_items)
    start_idx = (page - 1) * per_page
    end_idx = start_idx + per_page
    paginated_items = all_items[start_idx:end_idx]

    return {
        "items": paginated_items,
        "total_count": total_count,
        "page": page,
        "per_page": per_page,
        "has_next": end_idx < total_count
    }


@app.route("/notices", methods=["GET"])
def get_notices():
    """캐시된 학부 공지사항 데이터를 반환"""
    # 데이터가 아직 없으면 한 번 가져옴
    if not cached_notices["items"]:
        update_notices_cache()
    return jsonify(cached_notices)


def update_notices_cache():
    """백그라운드에서 실행될 크롤링 및 캐시 업데이트 함수"""
    global cached_notices
    print(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] 크롤링 시작...")
    try:
        result = fetch_notice_latest(page=1, per_page=1000)
        result["last_updated"] = time.strftime("%Y-%m-%d %H:%M:%S")
        cached_notices = result
        print(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] 크롤링 완료: {len(result['items'])}개의 공지사항 캐시됨")
    except Exception as e:
        print(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] 크롤링 실패: {e}")


@app.route("/health", methods=["GET"])
def health():
    """서버 상태 확인"""
    return jsonify({"status": "ok"})


if __name__ == "__main__":
    # 스케줄러 설정
    scheduler = BackgroundScheduler()
    # 5분(300초)마다 update_notices_cache 함수 실행
    scheduler.add_job(func=update_notices_cache, trigger="interval", seconds=300)
    scheduler.start()
    
    # 서버 시작 시 즉시 한 번 크롤링
    update_notices_cache()

    print("서버 시작: http://localhost:5000")
    print("학부 공지 API: http://localhost:5000/notices")
    print("상태 확인: http://localhost:5000/health")
    
    try:
        app.run(host="0.0.0.0", port=5000, debug=False, use_reloader=False)
    finally:
        scheduler.shutdown()
