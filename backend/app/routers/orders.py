from datetime import datetime, timezone
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session, joinedload

from ..database import get_db
from ..models import Order, OrderItem, Payment, Customer
from ..schemas import (
    OrderListResponse, OrderListItem, OrderDetail, MetaOut,
    OrderCreate, OrderCreated, StatusUpdate, StatusUpdated,
    OrderItemOut, PaymentOut, CustomerShort, CustomerFull,
    ErrorResponse,
)

router = APIRouter(prefix="/api/v1", tags=["orders"])

VALID_STATUSES = {"created", "paid", "processing", "shipped", "delivered", "cancelled"}

ALLOWED_TRANSITIONS = {
    "created": {"paid", "cancelled"},
    "paid": {"processing", "cancelled"},
    "processing": {"shipped", "cancelled"},
    "shipped": {"delivered"},
    "delivered": {"cancelled"},
    "cancelled": set(),
}


def _next_order_id() -> str:
    now = datetime.now(timezone.utc)
    short = uuid4().hex[:4].upper()
    return f"ORD-{now.year}-{short}"


# ----- LIST -----

@router.get("/orders", response_model=OrderListResponse)
def list_orders(
    status: str | None = None,
    customer_id: int | None = None,
    limit: int = Query(default=20, le=100),
    offset: int = Query(default=0, ge=0),
    db: Session = Depends(get_db),
):
    q = db.query(Order).options(joinedload(Order.customer), joinedload(Order.payment))

    if status:
        q = q.filter(Order.status == status)
    if customer_id:
        q = q.filter(Order.customer_id == customer_id)

    total = q.count()
    orders = q.order_by(Order.created_at.desc()).offset(offset).limit(limit).all()

    data = []
    for o in orders:
        data.append(OrderListItem(
            order_id=o.order_id,
            status=o.status,
            is_paid=o.is_paid,
            customer=CustomerShort.model_validate(o.customer),
            total=o.payment.total if o.payment else None,
            created_at=o.created_at,
        ))

    return OrderListResponse(data=data, total=total, limit=limit, offset=offset)


# ----- READ -----

@router.get(
    "/orders/{order_id}",
    response_model=OrderDetail,
    responses={404: {"model": ErrorResponse}},
)
def get_order(order_id: str, db: Session = Depends(get_db)):
    o = (
        db.query(Order)
        .options(joinedload(Order.customer), joinedload(Order.items), joinedload(Order.payment))
        .filter(Order.order_id == order_id)
        .first()
    )
    if not o:
        raise HTTPException(status_code=404, detail={"error": "NOT_FOUND", "message": f"Заказ {order_id} не найден"})

    return OrderDetail(
        order_id=o.order_id,
        created_at=o.created_at,
        updated_at=o.updated_at,
        status=o.status,
        is_paid=o.is_paid,
        comment=o.comment,
        meta=MetaOut(source=o.source, ip=o.ip, tags=o.tags),
        customer=CustomerFull.model_validate(o.customer),
        items=[OrderItemOut.model_validate(i) for i in o.items],
        payment=PaymentOut.model_validate(o.payment) if o.payment else None,
    )


# ----- CREATE -----

@router.post(
    "/orders",
    response_model=OrderCreated,
    status_code=201,
    responses={400: {"model": ErrorResponse}},
)
def create_order(body: OrderCreate, db: Session = Depends(get_db)):
    customer = db.query(Customer).get(body.customer_id)
    if not customer:
        raise HTTPException(400, detail={"error": "VALIDATION_ERROR", "message": f"Клиент {body.customer_id} не найден"})

    order = Order(
        order_id=_next_order_id(),
        customer_id=body.customer_id,
        status="created",
        is_paid=False,
        comment=body.comment,
        source=body.source,
        tags=body.tags,
    )

    for item in body.items:
        order.items.append(OrderItem(
            product_id=item.product_id,
            name=item.name,
            quantity=item.quantity,
            price=item.price,
            in_stock=item.in_stock,
        ))

    if body.payment:
        order.payment = Payment(
            method=body.payment.method,
            total=body.payment.total,
            currency=body.payment.currency,
        )

    db.add(order)
    db.commit()
    db.refresh(order)

    return OrderCreated(
        order_id=order.order_id,
        status=order.status,
        is_paid=order.is_paid,
        created_at=order.created_at,
    )


# ----- UPDATE STATUS -----

@router.patch(
    "/orders/{order_id}/status",
    response_model=StatusUpdated,
    responses={404: {"model": ErrorResponse}, 422: {"model": ErrorResponse}},
)
def update_status(order_id: str, body: StatusUpdate, db: Session = Depends(get_db)):
    order = db.query(Order).filter(Order.order_id == order_id).first()
    if not order:
        raise HTTPException(404, detail={"error": "NOT_FOUND", "message": f"Заказ {order_id} не найден"})

    if body.status not in VALID_STATUSES:
        raise HTTPException(422, detail={"error": "INVALID_STATUS", "message": f"Неизвестный статус '{body.status}'"})

    allowed = ALLOWED_TRANSITIONS.get(order.status, set())
    if body.status not in allowed:
        raise HTTPException(422, detail={
            "error": "INVALID_TRANSITION",
            "message": f"Нельзя перевести заказ из '{order.status}' в '{body.status}'",
        })

    order.status = body.status
    if body.status == "paid":
        order.is_paid = True
    order.updated_at = datetime.now(timezone.utc)

    db.commit()
    db.refresh(order)

    return StatusUpdated(order_id=order.order_id, status=order.status, updated_at=order.updated_at)


# ----- DELETE -----

@router.delete(
    "/orders/{order_id}",
    status_code=204,
    responses={404: {"model": ErrorResponse}},
)
def delete_order(order_id: str, db: Session = Depends(get_db)):
    order = db.query(Order).filter(Order.order_id == order_id).first()
    if not order:
        raise HTTPException(404, detail={"error": "NOT_FOUND", "message": f"Заказ {order_id} не найден"})

    db.delete(order)
    db.commit()
