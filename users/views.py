"""Auth views — register, verify email, login, password reset, user profile."""
import secrets

from django.conf import settings
from django.contrib.auth import get_user_model
from django.core.mail import send_mail
from django.utils.decorators import method_decorator
from django_ratelimit.decorators import ratelimit
from rest_framework import status
from rest_framework.authtoken.models import Token
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import EmailVerificationToken, PasswordResetToken
from .serializers import (
    LoginSerializer,
    PasswordResetConfirmSerializer,
    PasswordResetRequestSerializer,
    RegisterSerializer,
    UserSerializer,
    VerifyEmailSerializer,
)

User = get_user_model()


@method_decorator(ratelimit(key="ip", rate="3/h", method="POST", block=False), name="post")
class RegisterView(APIView):
    """Create a new user account. Rate-limited to 3 registrations per hour per IP."""

    permission_classes = [AllowAny]

    def post(self, request):
        # Check rate limit was not exceeded
        was_limited = getattr(request, "limited", False)
        if was_limited:
            return Response(
                {"error": "Too many registration attempts. Please try again later."},
                status=status.HTTP_429_TOO_MANY_REQUESTS,
            )

        serializer = RegisterSerializer(data=request.data)
        if not serializer.is_valid():
            # Return field-level errors
            errors = {}
            for field, msgs in serializer.errors.items():
                errors[field] = msgs[0] if isinstance(msgs, list) else str(msgs)
            return Response({"errors": errors}, status=status.HTTP_400_BAD_REQUEST)

        user = serializer.save()

        return Response(
            {
                "message": (
                    "Account created! Please check your email "
                    f"({user.email}) for a verification link."
                ),
                "user_id": user.id,
                "username": user.username,
                "email": user.email,
            },
            status=status.HTTP_201_CREATED,
        )


class VerifyEmailView(APIView):
    """Verify email address with token from registration email."""

    permission_classes = [AllowAny]

    def get(self, request):
        serializer = VerifyEmailSerializer(data=request.query_params)
        if not serializer.is_valid():
            return Response(
                {"error": "Invalid or missing verification token."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        token_str = serializer.validated_data["token"]

        try:
            token = EmailVerificationToken.objects.get(token=token_str, is_used=False)
        except EmailVerificationToken.DoesNotExist:
            return Response(
                {"error": "Invalid or already used verification token."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if token.is_expired():
            return Response(
                {"error": "Verification link has expired. Please register again."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Activate user
        user = token.user
        user.is_active = True
        user.save()

        # Mark token as used
        token.is_used = True
        token.save()

        return Response(
            {
                "message": "Email verified successfully! You can now log in.",
                "username": user.username,
                "email": user.email,
            }
        )


class LoginView(APIView):
    """Log in with username/email and password. Returns auth token.

    Rate-limited to 10 attempts per 15 minutes per IP to slow brute force
    (django-axes provides the harder lockout on top).
    """

    permission_classes = [AllowAny]

    @method_decorator(ratelimit(key="ip", rate="10/15m", method="POST", block=False))
    def post(self, request):
        if getattr(request, "limited", False):
            return Response(
                {"error": "Too many login attempts. Please wait a few minutes."},
                status=status.HTTP_429_TOO_MANY_REQUESTS,
            )
        serializer = LoginSerializer(data=request.data,
                                      context={"request": request})
        if not serializer.is_valid():
            error = list(serializer.errors.values())[0]
            msg = error[0] if isinstance(error, list) else str(error)
            return Response({"error": msg}, status=status.HTTP_401_UNAUTHORIZED)

        user = serializer.validated_data["user"]

        # Get or create auth token
        token, _ = Token.objects.get_or_create(user=user)

        return Response(
            {
                "token": token.key,
                "user": UserSerializer(user).data,
            }
        )


class LogoutView(APIView):
    """Log out by deleting the auth token."""

    permission_classes = [IsAuthenticated]

    def post(self, request):
        request.user.auth_token.delete()
        return Response({"message": "Logged out successfully."})


class UserProfileView(APIView):
    """Get the current user's profile."""

    permission_classes = [IsAuthenticated]

    def get(self, request):
        return Response(UserSerializer(request.user).data)


class PasswordResetRequestView(APIView):
    """Step 1 — email a 6-digit reset code. Never reveals whether the email exists.

    Rate-limited to 5 requests per hour per IP.
    """

    permission_classes = [AllowAny]

    @method_decorator(ratelimit(key="ip", rate="5/h", method="POST", block=False))
    def post(self, request):
        if getattr(request, "limited", False):
            return Response(
                {"error": "Too many requests. Please try again in an hour."},
                status=status.HTTP_429_TOO_MANY_REQUESTS,
            )

        serializer = PasswordResetRequestSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(
                {"error": "Enter a valid email address."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        email = serializer.validated_data["email"]
        user = User.objects.filter(email__iexact=email).first()

        # Same response whether or not the account exists (no account probing).
        generic = {"message": "If that email is registered, a reset code is on its way."}
        if user is None:
            return Response(generic)

        # Invalidate any outstanding codes for this user.
        PasswordResetToken.objects.filter(user=user, is_used=False).update(is_used=True)
        code = f"{secrets.randbelow(1_000_000):06d}"
        PasswordResetToken.objects.create(user=user, code=code)

        try:
            send_mail(
                subject="Your CalCity password reset code",
                message=(
                    f"Hi {user.username},\n\n"
                    f"Your CalCity password reset code is: {code}\n\n"
                    f"Enter it in the app within 30 minutes to set a new password.\n\n"
                    f"If you didn't request this, you can safely ignore this email.\n\n"
                    f"— The CalCity Team"
                ),
                from_email=settings.DEFAULT_FROM_EMAIL,
                recipient_list=[user.email],
                fail_silently=True,
            )
        except Exception:
            pass  # Never block the request on email delivery issues

        return Response(generic)


class PasswordResetConfirmView(APIView):
    """Step 2 — verify the code and set a new password.

    Rate-limited to 10 attempts per hour per IP to slow code guessing.
    """

    permission_classes = [AllowAny]

    @method_decorator(ratelimit(key="ip", rate="10/h", method="POST", block=False))
    def post(self, request):
        if getattr(request, "limited", False):
            return Response(
                {"error": "Too many attempts. Please try again in an hour."},
                status=status.HTTP_429_TOO_MANY_REQUESTS,
            )

        serializer = PasswordResetConfirmSerializer(data=request.data)
        if not serializer.is_valid():
            errors = {}
            for field, msgs in serializer.errors.items():
                errors[field] = msgs[0] if isinstance(msgs, list) else str(msgs)
            return Response({"errors": errors}, status=status.HTTP_400_BAD_REQUEST)

        email = serializer.validated_data["email"]
        code = serializer.validated_data["code"]
        new_password = serializer.validated_data["new_password"]

        user = User.objects.filter(email__iexact=email).first()
        invalid = {"error": "Invalid or expired reset code."}
        if user is None:
            return Response(invalid, status=status.HTTP_400_BAD_REQUEST)

        token = (
            PasswordResetToken.objects.filter(user=user, code=code, is_used=False)
            .order_by("-created_at")
            .first()
        )
        if token is None or token.is_expired():
            return Response(invalid, status=status.HTTP_400_BAD_REQUEST)

        user.set_password(new_password)
        user.save()

        # Code is single-use; invalidate any other outstanding codes too.
        token.is_used = True
        token.save()
        PasswordResetToken.objects.filter(user=user, is_used=False).update(is_used=True)

        return Response({"message": "Password reset successfully. You can now sign in."})
