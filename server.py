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


def fetch_notice_latest(page: int = 1):
    """학부 공지 게시판에서 2026년 이후 글을 가져와 페이지별로 반환"""
    list_url = urljoin(BASE_URL, NOTICE_PATH)
    per_page = 10

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

        items: list[dict] = []
        seen_seq: set[str] = set()

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

            # 2026년 이후 게시글만 필터링
            if date and not (date.startswith("2026") or int(date.split("-")[0]) > 2026):
                continue

            detail_url = urljoin(BASE_URL, f"/article/notice/detail/{article_seq}")
            items.append({"title": title, "date": date, "url": detail_url})

        # 날짜 내림차순 정렬 (최신순) - 날짜가 없거나 형식이 다를 경우를 대비하여 기본값 처리
        items.sort(key=lambda x: x["date"] if x["date"] else "0000-00-00", reverse=True)

        # 페이징 처리
        total_count = len(items)
        start_idx = (page - 1) * per_page
        end_idx = start_idx + per_page
        paginated_items = items[start_idx:end_idx]

        return {
            "items": paginated_items,
            "total_count": total_count,
            "page": page,
            "per_page": per_page,
            "has_next": end_idx < total_count
        }

    except Exception as e:
        print(f"크롤링 오류: {e}")
        return {"items": [], "total_count": 0, "page": page, "has_next": False}


@app.route("/notices", methods=["GET"])
def get_notices():
    """학부 공지사항을 페이지 단위로 반환 (기본 1페이지)"""
    from flask import request
    page = request.args.get("page", default=1, type=int)
    result = fetch_notice_latest(page=page)
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
