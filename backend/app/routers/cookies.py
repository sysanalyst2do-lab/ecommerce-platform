from uuid import uuid4

from fastapi import APIRouter, Request, Response
from pydantic import BaseModel, Field

router = APIRouter(prefix="/api/v1/cookies", tags=["cookies-demo"])

# Для локального HTTP-демо Secure=False.
# Для production обязательно Secure=True и HTTPS.
COOKIE_SECURE = False


class PreferencesIn(BaseModel):
    locale: str = Field(default="ru-RU")
    cookie_consent: str = Field(default="necessary_only")
    last_visited_item: str | None = None


def _set_cookie(
    response: Response,
    *,
    key: str,
    value: str,
    max_age: int,
    httponly: bool,
    samesite: str,
) -> None:
    response.set_cookie(
        key=key,
        value=value,
        max_age=max_age,
        secure=COOKIE_SECURE,
        httponly=httponly,
        samesite=samesite,
        path="/",
    )


@router.get("/status")
def cookie_status(request: Request):
    cookies = request.cookies
    return {
        "sessionId_present": "sessionId" in cookies,
        "csrfToken_present": "csrfToken" in cookies,
        "cartId": cookies.get("cartId"),
        "locale": cookies.get("locale"),
        "lastVisitedItem": cookies.get("lastVisitedItem"),
        "cookieConsent": cookies.get("cookieConsent"),
    }


@router.post("/session/start")
def start_session(response: Response):
    _set_cookie(
        response,
        key="sessionId",
        value=f"sid-{uuid4().hex}",
        max_age=30 * 60,
        httponly=True,
        samesite="lax",
    )
    _set_cookie(
        response,
        key="csrfToken",
        value=uuid4().hex,
        max_age=30 * 60,
        httponly=False,
        samesite="strict",
    )
    return {"message": "Учебная сессия создана (sessionId + csrfToken)."}


@router.post("/session/end")
def end_session(response: Response):
    response.delete_cookie("sessionId", path="/")
    response.delete_cookie("csrfToken", path="/")
    return {"message": "Учебная сессия завершена (sessionId + csrfToken удалены)."}


@router.post("/cart/ensure")
def ensure_cart(response: Response):
    _set_cookie(
        response,
        key="cartId",
        value=f"cart-{uuid4().hex[:12]}",
        max_age=14 * 24 * 60 * 60,
        httponly=False,
        samesite="lax",
    )
    return {"message": "cartId установлен/обновлен."}


@router.post("/preferences")
def set_preferences(body: PreferencesIn, response: Response):
    _set_cookie(
        response,
        key="locale",
        value=body.locale,
        max_age=90 * 24 * 60 * 60,
        httponly=False,
        samesite="lax",
    )
    _set_cookie(
        response,
        key="cookieConsent",
        value=body.cookie_consent,
        max_age=365 * 24 * 60 * 60,
        httponly=False,
        samesite="lax",
    )
    if body.last_visited_item:
        _set_cookie(
            response,
            key="lastVisitedItem",
            value=body.last_visited_item,
            max_age=30 * 24 * 60 * 60,
            httponly=False,
            samesite="lax",
        )
    return {"message": "Настройки cookie сохранены."}


@router.post("/analytics/disable")
def disable_analytics(response: Response):
    # В учебном примере analytics_id не используем постоянно, но показываем,
    # как корректно отзывать analytics-cookie при отказе от согласия.
    response.delete_cookie("analytics_id", path="/")
    return {"message": "analytics_id удален (если был установлен)."}
