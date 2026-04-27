from __future__ import annotations
from datetime import datetime
from decimal import Decimal
from pydantic import BaseModel, Field


# ---------- Customer ----------

class CustomerShort(BaseModel):
    id: int
    name: str
    model_config = {"from_attributes": True}


class CustomerFull(CustomerShort):
    email: str
    phone: str | None = None


# ---------- OrderItem ----------

class OrderItemOut(BaseModel):
    product_id: str
    name: str
    quantity: int
    price: Decimal
    in_stock: bool
    model_config = {"from_attributes": True}


class OrderItemIn(BaseModel):
    product_id: str
    name: str
    quantity: int = Field(gt=0)
    price: Decimal = Field(ge=0)
    in_stock: bool = True


# ---------- Payment ----------

class PaymentOut(BaseModel):
    method: str
    total: Decimal
    currency: str
    paid_at: datetime | None = None
    model_config = {"from_attributes": True}


class PaymentIn(BaseModel):
    method: str
    total: Decimal = Field(gt=0)
    currency: str = "RUB"


# ---------- Order ----------

class MetaOut(BaseModel):
    source: str | None = None
    ip: str | None = None
    tags: list[str] | None = None


class OrderListItem(BaseModel):
    order_id: str
    status: str
    is_paid: bool
    customer: CustomerShort
    total: Decimal | None = None
    created_at: datetime
    model_config = {"from_attributes": True}


class OrderListResponse(BaseModel):
    data: list[OrderListItem]
    total: int
    limit: int
    offset: int


class OrderDetail(BaseModel):
    order_id: str
    created_at: datetime
    updated_at: datetime
    status: str
    is_paid: bool
    comment: str | None = None
    meta: MetaOut
    customer: CustomerFull
    items: list[OrderItemOut]
    payment: PaymentOut | None = None
    model_config = {"from_attributes": True}


class OrderCreate(BaseModel):
    customer_id: int
    comment: str | None = None
    source: str | None = None
    tags: list[str] | None = None
    items: list[OrderItemIn] = Field(min_length=1)
    payment: PaymentIn | None = None


class OrderCreated(BaseModel):
    order_id: str
    status: str
    is_paid: bool
    created_at: datetime


class StatusUpdate(BaseModel):
    status: str


class StatusUpdated(BaseModel):
    order_id: str
    status: str
    updated_at: datetime


class ErrorResponse(BaseModel):
    error: str
    message: str


# ---------- Auth (JWT demo) ----------

class AuthLoginIn(BaseModel):
    username: str
    password: str


class AuthTokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: int
    refresh_token: str
    refresh_expires_in: int


class AuthRefreshIn(BaseModel):
    refresh_token: str


class AuthMeResponse(BaseModel):
    sub: str
    role: str
    exp: int


class AuthLogoutIn(BaseModel):
    refresh_token: str


class AuthMessageOut(BaseModel):
    message: str


# ---------- SMTP demo ----------

class MailTestIn(BaseModel):
    to: str
    subject: str = "SMTP demo message"
    body: str = "Hello from ecommerce-platform SMTP demo."


class MailTestOut(BaseModel):
    message: str
    smtp_host: str
    smtp_port: int
