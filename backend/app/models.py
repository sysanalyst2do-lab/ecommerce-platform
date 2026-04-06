from sqlalchemy import (
    Column, Integer, String, Text, Numeric, Boolean,
    ForeignKey, DateTime, ARRAY, CheckConstraint,
)
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from .database import Base


class Customer(Base):
    __tablename__ = "customers"

    id = Column(Integer, primary_key=True)
    name = Column(String(100), nullable=False)
    email = Column(String(255), nullable=False, unique=True)
    phone = Column(String(20))
    is_verified = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    orders = relationship("Order", back_populates="customer")


class Order(Base):
    __tablename__ = "orders"

    order_id = Column(String(20), primary_key=True)
    customer_id = Column(Integer, ForeignKey("customers.id"), nullable=False)
    status = Column(String(20), nullable=False, default="created")
    is_paid = Column(Boolean, nullable=False, default=False)
    comment = Column(Text)
    source = Column(String(20))
    ip = Column(String(45))
    tags = Column(ARRAY(Text))
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    customer = relationship("Customer", back_populates="orders")
    items = relationship("OrderItem", back_populates="order", cascade="all, delete-orphan")
    payment = relationship("Payment", back_populates="order", uselist=False, cascade="all, delete-orphan")

    __table_args__ = (
        CheckConstraint(
            "status IN ('created','paid','processing','shipped','delivered','cancelled')",
            name="ck_order_status",
        ),
    )


class OrderItem(Base):
    __tablename__ = "order_items"

    id = Column(Integer, primary_key=True)
    order_id = Column(String(20), ForeignKey("orders.order_id", ondelete="CASCADE"), nullable=False)
    product_id = Column(String(20), nullable=False)
    name = Column(String(255), nullable=False)
    quantity = Column(Integer, nullable=False)
    price = Column(Numeric(10, 2), nullable=False)
    in_stock = Column(Boolean, default=True)

    order = relationship("Order", back_populates="items")


class Payment(Base):
    __tablename__ = "payments"

    id = Column(Integer, primary_key=True)
    order_id = Column(String(20), ForeignKey("orders.order_id", ondelete="CASCADE"), nullable=False)
    method = Column(String(20), nullable=False)
    total = Column(Numeric(10, 2), nullable=False)
    currency = Column(String(3), default="RUB")
    paid_at = Column(DateTime(timezone=True))

    order = relationship("Order", back_populates="payment")
