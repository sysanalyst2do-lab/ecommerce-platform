import os
import smtplib
from email.message import EmailMessage

from fastapi import APIRouter, HTTPException

from ..schemas import MailTestIn, MailTestOut

router = APIRouter(prefix="/api/v1/mail", tags=["smtp-demo"])


@router.post("/test", response_model=MailTestOut)
def send_test_mail(body: MailTestIn):
    smtp_host = os.getenv("SMTP_HOST", "mailhog")
    smtp_port = int(os.getenv("SMTP_PORT", "1025"))
    smtp_from = os.getenv("SMTP_FROM", "no-reply@ecommerce.local")
    smtp_timeout = int(os.getenv("SMTP_TIMEOUT_SEC", "5"))

    msg = EmailMessage()
    msg["From"] = smtp_from
    msg["To"] = body.to
    msg["Subject"] = body.subject
    msg.set_content(body.body)

    try:
        with smtplib.SMTP(host=smtp_host, port=smtp_port, timeout=smtp_timeout) as client:
            client.send_message(msg)
    except Exception as exc:
        raise HTTPException(status_code=502, detail=f"smtp send failed: {exc}") from exc

    return MailTestOut(
        message="mail queued",
        smtp_host=smtp_host,
        smtp_port=smtp_port,
    )
