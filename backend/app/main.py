import os
import logging
from datetime import datetime, timezone
from pathlib import Path
from time import perf_counter
from typing import Literal
from uuid import uuid4

from fastapi import FastAPI, HTTPException, Query, Request
from fastapi.openapi.docs import get_redoc_html, get_swagger_ui_html
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, PlainTextResponse
from sqlalchemy import text

from .database import SessionLocal
from .routers import auth, cookies, mail, orders

logger = logging.getLogger("uvicorn.error")
if logger.level > logging.INFO:
    logger.setLevel(logging.INFO)

app = FastAPI(
    title="E-commerce Orders API",
    description="Модуль управления заказами e-commerce платформы",
    version="1.0.0",
    docs_url=None,
    redoc_url=None,
    openapi_url=None,
)

def _resolve_openapi_file() -> Path:
    # Priority for container deployments: explicit mount point.
    candidates = [
        Path("/app/openapi.yaml"),
        Path(__file__).resolve().parents[2] / "openapi.yaml",
        Path(__file__).resolve().parents[1] / "openapi.yaml",
        Path.cwd() / "openapi.yaml",
    ]
    for path in candidates:
        if path.exists():
            return path
    return candidates[0]


OPENAPI_FILE = _resolve_openapi_file()
APP_STARTED_AT = datetime.now(timezone.utc)

_default_cors = "http://localhost:3000,https://demo2dev.ru,https://www.demo2dev.ru"
_cors_origins = [
    o.strip()
    for o in os.getenv("CORS_ORIGINS", _default_cors).split(",")
    if o.strip()
]
_http_request_logs_enabled = os.getenv("HTTP_REQUEST_LOGS", "1").lower() in {"1", "true", "yes", "on"}

app.add_middleware(
    CORSMiddleware,
    allow_origins=_cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.middleware("http")
async def log_http_requests(request: Request, call_next):
    if not _http_request_logs_enabled:
        return await call_next(request)

    request_id = request.headers.get("x-request-id") or uuid4().hex[:12]
    client_ip = request.client.host if request.client else "-"
    query = request.url.query or "-"
    started_at = perf_counter()

    logger.info(
        "REQUEST START id=%s method=%s path=%s query=%s client=%s",
        request_id,
        request.method,
        request.url.path,
        query,
        client_ip,
    )

    try:
        response = await call_next(request)
    except Exception:
        duration_ms = (perf_counter() - started_at) * 1000
        logger.exception(
            "REQUEST ERROR id=%s method=%s path=%s query=%s duration_ms=%.2f",
            request_id,
            request.method,
            request.url.path,
            query,
            duration_ms,
        )
        raise

    duration_ms = (perf_counter() - started_at) * 1000
    response.headers["X-Request-ID"] = request_id
    logger.info(
        "REQUEST END id=%s method=%s path=%s status=%s duration_ms=%.2f",
        request_id,
        request.method,
        request.url.path,
        response.status_code,
        duration_ms,
    )
    return response


app.include_router(orders.router)
app.include_router(cookies.router)
app.include_router(auth.router)
app.include_router(mail.router)


@app.get("/openapi.yaml", include_in_schema=False)
def openapi_yaml():
    if not OPENAPI_FILE.exists():
        raise HTTPException(status_code=500, detail="openapi.yaml file is not found on server")
    return FileResponse(OPENAPI_FILE, media_type="application/yaml")


@app.get("/docs", include_in_schema=False)
def custom_swagger():
    return get_swagger_ui_html(
        openapi_url="/openapi.yaml",
        title="E-commerce Orders API - Swagger UI",
    )


@app.get("/redoc", include_in_schema=False)
def custom_redoc():
    return get_redoc_html(
        openapi_url="/openapi.yaml",
        title="E-commerce Orders API - ReDoc",
    )


@app.get("/health", tags=["system"])
def health(
    level: Literal["basic", "full"] = Query(default="basic"),
    check: str | None = Query(default=None, description="CSV: db,openapi"),
    timeout_ms: int = Query(default=1000, ge=100, le=10000),
    output_format: Literal["json", "plain"] = Query(default="json", alias="format"),
    verbose: bool = Query(default=True),
    include: str | None = Query(default=None, description="CSV: version,uptime,build"),
):
    available_checks = {"db", "openapi"}
    available_meta = {"version", "uptime", "build"}

    if include:
        requested_meta = {item.strip().lower() for item in include.split(",") if item.strip()}
        unknown_meta = sorted(requested_meta - available_meta)
        if unknown_meta:
            raise HTTPException(
                status_code=422,
                detail={
                    "error": "INVALID_INCLUDE",
                    "message": f"Неизвестные include-поля: {', '.join(unknown_meta)}. Доступно: version, uptime, build",
                },
            )
    else:
        requested_meta = set()

    if level == "basic" and not check:
        if output_format == "plain":
            return PlainTextResponse("ok")
        return {"status": "ok"}

    if check:
        requested_checks = {item.strip().lower() for item in check.split(",") if item.strip()}
        unknown = sorted(requested_checks - available_checks)
        if unknown:
            raise HTTPException(
                status_code=422,
                detail={
                    "error": "INVALID_CHECK",
                    "message": f"Неизвестные проверки: {', '.join(unknown)}. Доступно: db, openapi",
                },
            )
    else:
        requested_checks = set(available_checks)

    checks_result: dict[str, dict] = {}

    if "db" in requested_checks:
        started = perf_counter()
        try:
            with SessionLocal() as db:
                db.execute(text("SELECT 1"))
            latency_ms = round((perf_counter() - started) * 1000, 2)
            if latency_ms > timeout_ms:
                checks_result["db"] = {
                    "status": "down",
                    "latency_ms": latency_ms,
                    "error": f"timeout: {latency_ms}ms > {timeout_ms}ms",
                }
            else:
                checks_result["db"] = {"status": "ok", "latency_ms": latency_ms}
        except Exception as exc:
            latency_ms = round((perf_counter() - started) * 1000, 2)
            checks_result["db"] = {"status": "down", "latency_ms": latency_ms, "error": str(exc)}

    if "openapi" in requested_checks:
        started = perf_counter()
        if not OPENAPI_FILE.exists():
            latency_ms = round((perf_counter() - started) * 1000, 2)
            checks_result["openapi"] = {
                "status": "down",
                "latency_ms": latency_ms,
                "error": f"file is not found: {OPENAPI_FILE}",
            }
        else:
            latency_ms = round((perf_counter() - started) * 1000, 2)
            checks_result["openapi"] = {"status": "ok", "latency_ms": latency_ms}

    overall = "ok" if all(item.get("status") == "ok" for item in checks_result.values()) else "degraded"
    if not verbose:
        checks_result = {name: {"status": result["status"]} for name, result in checks_result.items()}

    payload = {
        "status": overall,
        "level": level,
        "checked_at": datetime.now(timezone.utc).isoformat(),
        "checked": sorted(requested_checks),
        "timeout_ms": timeout_ms,
        "checks": checks_result,
    }

    if "version" in requested_meta:
        payload["version"] = app.version
    if "build" in requested_meta:
        payload["build"] = os.getenv("APP_BUILD", "unknown")
    if "uptime" in requested_meta:
        payload["uptime_sec"] = int((datetime.now(timezone.utc) - APP_STARTED_AT).total_seconds())

    if output_format == "plain":
        lines = [
            f"status={payload['status']}",
            f"level={payload['level']}",
            f"checked={','.join(payload['checked'])}",
            f"timeout_ms={payload['timeout_ms']}",
        ]
        for check_name, check_item in payload["checks"].items():
            check_line = f"check.{check_name}={check_item['status']}"
            if verbose and "latency_ms" in check_item:
                check_line += f" latency_ms={check_item['latency_ms']}"
            if verbose and "error" in check_item:
                check_line += f" error={check_item['error']}"
            lines.append(check_line)
        if "version" in payload:
            lines.append(f"version={payload['version']}")
        if "build" in payload:
            lines.append(f"build={payload['build']}")
        if "uptime_sec" in payload:
            lines.append(f"uptime_sec={payload['uptime_sec']}")
        return PlainTextResponse("\n".join(lines))

    return payload
