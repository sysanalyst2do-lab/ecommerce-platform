import base64
import hashlib
import hmac
import json
import os
import secrets
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Header, HTTPException

from ..schemas import (
    AuthLoginIn,
    AuthLogoutIn,
    AuthMeResponse,
    AuthMessageOut,
    AuthRefreshIn,
    AuthTokenResponse,
)

router = APIRouter(prefix="/api/v1/auth", tags=["auth-demo"])

JWT_SECRET = os.getenv("JWT_SECRET", "demo-jwt-secret-change-me")
JWT_ALG = "HS256"
ACCESS_TTL_SEC = int(os.getenv("JWT_ACCESS_TTL_SEC", "300"))
REFRESH_TTL_SEC = int(os.getenv("JWT_REFRESH_TTL_SEC", "86400"))

# Demo in-memory store. Enough for learning flow.
_refresh_store: dict[str, dict[str, int | str]] = {}


def _b64url_encode(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).decode().rstrip("=")


def _b64url_decode(data: str) -> bytes:
    padding = "=" * ((4 - len(data) % 4) % 4)
    return base64.urlsafe_b64decode((data + padding).encode())


def _jwt_sign(message: bytes) -> str:
    digest = hmac.new(JWT_SECRET.encode(), message, hashlib.sha256).digest()
    return _b64url_encode(digest)


def _jwt_encode(payload: dict) -> str:
    header = {"alg": JWT_ALG, "typ": "JWT"}
    header_b64 = _b64url_encode(json.dumps(header, separators=(",", ":")).encode())
    payload_b64 = _b64url_encode(json.dumps(payload, separators=(",", ":")).encode())
    signing_input = f"{header_b64}.{payload_b64}".encode()
    signature = _jwt_sign(signing_input)
    return f"{header_b64}.{payload_b64}.{signature}"


def _jwt_decode_and_validate(token: str) -> dict:
    try:
        header_b64, payload_b64, signature = token.split(".")
    except ValueError as exc:
        raise HTTPException(status_code=401, detail="invalid token format") from exc

    signing_input = f"{header_b64}.{payload_b64}".encode()
    expected_signature = _jwt_sign(signing_input)
    if not hmac.compare_digest(signature, expected_signature):
        raise HTTPException(status_code=401, detail="invalid token signature")

    payload_raw = _b64url_decode(payload_b64)
    payload = json.loads(payload_raw.decode())

    exp = payload.get("exp")
    if not isinstance(exp, int):
        raise HTTPException(status_code=401, detail="token has invalid exp")
    now_ts = int(datetime.now(timezone.utc).timestamp())
    if now_ts >= exp:
        raise HTTPException(status_code=401, detail="token expired")

    return payload


def _create_access_token(sub: str, role: str) -> tuple[str, int]:
    exp_ts = int((datetime.now(timezone.utc) + timedelta(seconds=ACCESS_TTL_SEC)).timestamp())
    payload = {"sub": sub, "role": role, "exp": exp_ts}
    return _jwt_encode(payload), exp_ts


@router.post("/login", response_model=AuthTokenResponse)
def login(body: AuthLoginIn):
    # Demo users for classroom explanation.
    users = {
        "student": {"password": "student123", "role": "student"},
        "teacher": {"password": "teacher123", "role": "teacher"},
    }
    user = users.get(body.username)
    if not user or user["password"] != body.password:
        raise HTTPException(status_code=401, detail="invalid credentials")

    access_token, access_exp_ts = _create_access_token(body.username, user["role"])
    refresh_token = secrets.token_urlsafe(48)
    refresh_exp_ts = int((datetime.now(timezone.utc) + timedelta(seconds=REFRESH_TTL_SEC)).timestamp())
    _refresh_store[refresh_token] = {"sub": body.username, "role": user["role"], "exp": refresh_exp_ts}

    now_ts = int(datetime.now(timezone.utc).timestamp())
    return AuthTokenResponse(
        access_token=access_token,
        expires_in=access_exp_ts - now_ts,
        refresh_token=refresh_token,
        refresh_expires_in=refresh_exp_ts - now_ts,
    )


@router.get("/me", response_model=AuthMeResponse)
def me(authorization: str | None = Header(default=None)):
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="missing bearer token")
    token = authorization.split(" ", 1)[1]
    payload = _jwt_decode_and_validate(token)
    return AuthMeResponse(sub=payload["sub"], role=payload["role"], exp=payload["exp"])


@router.post("/refresh", response_model=AuthTokenResponse)
def refresh(body: AuthRefreshIn):
    record = _refresh_store.get(body.refresh_token)
    now_ts = int(datetime.now(timezone.utc).timestamp())
    if not record:
        raise HTTPException(status_code=401, detail="invalid refresh token")
    if now_ts >= int(record["exp"]):
        _refresh_store.pop(body.refresh_token, None)
        raise HTTPException(status_code=401, detail="refresh token expired")

    access_token, access_exp_ts = _create_access_token(str(record["sub"]), str(record["role"]))
    new_refresh = secrets.token_urlsafe(48)
    refresh_exp_ts = int((datetime.now(timezone.utc) + timedelta(seconds=REFRESH_TTL_SEC)).timestamp())
    _refresh_store.pop(body.refresh_token, None)
    _refresh_store[new_refresh] = {"sub": str(record["sub"]), "role": str(record["role"]), "exp": refresh_exp_ts}

    return AuthTokenResponse(
        access_token=access_token,
        expires_in=access_exp_ts - now_ts,
        refresh_token=new_refresh,
        refresh_expires_in=refresh_exp_ts - now_ts,
    )


@router.post("/logout", response_model=AuthMessageOut)
def logout(body: AuthLogoutIn):
    _refresh_store.pop(body.refresh_token, None)
    return AuthMessageOut(message="logged out")
