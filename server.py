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
import re
import ssl

app = Flask(__name__)
CORS(app)  # iOS 앱에서 접근 가능하도록 CORS 허용

BASE_URL = "https://cs.dongguk.edu"
NOTICE_PATH = "/article/notice/list"


def fetch_notice_latest(page: int = 1, per_page: int = 10):
    """학부 공지 게시판에서 2026년 이후의 모든 글을 여러 페이지에 걸쳐 가져와 페이지별로 반환"""
    all_items = []
    seen_seq = set()
    
    # 2026년 이전 글이 나올 때까지 또는 최대 5페이지까지 탐색
    for page_idx in range(1, 6):
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
    """학부 공지사항의 2026년도 이후 모든 데이터를 JSON으로 반환"""
    # page 인자를 무시하고 모든 데이터를 가져오도록 fetch_notice_latest의 로직을 
    # 조금 수정하거나 per_page를 아주 크게 설정할 수 있습니다.
    # 여기서는 per_page를 1000으로 설정하여 모든 데이터를 한 번에 가져옵니다.
    result = fetch_notice_latest(page=1, per_page=1000)
    return jsonify(result)


@app.route("/health", methods=["GET"])
def health():
    """서버 상태 확인"""
    return jsonify({"status": "ok"})


if __name__ == "__main__":
    print("서버 시작: http://localhost:5000")
    print("학부 공지 API: http://localhost:5000/notices")
    print("상태 확인: http://localhost:5000/health")
    app.run(host="0.0.0.0", port=5000, debug=True)
