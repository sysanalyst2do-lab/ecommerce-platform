from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .routers import orders

app = FastAPI(
    title="E-commerce Orders API",
    description="Модуль управления заказами e-commerce платформы",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(orders.router)


@app.get("/health", tags=["system"])
def health():
    return {"status": "ok"}
