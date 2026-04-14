import os
import logging
from time import perf_counter
from uuid import uuid4

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware

from .routers import cookies, orders

logger = logging.getLogger("uvicorn.error")
if logger.level > logging.INFO:
    logger.setLevel(logging.INFO)

app = FastAPI(
    title="E-commerce Orders API",
    description="Модуль управления заказами e-commerce платформы",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

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


@app.get("/health", tags=["system"])
def health():
    return {"status": "ok"}
