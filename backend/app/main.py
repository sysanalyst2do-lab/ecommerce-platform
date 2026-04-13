import os

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .routers import cookies, orders

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

app.add_middleware(
    CORSMiddleware,
    allow_origins=_cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(orders.router)
app.include_router(cookies.router)


@app.get("/health", tags=["system"])
def health():
    return {"status": "ok"}
